extends CanvasLayer
### The HUD. Counts beads, shows the win.

@onready var bead_label: Label = $BeadLabel
@onready var win_label: Label = $WinLabel

var beads_collected := 0
var beads_total := 0

func _ready() -> void:
	win_label.visible = false
	for bead in get_tree().get_nodes_in_group("beads"):
		bead.collected.connect(_on_bead_collected)
	beads_total = get_tree().get_nodes_in_group("beads").size()
	_update_label()

func _on_bead_collected() -> void:
	beads_collected += 1
	_update_label()

func _update_label() -> void:
	bead_label.text = "Beads: %d / %d" % [
		beads_collected, beads_total]

func show_win() -> void:
	win_label.visible = true
