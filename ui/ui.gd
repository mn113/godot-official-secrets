extends Control

var areas
var local_player_ref
var messages = []
var suspicion_stylebox = StyleBoxFlat.new()

const SUSPICION_H_MIN = 0.0 # hsv hue red
const SUSPICION_H_MAX = 0.33 # hsv hue green
const SUSPICION_S = 0.65 # hsv saturation component
const SUSPICION_V = 0.8 # hsv value component

func _ready():
	areas = {
		"sharing": $SharingModal,
		"secrets": $SecretsHUD,
		"secrets_rich_text": %Secrets_RichText,
		"messages": %MessagesHUD,
		"messages_text": %Messages_RichText,
		"goals": $GoalsHUD,
		"goals_text": %Goals_RichText,
		"suspicion": $SuspicionHUD,
		"suspicion_level": %Suspicion_ProgressBar,
	}
	# set up suspicion style
	areas.suspicion_level.add_theme_stylebox_override("fill", suspicion_stylebox)
	suspicion_stylebox.bg_color = Color.from_hsv(0, SUSPICION_S, SUSPICION_V)

	# set initial HUD state
	_toggle_area("sharing", false)
	_toggle_area("suspicion", true)
	_toggle_area("secrets", true)
	_toggle_area("messages", true)
	_toggle_area("goals", true)
	_update_area_property("messages_text", "text", "Hello World!")

	# set up signals
	PubSub.player_ready.connect(func (player):
		local_player_ref = player
		_update_hud_player_secrets()
		_update_hud_player_suspicion(0.1) #(player.suspicion)
	)
	PubSub.goals_change.connect(func (goals):
		_update_area_property("goals_text", "text", "\n\n".join(goals.map(func (goal): return "- " + goal)))
	)
	PubSub.open_secrets.connect(open_secrets)
	PubSub.close_secrets.connect(close_secrets)
	PubSub.player_secrets_change.connect(func (secret):
		add_message("Received L%s secret: \"%s\"." % [secret.grade, secret._to_string_rich()])
		_update_hud_player_secrets()
	)
	PubSub.player_suspicion_change.connect(func (suspicion):
		print("suspicion: %f" % suspicion)
		_update_hud_player_suspicion(suspicion)
	)
	PubSub.outbox_interact.connect(func ():
		open_secrets(null, null, "exfil")
	)
	# responsiveness
	_on_size_changed()
	get_tree().get_root().size_changed.connect(_on_size_changed)


func _on_size_changed():
	# make UI font sizes scale with window
	var percent = get_window().size.y / 100.0
	self.theme.set_font_size("font_size", "Label", 2 * percent)
	self.theme.set_font_size("font_size", "Button", 2 * percent)
	self.theme.set_font_size("normal_font_size", "RichTextLabel", 2 * percent)


# signalled from NPC
func open_secrets(npc, data, mode = "npc"):
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	areas.sharing.open_secrets(local_player_ref, npc, data, mode)


# signalled from SharingModal
func close_secrets():
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _toggle_area(areaName, value):
	if value == true:
		areas[areaName].show()
	elif value == false:
		areas[areaName].hide()
	else:
		areas[areaName].visible = !areas[areaName].visible


func _update_area_property(areaName, property, value):
	areas[areaName][property] = value


func _update_hud_player_secrets():
	var secrets_text = ""
	var grades = Secrets.SECRET_GRADES.duplicate()
	grades.reverse()
	for grade in grades:
		var grade_secrets = local_player_ref.held_secrets.filter(func (secret): return secret.grade == grade)
		var bullets_text = "".join(grade_secrets.map(func (secret): return secret._to_bullet()))
		secrets_text += Secrets.colourise(grade, "L%d: %s\n" % [grade, bullets_text if len(bullets_text) else "-"])
	# print(secrets_text)
	_update_area_property("secrets_rich_text", "text", secrets_text)


func _update_hud_player_suspicion(suspicion):
	add_message("suspicion: %s" % suspicion)

	# alter suspicion bar width
	_update_area_property("suspicion_level", "value", suspicion * 100)

	# change hue - range scale is from green (low) to red (high)
	var old_hue = suspicion_stylebox.bg_color.h
	var new_hue = (1 - suspicion) / 3.0 # map 0..1 domain to hue range 0.33..0
	add_message("old_hue: %f new_hue: %f" % [old_hue, new_hue])
	print("old_hue: %f new_hue: %f" % [old_hue, new_hue])
	suspicion_stylebox.bg_color.h = new_hue


func add_message(richtext):
	messages.append(richtext)
	_update_area_property("messages_text", "text", "\n".join(messages.map(func (message): return "- " + message)))
