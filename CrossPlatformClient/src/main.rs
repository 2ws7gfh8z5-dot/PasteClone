mod history;

use arboard::Clipboard;
use eframe::egui::{self, Color32, CornerRadius, Key as EguiKey, RichText, Vec2};
use enigo::{
    Direction::{Click, Press, Release},
    Enigo, Key, Keyboard, Settings,
};
use history::{insert, Clip};
use std::{
    fs, io,
    path::PathBuf,
    thread,
    time::{Duration, Instant},
};

const LIMIT: usize = 500;

fn main() -> eframe::Result {
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
        Box::new(|cc| Ok(Box::new(App::new(cc)))),
    )
}

struct App {
    items: Vec<Clip>,
    query: String,
    clipboard: Option<Clipboard>,
    last_text: String,
    last_poll: Instant,
    status: String,
    selected: usize,
    visible: bool,
}

impl App {
    fn new(cc: &eframe::CreationContext<'_>) -> Self {
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
            status,
            selected: 0,
            visible: false, // Fixed: start hidden
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
                    // Fixed: increased delay from 150ms to 300ms for better reliability
                    // on Windows/Linux where input injection timing is less predictable
                    thread::sleep(Duration::from_millis(300));
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
    fn delete(&mut self, index: usize) {
        if index < self.items.len() {
            self.items.remove(index);
            self.save();
        }
    }
    fn save(&mut self) {
        if let Err(error) = save(&self.items) {
            self.status = format!("保存失败：{error}");
        }
    }
}

impl eframe::App for App {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        // Toggle visibility with Ctrl+Shift+V (handled via egui hotkey)
        if ctx.input_mut(|i| i.consume_key(egui::Modifiers::CTRL | egui::Modifiers::SHIFT, EguiKey::V)) {
            self.visible = !self.visible;
        }
        
        if !self.visible {
            return;
        }
        
        // Always poll clipboard when visible
        self.poll_clipboard();
        
        egui::CentralPanel::default().show(ctx, |ui| {
            // Keyboard navigation
            ui.input_mut(|i| {
                let visible = self.visible_indices();
                if visible.is_empty() {
                    return;
                }
                
                // Up arrow
                if i.consume_key(egui::Modifiers::NONE, EguiKey::ArrowUp) {
                    self.selected = self.selected.saturating_sub(1).min(visible.len() - 1);
                }
                // Down arrow
                if i.consume_key(egui::Modifiers::NONE, EguiKey::ArrowDown) {
                    self.selected = (self.selected + 1).min(visible.len() - 1);
                }
                // Enter to paste
                if i.consume_key(egui::Modifiers::NONE, EguiKey::Enter) {
                    if let Some(idx) = visible.get(self.selected) {
                        self.paste(*idx, ctx);
                    }
                }
                // Escape to hide
                if i.consume_key(egui::Modifiers::NONE, EguiKey::Escape) {
                    self.visible = false;
                }
            });
            
            ui.heading("剪贴板历史");
            ui.separator();
            
            // Search box
            ui.horizontal(|ui| {
                ui.text_edit_singleline(&mut self.query);
                if ui.button("清空搜索").clicked() {
                    self.query.clear();
                }
            });
            ui.separator();
            
            // List items
            let visible = self.visible_indices();
            if visible.is_empty() {
                ui.centered_and_justified(|ui| {
                    ui.label(
                        if self.query.is_empty() {
                            RichText::new("暂无历史记录\n请先复制一些内容").color(Color32::from_rgb(150, 140, 130))
                        } else {
                            RichText::new("没有找到匹配的记录").color(Color32::from_rgb(150, 140, 130))
                        }
                    );
                });
            } else {
                for (vis_idx, &orig_idx) in visible.iter().enumerate() {
                    let is_selected = vis_idx == self.selected;
                    ui.horizontal(|ui| {
                        if is_selected {
                            ui.visuals_mut().selection.bg_fill = Color32::from_rgb(204, 105, 51);
                        }
                        
                        // Pinned icon
                        if self.items[orig_idx].pinned {
                            ui.label(
                                RichText::new("📌")
                                    .size(16.0),
                            );
                        }
                        
                        // Text content (truncated)
                        let text = &self.items[orig_idx].text;
                        let display_text = if text.len() > 50 {
                            format!("{}...", &text[..50])
                        } else {
                            text.clone()
                        };
                        ui.label(RichText::new(display_text).small());
                        
                        // Paste button
                        if ui.small_button("粘贴").clicked() {
                            self.paste(orig_idx, ctx);
                        }
                        
                        // Pin/Unpin button
                        if ui.small_button(if self.items[orig_idx].pinned { "取消" } else { "固定" }).clicked() {
                            self.items[orig_idx].pinned = !self.items[orig_idx].pinned;
                            self.save();
                        }
                        
                        // Delete button
                        if ui.small_button("删除").clicked() {
                            self.delete(orig_idx);
                        }
                    });
                }
            }
            
            ui.separator();
            ui.horizontal(|ui| {
                ui.label(
                    RichText::new(format!(
                        "{} 条记录 · ↑↓选择 Enter粘贴 · Esc隐藏 · Ctrl+Shift+V切换",
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
                    if ui.button("全部清除").clicked() {
                        self.items.clear();
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
    // Fixed: atomic rename without pre-deletion on Windows
    // ponytail: Windows rename may fail if target exists; use overwrite flag if needed
    #[cfg(target_os = "windows")]
    fs::remove_file(&path).ok(); // Best-effort removal
    fs::rename(&temporary, &path).or_else(|error| {
        let _ = fs::remove_file(&temporary);
        Err(error)
    })
}
