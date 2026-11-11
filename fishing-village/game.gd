extends Node2D

# In game.gd — defined as a constant at the top of the file
# name, value, min_rod, weight
const FISH_TABLE: Array[Dictionary] = [
	{ name = "Sardine", value = 2, min_rod = 1, weight = 60 },
	{ name = "Mackerel", value = 5, min_rod = 1, weight = 35 },
	{ name = "Bass", value = 12, min_rod = 2, weight = 25 },
	{ name = "Snapper", value = 18, min_rod = 2, weight = 18 },
	{ name = "Tuna", value = 35, min_rod = 3, weight = 10 },
	{ name = "Swordfish", value = 60, min_rod = 3, weight = 5 },
	{ name = "Oarfish", value = 150, min_rod = 4, weight = 2 },
	{ name = "Kraken Arm", value = 500, min_rod = 5, weight = 1 },
]

const UPGRADE_TABLE: Array[Dictionary] = [
	{
		id = "rod",
		label = "Better Rod",
		desc = "Unlocks rarer fish and reduces bite wait time",
		base_cost = 20,
		cost_mult = 2.2,
		max_level = 5,
	},
	{
		id = "boat",
		label = "Bigger Boat",
		desc = "Increases inventory capacity by 3 fish per level",
		base_cost = 35,
		cost_mult = 2.0,
		max_level = 4,
	},
	{
		id = "market",
		label = "Market Permit",
		desc = "Adds 20% bonus to all sell prices per level",
		base_cost = 50,
		cost_mult = 2.5,
		max_level = 3,
	},
]

const SAVE_PATH = "user://fishing_village.save"

# Derived gameplay values
func get_inventory_cap() -> int:
	return 3 + player_data.boat_level * 3

func get_bite_wait() -> float:
	return max(4.0 - player_data.rod_level * 0.6, 1.2)

func get_sell_bonus() -> float:
	return player_data.market_level * 0.20

# Player persistent data — saved to and loaded from disk
var player_data: Dictionary = {
	coins = 0,
	rod_level = 1,
	boat_level = 1,
	market_level = 0,
	last_save_time = 0,
}

# Runtime state (never saved)
var inventory: Array[Dictionary] = [] # Fish currently in the hold
var is_fishing: bool = false
var _bite_pending: bool = false
var fish_on_hook: Dictionary = {}

@onready var bobber = $UI/Bobber
@onready var cast_button = $UI/CastButton
@onready var reel_button = $UI/ReelButton
@onready var sell_button = $UI/SellButton
@onready var coins_label = $UI/CoinsLabel
@onready var status_label = $UI/StatusLabel
@onready var catch_label = $UI/CatchLabel
@onready var inventory_panel = $UI/InventoryPanel
@onready var upgrade_panel = $UI/UpgradePanel

func _ready() -> void:
	_load_game()
	_connect_buttons()
	_build_upgrade_panel()
	_update_all_hud()
	bobber.bite_ready.connect(_on_bite_ready)
	bobber.bite_missed.connect(_on_bite_missed)
	# Shimmer animation
	var sh = create_tween().set_loops()
	sh.tween_property($UI/Shimmer, "position:y", 80.0, 3.0).set_trans(Tween.TRANS_SINE)
	sh.tween_property($UI/Shimmer, "position:y", 160.0, 3.0).set_trans(Tween.TRANS_SINE)

