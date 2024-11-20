extends CharacterBody3D

# How fast the player moves
const SPEED = 7 # m/s
const MOUSE_SENSITIVITY = 0.001

# player achievements - for win/loss scenarios and dynamic level progression
var achieved = {
	"trades": 0,
	"know_all": false,
	"l1_out": false,
	"l2_found": false,
	"l2_out": false,
	"l3_found": false,
	"l3_out": false,
	"l4_found": false,
	"l4_out": false,
	"l5_found": false,
	"l5_out": false
}

# initable / game data
var suspicion = 0.5
var initial_secrets = []
var held_secrets = []

# runtime / ephemeral data
var heading := Vector3(0, 0, 0)


func _init():
	add_to_group("player")
	# choose starting secrets
	initial_secrets.append(Secrets.get_secret(1))
	initial_secrets.append(Secrets.get_secret(1))
	initial_secrets.append(Secrets.get_secret(1))
	held_secrets = initial_secrets.duplicate()


func _ready():
	PubSub.player_ready.emit(self)
	PubSub.player_npc_trade.connect(func ():
		achieved.trades += 1
		check_goals()
	)


func _input(event):
	if event is InputEventKey:
		var input = Input.get_vector("left", "right", "forward", "back")
		heading = transform.basis * Vector3(input.x, 0, input.y)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		$Camera3D.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		$Camera3D.rotation.x = clampf($Camera3D.rotation.x, -deg_to_rad(45), deg_to_rad(45))


func _physics_process(_delta):
	velocity.x = heading.x * SPEED
	velocity.z = heading.z * SPEED
	move_and_slide()
	apply_floor_snap()


func _update_secrets():
	held_secrets = held_secrets.filter(func (secret):
		return secret.grade > 0
	)


func give_secret(secret):
	if not secret in held_secrets:
		held_secrets.append(secret)
		secret.share()
		_update_secrets();
		PubSub.player_secrets_change.emit(secret)


func take_secret(secret):
	held_secrets.erase(secret)
	PubSub.player_secrets_change.emit(secret)


func has_secret(secret):
	return secret in held_secrets


func set_suspicion(value):
	suspicion = clampf(value, 0, 1)
	PubSub.player_suspicion_change.emit(suspicion)


func get_shareable_secrets(exclude = []):
	var shareable_secrets = held_secrets.filter(func (secret): return not secret in exclude)
	if len(shareable_secrets) == 0:
		return null
	return shareable_secrets


func check_goals():
	if achieved.trades == 5:
		PubSub.player_achievement.emit("5_trades")

	var unknown_npcs = get_tree().get_nodes_in_group("npcs").filter(func (npc): return not npc.is_name_known)
	if len(unknown_npcs) == 0:
		PubSub.player_achievement.emit("know_all")

	var held_grades = held_secrets.map(func (s): return s.grade)
	if held_grades.count(2):
		PubSub.player_achievement.emit("l2_found")
	if held_grades.count(3):
		PubSub.player_achievement.emit("l3_found")
	if held_grades.count(4):
		PubSub.player_achievement.emit("l4_found")
	if held_grades.count(5):
		PubSub.player_achievement.emit("l5_found")
