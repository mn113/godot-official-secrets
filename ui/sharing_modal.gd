extends Control

var areas
var local_npc_ref
var local_player_ref
var npc_secret
var outgoing_secrets

func _ready():
	areas = {
		"sharing_modal_heading": %Heading_Label,
		"sharing_npc_greeting": %Greeting_Label,
		"sharing_npc_portrait": %NPC_TextureRect,
		"sharing_npc_secrets_list": %NPCSecrets_ItemList,
		"sharing_player_secrets_list": %PlayerSecrets_ItemList
	}
	%NPC_PanelContainer.hide()
	# responsiveness
	_on_size_changed()
	get_tree().get_root().size_changed.connect(_on_size_changed)


func _input(event):
	if event is InputEventKey:
		if event.is_action_pressed("ui_cancel"):
			if visible:
				_on_cancel_button_pressed()


func _on_size_changed():
	# make UI font sizes scale with window
	var percent = get_window().size.y / 100.0
	theme.set_font_size("font_size", "Label", 2 * percent)
	theme.set_font_size("font_size", "Button", 2 * percent)
	theme.set_font_size("font_size", "ItemList", 2 * percent)
	theme.set_font_size("normal_font_size", "RichTextLabel", 2 * percent)
	areas["sharing_npc_secrets_list"].set_icon_scale(0.16 * percent)
	areas["sharing_player_secrets_list"].set_icon_scale(0.16 * percent)


func _update_area_property(areaName, property, value):
	areas[areaName][property] = value


# signalled from UI
func open_secrets(player, npc, data, mode = "npc"):
	local_player_ref = player
	local_npc_ref = npc
	show()

	var can_share = true
	if mode == "npc":
		_update_area_property("sharing_modal_heading", "text", "Share secret with %s?" % local_npc_ref.character_name)
		outgoing_secrets = local_player_ref.get_shareable_secrets()
		can_share = open_npc_card(data) and outgoing_secrets
	elif mode == 'exfil':
		_update_area_property("sharing_modal_heading", "text", "Exfiltrate secret?")
		outgoing_secrets = local_player_ref.get_exfilable_secrets()
		can_share = !!outgoing_secrets

	open_player_card(can_share, mode)


func close_secrets():
	local_npc_ref = null
	npc_secret = null
	outgoing_secrets = null
	close_npc_card()
	close_player_card()
	PubSub.close_secrets.emit()
	hide()


func open_npc_card(data = {}) -> bool:
	%NPC_PanelContainer.show()

	_update_area_property("sharing_npc_portrait", "texture", load(local_npc_ref.texture_path))
	areas.sharing_npc_secrets_list.clear()

	var can_share = true
	var npc_secrets = local_npc_ref.get_shareable_secrets(local_player_ref.held_secrets)
	var player_secrets = local_player_ref.get_shareable_secrets(local_npc_ref.held_secrets)

	if !npc_secrets:
		_update_area_property("sharing_npc_greeting", "text", "\"Sorry, I have nothing I can share.\"")
		can_share = false

	elif !player_secrets:
		_update_area_property("sharing_npc_greeting", "text", "\"Sorry, you have no secrets worth knowing.\"")
		can_share = false

	else:
		_update_area_property("sharing_npc_greeting", "text", data.greeting)
		var list_secrets = local_npc_ref.held_secrets
		list_secrets.sort_custom(Secrets.sort_by_grade)
		for secret in list_secrets:
			var secret_string = secret._to_string() if secret in local_player_ref.held_secrets else secret._to_masked_string()
			var list_item = "%s %s" % [secret._to_grade(), secret_string]
			var icon = Secrets.SECRET_ICON_IMAGES[secret.grade - 1]
			areas.sharing_npc_secrets_list.add_item(list_item, icon, false)

	return can_share


func close_npc_card():
	areas.sharing_npc_secrets_list.clear()
	%NPC_PanelContainer.hide()


func open_player_card(can_share = true, mode = "npc"):
	areas.sharing_player_secrets_list.clear()
	var list_secrets = outgoing_secrets
	if mode == "exfil":
		list_secrets = list_secrets.filter(func (secret): return secret.grade > 1)
	list_secrets.sort_custom(Secrets.sort_by_grade)

	for secret in list_secrets:
		var list_item = "%s %s" % [secret._to_grade(), secret._to_string()]
		var icon = Secrets.SECRET_ICON_IMAGES[secret.grade - 1]
		areas.sharing_player_secrets_list.add_item(list_item, icon, can_share)

	if mode == "npc":
		%Share_Button.show()
		%Exfiltrate_Button.hide()
	elif mode == "exfil":
		%Share_Button.hide()
		%Exfiltrate_Button.show()

	if len(list_secrets):
		%Share_Button.disabled = false
		%Exfiltrate_Button.disabled = false
	else:
		%Share_Button.disabled = true
		%Exfiltrate_Button.disabled = true