func _connect_buttons() -> void:
	cast_button.pressed.connect(_on_cast_pressed)
	reel_button.pressed.connect(_on_reel_pressed)
	sell_button.pressed.connect(_on_sell_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_just_pressed("cast"):
		_on_cast_pressed()
	elif event.is_action_just_pressed("reel"):
		_on_reel_pressed()

func _on_cast_pressed() -> void:
	if is_fishing:
		return
	if inventory.size() >= get_inventory_cap():
		status_label.text = "Hold is full! Sell your fish first."
		return
	is_fishing = true
	_bite_pending = false
	cast_button.disabled = true
	reel_button.disabled = false
	# Place bobber in the water (centre of the ocean area)
	var water_pos = Vector2(randf_range(120, 360), randf_range(80, 150))
	bobber.cast(water_pos)
	status_label.text = "Waiting for a bite..."
	# Schedule the bite after a random wait
	var wait = randf_range(get_bite_wait() * 0.7, get_bite_wait() * 1.3)
	await get_tree().create_timer(wait).timeout
	if is_fishing:
		fish_on_hook = _pick_fish()
		_bite_pending = true
		bobber.trigger_bite()
		status_label.text = "BITE! Press Reel!"

func _on_bite_ready() -> void:
	pass # bobber.gd handles the flash; game just waits for Reel input

func _on_bite_missed() -> void:
	_reset_fishing_state()
	status_label.text = "The fish got away!"
	catch_label.text = ""

func _on_reel_pressed() -> void:
	if not is_fishing:
		return
	if _bite_pending:
		# Successful catch!
		var bonus_val = int(fish_on_hook.value * (1.0 + get_sell_bonus()))
		inventory.append(fish_on_hook)
		catch_label.text = "Caught: %s (+%dg)" % [fish_on_hook.name, bonus_val]
		status_label.text = "Nice catch!"
		bobber.reel_in()
		_reset_fishing_state()
		_refresh_inventory_ui()
	else:
		# Reeled too early — fish escapes
		status_label.text = "Too early! The fish escaped."
		bobber.reel_miss()
		_reset_fishing_state()

func _reset_fishing_state() -> void:
	is_fishing = false
	_bite_pending = false
	fish_on_hook = {}
	cast_button.disabled = false
	reel_button.disabled = true

func _on_sell_pressed() -> void:
	if inventory.is_empty():
		return
	var total = 0
	for fish in inventory:
		total += int(fish.value * (1.0 + get_sell_bonus()))
	player_data.coins += total
	status_label.text = "Sold %d fish for %dg!" % [inventory.size(), total]
	inventory.clear()
	_refresh_inventory_ui()
	_update_all_hud()
	_save_game()

func _refresh_inventory_ui() -> void:
	# Remove all existing FishCard children
	for child in inventory_panel.get_children():
		child.queue_free()
	# Spawn a FishCard for each fish in the hold
	var FishCardScene = preload("res://scenes/FishCard.tscn")
	for fish in inventory:
		var card = FishCardScene.instantiate()
		inventory_panel.add_child(card)
		card.setup(fish, get_sell_bonus())
	# Enable sell button only when there is something to sell
	sell_button.disabled = inventory.is_empty()
	# Show how full the hold is
	var cap = get_inventory_cap()
	status_label.text = "Hold: %d / %d" % [inventory.size(), cap] if not is_fishing else status_label.text

func _build_upgrade_panel() -> void:
	# Clear any existing upgrade buttons
	for child in upgrade_panel.get_children():
		if child.name != "UpgradeTitleLabel":
			child.queue_free()
	for upg in UPGRADE_TABLE:
		var current_level = player_data.get(upg.id + "_level", 0)
		var cost = _upgrade_cost(upg, current_level)
		var at_max = current_level >= upg.max_level
		var btn = Button.new()
		upgrade_panel.add_child(btn)
		btn.custom_minimum_size = Vector2(128, 30)
		if at_max:
			btn.text = "%s\nMAXED" % upg.label
			btn.disabled = true
		else:
			btn.text = "%s\nLv%d %dg" % [upg.label, current_level + 1, cost]
			btn.disabled = (player_data.coins < cost)
		# Bind the upgrade id to the button's pressed signal
		btn.pressed.connect(_on_upgrade_pressed.bind(upg.id))

func _on_upgrade_pressed(upgrade_id: String) -> void:
	# Find the matching upgrade in the table
	var upg = UPGRADE_TABLE.filter(func(u): return u.id == upgrade_id)
	if upg.is_empty():
		return
	upg = upg[0]
	var level_key = upgrade_id + "_level"
	var current_level = player_data.get(level_key, 0)
	if current_level >= upg.max_level:
		return
	var cost = _upgrade_cost(upg, current_level)
	if player_data.coins < cost:
		return
	player_data.coins -= cost
	player_data[level_key] = current_level + 1
	status_label.text = "%s upgraded to level %d!" % [upg.label, current_level + 1]
	_build_upgrade_panel() # Rebuild to show new levels and costs
	_update_all_hud()
	_save_game()

func _upgrade_cost(upg: Dictionary, current_level: int) -> int:
	return int(upg.base_cost * pow(upg.cost_mult, current_level))

func _update_all_hud() -> void:
	coins_label.text = "Coins: %d" % player_data.coins
	# Rebuild upgrades in case affordability changed
	_build_upgrade_panel()
	_refresh_inventory_ui()

func _save_game() -> void:
	# Add this key to player_data so it gets saved:
	# last_save_time = 0 (Unix timestamp)
	player_data.last_save_time = Time.get_unix_time_from_system()
	# Open the save file for writing — creates it if it does not exist
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not open save file for writing: " + SAVE_PATH)
		return
	# Convert our Dictionary to a JSON string and write it
	file.store_string(JSON.stringify(player_data))
	file.close()
	print("Game saved.")

func _load_game() -> void:
	# Check that a save file exists before trying to open it
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found — starting fresh.")
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open save file for reading.")
		return
	var text = file.get_as_text()
	file.close()
	# Parse the JSON back into a Dictionary
	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("Save file is corrupted — starting fresh.")
		return
	# Merge loaded values into player_data
	# This keeps any new keys added in an update from breaking old saves
	for key in parsed.keys():
		if player_data.has(key):
			player_data[key] = parsed[key]
	print("Game loaded: ", player_data)
	_apply_idle_income()

func _pick_fish() -> Dictionary:
	# Filter to fish available at current rod level
	var available = FISH_TABLE.filter(func(f): return f.min_rod <= player_data.rod_level)
	# Sum all weights
	var total_weight = 0
	for f in available:
		total_weight += f.weight
	# Roll
	var roll = randf_range(0.0, float(total_weight))
	var acc = 0.0
	for f in available:
		acc += f.weight
		if roll < acc:
			return f
	return available.back() # Fallback

func _apply_idle_income() -> void:
	if not player_data.has("last_save_time"):
		return
	var now = Time.get_unix_time_from_system()
	var elapsed = now - player_data.last_save_time
	# Cap idle income at 2 hours to prevent abuse
	elapsed = min(elapsed, 7200.0)
	# Award 1 coin per 30 seconds of idle time, scaled by rod level
	var idle_coins = int(elapsed / 30.0) * player_data.rod_level
	if idle_coins <= 0:
		return
	player_data.coins += idle_coins
	status_label.text = "Welcome back! Earned %d idle coins." % idle_coins
