extends Node2D

@onready var automator: AnimationPlayer = $Automator

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Automator.play("fade_in")
	
	# Let's build a web
	# Base layer fade in
	
	# find collission edges
	
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
