extends Sprite

signal turn_over

const FishMarker = preload("res://Scenes/FishMarker.tscn")
const CatchMarkerEasy = preload("res://Scenes/CatchMarkers/CatchMarkerEasy.tscn")
const CatchMarkerNormal = preload("res://Scenes/CatchMarkers/CatchMarkerNormal.tscn")
const CatchMarkerHard = preload("res://Scenes/CatchMarkers/CatchMarkerHard.tscn")

const Indicator = preload("res://Scenes/Indicator.tscn")

var GameManager

var SPEED = 120

var power_indicator
var catch_indicator
var catch_marker
var selected_fish

var total_accuracy = 0

var starting_transform
var indicator_direction = "left"
var BarState = STATE.idle

enum STATE {
	idle
	reset,
	resetting,
	turn_started,
	check_power_accuracy,
	check_catch,
	check_catch_accuracy
}

func _ready():
	starting_transform = $PowerIndicator.global_transform
	GameManager = get_tree().get_root().get_node("MainScreen")
	
func _physics_process(delta):
	match BarState:
		STATE.idle:
			pass

		STATE.reset:
			$ResetTimer.start()
			BarState = STATE.resetting

		STATE.resetting:
			pass # This stops the user from starting the indicator again before a new turn

		STATE.turn_started: 
			
			if indicator_direction == "left":
				$PowerIndicator.position -= transform.x * SPEED * delta
			elif indicator_direction == "right":
				$PowerIndicator.position += transform.x * SPEED * delta

			if Input.is_action_just_pressed("action"):
				BarState = STATE.check_power_accuracy

		STATE.check_power_accuracy:
			yield(get_tree(), "idle_frame") # Godot seemingly needs an extra frame to correctly get the overlapping areas.
			
			var power_areas = $PowerIndicator.get_overlapping_areas()

			if power_areas.size() > 0:
				power_areas[0].get_owner().keep = true
				selected_fish = power_areas[0].get_owner().parent_fish
				check_power_accuracy(power_areas)
				clear_bar()
				spawn_catch_indicator()
				BarState = STATE.check_catch

			else:
				GameManager.miss()
				BarState = STATE.reset

		STATE.check_catch:
			if indicator_direction == "left":
				catch_indicator.position -= transform.x * SPEED * delta
			elif indicator_direction == "right":
				catch_indicator.position += transform.x * SPEED * delta

			if Input.is_action_just_pressed("action"):
				BarState = STATE.check_catch_accuracy

		STATE.check_catch_accuracy:
			yield(get_tree(), "idle_frame") # Godot seemingly needs an extra frame to correctly get the overlapping areas.
			
			var areas = catch_indicator.get_overlapping_areas()

			if areas.size() > 0:
				check_catch_accuracy(areas)
			else:
				GameManager.miss()
				BarState = STATE.reset

func check_power_accuracy(areas):
	var collisions = []
		
	for area in areas:
		collisions.append(area.get_name())
		selected_fish = area.get_owner().parent_fish
		
	if collisions.has("InnerArea") and !collisions.has("OuterArea"):
		print("Perfect!")
		catch_marker = CatchMarkerEasy.instance()
		catch_marker.position = $CatchMarkerPosition.position
		self.add_child(catch_marker)
		total_accuracy += 3

	elif collisions.has("InnerArea") and collisions.has("OuterArea"):
		print("Nearly")
		catch_marker = CatchMarkerNormal.instance()
		catch_marker.position = $CatchMarkerPosition.position
		self.add_child(catch_marker)
		total_accuracy += 2

	elif collisions.has("OuterArea") and !collisions.has("InnerArea"):
		print("Poor")
		catch_marker = CatchMarkerHard.instance()
		catch_marker.position = $CatchMarkerPosition.position
		self.add_child(catch_marker)
		total_accuracy += 1
		
func check_catch_accuracy(areas):
	var collisions = []
		
	for area in areas:
		collisions.append(area.get_name())

	if collisions.has("InnerArea") and !collisions.has("OuterArea"):
		print("Perfect!")
		total_accuracy += 3
		fish_hooked()

	elif collisions.has("InnerArea") and collisions.has("OuterArea"):
		print("Nearly")
		fish_hooked()
		total_accuracy += 2
		
	elif collisions.has("OuterArea") and !collisions.has("InnerArea"):
		print("Poor")
		fish_hooked()
		total_accuracy += 1
	else:
		print("Miss!")
	
	BarState = STATE.reset
		
func spawn_catch_indicator():
	catch_indicator = Indicator.instance()
	catch_indicator.position = $PowerIndicator.position
	self.add_child(catch_indicator)

func populate_bar(fish_markers, fish): 
	
	var fish_counter = 0
	
	for marker in fish_markers:
		var fish_marker = FishMarker.instance()
		fish_marker.position = $FishMarkerPosition.position
		fish_marker.position.x += (marker.y/1.5 - 20) # magic number
		fish_marker.name = "fish_marker_" + String(fish_counter)
		fish_marker.parent_fish = fish[fish_counter]
		
		self.add_child(fish_marker)
		
		fish_counter += 1
	
	BarState = STATE.turn_started	

func clear_bar():
	get_tree().call_group("fish_markers", "destroy_if_not_active")
	
func fish_hooked():
	var fish = get_tree().get_root().get_node("BaseGame/Pond/" + selected_fish)
	if fish_is_caught():
		fish.caught()
	else:
		print("It got away!")
		
func fish_is_caught():
	randomize()
	
	match total_accuracy:
		6:
			return true
		5:
			if randi() % 9 == 0: # 80% chance to catch
				return false
			else:
				return true
		4:
			if randi() % 5 == 0: # 50% chance to catch
				return false
			else:
				return true
		2:
			if randi() % 3 == 0: # 33.3% chance to catch
				return false
			else:
				return true
				
# SIGNALS #
func _on_ResetTimer_timeout():
	$PowerIndicator.position.x = 0
	$PowerIndicator.global_transform = starting_transform
	
	indicator_direction = "left"
	SPEED += 5
	total_accuracy = 0
	
	BarState = STATE.idle
	
	if catch_indicator:
		catch_indicator.queue_free()
	if catch_marker:
		catch_marker.queue_free()
	
	emit_signal("turn_over")
	get_tree().call_group("fish_markers", "destroy_self")
	
func _on_Sides_entered(_area):
	if indicator_direction == "left":
		indicator_direction = "right"
	else:
		_on_ResetTimer_timeout()
