extends Node

const NUM_NPCS = 12;

const TIPS = [
	""
]

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

var spawn_markers = []

var door_nodes = {
	'1': { 'id': 1, 'node': null, 'open': true },
	'2': { 'id': 2, 'node': null, 'open': true },
	'3': { 'id': 3, 'node': null, 'open': false }, # opens after 5 trades
	'4': { 'id': 4, 'node': null, 'open': false }, # opens after L2 exfiltration
	'5': { 'id': 5, 'node': null, 'open': false }, # opens after L3 exfiltration
	'6': { 'id': 6, 'node': null, 'open': false }  # opens after L4 exfiltration
}
var postbox_node = null
var postbox_open = false # varies based on goals


func get_random_spawn_point() -> Marker3D:
	return spawn_markers.pick_random()


func open_door(id):
	#door_nodes[str(id)].node.position.y -= 5
	door_nodes[str(id)].node.hide()
	door_nodes[str(id)].node.set_process_mode(Node.PROCESS_MODE_DISABLED)
	door_nodes[str(id)].open = true


func _calc_shown_goals():
	shown_goals = []
	for i in shown_goal_indexes:
		shown_goals.append(GOALS[i])


func _ready():
	# geometry
	$Ceiling.show() # kept hidden in Godot for convenience

	# spawns
	spawn_markers = $Markers.get_children()

	# doors
	door_nodes['1'].node = $Doors/Door1
	door_nodes['2'].node = $Doors/Door2

	# goals
	_calc_shown_goals()
	PubSub.goals_change.emit(shown_goals)

	PubSub.player_achievement.connect(func (achievement):
		if achievement == "5_trades":
			open_door(1)
			shown_goal_indexes.erase(1)
			shown_goal_indexes.erase(1)

		if achievement == "l2_found":
			shown_goal_indexes.append(2)

		if achievement == "l2_exfil":
			open_door(2)
			shown_goal_indexes.erase(2)

		if achievement == "l3_found":
			shown_goal_indexes.append(3)

		if achievement == "l3_exfil":
			open_door(2)
			shown_goal_indexes.erase(3)

		if achievement == "l4_found":
			shown_goal_indexes.append(4)

		if achievement == "l4_exfil":
			open_door(2)
			shown_goal_indexes.erase(4)

		if achievement == "l5_found":
			shown_goal_indexes.append(5)

		if achievement == "l5_exfil":
			shown_goal_indexes.erase(5)
			# game beaten!

		if achievement == "know_all":
			pass

		_calc_shown_goals()
		PubSub.goals_change.emit(shown_goals)
	)