func close_player_card():
	areas.sharing_player_secrets_list.clear()


func _choose_npc_secret(npc_secrets, player_secret) -> Secrets.Secret:
	# do not provide too high-grade a secret
	var sought_grade = local_player_ref.get_sought_secret_grade()
	var eligible_npc_secrets = npc_secrets.filter(func (secret): return secret.grade <= sought_grade)

	# NPC higher/equal/lower-grade secrets
	var higher = eligible_npc_secrets.filter(func (secret): return secret.grade - 1 == player_secret.grade)
	var equal = eligible_npc_secrets.filter(func (secret): return secret.grade == player_secret.grade)
	var lower = eligible_npc_secrets.filter(func (secret): return secret.grade + 1 == player_secret.grade)

	var thresholds = { 'lo': 0, 'eq': 0.5,  'hi': 0.75 }
	if local_npc_ref.is_hostile:
		thresholds = { 'lo': 0, 'eq': 0.6,  'hi': 0.85 }

	var candidates = npc_secrets
	var r = randf()
	if r > thresholds['lo'] and len(lower) > 0:
		candidates = lower
	if r > thresholds['eq'] and len(equal) > 0:
		candidates = equal
	if r > thresholds['hi'] and len(higher) > 0:
		candidates = higher

	return candidates.pick_random()


func _on_cancel_button_pressed():
	var suspicion = local_player_ref.suspicion
	suspicion = clampf(suspicion - 0.01, 0, 1)
	local_player_ref.set_suspicion(suspicion)
	PubSub.audio_play_sfx.emit("menu-cancel")
	close_secrets()


func _on_share_button_pressed():
	if not areas.sharing_player_secrets_list.is_anything_selected():
		return
	var selected_index = areas.sharing_player_secrets_list.get_selected_items()[0]
	var outgoing_secret = outgoing_secrets[selected_index]
	var incoming_secret = _choose_npc_secret(local_npc_ref.held_secrets, outgoing_secret)
	if outgoing_secret and incoming_secret:
		local_npc_ref.give_secret(outgoing_secret)
		local_player_ref.give_secret(incoming_secret)
		PubSub.player_npc_trade.emit()
		PubSub.audio_play_sfx.emit("whisper")
		_change_suspicion(local_player_ref, local_npc_ref, outgoing_secret, incoming_secret)

		# subsequent NPC-only trades:
		if randf() > 0.5:
			_npcs_trade()
		if randf() > 0.5:
			_npcs_trade()

	close_secrets()


func _on_exfiltrate_button_pressed():
	if not areas.sharing_player_secrets_list.is_anything_selected():
		return
	var selected_index = areas.sharing_player_secrets_list.get_selected_items()[0]
	var outgoing_secret = outgoing_secrets[selected_index]
	if outgoing_secret:
		# local_player_ref.take_secret(outgoing_secret)
		var achievement = "l%s_exfil" % outgoing_secret.grade
		local_player_ref.achieve(achievement)
		PubSub.audio_play_sfx.emit("unlock")
	close_secrets()


func _change_suspicion(player, npc, outgoing_secret, incoming_secret):
	var suspicion = player.suspicion
	var delta = 0
	# every transaction is suspicious
	delta = delta + 0.01
	# trading with hostiles raises suspicion
	if npc.is_hostile: # and randf() > 0.7:
		delta = delta + outgoing_secret.grade / 20.0
	# trading higher for lower raises suspicion
	if outgoing_secret.grade > incoming_secret.grade:
		delta = delta + 0.02
	# trading lower for higher lowers suspicion
	elif outgoing_secret.grade < incoming_secret.grade:
		delta += 0.02

	suspicion = clampf(suspicion + delta, 0, 1)

	print("L%s / sus %s" % [outgoing_secret.grade, suspicion])
	local_player_ref.set_suspicion(suspicion)


func _npcs_trade():
	var npcs = get_tree().get_nodes_in_group("npcs")
	var npc1 = npcs.pick_random()
	var npc2 = null
	while !npc2 or npc2 == npc1:
		npc2 = npcs.pick_random()

	var npc1_secret = npc1.held_secrets.pick_random()
	var npc2_secret = npc2.held_secrets.pick_random()
	npc1.give_secret(npc2_secret)
	npc2.give_secret(npc1_secret)
