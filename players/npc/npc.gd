extends CharacterBody3D

# static classes
var Greetings = preload("res://players/npc/npc_greetings.gd")
var Names = preload("res://players/npc/npc_names.gd")

# constants
const NPC_SPEED := 5.0 # metres/tick
const SHOW_NAME_DISTANCE := 25.0 #10 # metres
const MIN_WALK_TIME := 3.0 # seconds
const MAX_WALK_TIME := 6.0 # seconds
const MIN_PAUSE_TIME := 3.0 # seconds
const MAX_PAUSE_TIME := 10.0 # seconds
const INTERACT_COOLDOWN_TIME := 5.0 # 20 seconds

# initable / game data
var character_name = ""
var texture = NpcTextures.get_texture()
var texture_path = texture.path
var gender = texture.gender
var is_hostile = randf() > 0.5
var suspicion = 0.5
var initial_secrets = []
var held_secrets = []

# runtime / ephemeral data
var is_name_known := randf() > 0.5
var is_player_adjacent := false
var speed := NPC_SPEED + randf_range(-NPC_SPEED/8.0, NPC_SPEED/8.0)
var heading := Vector3(0, 0, 0) # 'y' always 0
var paused_time_countdown := randf_range(MIN_PAUSE_TIME, MAX_PAUSE_TIME) # starts paused
var walk_time_countdown := 0.0
var interact_cooldown_countdown := 0.0
var max_grade := Secrets.SECRET_GRADES[4]


# chain this call, as: NPC.instantiate().with_data({})
func with_data(data):
	position = data.position
	max_grade = data.max_grade
	print("placed NPC at pos %s", position)
	return self


func _init():
	add_to_group("npcs")
	# choose attributes
	character_name = Names.generate_name(gender)
	is_hostile = randf() > 0.8
	suspicion = 0.5 + randf_range(-0.2, 0.2)


func _ready():
	# assign randomly chosen texture
	$"Sprites/Sprite3D".texture = load(texture_path)
	_update_name_label()
	# compensate for separate scenes offset
	position.y += 1
	# choose starting secrets
	initial_secrets.append(Secrets.get_secret(null, max_grade))
	initial_secrets.append(Secrets.get_secret(null, max_grade))
	if randf() > 0.5:
		initial_secrets.append(Secrets.get_secret(max_grade, max_grade))
	held_secrets = initial_secrets.duplicate()

	# event for later
	PubSub.add_npc_secret.connect(func (grade):
		if len(held_secrets) < 4 and randf() > 0.5:
			var secret = Secrets.get_secret(grade)
			if secret: # can be null if nothing left
				held_secrets.append(secret)
				print("L%s secret assigned to %s" % [grade, character_name])
	)


func _pick_heading():
	heading = Vector3(randf() - 0.5, 0, randf() - 0.5)
	heading = heading.normalized()


func _process(delta):
	var player = get_tree().get_nodes_in_group("player")[0]
	$NameLabel.visible = self.position.distance_to(player.position) < SHOW_NAME_DISTANCE
	$NameLabel.modulate = get_max_secret_colour() if is_player_adjacent else Color.WHITE
	if interact_cooldown_countdown > 0:
		interact_cooldown_countdown -= delta


func _physics_process(delta):
	# random movement interspersed with pauses
	if paused_time_countdown > 0:
		paused_time_countdown -= delta
		if paused_time_countdown <= 0:
			walk_time_countdown = randf_range(MIN_WALK_TIME, MAX_WALK_TIME)

	elif walk_time_countdown > 0:
		walk_time_countdown -= delta
		if walk_time_countdown <= 0:
			paused_time_countdown = randf_range(MIN_PAUSE_TIME, MAX_PAUSE_TIME)

		var r = randf()
		if r > 0.025:
			# walk
			# position += heading * speed
			var _collision = move_and_collide(heading * speed * delta)
		else:
			# turn
			_pick_heading()


# connected from Area3D node in Godot UI
func _on_body_entered(body):
	if body.is_in_group("player"):
		is_player_adjacent = true
		# stop walking so player doesn't need to chase
		walk_time_countdown = 0
		paused_time_countdown = 2


# connected from Area3D node in Godot UI
func _on_body_exited(body):
	if body.is_in_group("player"):
		is_player_adjacent = false


func _input(event):
	if event.is_action_pressed("interact") and interact_cooldown_countdown <= 0:
		if (is_player_adjacent):
			interact()
			interact_cooldown_countdown = INTERACT_COOLDOWN_TIME


func _update_name_label():
	$NameLabel.text = character_name if is_name_known else "unknown"
	# $NameLabel.text += " %s" % Secrets.SECRET_ICONS[max_grade - 1]


func interact():
	is_name_known = true
	_update_name_label()
	# signal to open card UI
	PubSub.open_secrets.emit(self, {
		"greeting": Greetings.get_greeting(),
		"character_name": character_name,
		"held_secrets": held_secrets
	})
	if gender == "f":
		PubSub.audio_play_sfx.emit(["f_huh1", "f_huh2", "f_huh3"].pick_random())
	else:
		PubSub.audio_play_sfx.emit(["m_huh1", "m_huh2", "m_huh3", "m_huh4"].pick_random())


func get_max_secret_colour():
	_update_held_secrets()
	if is_name_known:
		return Secrets.SECRET_COLORS[held_secrets[0].grade - 1]
	return Secrets.SECRET_COLORS[0]


func _update_held_secrets():
	held_secrets.sort_custom(Secrets.sort_by_grade)
	held_secrets = held_secrets.filter(func (secret):
		return secret.grade > 0
	)


func give_secret(secret):
	if not secret in held_secrets:
		held_secrets.append(secret)
		secret.share()
		_update_held_secrets()


func get_shareable_secrets(exclude = []):
	_update_held_secrets()
	var shareable_secrets = held_secrets.filter(func (secret): return not secret in exclude)
	if len(shareable_secrets) == 0:
		return null
	return shareable_secrets


func get_secret(exclude = []):
	var shareable_secrets = get_shareable_secrets(exclude)
	if shareable_secrets == null:
		return null
	return shareable_secrets.pick_random()
