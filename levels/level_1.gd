extends Node

const NUM_NPCS = 13

const STORY = {
	0: [],
	1: [
		"Agent, the organisation you've infiltrated is now on high alert!",
		"Your cover is surely not going to last much longer in this climate.",
		"We need you to recover intelligence - whatever you can get your hands on.",
		"Exfiltrate any worthwhile secrets via the Whisper pipe we've set up, while it is still safe.",
		"Good luck, and if caught - remember you are on your own!"
	],
	2: [
		"Received. Good work, we have the [color=yellow]L2 secret[/color].",
		"Your future with us is more than secured."
	],
	3: [
		"Received. Excellent, we have the [color=lime]L3 secret[/color].",
		"Your family will be moved to witness protection as we discussed."
	],
	4: [
		"Received. Superb! We have the [color=dodgerblue]L4 secret[/color].",
		"Stephen is taking your wife out of the electric chair as we speak."
	],
	5: [
		"Received. Top job, we have the [color=purple]L5 secret[/color] at last.",
		"Well done for staying undetected.",
		"I'll just deactivate the explosive charge we placed inside your spine.",
		"I hope this is the right command to send...",
		"Ok, done. ",
		"Make your way to the exit at your leisure.",
		"It was a pleasure working with you, Agent."
	],
	6: [
		"Somebody is getting well-connected..."
	]
}

const GOALS = [
	"Keep suspicion low to avoid losing!", # permanent
	"Gain higher-grade secrets by trading with colleagues.", # needs to go after 5 trades
	"Get the [color=yellow]L2 secret[/color] out of the room.", # appears with first L2
	"Get the [color=lime]L3 secret[/color] out of the room.",
	"Get the [color=dodgerblue]L4 secret[/color] out of the room.",
	"Get the [color=purple]L5 secret[/color] out of the room.",
	"Avoid sharing sensitive secrets to hostiles!" # permanent
]
var shown_goal_indexes = [0, 1, 6]
var shown_goals = []

var spawn_markers: Array[Node] = []

var door_nodes = {
	1: { "id": 1, "node": null, "open": false }, # opens after 5 trades
	2: { "id": 2, "node": null, "open": false }, # opens after L2 exfiltration
	3: { "id": 3, "node": null, "open": false }, # opens after L3 exfiltration
}

var injected: Node


func wait(seconds: float):
	await get_tree().create_timer(seconds).timeout


func get_random_spawn_point() -> Marker3D:
	# spawning an NPC on top of an NPC could result in them getting y stuck high or low
	# so use each marker once only
	return spawn_markers.pop_front()


func open_door(id):
	door_nodes[id].node.hide()
	door_nodes[id].node.set_process_mode(Node.PROCESS_MODE_DISABLED)
	door_nodes[id].open = true
	PubSub.audio_play_sfx.emit("door")


func _calc_shown_goals():
	shown_goals = []
	for i in shown_goal_indexes:
		shown_goals.append(GOALS[i])


func _ready():
	injected = $Injected

	# geometry
	$Ceiling.show() # kept hidden in Godot for convenience

	# spawns
	spawn_markers = $Markers.get_children()
	spawn_markers.shuffle()

	# doors
	door_nodes[1].node = $Doors/Door1 # to L3 room
	door_nodes[2].node = $Doors/Door2 # to L4 room
	door_nodes[3].node = $Doors/Door3 # to L5 room

	# music
	PubSub.audio_play_music.emit("game")

	# goals
	_calc_shown_goals()
	PubSub.goals_change.emit(shown_goals)

	# story
	wait(3)
	PubSub.story_feed.emit(STORY[1][0])
	PubSub.story_feed.emit(STORY[1][1])

	PubSub.player_achievement.connect(_process_achievement)


func _process_achievement(achievement):
	if achievement == "moved_5m":
		PubSub.story_feed.emit(STORY[1][2])
		PubSub.story_feed.emit(STORY[1][3])

	elif achievement == "moved_15m":
		PubSub.story_feed.emit(STORY[1][4])

	elif achievement == "5_trades":
		open_door(1)
		shown_goal_indexes.erase(1)

	elif achievement == "l2_found" and !shown_goal_indexes.has(2):
		shown_goal_indexes.erase(1)
		shown_goal_indexes.append(2)

	elif achievement == "l2_exfil":
		open_door(2)
		shown_goal_indexes.erase(2)
		PubSub.story_feed.emit(STORY[2][0])
		PubSub.story_feed.emit(STORY[2][1])

	elif achievement == "l3_found" and !shown_goal_indexes.has(3):
		shown_goal_indexes.erase(1)
		shown_goal_indexes.append(3)

	elif achievement == "l3_exfil":
		open_door(3)
		shown_goal_indexes.erase(3)
		PubSub.story_feed.emit(STORY[3][0])
		PubSub.story_feed.emit(STORY[3][1])

	elif achievement == "l4_found" and !shown_goal_indexes.has(4):
		shown_goal_indexes.append(4)

	elif achievement == "l4_exfil":
		shown_goal_indexes.erase(4)
		PubSub.story_feed.emit(STORY[4][0])
		PubSub.story_feed.emit(STORY[4][1])

	elif achievement == "l5_found" and !shown_goal_indexes.has(5):
		shown_goal_indexes.append(5)

	elif achievement == "l5_exfil":
		shown_goal_indexes.erase(5)
		# game beaten!
		PubSub.story_feed.emit(STORY[5][0])
		PubSub.story_feed.emit(STORY[5][1])
		wait(3)
		PubSub.story_feed.emit(STORY[5][2])
		PubSub.story_feed.emit(STORY[5][3])
		wait(3)
		PubSub.story_feed.emit(STORY[5][4])
		PubSub.story_feed.emit(STORY[5][5])
		wait(2)
		PubSub.story_feed.emit(STORY[5][6])
		wait(3)
		PubSub.game_win.emit()

	elif achievement == "know_all":
		PubSub.story_feed.emit(STORY[6][0])

	_calc_shown_goals()
	PubSub.goals_change.emit(shown_goals)
