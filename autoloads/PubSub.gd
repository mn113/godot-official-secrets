extends Node

# PubSub system for signals
#
# To listen to a signal from a script:
#   PubSub.player_ready.connect(on_player_ready)
#
# To emit a signal from a script:
#   PubSub.player_ready.emit(detail)

signal settings_change # emitted by menu, received by main
signal game_state # received by main
signal game_begin # emitted by menu, received by main
signal game_win # received by main
signal game_lose # received by main
signal audio_play_sfx # received by audio
signal audio_play_music # received by audio
signal player_ready # emitted by player when ready
signal player_secrets_change # emitted by player when secrets change
signal player_suspicion_change # emitted by player when suspicion changes
signal player_npc_trade # emitted by player
signal player_achievement # emitted by player
signal open_secrets # emitted by NPC or Outbox when interacted
signal close_secrets # emitted by UI node
signal messages_add # received by UI messages node
signal messages_clear # received by UI messages node
signal goals_change # emitted by level node
signal outbox_interact # emitted by Outbox
signal story_feed # emitted by level, for UI
