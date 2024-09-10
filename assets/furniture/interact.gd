extends StaticBody3D

@onready var animationPlayer = $"../AnimationPlayer"
var state = "closed"


func interact():
	if state == "closed":
		animationPlayer.play("open")
		state = "open"
	elif state == "open":
		animationPlayer.play_backwards("open")
		state = "closed"
