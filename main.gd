##
# Scene manager class
#
extends Node


const scenes = {
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
const Audio: PackedScene = preload(scenes.audio)
const Menu: PackedScene = preload(scenes.menu)
const UI: PackedScene = preload(scenes.ui)
const Player: PackedScene = preload(scenes.player)
const NPC: PackedScene = preload(scenes.npc)

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

func set_game_state(new_state):
	print("set_game_state %s" % new_state)
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


func _init():
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED # for menu


func _input(event):
	# keep mouse pointer within the game (but invisible) until Esc is pressed
	if event.is_action_pressed("ui_cancel"):
		if game_state in [STATE_MENU, STATE_PAUSED, STATE_ENDED]:
			# can get out of game window by Escape
			print("MM_VISIBLE")
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # out of game
		elif game_state == STATE_PLAYING:
			# can pause action by Escape
			pause()
			print("MM_CONFINED")
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED

	elif event is InputEventMouseButton and event.pressed:
		if game_state == STATE_PLAYING:
			# go into mouse-look mode
			print("MM_CAPTURED")
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			# for using menus
			print("MM_CONFINED")
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED


func _ready():
	print('main.gd ready')
	_load_audio()
	_load_menu()

	PubSub.game_begin.connect(func ():
		print("game_begin", game_state)
		if game_state == STATE_PAUSED:
			resume()
		elif game_state == STATE_ENDED:
			pass # TODO:
		else:
			start()
	)
	PubSub.game_win.connect(win_game)
	PubSub.game_lose.connect(lose_game)
	PubSub.game_state.connect(set_game_state)


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
	if level_scn:
		level_scn.destroy()
	# load new
	level_scn = load(scenes.levels[number]).instantiate()
	self.add_child(level_scn)

	# put player back in
	player_scn.reparent(level_scn.get_node("Injected"))

	_load_npcs(level_scn.NUM_NPCS)

	resume()


func _load_npcs(number):
	for i in range(number):
		var spawn = level_scn.get_random_spawn_point()
		var max_grade = spawn.get_meta("max_grade") if spawn.has_meta("max_grade") else DEFAULT_SPAWN_MAX_GRADE
		var npc = NPC.instantiate().with_data({ 'position': spawn.position, 'max_grade': max_grade })
		level_scn.get_node("Injected").add_child(npc)


func start():
	print("start")
	menu_scn.hide()
	menu_scn.set_initial_state()
	_load_level(1)
	set_game_state(STATE_PLAYING)


func pause():
	print("pause")
	get_tree().paused = true # pauses all nodes, but not menu.gd
	menu_scn.show()
	# move_child(menu_scn, -1) # last in tree is like z-index fix
	menu_scn.set_paused_state()
	level_scn.hide()
	player_scn.hide()
	ui_scn.hide()
	set_game_state(STATE_PAUSED)


func resume():
	print("resume")
	get_tree().paused = false
	menu_scn.hide()
	level_scn.show()
	player_scn.show()
	ui_scn.show()
	set_game_state(old_game_state) # STATE_PLAYING or STATE_INTERACT
	print("MM_CAPTURED")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func win_game():
	pause()
	PubSub.audio_play_sfx.emit("win")
	menu_scn.set_won_state()
	set_game_state(STATE_ENDED)


func lose_game():
	PubSub.audio_play_sfx.emit("lose")
	pause()
	menu_scn.set_lost_state()
	set_game_state(STATE_ENDED)
