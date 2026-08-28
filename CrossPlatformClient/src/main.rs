mod history;

use arboard::Clipboard;
use eframe::egui::{self, Color32, CornerRadius, Key as EguiKey, RichText, Stroke, Vec2};
use enigo::{
    Direction::{Click, Press, Release},
    Enigo, Key, Keyboard, Settings,
};
use global_hotkey::{
    hotkey::{Code, HotKey, Modifiers},
    GlobalHotKeyEvent, GlobalHotKeyManager, HotKeyState,
};
use history::{insert, Clip};
use std::{
    fs, io,
    path::PathBuf,
    sync::mpsc,
    thread,
    time::{Duration, Instant},
};

const LIMIT: usize = 500;

fn main() -> eframe::Result {
    let (show_tx, show_rx) = mpsc::channel();
    thread::spawn(move || {
        let manager = GlobalHotKeyManager::new().ok();
        let hotkey = HotKey::new(Some(Modifiers::CONTROL | Modifiers::SHIFT), Code::KeyV);
        if let Some(manager) = manager.as_ref() {
            let _ = manager.register(hotkey);
        }
        let receiver = GlobalHotKeyEvent::receiver();
        while let Ok(event) = receiver.recv() {
            if event.id == hotkey.id() && event.state == HotKeyState::Pressed {
                let _ = show_tx.send(());
            }
        }
    });
    let viewport = egui::ViewportBuilder::default()
        .with_title("PasteClone")
        .with_inner_size([430.0, 560.0])
        .with_min_inner_size([360.0, 420.0]);
    eframe::run_native(
        "PasteClone",
        eframe::NativeOptions {
            viewport,
            ..Default::default()
        },
        Box::new(|cc| Ok(Box::new(App::new(cc, show_rx)))),
    )
}

struct App {
    items: Vec<Clip>,
    query: String,
    clipboard: Option<Clipboard>,
    last_text: String,
    last_poll: Instant,
    show_rx: mpsc::Receiver<()>,
    status: String,
    selected: usize,
    visible: bool,
}

impl App {
    fn new(cc: &eframe::CreationContext<'_>, show_rx: mpsc::Receiver<()>) -> Self {
        configure_style(&cc.egui_ctx);
        let (items, status) = match load() {
            Ok(items) => (items, String::new()),
            Err(error) => (Vec::new(), format!("历史记录读取失败：{error}")),
        };
        Self {
            items,
            query: String::new(),
            clipboard: Clipboard::new().ok(),
            last_text: String::new(),
            last_poll: Instant::now(),
            show_rx,
            status,
            selected: 0,
            visible: true,
        }
    }
    fn visible_indices(&self) -> Vec<usize> {
        let query = self.query.to_lowercase();
        self.items
            .iter()
            .enumerate()
            .filter(|(_, i)| i.text.to_lowercase().contains(&query))
            .map(|(i, _)| i)
            .collect()
    }
    fn poll_clipboard(&mut self) {
        if self.last_poll.elapsed() < Duration::from_millis(350) {
            return;
        }
        self.last_poll = Instant::now();
        if let Some(clipboard) = &mut self.clipboard {
            if let Ok(text) = clipboard.get_text() {
                if text != self.last_text {
                    self.last_text = text.clone();
                    insert(&mut self.items, text, LIMIT);
                    if let Err(error) = save(&self.items) {
                        self.status = format!("历史记录保存失败：{error}");
                    }
                }
            }
        }
    }
    fn paste(&mut self, index: usize, ctx: &egui::Context) {
        let Some(item) = self.items.get(index) else {
            return;
        };
        let text = item.text.clone();
        if let Some(clipboard) = &mut self.clipboard {
            if clipboard.set_text(text.clone()).is_ok() {
                self.last_text = text;
                // Hide first so the previously active editor regains focus before synthetic paste.
                self.visible = false;
                ctx.send_viewport_cmd(egui::ViewportCommand::Visible(false));
                thread::spawn(|| {
                    thread::sleep(Duration::from_millis(150));
                    if let Ok(mut enigo) = Enigo::new(&Settings::default()) {
                        #[cfg(target_os = "macos")]
                        {
                            let _ = enigo.key(Key::Meta, Press);
                            let _ = enigo.key(Key::Unicode('v'), Click);
                            let _ = enigo.key(Key::Meta, Release);
                        }
                        #[cfg(not(target_os = "macos"))]
                        {
                            let _ = enigo.key(Key::Control, Press);
                            let _ = enigo.key(Key::Unicode('v'), Click);
                            let _ = enigo.key(Key::Control, Release);
                        }
                    }
                });
                self.status = "已粘贴到当前输入框".into();
            } else {
                self.status = "无法写入系统剪贴板".into();
            }
        } else {
            self.status = "剪贴板不可用，请检查系统权限".into();
        }
    }
    fn save(&mut self) {
        if let Err(error) = save(&self.items) {
            self.status = format!("历史记录保存失败：{error}");
        }
    }
    fn delete(&mut self, index: usize) {
        if index < self.items.len() {
            self.items.remove(index);
            self.selected = self.selected.min(self.items.len().saturating_sub(1));
            self.save();
        }
    }
}

