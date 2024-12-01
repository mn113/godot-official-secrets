extends CharacterBody3D

# How fast the player moves
const SPEED := 7.0 # m/s
const MOUSE_SENSITIVITY := 0.001

# player achievements - for win/loss scenarios and dynamic level progression
var achieved = {
	"moved_5m": false,
	"moved_15m": false,
	"trades": 0,
	"5_trades": false,
	"know_all": false,
	"l2_found": false,
	"l2_exfil": false,
	"l3_found": false,
	"l3_exfil": false,
	"l4_found": false,
	"l4_exfil": false,
	"l5_found": false,
	"l5_exfil": false
}

# initable / game data
var suspicion := 0.5
var initial_secrets := []
var held_secrets := []

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
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		$Camera3D.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		$Camera3D.rotation.x = clampf($Camera3D.rotation.x, -deg_to_rad(45), deg_to_rad(45))


func _physics_process(_delta):
	velocity.x = heading.x * SPEED
	velocity.z = heading.z * SPEED
	move_and_slide()
	apply_floor_snap()

	if !achieved["moved_5m"] and position.distance_to(Vector3(0,0,0)) > 5:
		achieved["moved_5m"] = true
		PubSub.player_achievement.emit("moved_5m")
	if !achieved["moved_15m"] and position.distance_to(Vector3(0,0,0)) > 15:
		achieved["moved_15m"] = true
		PubSub.player_achievement.emit("moved_15m")


func _process(_delta):
	check_goals()


func _update_held_secrets():
	held_secrets = held_secrets.filter(func (secret):
		return secret.grade > 0
	)


func give_secret(secret):
	if not secret in held_secrets:
		held_secrets.append(secret)
		secret.share()
		_update_held_secrets()
		PubSub.player_secrets_receive.emit(secret)
		PubSub.player_secrets_change.emit()


func take_secret(secret):
	held_secrets.erase(secret)
	PubSub.player_secrets_change.emit()


func has_secret(secret):
	return secret in held_secrets


func set_suspicion(value):
	suspicion = clampf(value, 0, 1)
	PubSub.player_suspicion_change.emit(suspicion)
	if suspicion > 0.8:
		PubSub.game_lose.emit()


func get_shareable_secrets(exclude = []):
	_update_held_secrets()
	var shareable_secrets = held_secrets.filter(func (secret): return not secret in exclude)
	if len(shareable_secrets) == 0:
		return null
	return shareable_secrets


func get_exfilable_secrets():
	_update_held_secrets()
	var exfil_grade = get_exfil_grade()
	print("exfil_grade", exfil_grade)
	var exfilable_secrets = held_secrets.filter(func (secret): return secret.grade == exfil_grade)
	print("get_exfilable_secrets", exfilable_secrets)
	if len(exfilable_secrets) == 0:
		return null
	return exfilable_secrets


func get_exfil_grade() -> int:
	var held_grades = held_secrets.map(func (secret): return secret.grade)
	if achieved["l4_exfil"] and held_grades.count(5):
		return 5
	elif achieved["l3_exfil"] and held_grades.count(4):
		return 4
	elif achieved["l2_exfil"] and held_grades.count(3):
		return 3
	elif held_grades.count(2):
		return 2
	return 0


func get_sought_secret_grade() -> int:
	if achieved["l4_exfil"]:
		return 5
	elif achieved["l3_exfil"]:
		return 4
	elif achieved["l2_exfil"]:
		return 3
	return 2


func achieve(key):
	print("achieve", key)
	if key in achieved:
		achieved[key] = true
		PubSub.player_achievement.emit(key)
		print("achievement", key)
	# ensure later stages are not too secret-barren:
	if key == "l2_exfil":
		PubSub.add_npc_secret.emit(3)
		PubSub.add_npc_secret.emit(3)
		PubSub.add_npc_secret.emit(3)
	if key == "l3_exfil":
		PubSub.add_npc_secret.emit(4)
		PubSub.add_npc_secret.emit(4)
		PubSub.add_npc_secret.emit(4)
	if key == "l4_exfil":
		PubSub.add_npc_secret.emit(5)
		PubSub.add_npc_secret.emit(5)
		PubSub.add_npc_secret.emit(5)


func check_goals():
	if achieved.trades == 5 and !achieved["5_trades"]:
		PubSub.player_achievement.emit("5_trades")
		achieved["5_trades"] = true

	var unknown_npcs = get_tree().get_nodes_in_group("npcs").filter(func (npc): return !npc.is_name_known)
	if len(unknown_npcs) == 0 and !achieved["know_all"]:
		PubSub.player_achievement.emit("know_all")
		achieved["know_all"] = true
		suspicion -= 0.2

	var held_grades = held_secrets.map(func (s): return s.grade)
	if held_grades.count(2) and !achieved["l2_found"]:
		PubSub.player_achievement.emit("l2_found")
		achieved["l2_found"] = true
		suspicion -= 0.1
	if held_grades.count(3) and !achieved["l3_found"]:
		PubSub.player_achievement.emit("l3_found")
		achieved["l3_found"] = true
		suspicion -= 0.075
	if held_grades.count(4) and !achieved["l4_found"]:
		PubSub.player_achievement.emit("l4_found")
		achieved["l4_found"] = true
		suspicion -= 0.05
	if held_grades.count(5) and !achieved["l5_found"]:
		PubSub.player_achievement.emit("l5_found")
		achieved["l5_found"] = true
