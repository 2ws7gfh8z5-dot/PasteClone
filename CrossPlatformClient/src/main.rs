mod history;

use arboard::Clipboard;
use eframe::egui::{self, Color32, CornerRadius, RichText, Stroke, Vec2};
use enigo::{Direction::{Click, Press, Release}, Enigo, Key, Keyboard, Settings};
use global_hotkey::{hotkey::{Code, HotKey, Modifiers}, GlobalHotKeyEvent, GlobalHotKeyManager};
use history::{insert, Clip};
use std::{fs, path::PathBuf, sync::mpsc, thread, time::{Duration, Instant}};

const LIMIT: usize = 500;

fn main() -> eframe::Result {
    let (show_tx, show_rx) = mpsc::channel();
    thread::spawn(move || {
        let manager = GlobalHotKeyManager::new().ok();
        let hotkey = HotKey::new(Some(Modifiers::CONTROL | Modifiers::SHIFT), Code::KeyV);
        if let Some(manager) = manager.as_ref() { let _ = manager.register(hotkey); }
        let receiver = GlobalHotKeyEvent::receiver();
        while receiver.recv().is_ok() { let _ = show_tx.send(()); }
    });

    let viewport = egui::ViewportBuilder::default()
        .with_title("PasteClone")
        .with_inner_size([430.0, 560.0])
        .with_min_inner_size([360.0, 420.0]);
    eframe::run_native("PasteClone", eframe::NativeOptions { viewport, ..Default::default() },
        Box::new(|cc| Ok(Box::new(App::new(cc, show_rx)))))
}

struct App {
    items: Vec<Clip>,
    query: String,
    clipboard: Option<Clipboard>,
    last_text: String,
    last_poll: Instant,
    show_rx: mpsc::Receiver<()>,
    status: String,
}

impl App {
    fn new(cc: &eframe::CreationContext<'_>, show_rx: mpsc::Receiver<()>) -> Self {
        configure_style(&cc.egui_ctx);
        Self {
            items: load(), query: String::new(), clipboard: Clipboard::new().ok(),
            last_text: String::new(), last_poll: Instant::now(), show_rx, status: String::new(),
        }
    }

    fn poll_clipboard(&mut self) {
        if self.last_poll.elapsed() < Duration::from_millis(350) { return; }
        self.last_poll = Instant::now();
        if let Some(clipboard) = &mut self.clipboard {
            if let Ok(text) = clipboard.get_text() {
                if text != self.last_text {
                    self.last_text = text.clone();
                    insert(&mut self.items, text, LIMIT);
                    save(&self.items);
                }
            }
        }
    }

    fn paste(&mut self, index: usize) {
        let Some(item) = self.items.get(index) else { return };
        if let Some(clipboard) = &mut self.clipboard {
            if clipboard.set_text(item.text.clone()).is_ok() {
                self.last_text = item.text.clone();
                thread::spawn(|| {
                    thread::sleep(Duration::from_millis(120));
                    if let Ok(mut enigo) = Enigo::new(&Settings::default()) {
                        let _ = enigo.key(Key::Control, Press);
                        let _ = enigo.key(Key::Unicode('v'), Click);
                        let _ = enigo.key(Key::Control, Release);
                    }
                });
                self.status = "已粘贴到当前输入框".into();
            }
        }
    }
}

impl eframe::App for App {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        self.poll_clipboard();
        while self.show_rx.try_recv().is_ok() {
            ctx.send_viewport_cmd(egui::ViewportCommand::Visible(true));
            ctx.send_viewport_cmd(egui::ViewportCommand::Focus);
        }
        ctx.request_repaint_after(Duration::from_millis(100));

        egui::CentralPanel::default().frame(egui::Frame::new().fill(Color32::from_rgb(250, 246, 237)).inner_margin(16.0)).show(ctx, |ui| {
            ui.horizontal(|ui| {
                ui.heading(RichText::new("PasteClone").strong().color(Color32::from_rgb(42, 35, 29)));
                ui.add_space(8.0);
                ui.add_sized([ui.available_width(), 32.0], egui::TextEdit::singleline(&mut self.query).hint_text("搜索剪贴板…"));
            });
            ui.add_space(10.0);
            let query = self.query.to_lowercase();
            let visible: Vec<usize> = self.items.iter().enumerate().filter(|(_, item)| item.text.to_lowercase().contains(&query)).map(|(i, _)| i).collect();
            let mut action = None;
            egui::ScrollArea::vertical().auto_shrink([false, false]).show(ui, |ui| {
                for index in visible {
                    let item = &self.items[index];
                    egui::Frame::new().fill(Color32::from_rgb(255, 253, 248)).stroke(Stroke::new(1.0_f32, Color32::from_rgb(224, 215, 201))).corner_radius(CornerRadius::same(10)).inner_margin(10.0).show(ui, |ui| {
                        ui.horizontal(|ui| {
                            ui.label(RichText::new(if item.pinned { "📌" } else { "T" }).size(16.0));
                            ui.add_sized([ui.available_width() - 90.0, 38.0], egui::Label::new(RichText::new(&item.text).color(Color32::from_rgb(42, 35, 29))).truncate());
                            if ui.button("粘贴 ↵").on_hover_text("粘贴到当前输入框").clicked() { action = Some(("paste", index)); }
                            if ui.small_button(if item.pinned { "取消固定" } else { "固定" }).clicked() { action = Some(("pin", index)); }
                        });
                    });
                    ui.add_space(7.0);
                }
            });
            if let Some((kind, index)) = action {
                if kind == "paste" { self.paste(index); }
                else if let Some(item) = self.items.get_mut(index) { item.pinned = !item.pinned; save(&self.items); }
            }
            ui.separator();
            ui.horizontal(|ui| {
                ui.label(RichText::new(format!("{} 条记录", self.items.len())).small().color(Color32::from_rgb(105, 92, 79)));
                ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                    if ui.button("清除未固定").clicked() { self.items.retain(|item| item.pinned); save(&self.items); }
                    ui.label(RichText::new(&self.status).small().color(Color32::from_rgb(204, 105, 51)));
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
    dirs::data_local_dir().unwrap_or_else(std::env::temp_dir).join("PasteClone").join("history.json")
}
fn load() -> Vec<Clip> { fs::read(data_path()).ok().and_then(|bytes| serde_json::from_slice(&bytes).ok()).unwrap_or_default() }
fn save(items: &[Clip]) {
    let path = data_path();
    if let Some(parent) = path.parent() { let _ = fs::create_dir_all(parent); }
    if let Ok(data) = serde_json::to_vec(items) { let _ = fs::write(path, data); }
}
