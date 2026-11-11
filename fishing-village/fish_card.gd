extends PanelContainer

# Colour map for fish icons — purely visual
const FISH_COLORS: Dictionary = {
	"Sardine": Color(0.70, 0.75, 0.80),
	"Mackerel": Color(0.30, 0.55, 0.70),
	"Bass": Color(0.20, 0.45, 0.30),
	"Snapper": Color(0.85, 0.30, 0.20),
	"Tuna": Color(0.15, 0.25, 0.60),
	"Swordfish": Color(0.55, 0.55, 0.70),
	"Oarfish": Color(0.70, 0.20, 0.70),
	"Kraken Arm": Color(0.10, 0.10, 0.10),
}

@onready var fish_icon: ColorRect = $HBoxContainer/FishIcon
@onready var fish_name: Label = $HBoxContainer/FishName
@onready var fish_value: Label = $HBoxContainer/FishValue

# Called right after instantiation by game.gd
func setup(fish_data: Dictionary, sell_bonus_pct: float) -> void:
	var value = int(fish_data.value * (1.0 + sell_bonus_pct))
	fish_name.text = fish_data.name
	fish_value.text = "%dg" % value
	fish_icon.color = FISH_COLORS.get(fish_data.name, Color.GREY)
