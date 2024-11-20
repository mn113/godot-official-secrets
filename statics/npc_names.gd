# static class

extends Node

const first_female = [
	"Anne",
	"Mary",
	"Janine",
	"Elizabeth",
	"Abigail",
	"Sarah",
	"Margaret",
	"Muriel",
	"Edith",
	"Cleopatra",
	"Summer",
	"Rosamund",
	"Karen",
	"Viktoria",
	"Freya",
	"Erin",
	"Lulu",
	"Miriam",
	"Dolores"
]

const first_male = [
	"George",
	"Joseph",
	"Charles",
	"William",
	"Zephaniah",
	"Isaac",
	"Joseph",
	"Jean-Jacques",
	"Günther",
	"Albert",
	"Erik",
	"Henry",
	"Alphonse",
	"Zeke",
	"Mohamed",
	"Ruben",
	"Luka",
	"Bong",
	"Toby"
]

const last = [
	"Adams",
	"Johnson",
	"Williams",
	"Jones",
	"Davis",
	"Jackson",
	"White",
	"Harris",
	"Martin",
	"Thompson",
	"Garcia",
	"Martinez",
	"Roberts",
	"Lewis",
	"Crilly",
	"Steinbeck",
	"Molotov",
	"Lenin",
	"Bergström",
	"Matheson",
	"Pappas",
	"Freeman",
	"Heimlich",
	"Langerhans",
	"Mounce",
	"Stojkovic",
	"Müller",
	"Ferrari",
	"Fitzpatrick",
	"Garibaldi",
	"Carruthers",
	"Moon"
]

const initials = [
	"A",
	"B",
	"C",
	"D",
	"E",
	"F",
	"G",
	"H",
	"I",
	"J",
	"K",
	"L",
	"M",
	"N",
	"O",
	"P",
	"Q",
	"R",
	"S",
	"T",
	"U",
	"V",
	"W",
	"X",
	"Y",
	"Z"
]

static func generate_name(gender = "f"):
	var fname = first_female.pick_random()
	if gender == "m":
		fname = first_male.pick_random()
	var lname = last.pick_random()
	var initial = initials.pick_random()

	var templates = [
		[0.35, "first last"],
		[0.5, "first initial. last"],
		[0.65, "initial. first last"],
		[0.75, "initial. last"],
		[0.9, "first"],
		[1, "first last"]
	]
	var r = randf()
	while true:
		var template = templates.pop_front()
		if r <= template[0]:
			return template[1].replace("first", fname).replace("last", lname).replace("initial", initial)
