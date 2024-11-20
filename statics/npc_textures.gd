# static class with state

extends Node

const TEXTURES_BASE = "res://assets/spcm/"
const ALL_TEXTURES = [
	{ "file": "sprite10.png", "gender": "f" },
	{ "file": "sprite19.png", "gender": "f" },
	{ "file": "sprite24.png", "gender": "f" },
	{ "file": "sprite31.png", "gender": "f" },
	{ "file": "sprite44.png", "gender": "f" },
	{ "file": "sprite48.png", "gender": "f" },
	{ "file": "sprite70.png", "gender": "f" },
	{ "file": "sprite73.png", "gender": "f" },
	{ "file": "sprite89.png", "gender": "f" },
	{ "file": "sprite09.png", "gender": "m" },
	{ "file": "sprite12.png", "gender": "m" },
	{ "file": "sprite15.png", "gender": "m" },
	{ "file": "sprite20.png", "gender": "m" },
	{ "file": "sprite24.png", "gender": "m" },
	{ "file": "sprite32.png", "gender": "m" },
	{ "file": "sprite37.png", "gender": "m" },
	{ "file": "sprite45.png", "gender": "m" },
	{ "file": "sprite46.png", "gender": "m" },
	{ "file": "sprite56.png", "gender": "m" }
]

# instance vars
static var _unused_textures = ALL_TEXTURES.duplicate()
static var _used_textures = []

static func get_texture():
	if len(_unused_textures) == 0:
		return {}
	var texture = _unused_textures.pick_random()
	_unused_textures.erase(texture)
	_used_textures.append(texture)
	return { "path": TEXTURES_BASE + texture.file, "gender": texture.gender }
