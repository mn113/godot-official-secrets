# static class

extends Node

const GREETINGS = [
	"Hi.",
	"Hello.",
	"Ciao.",
	"Alright.",
	"Hail Caesar.",
	"Howdy, pardner.",
	"Morning, guvnor.",
	"Hail fellow well met.",
	"What gives?",
	"What's the news?",
	"What's occurring?",
	"Penny for your thoughts?",
	"Tell me what's on your mind.",
	"What light from yonder window breaks?",
]

static func get_greeting():
	return GREETINGS.pick_random()
