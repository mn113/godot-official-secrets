# static class

extends Node

const FIRST_NAMES_FEMALE := [
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
	"Dolores",
	"Cher",
	"Laila"
]

const FIRST_NAMES_MALE := [
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
	"Toby",
	"Nour",
	"Ringo",
	"Napoleon"
]

const LAST_NAMES := [
	"Adams",
	"Johnson",
	"Williams",
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
	"Moon",
	"Al-Ahly",
	"Klopp",
	"Tarpoleon",
	"Dynamite",
	"Rohwavé",
	"Camembert"
]

const INITIALS := [
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
	var fname = FIRST_NAMES_FEMALE.pick_random()
	if gender == "m":
		fname = FIRST_NAMES_MALE.pick_random()
	var lname = LAST_NAMES.pick_random()
	var initial = INITIALS.pick_random()

	var templates = [
		[0.35, "first last"],
		[0.5, "first initial. last"],
		[0.7, "initial. first last"],
		[0.75, "initial. last"],
		[0.9, "first"],
		[1, "first last"] # can never be reached
	]
	var r = randf()
	while true:
		var template = templates.pop_front()
		if r <= template[0]:
			return template[1].replace("first", fname).replace("last", lname).replace("initial", initial)
