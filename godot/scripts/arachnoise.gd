extends Node2D

const Mozzie = preload("res://scenes/prey/mozzie.tscn")
const OCT_1_31_CELESTE_C_1 = preload("uid://dqb13ymsy146u")
const OCT_1_32_CELESTE_D_1 = preload("uid://6ugr75johqiy")
const OCT_1_33_CELESTE_D_1 = preload("uid://bso0iajl0cgt1")
const OCT_1_34_CELESTE_E_1 = preload("uid://8thoplqkkpbk")
const OCT_1_35_CELESTE_F_1 = preload("uid://b0lql3mp865rf")
const OCT_1_36_CELESTE_F_1 = preload("uid://clnj0ghelpr1f")
const OCT_1_37_CELESTE_G_1 = preload("uid://c8n7dn317mqk6")
const OCT_1_38_CELESTE_G_1 = preload("uid://b41n1m1no8oit")
const OCT_1_39_CELESTE_A_1 = preload("uid://coqr3bncau662")
const OCT_1_40_CELESTE_A_1 = preload("uid://k1iudb7tv1xc")
const OCT_1_41_CELESTE_B_1 = preload("uid://82207crsxalv")
const OCT_1_CELESTE_C_1 = preload("uid://dkjget8ij7k2a")
const OCT_2_43_CELESTE_C_2 = preload("uid://d1khl1ron3nkb")
const OCT_2_44_CELESTE_C_2 = preload("uid://cugopm3i1kuvm")
const OCT_2_45_CELESTE_D_2 = preload("uid://bvt5ql4ypbhvj")
const OCT_2_46_CELESTE_D_2 = preload("uid://dehcwy81jyk1l")
const OCT_2_47_CELESTE_E_2 = preload("uid://byv5225wwb6cl")
const OCT_2_48_CELESTE_F_2 = preload("uid://bevmw4gqd1po6")
const OCT_2_49_CELESTE_F_2 = preload("uid://dbuc3tpr06own")
const OCT_2_50_CELESTE_G_2 = preload("uid://cmlsdlgbnxcsm")
const OCT_2_51_CELESTE_G_2 = preload("uid://mkq8ck68rjnk")
const OCT_2_52_CELESTE_A_2 = preload("uid://bej0rytceule0")
const OCT_2_53_CELESTE_A_2 = preload("uid://d01spd7mcl5xf")
const OCT_2_54_CELESTE_B_2 = preload("uid://bc6fwd15f616m")
const OCT_2_55_CELESTE_C_3 = preload("uid://b82ipfy2krl2r")

@onready var automator: AnimationPlayer = $Automator
@onready var game: Parallax2D = %Game
var initial_buzz = false
# Okay, we're vaguely setup. 

# We're going to make use of our 'anchor' lines, 1-13,
# which are representative of the following -

# 1 - C > C Dm Em F G Am B
# 2 - G > G Am Bm C D Em F#
# 3 - D > D Em F#m G A Bm C#
# 4 - A > A Bm C# D E F#m G#
# 5 - E > E F#m G#m A B C#m D#
# 6 - B > B C#m D#m E F# G#m A#
# 7 - F# > F# G#m A#m B C# D#m E#
# 8 - Gb > Gb Abm Bbm Cb Db Ebm F
# 9 - Db > Db Ebm Fm Gb Ab Bbm C
#10 - Ab > Ab Bbm Cm Db Eb Fm G
#11 - Eb > Eb Fm Gm Ab Bb Cm D
#12 - Bb > Bb Cm Dm Eb F Gm A
#13 - F > F Gm Am Bb C Dm E


# This gives us a sequence to follow for each 'prey'

func _ready() -> void:
	$Automator.play("fade_in")
	$Ambience.finished.connect(func(): $Ambience.play())

func _buzz_spidey():
	if $Game/Prey/Container.get_child_count() == 0:
		var prey = _new_prey()
		$Game/Prey/Container.add_child(prey)
		$Game/Prey/Automator.play_with_capture("lurk", 1.5)
	else:
		print("uhm?")

func _new_prey() -> CharacterBody2D: 
	var prey: = Mozzie.instantiate()
	return prey
	
func _drop_prey():
	for i in $Game/Prey/Container.get_child_count():
		$Game/Prey/Container.get_child(i).queue_free()
		
func _on_loitering_state_entered() -> void:
	# Random timer from 4-7s, mosquito 'appears' - root note chosen, gradient radial blur with note
	# color and pulse animation near random screen edge. 
	if $Game/Prey/Container.get_child_count() > 0:
		$Game/Prey/Automator.play_with_capture("flee", 1.5)
		get_tree().create_timer(2.5).timeout.connect(_drop_prey)
	
	var wait_length = randi_range(4,7) * (2 if not initial_buzz else 4)
	get_tree().create_timer(wait_length).timeout.connect(_buzz_spidey)

func _on_enticing_state_entered() -> void:
	var player = AudioStreamPlayer2D.new()
	add_child(player)
	player.stream = OCT_2_48_CELESTE_F_2
	player.global_position = $Game/Prey/Container.get_child(0).global_position
	player.finished.connect(player.queue_free)
	player.play()

func _on_trapping_state_entered() -> void:
	pass # Replace with function body.

func _on_ensnared_state_entered() -> void:
	pass # Replace with function body.

func _on_phrase_1_state_entered() -> void:
	pass # Replace with function body.

func _on_phrase_2_state_entered() -> void:
	pass # Replace with function body.

func _on_phrase_3_state_entered() -> void:
	pass # Replace with function body.

func _on_success_state_entered() -> void:
	pass # Replace with function body.

func _on_prey_startled_taken() -> void:
	pass # Replace with function body.

func _on__plucked(key: String, note: int) -> void:
	# Actually check harmony/discord
	$State.send_event("StartlePrey")
