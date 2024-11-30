# AutoLoaded global singleton

extends Node

const TEXTURES_BASE = "res://assets/sprites/spcm/"
const ALL_TEXTURES = [
	{ "file": "sprite10.png", "gender": "f" }, # arsenal fan
	{ "file": "sprite19.png", "gender": "f" }, # sci-fi bra
	{ "file": "sprite24.png", "gender": "f" }, # capri pony
	{ "file": "sprite31.png", "gender": "f" }, # tall boots
	{ "file": "sprite44.png", "gender": "f" }, # blonde shawl
	{ "file": "sprite48.png", "gender": "f" }, # slutty brunette
	{ "file": "sprite70.png", "gender": "f" }, # tie shorts
	{ "file": "sprite73.png", "gender": "f" }, # diagonal stripe
	{ "file": "sprite89.png", "gender": "f" }, # high pony
	{ "file": "sprite09.png", "gender": "m" }, # dragonball gown
	{ "file": "sprite12.png", "gender": "m" }, # duffel coat
	{ "file": "sprite15.png", "gender": "m" }, # light hood
	{ "file": "sprite20.png", "gender": "m" }, # monkish quiff
	{ "file": "sprite32.png", "gender": "m" }, # suspenders flares
	{ "file": "sprite37.png", "gender": "m" }, # wizardly hat
	{ "file": "sprite45.png", "gender": "m" }, # shoulder pads
	{ "file": "sprite46.png", "gender": "m" }, # scraggy cloak
	{ "file": "sprite56.png", "gender": "m" }  # holy sleeves
]


# instance vars
var _unused_textures
var _used_textures


func reset():
	_unused_textures = ALL_TEXTURES.duplicate()
	_used_textures = []


func _init():
	reset()


func get_texture():
	if len(_unused_textures) == 0:
		return {}
	var texture = _unused_textures.pick_random()
	_unused_textures.erase(texture)
	_used_textures.append(texture)
	return {
		"path": TEXTURES_BASE + texture.file,
		"gender": texture.gender
	}
