# AutoLoaded global singleton

extends Node

# var image = Image.load_from_file("res://assets/icons/Mail_256.png")
# var texture = ImageTexture.create_from_image(image)

const SECRET_GRADES = [1, 2, 3, 4, 5]
const SECRET_THRESHOLDS = [0.5, 0.7, 0.85, 0.95, 1] # 50% chance of being L1; 70% being L1-L2...
const SECRET_COLORS = ["orange", "yellow", "lime", "dodgerblue", "purple", "red"]
const SECRET_ICONS  = ["🟠", "🟡", "🟢", "🔵", "🟣", "🔴"]
const SECRET_ICONS2 = ["🟧", "🟨", "🟩", "🟦", "🟪", "🟥"]
const SECRET_TEXTURES = [
	preload("res://assets/kenney_prototypetextures/PNG/Dark/texture_01.png"),
	preload("res://assets/kenney_prototypetextures/PNG/Green/texture_01.png"),
	preload("res://assets/kenney_prototypetextures/PNG/Orange/texture_01.png"),
	preload("res://assets/kenney_prototypetextures/PNG/Purple/texture_01.png"),
	preload("res://assets/kenney_prototypetextures/PNG/Red/texture_01.png")
]


# child class, private
class Secret extends Object:
	var text
	var grade
	var originator
	var shares = 0

	func _init(ptext = "", pgrade = 1):
		text = ptext
		grade = pgrade
		if not len(text):
			print("out of secrets?")
			breakpoint # probably ran out of secrets

	func share():
		shares += 1
		if shares % 4 == 0:
			grade -= 1

	func _to_grade() -> String:
		return "[L%d]" % grade

	func _to_string() -> String:
		return text

	func _to_string_rich() -> String:
		return "[color=%s]%s[/color]" % [SECRET_COLORS[grade - 1], text]

	func _to_masked_string() -> String:
		return "*".repeat(len(text))

	func _to_masked_string_rich() -> String:
		return "[color=%s]%s[/color]" % [SECRET_COLORS[grade - 1], _to_masked_string()]

	func _to_bullet() -> String:
		return SECRET_ICONS2[grade - 1]

	func _to_bullet_rich() -> String:
		return "[color=%s]%s[/color]" % [SECRET_COLORS[grade - 1], SECRET_ICONS2[grade - 1]]

	func __to_icon() -> Texture2D:
		return SECRET_TEXTURES[grade - 1]


const all_texts: Array[String] = [
"The snail has landed.",
"A thousand flowers bloom.",
"The walls have ears, and their otologist is a spy.",
"The fox knows where the badger sleeps.",
"The pterodactyl flies at midnight.",
"The canteen's toad-in-the-hole is made with vegan toad substitute.",
"Agent 003½ has been compromised.",
"ABBA has never used an ABABA rhyming scheme.",
"Red Lotus is not to be trusted.",
"Shrinking violet called in sick, but isn't.",
"Safe house number 7 is not safe.",
"Cut the yellow wire, even if they tell you the blue.",
"Maroon raccoon is carrying the virus.",
"The fifth Beatle was half beetle.",
"Susan spent her holidays in Sudan.",
"Big Brother is watching Dave.",
"Circle Line westbound - 4 stops from HQ.",
"SPL prediction: Forfar 4 - Fife 5.",
"Stone Fist will take a dive in round 3.",
"I left my heart in East Berlin.",
"A mojito has 3 ingredients, 4 if you include arsenic.",
"The man who shot JFK was a one-armed bandit.",
"Gavin Strepsil cheated on his biology A-level.",
"Never feed a hamster cured ham.",
"Check LOTR book 1 page 137 line 15 word 3.",
"Han shot first. I read it in an exclusive first draft.",
"Alfredo Garcia is still alive. He used a fake head.",
"Half of all E-numbers in food are biblical references.",
"The sword \"Excalibur\" was held down with Gorilla Glue.",
"Ich bin ein Berliner.",
"The secret sauce ingredient is usually nduja.",
"There are not really nine million bicycles in Beijing.",
"Bitcoin will jump 300% on 29/2/2026.",
"ISO27001 is a scam to repress the masses.",
"Beware the geeks, even when they are bearing gift vouchers.",
"The events in Toy Story 3 actually happened.",
"The moon landing was faked, because a woman walked there first.",
"The lost city of Atlantis has be rediscovered by John West of tuna fame.",
"State surveillance is so boring they drug us to do it.",
"Loose lips sink ships... and Doctor Finkelstein is a horrible plastic surgeon.",
"The player who chooses the dog wins 38% of all Monopoly games."
]

# instance vars
var all_secrets = []
var unused_secrets = []
var used_secrets = []


func _init():
	for text in all_texts:
		all_secrets.append(Secret.new(text, SECRET_GRADES.pick_random()))
	unused_secrets = all_secrets.duplicate()
	unused_secrets.shuffle()


# returns:
# 1 with 50% chance
# 2 with 20% chance
# 3 with 15% chance
# 4 with 10% chance
# 5 with 5% chance
func get_grade(max_grade = 5) -> int:
	var r = randf()
	for g in range(len(SECRET_GRADES)):
		if r <= SECRET_THRESHOLDS[g]:
			return min(g + 1, max_grade)
	return 1


# get a unique secret, with randomly selected text and distributed grade
func get_secret(grade = null, max_grade = 5) -> Secret:
	if len(unused_secrets) == 0:
		return Secret.new() # ideally should never happen

	var s = unused_secrets.pop_back()
	unused_secrets.erase(s)

	s.grade = grade if grade != null else get_grade(max_grade)
	used_secrets.append(s)
	return s


func colourise(grade, text) -> String:
	return "[color=%s]%s[/color]" % [SECRET_COLORS[grade - 1], text]


func sort_by_grade(a, b):
	return a.grade > b.grade
