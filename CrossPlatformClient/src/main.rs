mod history;

use arboard::Clipboard;
use eframe::egui::{self, Color32, CornerRadius, Key as EguiKey, RichText, Vec2};
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
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc,
    },
    thread,
    time::{Duration, Instant},
};

const LIMIT: usize = 500;

const CJK_FONT_PATHS: [&str; 7] = [
    "/System/Library/Fonts/PingFang.ttc",
    "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
    r"C:\Windows\Fonts\msyh.ttc",
    r"C:\Windows\Fonts\simhei.ttf",
    "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
    "/usr/share/fonts/noto-cjk/NotoSansCJK-Regular.ttc",
    "/usr/share/fonts/truetype/wqy/wqy-microhei.ttc",
];

fn main() -> eframe::Result {
    let hotkey_manager = GlobalHotKeyManager::new().ok();
    let hotkey_registered = hotkey_manager.as_ref().is_some_and(|manager| {
        manager
            .register(HotKey::new(Some(Modifiers::CONTROL | Modifiers::SHIFT), Code::KeyV))
            .is_ok()
    });
    let viewport = egui::ViewportBuilder::default()
        .with_title("Just Paste")
        .with_inner_size([430.0, 560.0])
        .with_min_inner_size([360.0, 420.0])
        .with_icon(
            eframe::icon_data::from_png_bytes(include_bytes!("../assets/just-paste-icon.png"))
                .expect("bundled Just Paste icon must be valid PNG"),
        );
    eframe::run_native(
        "Just Paste",
        eframe::NativeOptions {
            viewport,
            ..Default::default()
        },
        Box::new(move |cc| Ok(Box::new(App::new(cc, hotkey_registered)))),
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
    show: Arc<AtomicBool>,
    persist: bool,
}

impl App {
    fn new(cc: &eframe::CreationContext<'_>, hotkey_registered: bool) -> Self {
        configure_style(&cc.egui_ctx);
        install_cjk_font(&cc.egui_ctx);
        let (items, persist, mut status) = match load() {
            Ok(items) => (items, true, String::new()),
            Err(error) => (Vec::new(), false, format!("历史记录读取失败：{error}")),
        };
        if !hotkey_registered {
            let message = "全局热键不可用";
            status = if status.is_empty() {
                message.into()
            } else {
                format!("{message}；{status}")
            };
        }
        let show = Arc::new(AtomicBool::new(false));
        {
            let show = show.clone();
            let ctx = cc.egui_ctx.clone();
            thread::spawn(move || {
                while let Ok(event) = GlobalHotKeyEvent::receiver().recv() {
                    if event.state == HotKeyState::Pressed {
                        show.store(true, Ordering::SeqCst);
                        ctx.request_repaint();
                    }
                }
            });
        }
        Self {
            items,
            query: String::new(),
            clipboard: Clipboard::new().ok(),
            last_text: String::new(),
            last_poll: Instant::now(),
            status,
            selected: 0,
            visible: true,
            show,
            persist,
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
                    self.save();
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
        if !self.persist {
            self.status = "历史记录读取失败，已阻止写入以保护原文件".into();
            return;
        }
        if let Err(error) = save(&self.items) {
            self.status = format!("保存失败：{error}");
        }
    }
}

impl eframe::App for App {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        ctx.request_repaint_after(Duration::from_millis(350));
        self.poll_clipboard();
        if self.show.swap(false, Ordering::SeqCst) {
            self.visible = true;
            ctx.send_viewport_cmd(egui::ViewportCommand::Visible(true));
            ctx.send_viewport_cmd(egui::ViewportCommand::Focus);
        }

        if !self.visible {
            return;
        }

        // Keys are read outside any nested input lock: paste() and Visible(false) take the context lock.
        let indices = self.visible_indices();
        let (up, down, enter, escape) = ctx.input_mut(|i| {
            (
                i.consume_key(egui::Modifiers::NONE, EguiKey::ArrowUp),
                i.consume_key(egui::Modifiers::NONE, EguiKey::ArrowDown),
                i.consume_key(egui::Modifiers::NONE, EguiKey::Enter),
                i.consume_key(egui::Modifiers::NONE, EguiKey::Escape),
            )
        });
        if !indices.is_empty() {
            if up {
                self.selected = self.selected.saturating_sub(1).min(indices.len() - 1);
            }
            if down {
                self.selected = (self.selected + 1).min(indices.len() - 1);
            }
            if enter {
                if let Some(idx) = indices.get(self.selected) {
                    self.paste(*idx, ctx);
                }
            }
        }
        if escape {
            self.visible = false;
            ctx.send_viewport_cmd(egui::ViewportCommand::Visible(false));
        }

        egui::CentralPanel::default().show(ctx, |ui| {
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
                let mut pending_delete = None;
                egui::ScrollArea::vertical()
                    .auto_shrink([false, false])
                    .show(ui, |ui| {
                        for (vis_idx, &orig_idx) in visible.iter().enumerate() {
                            let is_selected = vis_idx == self.selected;
                            egui::Frame::new()
                                .fill(if is_selected {
                                    Color32::from_rgb(238, 194, 151)
                                } else {
                                    Color32::TRANSPARENT
                                })
                                .corner_radius(CornerRadius::same(6))
                                .show(ui, |ui| {
                                    ui.horizontal(|ui| {
                                        // Pinned icon
                                        if self.items[orig_idx].pinned {
                                            ui.label(
                                                RichText::new("📌")
                                                    .size(16.0),
                                            );
                                        }

                                        // Text content (truncated)
                                        ui.label(RichText::new(preview(&self.items[orig_idx].text)).small());

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
                                            pending_delete = Some(orig_idx);
                                        }
                                    });
                                });
                        }
                    });
                if let Some(index) = pending_delete {
                    self.delete(index);
                }
            }

            ui.separator();
            ui.horizontal(|ui| {
                ui.label(
                    RichText::new(format!(
                        "{} 条记录 · ↑↓选择 Enter粘贴 · Esc隐藏 · Ctrl+Shift+V呼出",
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

fn preview(text: &str) -> String {
    if text.chars().count() > 50 {
        let head: String = text.chars().take(50).collect();
        format!("{head}...")
    } else {
        text.to_string()
    }
}

fn install_cjk_font(ctx: &egui::Context) {
    let Some(data) = CJK_FONT_PATHS.iter().find_map(|path| fs::read(path).ok()) else {
        return;
    };
    let mut fonts = egui::FontDefinitions::default();
    fonts
        .font_data
        .insert("cjk".to_owned(), Arc::new(egui::FontData::from_owned(data)));
    for family in [egui::FontFamily::Proportional, egui::FontFamily::Monospace] {
        fonts.families.entry(family).or_default().push("cjk".to_owned());
    }
    ctx.set_fonts(fonts);
}

fn configure_style(ctx: &egui::Context) {
    let mut style = (*ctx.style()).clone();
    style.spacing.item_spacing = Vec2::new(8.0, 8.0);
    style.visuals.widgets.inactive.corner_radius = CornerRadius::same(8);
    style.visuals.widgets.hovered.corner_radius = CornerRadius::same(8);
    style.visuals.widgets.hovered.bg_fill = Color32::from_rgb(238, 194, 151);
    style.visuals.selection.bg_fill = Color32::from_rgb(204, 105, 51);
    style.scroll_animation = egui::style::ScrollAnimation::none();
    ctx.set_style(style);
}

fn data_path() -> PathBuf {
    dirs::data_local_dir()
        .unwrap_or_else(std::env::temp_dir)
        .join("JustPasteDesktop")
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
    // std::fs::rename replaces an existing target on Windows and Unix, so no pre-delete (a crash in between would lose history).
    fs::rename(&temporary, &path).or_else(|error| {
        let _ = fs::remove_file(&temporary);
        Err(error)
    })
}

#[cfg(test)]
mod tests {
    use super::preview;

    #[test]
    fn preview_truncates_cjk_by_chars_without_panicking() {
        let text = "中".repeat(60);
        assert_eq!(preview(&text), format!("{}...", "中".repeat(50)));
    }
}
