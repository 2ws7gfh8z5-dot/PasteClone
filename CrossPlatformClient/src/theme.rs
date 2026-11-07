//! Fluent Design token layer: neutral grays, accent blue, 4px-grid spacing,
//! 4/8px corner radii and the Segoe-UI type ramp, resolved for light/dark.

use eframe::egui::{
    self, Color32, CornerRadius, FontFamily, FontId, Margin, Stroke, TextStyle, Vec2,
};

// Corner radii (Fluent: small/medium controls 4, overlays/cards 8).
pub const RADIUS_CONTROL: u8 = 4;
pub const RADIUS_OVERLAY: u8 = 8;

// Spacing on the 4px grid.
pub const SPACE_S: f32 = 4.0;
pub const SPACE_M: f32 = 8.0;
pub const SPACE_L: f32 = 12.0;

// Type ramp (Segoe UI sizes; weight simulated via strong()).
pub const TEXT_CAPTION: f32 = 12.0;
pub const TEXT_BODY: f32 = 14.0;
pub const TEXT_TITLE: f32 = 20.0;

#[derive(Clone, Copy)]
pub struct Tokens {
    pub bg_app: Color32,
    pub bg_card: Color32,
    pub bg_subtle: Color32,
    pub bg_hover: Color32,
    pub bg_pressed: Color32,
    pub row_selected: Color32,
    pub text_primary: Color32,
    pub text_secondary: Color32,
    pub accent: Color32,
    pub on_accent: Color32,
    pub stroke: Color32,
    pub shadow: Color32,
}

pub fn tokens(dark: bool) -> Tokens {
    if dark {
        Tokens {
            bg_app: Color32::from_rgb(0x20, 0x20, 0x20),
            bg_card: Color32::from_rgb(0x2B, 0x2B, 0x2B),
            bg_subtle: Color32::from_rgb(0x28, 0x28, 0x28),
            bg_hover: Color32::from_rgb(0x38, 0x38, 0x38),
            bg_pressed: Color32::from_rgb(0x2E, 0x2E, 0x2E),
            row_selected: Color32::from_rgb(0x23, 0x36, 0x4B),
            text_primary: Color32::from_rgb(0xFF, 0xFF, 0xFF),
            text_secondary: Color32::from_rgb(0xC8, 0xC8, 0xC8),
            accent: Color32::from_rgb(0x47, 0x9E, 0xF5),
            on_accent: Color32::from_rgb(0x1B, 0x1B, 0x1B),
            stroke: Color32::from_rgb(0x44, 0x44, 0x44),
            shadow: Color32::from_black_alpha(96),
        }
    } else {
        Tokens {
            bg_app: Color32::from_rgb(0xF3, 0xF3, 0xF3),
            bg_card: Color32::from_rgb(0xFF, 0xFF, 0xFF),
            bg_subtle: Color32::from_rgb(0xFA, 0xFA, 0xFA),
            bg_hover: Color32::from_rgb(0xEB, 0xEB, 0xEB),
            bg_pressed: Color32::from_rgb(0xE0, 0xE0, 0xE0),
            row_selected: Color32::from_rgb(0xEB, 0xF3, 0xFC),
            text_primary: Color32::from_rgb(0x24, 0x24, 0x24),
            text_secondary: Color32::from_rgb(0x61, 0x61, 0x61),
            accent: Color32::from_rgb(0x0F, 0x6C, 0xBD),
            on_accent: Color32::from_rgb(0xFF, 0xFF, 0xFF),
            stroke: Color32::from_rgb(0xE0, 0xE0, 0xE0),
            shadow: Color32::from_black_alpha(48),
        }
    }
}

pub fn apply(ctx: &egui::Context, dark: bool) {
    let t = tokens(dark);
    let mut style = (*ctx.style()).clone();

    let mut v = if dark {
        egui::Visuals::dark()
    } else {
        egui::Visuals::light()
    };
    v.panel_fill = t.bg_app;
    v.window_fill = t.bg_app;
    v.faint_bg_color = t.bg_subtle;
    v.extreme_bg_color = t.bg_card;
    v.hyperlink_color = t.accent;
    v.window_stroke = Stroke::new(1.0_f32, t.stroke);
    let elevation = egui::epaint::Shadow {
        offset: [0, 4],
        blur: 16,
        spread: 0,
        color: t.shadow,
    };
    v.window_shadow = elevation;
    v.popup_shadow = elevation;
    v.selection.bg_fill = t.accent;
    v.selection.stroke = Stroke::new(1.0_f32, t.accent);

    v.widgets.noninteractive.weak_bg_fill = t.bg_subtle;
    v.widgets.noninteractive.bg_stroke = Stroke::new(1.0_f32, t.stroke);
    v.widgets.noninteractive.fg_stroke = Stroke::new(1.0_f32, t.text_primary);
    v.widgets.noninteractive.corner_radius = CornerRadius::same(RADIUS_OVERLAY);
    v.widgets.inactive.weak_bg_fill = t.bg_subtle;
    v.widgets.inactive.bg_fill = t.bg_card;
    v.widgets.inactive.bg_stroke = Stroke::new(1.0_f32, t.stroke);
    v.widgets.inactive.fg_stroke = Stroke::new(1.0_f32, t.text_primary);
    v.widgets.inactive.corner_radius = CornerRadius::same(RADIUS_CONTROL);
    v.widgets.hovered.weak_bg_fill = t.bg_hover;
    v.widgets.hovered.bg_fill = t.bg_hover;
    v.widgets.hovered.bg_stroke = Stroke::new(1.0_f32, t.stroke);
    v.widgets.hovered.fg_stroke = Stroke::new(1.0_f32, t.text_primary);
    v.widgets.hovered.corner_radius = CornerRadius::same(RADIUS_CONTROL);
    v.widgets.active.weak_bg_fill = t.bg_pressed;
    v.widgets.active.bg_fill = t.bg_pressed;
    v.widgets.active.fg_stroke = Stroke::new(1.0_f32, t.text_primary);
    v.widgets.active.corner_radius = CornerRadius::same(RADIUS_CONTROL);
    v.widgets.open.weak_bg_fill = t.bg_hover;
    v.widgets.open.corner_radius = CornerRadius::same(RADIUS_CONTROL);

    style.visuals = v;
    style.spacing.item_spacing = Vec2::new(SPACE_M, SPACE_M - 2.0);
    style.spacing.button_padding = Vec2::new(SPACE_L, SPACE_S);
    style.spacing.window_margin = Margin::same(12);
    style.text_styles.insert(
        TextStyle::Heading,
        FontId::new(TEXT_TITLE, FontFamily::Proportional),
    );
    style.text_styles.insert(
        TextStyle::Body,
        FontId::new(TEXT_BODY, FontFamily::Proportional),
    );
    style.text_styles.insert(
        TextStyle::Button,
        FontId::new(TEXT_BODY, FontFamily::Proportional),
    );
    style.text_styles.insert(
        TextStyle::Small,
        FontId::new(TEXT_CAPTION, FontFamily::Proportional),
    );
    style
        .text_styles
        .insert(TextStyle::Monospace, FontId::new(13.0, FontFamily::Monospace));
    style.scroll_animation = egui::style::ScrollAnimation::none();
    ctx.set_style(style);
}
