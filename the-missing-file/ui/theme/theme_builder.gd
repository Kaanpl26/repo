class_name ThemeBuilder
## Builds the game's UI theme in code so that all colours, fonts and sizes live in one place.

const FONT_SANS := "res://ui/theme/fonts/Inter.ttf"
const FONT_SERIF := "res://ui/theme/fonts/PlayfairDisplay.ttf"
const FONT_TYPE := "res://ui/theme/fonts/CourierPrime-Regular.ttf"
const FONT_TYPE_BOLD := "res://ui/theme/fonts/CourierPrime-Bold.ttf"


static func weighted(path: String, weight: int) -> FontVariation:
	var fv := FontVariation.new()
	fv.base_font = load(path)
	var tag := TextServerManager.get_primary_interface().name_to_tag("wght")
	fv.variation_opentype = {tag: weight}
	return fv


static func box(bg: Color, border: Color, border_w: int = 2, radius: int = 10, pad_h: int = 36, pad_v: int = 20) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = pad_h
	sb.content_margin_right = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_bottom = pad_v
	return sb


static func build() -> Theme:
	var t := Theme.new()
	t.default_font = weighted(FONT_SANS, 450)
	t.default_font_size = 34

	# Labels
	t.set_color("font_color", "Label", Palette.PAPER)
	t.set_constant("line_spacing", "Label", 8)

	t.set_type_variation("TitleLabel", "Label")
	t.set_font("font", "TitleLabel", weighted(FONT_SERIF, 700))
	t.set_font_size("font_size", "TitleLabel", 110)
	t.set_color("font_color", "TitleLabel", Palette.PAPER)

	t.set_type_variation("HeaderLabel", "Label")
	t.set_font("font", "HeaderLabel", weighted(FONT_SERIF, 600))
	t.set_font_size("font_size", "HeaderLabel", 52)
	t.set_color("font_color", "HeaderLabel", Palette.AMBER)

	t.set_type_variation("SmallLabel", "Label")
	t.set_font_size("font_size", "SmallLabel", 28)
	t.set_color("font_color", "SmallLabel", Palette.MUTED)

	t.set_type_variation("NameLabel", "Label")
	t.set_font("font", "NameLabel", weighted(FONT_SANS, 700))
	t.set_font_size("font_size", "NameLabel", 34)
	t.set_color("font_color", "NameLabel", Palette.AMBER)

	t.set_type_variation("PaperLabel", "Label")
	t.set_font("font", "PaperLabel", load(FONT_TYPE))
	t.set_font_size("font_size", "PaperLabel", 32)
	t.set_color("font_color", "PaperLabel", Palette.INK)
	t.set_constant("line_spacing", "PaperLabel", 10)

	t.set_type_variation("PaperTitle", "Label")
	t.set_font("font", "PaperTitle", load(FONT_TYPE_BOLD))
	t.set_font_size("font_size", "PaperTitle", 38)
	t.set_color("font_color", "PaperTitle", Palette.INK)

	# Buttons
	t.set_font("font", "Button", weighted(FONT_SANS, 600))
	t.set_font_size("font_size", "Button", 36)
	t.set_color("font_color", "Button", Palette.PAPER)
	t.set_color("font_hover_color", "Button", Palette.PAPER)
	t.set_color("font_pressed_color", "Button", Palette.NAVY)
	t.set_color("font_focus_color", "Button", Palette.PAPER)
	t.set_color("font_disabled_color", "Button", Palette.MUTED)
	t.set_stylebox("normal", "Button", box(Palette.CHARCOAL, Palette.AMBER.darkened(0.35)))
	t.set_stylebox("hover", "Button", box(Palette.SLATE, Palette.AMBER))
	t.set_stylebox("pressed", "Button", box(Palette.AMBER, Palette.AMBER))
	t.set_stylebox("disabled", "Button", box(Palette.CHARCOAL.darkened(0.2), Palette.SLATE))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())

	t.set_type_variation("ChoiceButton", "Button")
	t.set_font("font", "ChoiceButton", weighted(FONT_SANS, 500))
	t.set_font_size("font_size", "ChoiceButton", 34)
	t.set_stylebox("normal", "ChoiceButton", box(Color(Palette.NAVY, 0.94), Palette.SLATE, 2, 8, 32, 22))
	t.set_stylebox("hover", "ChoiceButton", box(Palette.SLATE, Palette.AMBER, 2, 8, 32, 22))
	t.set_stylebox("pressed", "ChoiceButton", box(Palette.AMBER, Palette.AMBER, 2, 8, 32, 22))

	t.set_type_variation("AccentButton", "Button")
	t.set_color("font_color", "AccentButton", Palette.NAVY)
	t.set_color("font_hover_color", "AccentButton", Palette.NAVY)
	t.set_color("font_focus_color", "AccentButton", Palette.NAVY)
	t.set_stylebox("normal", "AccentButton", box(Palette.AMBER, Palette.AMBER))
	t.set_stylebox("hover", "AccentButton", box(Palette.AMBER.lightened(0.15), Palette.PAPER))
	t.set_stylebox("pressed", "AccentButton", box(Palette.PAPER, Palette.PAPER))

	t.set_type_variation("DangerButton", "Button")
	t.set_stylebox("normal", "DangerButton", box(Palette.RED.darkened(0.25), Palette.RED))
	t.set_stylebox("hover", "DangerButton", box(Palette.RED, Palette.PAPER))
	t.set_stylebox("pressed", "DangerButton", box(Palette.PAPER, Palette.PAPER))

	t.set_type_variation("InsightButton", "Button")
	t.set_stylebox("normal", "InsightButton", box(Palette.JADE.darkened(0.65), Palette.JADE))
	t.set_stylebox("hover", "InsightButton", box(Palette.JADE.darkened(0.5), Palette.JADE))
	t.set_stylebox("pressed", "InsightButton", box(Palette.JADE, Palette.JADE))

	t.set_type_variation("TabButton", "Button")
	t.set_stylebox("normal", "TabButton", box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 8, 30, 18))
	t.set_stylebox("hover", "TabButton", box(Palette.SLATE, Palette.SLATE, 0, 8, 30, 18))
	t.set_stylebox("pressed", "TabButton", box(Palette.AMBER, Palette.AMBER, 0, 8, 30, 18))
	t.set_color("font_color", "TabButton", Palette.MUTED)

	# Panels
	t.set_stylebox("panel", "PanelContainer", box(Color(Palette.NAVY, 0.96), Palette.SLATE, 2, 14, 44, 36))
	t.set_type_variation("PaperPanel", "PanelContainer")
	var paper := box(Palette.PAPER, Palette.PAPER_DARK, 3, 4, 40, 32)
	paper.shadow_color = Color(0, 0, 0, 0.45)
	paper.shadow_size = 12
	t.set_stylebox("panel", "PaperPanel", paper)
	t.set_type_variation("BoardPanel", "PanelContainer")
	t.set_stylebox("panel", "BoardPanel", box(Color("2b2018"), Color("5a4028"), 10, 6, 40, 30))
	t.set_type_variation("BarPanel", "PanelContainer")
	t.set_stylebox("panel", "BarPanel", box(Color(Palette.NAVY, 0.82), Color(Palette.SLATE, 0.9), 2, 10, 28, 14))

	# Scroll bars: wide enough to see and to grab with a thumb
	var track := box(Color(Palette.SLATE, 0.55), Color(0, 0, 0, 0), 0, 14, 14, 0)
	t.set_stylebox("scroll", "VScrollBar", track)
	t.set_stylebox("scroll_focus", "VScrollBar", track)
	t.set_stylebox("grabber", "VScrollBar", box(Palette.AMBER.darkened(0.25), Color(0, 0, 0, 0), 0, 14, 14, 0))
	t.set_stylebox("grabber_highlight", "VScrollBar", box(Palette.AMBER, Color(0, 0, 0, 0), 0, 14, 14, 0))
	t.set_stylebox("grabber_pressed", "VScrollBar", box(Palette.PAPER, Color(0, 0, 0, 0), 0, 14, 14, 0))

	t.set_constant("separation", "VBoxContainer", 20)
	t.set_constant("separation", "HBoxContainer", 20)
	return t
