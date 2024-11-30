# AutoLoaded global singleton

extends Node

const SECRET_GRADES := [1, 2, 3, 4, 5]
const SECRET_THRESHOLDS := [0.5, 0.7, 0.85, 0.95, 1] # 50% chance of being L1, 70% being L1-L2...
const SECRET_AMOUNTS := [12, 11, 10, 9, 8] # 50 total (initial)
const SECRET_COLORS := ["orange", "yellow", "lime", "dodgerblue", "purple"]
const SECRET_ICONS := ["🟧", "🟨", "🟩", "🟦", "🟪"]
const SECRET_TEXTS := [
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
	"The secret sauce ingredient is usually nduja.",

	"There are not really nine million bicycles in Beijing.",
	"Bitcoin will jump 300% on 29/2/2028.",
	"ISO27001 is a scam to repress the masses.",
	"Beware the geeks, even when they are bearing gift vouchers.",
	"The events in Toy Story 3 actually happened.",
	"The moon landing was faked, because a woman walked there first.",
	"The lost city of Atlantis has been rediscovered by John West of tuna fame.",
	"State surveillance is so boring they drug us to do it.",
	"Loose lips sink ships... and Doctor Finkelstein is a horrible plastic surgeon.",
	"The player who chooses the dog wins 38% of all Monopoly games.",

	"The secret ingredient in a Filet-O-Fish is ambergris.",
	"Windows 95 was largely copied from a design by Sir Francis Drake.",
	"Steve Gutenberg was separated from his brother Johannes at birth.",
	"For a good time, call 8675-309.",
	"Fortune cookie papers are key to a balanced diet.",
	"William Brown is a very naughty boy.",
	"In some cases, an apostrophe can be used to make a plural.",
	"Fax machine noises are actually transmissions from aliens.",
	"The password is \"Clam Chowder\"; I'm not sure what colour.",
	"Tutankhamun lost his wealth due to a pyramid scheme.",

	"You can never have too much of a good thing.",
	"I saw Mommy kissing Santi Cazorla.",
	"Bob Dylan is afraid of Virginia Woolf.",
	"Archimedes had a secret invention: the triangular bath.",
	"Yellow snow should only be eaten on the advice of a qualified dietician.",
	"Q placed a USB stick with 1BTC in the toilets at York station.",
	"The segmentation fault was nothing to do with me.",
	"HR knows who put the bomp in the bomp-di-bomp-di-bomp.",
	"Non-league football is an international people-smuggling operation.",
	"The acting quartermaster of Chinese Intelligence is Maggie Q."
]


# child class, private
class Secret extends Object:
	var text
	var grade
	var shares := 0

	func _init(ptext = "", pgrade = 1):
		text = ptext
		grade = pgrade
		if not len(text):
			print("out of secrets?")
			breakpoint # probably ran out of secrets

	func share():
		shares += 1
		if shares % 4 == 0 and grade < 3:
			grade -= 1

	func _to_grade() -> String:
		return "[L%d]" % grade

	func _to_string() -> String:
		return text

	func _to_string_rich() -> String:
		return "[color=%s]%s[/color]" % [SECRET_COLORS[grade - 1], text]

	func _to_masked_string() -> String:
		return "*".repeat(len(text))

	func _to_bullet() -> String:
		return SECRET_ICONS[grade - 1]


# instance vars
var all_secrets : Array[Secrets.Secret]
var unused_secrets : Array[Secrets.Secret]
var used_secrets : Array[Secrets.Secret]


func reset():
	all_secrets = _generate_secrets()
	unused_secrets = all_secrets.duplicate()
	unused_secrets.shuffle()
	used_secrets = []


func _init():
	reset()


func _generate_secrets():
	var tmp_secrets = [] as Array[Secrets.Secret]
	var tmp_secret_texts = []
	for text in SECRET_TEXTS:
		tmp_secret_texts.append(text)
	tmp_secret_texts.shuffle()

	for grade in SECRET_GRADES:
		var amt = SECRET_AMOUNTS[grade - 1]
		for _i in range(amt):
			tmp_secrets.append(Secret.new(tmp_secret_texts.pop_front(), grade))

	return tmp_secrets


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
		print("get_secret: out of secrets")
		return null # ideally should never happen

	var s = unused_secrets.pop_back()
	unused_secrets.erase(s)

	s.grade = grade if grade != null else get_grade(max_grade)
	used_secrets.append(s)
	return s


func colourise(grade, text) -> String:
	return "[color=%s]%s[/color]" % [SECRET_COLORS[grade - 1], text]


# sorts a list of secrets high to low
func sort_by_grade(a, b):
	return a.grade > b.grade
