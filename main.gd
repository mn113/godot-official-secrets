##
# Scene manager class
#
extends Node

const SCENES = {
	"audio": "res://Audio.tscn",
	"menu": "res://ui/Menu.tscn",
	"ui": "res://ui/UI.tscn",
	"player": "res://players/Player.tscn",
	"npc": "res://players/npc/NPC.tscn",
	"levels": {
		1: "res://levels/Level1.tscn"
	}
}

# imports
const Audio: PackedScene = preload(SCENES.audio)
const Menu: PackedScene = preload(SCENES.menu)
const UI: PackedScene = preload(SCENES.ui)
const Player: PackedScene = preload(SCENES.player)
const NPC: PackedScene = preload(SCENES.npc)

const DEFAULT_SPAWN_MAX_GRADE = 2

# dynamically moved scene nodes
# MainScene (here)
# └ Menu
# └ LevelN
#   └ Player* (contains camera) needs to be child of level to work
#     └ UI* (contains CanvasLayer) needs to be child of player to work
#   └ NPCGroup
#     └ NPC*
var audio_scn
var menu_scn
var ui_scn
var player_scn
var level_scn

# const STATE_UNFOCUSED = 0 # MOUSE_MODE_VISIBLE
const STATE_MENU = 0 # MOUSE_MODE_CONFINED
const STATE_PLAYING = 1 # MOUSE_MODE_CAPTURED
const STATE_INTERACT = 2 # MOUSE_MODE_CONFINED
const STATE_PAUSED = 3 # MOUSE_MODE_CONFINED
const STATE_ENDED = 4 # MOUSE_MODE_CONFINED
const STATES = [0, 1, 2, 3, 4]

var old_game_state = STATE_PLAYING
var game_state = STATE_MENU


func _set_game_state(new_state):
	print("_set_game_state %s" % new_state)
	old_game_state = game_state

	if new_state in STATES:
		game_state = new_state
	# if new_state == STATE_MENU:
	# 	pause()
	# elif new_state == STATE_PLAYING:
	# 	pass
	# elif new_state == STATE_INTERACT:
	# 	pass
	# elif new_state == STATE_PAUSED:
	# 	pause()


func _show_and_free_pointer():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("MOUSE_MODE_VISIBLE")


func _show_pointer():
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	print("MOUSE_MODE_CONFINED")


func _hide_pointer():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	print("MOUSE_MODE_CAPTURED")


func _init():
	_show_pointer()


func _input(event):
	# keep mouse pointer within the game (but invisible) until Esc is pressed
	if event.is_action_pressed("ui_cancel"):
		if game_state in [STATE_MENU, STATE_PAUSED, STATE_ENDED]:
			# can get out of game window by Escape
			_show_and_free_pointer() # out of game
		elif game_state == STATE_PLAYING:
			# can pause action by Escape
			pause()
			_show_pointer()

	elif event is InputEventMouseButton and event.pressed:
		if game_state == STATE_PLAYING:
			# go into mouse-look mode
			_hide_pointer()
		else:
			# for using menus
			_show_pointer()


func _ready():
	print("main.gd ready")
	_load_menu()
	_load_audio()

	PubSub.game_begin.connect(func ():
		print("game_begin", game_state)
		if game_state == STATE_PAUSED:
			resume()
		elif game_state == STATE_ENDED:
			restart()
		else:
			start()
	)
	PubSub.game_win.connect(win_game)
	PubSub.game_lose.connect(lose_game)
	PubSub.game_state.connect(func (key):
		# only accept external events in active gameplay states
		if game_state in [STATE_PLAYING, STATE_INTERACT]:
			_set_game_state(key)
	)


func _load_audio():
	if not audio_scn:
		audio_scn = Audio.instantiate()
		self.add_child(audio_scn)


func _load_menu():
	if not menu_scn:
		menu_scn = Menu.instantiate()
		self.add_child(menu_scn)


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
	# if level_scn:
	# 	level_scn.queue_free()
	# load new
	level_scn = load(SCENES.levels[number]).instantiate()
	self.add_child(level_scn)

	# put player back in
	player_scn.reparent(level_scn.get_node("Injected"))

	_load_npcs(level_scn.NUM_NPCS)

	resume()


func _load_npcs(number):
	for i in range(number):
		var spawn = level_scn.get_random_spawn_point()
		spawn.position.y -= 0.05
		var max_grade = spawn.get_meta("max_grade") if spawn.has_meta("max_grade") else DEFAULT_SPAWN_MAX_GRADE
		var npc = NPC.instantiate().with_data({ 'position': spawn.position, 'max_grade': max_grade })
		level_scn.get_node("Injected").add_child(npc)


func _unload_all_entities():
	player_scn.queue_free()
	player_scn = null
	level_scn.queue_free()
	level_scn = null
	Secrets.reset()
	NpcTextures.reset()
	print("unloaded & reset all entities")
	print("game state %s" % game_state)


func start():
	print("start")
	menu_scn.hide()
	menu_scn.set_initial_state()
	_load_level(1)
	_set_game_state(STATE_PLAYING)


func restart():
	print("restart")
	start()


func pause():
	print("pause")
	get_tree().paused = true # pauses all nodes, but not menu.gd
	menu_scn.show()
	menu_scn.set_paused_state()
	_set_game_state(STATE_PAUSED)
	if old_game_state == STATE_PLAYING:
		level_scn.hide()
		player_scn.hide()
		ui_scn.hide()

func resume():
	print("resume")
	get_tree().paused = false
	menu_scn.hide()
	level_scn.show()
	player_scn.show()
	ui_scn.show()
	_set_game_state(old_game_state) # STATE_PLAYING or STATE_INTERACT
	_hide_pointer()


func win_game():
	PubSub.audio_play_sfx.emit("win")
	get_tree().paused = true
	menu_scn.show()
	menu_scn.set_won_state()
	_set_game_state(STATE_ENDED)
	_unload_all_entities()
	_show_and_free_pointer()


func lose_game():
	PubSub.audio_play_sfx.emit("lose")
	get_tree().paused = true
	menu_scn.show()
	menu_scn.set_lost_state()
	_set_game_state(STATE_ENDED)
	_unload_all_entities()
	_show_and_free_pointer()