impl eframe::App for App {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        self.poll_clipboard();
        while self.show_rx.try_recv().is_ok() {
            self.visible = true;
            ctx.send_viewport_cmd(egui::ViewportCommand::Visible(true));
            ctx.send_viewport_cmd(egui::ViewportCommand::Focus);
        }
        let visible = self.visible_indices();
        let search_focused = ctx.memory(|memory| memory.focused() == Some(egui::Id::new("search")));
        ctx.input(|input| {
            if input.key_pressed(EguiKey::Escape) {
                self.visible = false;
                ctx.send_viewport_cmd(egui::ViewportCommand::Visible(false));
            }
            if input.modifiers.command && input.key_pressed(EguiKey::F) {
                ctx.memory_mut(|m| m.request_focus(egui::Id::new("search")));
            }
            if search_focused {
                return;
            }
            if input.key_pressed(EguiKey::ArrowDown) && !visible.is_empty() {
                self.selected = (self.selected + 1).min(visible.len() - 1);
            }
            if input.key_pressed(EguiKey::ArrowUp) {
                self.selected = self.selected.saturating_sub(1);
            }
            if input.key_pressed(EguiKey::Enter) {
                if let Some(&i) = visible.get(self.selected) {
                    self.paste(i, ctx);
                }
            }
            if input.key_pressed(EguiKey::Delete) {
                if let Some(&i) = visible.get(self.selected) {
                    self.delete(i);
                }
            }
            if input.modifiers.command && input.key_pressed(EguiKey::P) {
                if let Some(&i) = visible.get(self.selected) {
                    if let Some(item) = self.items.get_mut(i) {
                        item.pinned = !item.pinned;
                    }
                    self.save();
                }
            }
            for (n, key) in [
                EguiKey::Num1,
                EguiKey::Num2,
                EguiKey::Num3,
                EguiKey::Num4,
                EguiKey::Num5,
                EguiKey::Num6,
                EguiKey::Num7,
                EguiKey::Num8,
                EguiKey::Num9,
            ]
            .iter()
            .enumerate()
            {
                if input.key_pressed(*key) && input.modifiers.command {
                    if let Some(&i) = visible.get(n) {
                        self.paste(i, ctx);
                    }
                }
            }
        });
        ctx.request_repaint_after(Duration::from_millis(100));
        egui::CentralPanel::default()
            .frame(
                egui::Frame::new()
                    .fill(Color32::from_rgb(250, 246, 237))
                    .inner_margin(16.0),
            )
            .show(ctx, |ui| {
                ui.horizontal(|ui| {
                    ui.heading(
                        RichText::new("PasteClone")
                            .strong()
                            .color(Color32::from_rgb(42, 35, 29)),
                    );
                    ui.add_space(8.0);
                    ui.add_sized(
                        [ui.available_width(), 32.0],
                        egui::TextEdit::singleline(&mut self.query)
                            .id(egui::Id::new("search"))
                            .hint_text("搜索剪贴板…"),
                    );
                });
                ui.add_space(10.0);
                let mut action: Option<(&str, usize)> = None;
                egui::ScrollArea::vertical()
                    .auto_shrink([false, false])
                    .show(ui, |ui| {
                        for (position, index) in visible.iter().enumerate() {
                            let item = &self.items[*index];
                            let selected = position == self.selected;
                            egui::Frame::new()
                                .fill(if selected {
                                    Color32::from_rgb(255, 242, 224)
                                } else {
                                    Color32::from_rgb(255, 253, 248)
                                })
                                .stroke(Stroke::new(1.0_f32, Color32::from_rgb(224, 215, 201)))
                                .corner_radius(CornerRadius::same(10))
                                .inner_margin(10.0)
                                .show(ui, |ui| {
                                    ui.horizontal(|ui| {
                                        ui.label(
                                            RichText::new(if item.pinned { "P" } else { "T" })
                                                .size(16.0),
                                        );
                                        ui.add_sized(
                                            [(ui.available_width() - 150.0).max(40.0), 38.0],
                                            egui::Label::new(
                                                RichText::new(&item.text)
                                                    .color(Color32::from_rgb(42, 35, 29)),
                                            )
                                            .truncate(),
                                        );
                                        if ui
                                            .button("粘贴 ↵")
                                            .on_hover_text("粘贴到当前输入框")
                                            .clicked()
                                        {
                                            action = Some(("paste", *index));
                                        }
                                        if ui
                                            .small_button(if item.pinned {
                                                "取消固定"
                                            } else {
                                                "固定"
                                            })
                                            .clicked()
                                        {
                                            action = Some(("pin", *index));
                                        }
                                        if ui.small_button("删除").clicked() {
                                            action = Some(("delete", *index));
                                        }
                                    });
                                });
                            ui.add_space(7.0);
                        }
                    });
                if let Some((kind, index)) = action {
                    match kind {
                        "paste" => self.paste(index, ctx),
                        "delete" => self.delete(index),
                        _ => {
                            if let Some(item) = self.items.get_mut(index) {
                                item.pinned = !item.pinned;
                            }
                            self.save();
                        }
                    }
                }
                ui.separator();
                ui.horizontal(|ui| {
                    ui.label(
                        RichText::new(format!(
                            "{} 条记录 · ↑↓选择 Enter粘贴 · Esc隐藏",
                            self.items.len()
                        ))
                        .small()
                        .color(Color32::from_rgb(105, 92, 79)),
                    );
                    ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                        if ui.button("清除未固定").clicked() {
                            self.items.retain(|i| i.pinned);
                            self.save();
                        }
                        ui.label(
                            RichText::new(&self.status)
                                .small()
                                .color(Color32::from_rgb(204, 105, 51)),
                        );
                    });
                });
            });
    }
}
fn configure_style(ctx: &egui::Context) {
    let mut style = (*ctx.style()).clone();
    style.spacing.item_spacing = Vec2::new(8.0, 8.0);
    style.visuals.widgets.inactive.corner_radius = CornerRadius::same(8);
    style.visuals.widgets.hovered.corner_radius = CornerRadius::same(8);
    style.visuals.widgets.hovered.bg_fill = Color32::from_rgb(238, 194, 151);
    style.visuals.selection.bg_fill = Color32::from_rgb(204, 105, 51);
    ctx.set_style(style);
}
fn data_path() -> PathBuf {
    dirs::data_local_dir()
        .unwrap_or_else(std::env::temp_dir)
        .join("PasteClone")
        .join("history.json")
}
fn load() -> io::Result<Vec<Clip>> {
    let path = data_path();
    match fs::read(path) {
        Ok(data) => serde_json::from_slice(&data).map_err(io::Error::other),
        Err(error) if error.kind() == io::ErrorKind::NotFound => Ok(Vec::new()),
        Err(error) => Err(error),
    }
}
fn save(items: &[Clip]) -> io::Result<()> {
    let path = data_path();
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    let temporary = path.with_extension("json.tmp");
    let data = serde_json::to_vec(items).map_err(io::Error::other)?;
    fs::write(&temporary, data)?;
    #[cfg(target_os = "windows")]
    if path.exists() {
        fs::remove_file(&path)?;
    }
    fs::rename(&temporary, &path).or_else(|error| {
        let _ = fs::remove_file(&temporary);
        Err(error)
    })
}
