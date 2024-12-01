extends Control


func _ready():
	set_initial_state()

	# responsiveness
	_on_size_changed()
	get_tree().get_root().size_changed.connect(_on_size_changed)


func _on_size_changed():
	# make UI font sizes scale with window
	var percent = get_window().size.y / 100.0
	theme.set_font_size("font_size", "Label", 2 * percent)
	theme.set_font_size("font_size", "Button", 2 * percent)
	%Logo_TextureRect.custom_minimum_size.y = 25 * percent


func set_initial_state():
	%MainMenu_Rect.show()
	%Controls_Rect.hide()
	%Settings_Rect.hide()
	%Credits_Rect.hide()
	%Won_Label.hide()
	%Lost_Label.hide()
	%Start_Button.show()
	%Start_Button.grab_focus()


func set_paused_state():
	%Start_Button.text = "Resume"


func set_won_state():
	%Won_Label.show()
	%Start_Button.text = "Play again"


func set_lost_state():
	%Lost_Label.show()
	%Start_Button.text = "Play again"


func _on_start_button_pressed():
	PubSub.audio_play_sfx.emit("menu-in")
	PubSub.game_begin.emit()


func _on_controls_button_pressed():
	%MainMenu_Rect.hide()
	%Controls_Rect.show()
	%Back_Button.grab_focus()
	PubSub.audio_play_sfx.emit("menu-in")


func _on_settings_button_pressed():
	%MainMenu_Rect.hide()
	%Settings_Rect.show()
	%Back_Button2.grab_focus()
	PubSub.audio_play_sfx.emit("menu-in")


func _on_credits_button_pressed() -> void:
	%MainMenu_Rect.hide()
	%Credits_Rect.show()
	%Back_Button3.grab_focus()
	PubSub.audio_play_sfx.emit("menu-in")


func _on_back_button_pressed():
	%Controls_Rect.hide()
	%Settings_Rect.hide()
	%Credits_Rect.hide()
	%MainMenu_Rect.show()
	%Start_Button.grab_focus()
	PubSub.audio_play_sfx.emit("cancel")


func _on_quit_button_pressed():
	PubSub.quit.emit()


func _on_music_h_slider_value_changed(value:float):
	PubSub.settings_change.emit('music', value)


func _on_sfx_h_slider_value_changed(value:float):
	PubSub.settings_change.emit('sfx', value)
	PubSub.audio_play_sfx.emit("menu-in")
