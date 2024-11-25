extends Node

const MIN_SETTINGS_VOLUME = 0
const MAX_SETTINGS_VOLUME = 5

# slider inputs of 0-5 will be mapped to dB volume values:
const MUSIC_DB_VOLUMES = [-80, -24, -12, -6, -3, 0]
const SFX_DB_VOLUMES = [-80, -24, -12, -6, -3, 0]

const MUSIC_BASE = "res://assets/sounds/music/"
const MUSIC_FILES = {
	"menu": {
		1: "Atmosphere_Hum_Eerie_Loop_Stereo.wav", #
		2: "Ambiance_Wind_Calm_Loop_Stereo.wav", #
	},
	"game": {
		"alight": "Clement Panchout _ Another Light (Intro).wav", #
		"lj_break": "Clement Panchout _ LJ_Tel_Breakbeat.wav", #
		"lj_hop": "Clement Panchout _ LJ_Tel_HipHop.wav", #
		"revenge": "Clement Panchout _ Revenge.wav", #
		"arabian": "Modern _ Eastern _ Arabian Princess _ Clement Panchout 2019.wav", #
	}
}
const SFX_BASE = "res://assets/sounds/sfx/"
const SFX_FILES = {
	"menu-in": "CursorSound3.mp3",
	"menu-cancel": "abs-cancel-2.mp3", # ok
	"door": "Vehicle_Car_Trunk_Open_Mono.wav", #
	"exchange": "mixkit-video-game-treasure-2066.wav",
	"whoosh": "whoosh1.wav",
	"win": "SuccessSound3.mp3",
	"lose": "ErrorSound3.mp3",
	"f_huh1": "Voice_Female_V2_Reflexion_Mouth_Close_Mono_03.wav",
	"f_huh2": "Voice_Female_V2_Reflexion_Mouth_Close_Mono_06.wav",
	"f_huh3": "Voice_Female_V2_Reflexion_Mouth_Open_Mono_06.wav",
	"m_huh1": "Voice_Male_V1_Reflexion_Mouth_Close_Mono_05.wav",
	"m_huh2": "Voice_Male_V1_Reflexion_Mouth_Close_Mono_06.wav",
	"m_huh3": "Voice_Male_V2_Nod_Mono_03.wav",
	"m_huh4": "Voice_Male_V2_Reflexion_Mouth_Close_Mono_02.wav",
}
const FADE_TIME := 3.0

# nodes
var music_array : Array[AudioStreamPlayer]
var sfx_array : Array[AudioStreamPlayer]
var current_music_player : AudioStreamPlayer

var music_timer : Timer

# settings
var user_music_volume_db := 0.0


func _select_music(key: String) -> String:
	if key in MUSIC_FILES:
		var res = MUSIC_BASE + MUSIC_FILES[key].values().pick_random()
		print("music picked for %s: %s" % [key, res])
		return res;
	return ""


func _load_sfx(key: String) -> AudioStream:
	if key in SFX_FILES:
		return load(SFX_BASE + SFX_FILES[key])
	return null


func _fade_music_in(key: String):
	current_music_player.stream = load(_select_music(key))
	current_music_player.volume_db = MUSIC_DB_VOLUMES[0]
	current_music_player.play()
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(current_music_player, "volume_db", user_music_volume_db, FADE_TIME)

	music_timer.wait_time = current_music_player.stream.get_length() - 3
	music_timer.start()
	print("will crossfade in %ss" % music_timer.wait_time)
	music_timer.connect("timeout", func ():
		# stop the AudioStreamPlayer or the Timer to avoid crossfade
		if current_music_player.playing:
			_crossfade_music_to(key)
	)


func _fade_current_music_out():
	var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_property(current_music_player, "volume_db", MUSIC_DB_VOLUMES[0], FADE_TIME)


# crossfade 2 tracks within current music context
func _crossfade_music_to(key: String):
	_fade_current_music_out()
	current_music_player = music_array[0] if current_music_player == music_array[1] else music_array[1]
	_fade_music_in(key)


# switch to a new music context (stop whatever's playing and don't repeat it)
func _switch_music_to(key: String):
	music_timer.stop()
	current_music_player.stop()
	current_music_player = music_array[0] if current_music_player == music_array[1] else music_array[1]
	_fade_music_in(key)


func _audio_play_music(key: String):
	_switch_music_to(key)


func _audio_play_sfx(key: String):
	print("will play sfx %s" % key)
	# polyphonic node
	sfx_array[0].stream = _load_sfx(key)
	sfx_array[0].play()


func _ready():
	music_array = [
		%Music_AudioStreamPlayer1,
		%Music_AudioStreamPlayer2
	]
	sfx_array = [
		%Sfx_AudioStreamPlayer1,
		%Sfx_AudioStreamPlayer2,
		%Sfx_AudioStreamPlayer3,
		%Sfx_AudioStreamPlayer4
	]
	current_music_player = music_array[1]
	music_timer = $Crossfade_Timer
	_switch_music_to("menu")

	PubSub.settings_change.connect(func (key, value):
		if key == "music":
			user_music_volume_db = MUSIC_DB_VOLUMES[value]

		elif key == "sfx":
			for sfx_node in sfx_array:
				sfx_node.volume_db = SFX_DB_VOLUMES[value]
	)

	PubSub.audio_play_music.connect(_audio_play_music)
	PubSub.audio_play_sfx.connect(_audio_play_sfx)
