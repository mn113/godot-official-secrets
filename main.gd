##
# Scene manager class
#
extends Node

const scenes = {
	"player": "res://players/player.tscn",
	"npc": "res://players/npc/npc.tscn",
	"ui": "res://ui/ui.tscn",
	"levels": {
		1: "res://levels/Level1.tscn",
		2: "res://levels/Level2.tscn",
		3: "res://levels/Level3.tscn"
	}
}

# imports
const Player: PackedScene = preload(scenes.player)
const NPC: PackedScene = preload(scenes.npc)
const UI: PackedScene = preload(scenes.ui)

const DEFAULT_SPAWN_MAX_GRADE = 3

# dynamically moved scene nodes
# MainScene (here)
# └ LevelN
#   └ Player* (contains camera) needs to be child of level to work
#     └ UI* (contains CanvasLayer) needs to be child of player to work
#   └ NPCGroup
#     └ NPC*
var ui_scn
var player_scn
var level_scn


func _init():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event):
	# keep mouse pointer within the game (but invisible) until Esc is pressed
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _ready():
	print('main.gd ready')
	_load_ui()
	_load_player()
	_load_level(1)
	_load_npcs(level_scn.NUM_NPCS)


func _load_ui():
	if not ui_scn:
		ui_scn = UI.instantiate()
		self.add_child(ui_scn)


func _load_player():
	if not player_scn:
		player_scn = Player.instantiate()
		self.add_child(player_scn)


func _load_level(number):
	print("loading level", number)
	_load_ui()
	_load_player()
	ui_scn.reparent(player_scn)

	# get player out, to this scene
	if not player_scn in self.get_children():
		player_scn.reparent(self)

	# destroy old
	if level_scn:
		level_scn.destroy()
	# load new
	level_scn = load(scenes.levels[number]).instantiate()
	self.add_child(level_scn)

	# put player back in
	player_scn.reparent(level_scn.get_node("Injected"))


func _load_npcs(number):
	for i in range(number):
		var spawn = level_scn.get_random_spawn_point()
		var max_grade = spawn.get_meta("max_grade") if spawn.has_meta("max_grade") else DEFAULT_SPAWN_MAX_GRADE
		var npc = NPC.instantiate().with_data({ 'position': spawn.position, 'max_grade': max_grade })
		level_scn.add_child(npc)


func get_level_goals():
	return level_scn.GOALS
