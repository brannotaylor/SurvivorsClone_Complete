extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimationPlayer.play("explode")

func _on_animation_player_animation_finished(_anim_name):
	queue_free()
