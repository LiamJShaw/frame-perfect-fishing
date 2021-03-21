extends Node2D

const SPEED = 100

enum STATE {
	ready,
	reset,
	resetting,
	turn_started,
	check_accuracy,
	powerbar_active
}

var starting_transform
var GameState = STATE.ready
var rod_direction = "left"

func _ready():
	# Populate pond
	starting_transform = $Rod.global_transform
	$PowerBar.connect("turn_over", self, "turn_over")

func _physics_process(delta):
	
	match GameState:
		
		STATE.reset:
			$Rod/Timer.start()
			GameState = STATE.resetting
		
		STATE.resetting:
			pass
		
		STATE.ready:
			
			if rod_direction == "left":
				$Rod.position -= transform.x * SPEED * delta
				$Rod.set_scale(Vector2(1,1))
				$PondSides/Left.disabled = false
				$PondSides/Right.disabled = true
			elif rod_direction == "right":
				$Rod.position += transform.x * SPEED * delta
				$Rod.set_scale(Vector2(-1,1))
				$PondSides/Left.disabled = true
				$PondSides/Right.disabled = false

			if Input.is_action_just_pressed("action"):
				GameState = STATE.check_accuracy
				
		STATE.check_accuracy:
			yield(get_tree(), "idle_frame") # Godot seemingly needs an extra frame to correctly get the overlapping areas.

			var areas = $Rod.get_overlapping_areas()

			if areas.size() > 0:
				activate_powerbar(areas)

			else:
				miss()
				GameState = STATE.reset
					
		STATE.powerbar_active:
			# Is this just the same as idle?
			pass
					
func activate_powerbar(areas):
	var fish_markers = []
	var fish = []
	
	for area in areas:
		fish_markers.append(area.get_global_position())
		fish.append(area.get_name())
		
	$PowerBar.populate_bar(fish_markers, fish)
		
	GameState = STATE.powerbar_active
	
func miss():
	print("Miss!")
	$ShakeCamera2D.add_trauma(0.12)
		
## SIGNALS ##

func _on_PondSides_area_entered(_area):
	if rod_direction == "left":
		rod_direction = "right"
	else:
		rod_direction = "left"

func turn_over():
#	$Rod.position.x = 0
#	$Rod.global_transform = starting_transform
	GameState = STATE.ready
