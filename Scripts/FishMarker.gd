extends Area2D

var keep = false
var parent_fish

func _ready():
	add_to_group("fish_markers")

func destroy_if_not_active():
	if !keep:
		queue_free()

func destroy_self():
	queue_free()
