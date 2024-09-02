extends BaseControler3D
class_name TopDownControler3D

enum action_types {
	directional,
	move_to_click
}

@export_category("Movement")
@export var Action_Type : action_types = action_types.directional
@export var Turn_Speed = 10
@export var Floor_Group : String = "floor"

@export_category("Camera")
@export var Handle_Camera : bool = true
@export var Camera_Smooth_Distance : float = 0
@export var Camera_Smooth_Speed : float = 0
@export var Spring_Length : float = 10
@export var Angle : float = -70
@export var Horizontal_Offset : float = 0
@export var Vertical_Offset : float = 0
@export var Custom_Camera : Camera3D

var pivot : Node3D 
var camera : Camera3D 
var camera_rest_position : Vector3
var use_pivot = true
var target = Vector3.ZERO

func _ready() -> void:
	if Handle_Camera:
		if Custom_Camera:
			camera = Custom_Camera
			use_pivot = false
		else:
			pivot = Node3D.new()
			add_child(pivot)
			pivot.global_rotation.x = deg_to_rad(Angle)
			pivot.position.x = Horizontal_Offset
			pivot.position.y = Vertical_Offset	
			camera = Camera3D.new()		
			pivot.add_child(camera)	
			camera.position.z = Spring_Length
			use_pivot = true	
		
	if not Geometry:
		for child in parent.get_children():
			if child is MeshInstance3D:
				Geometry = child
				continue
	
	if Action_Type == action_types.move_to_click:
		var floors = get_tree().get_nodes_in_group(Floor_Group)
		for floor in floors:
			floor.connect("input_event", on_floor_input)	
				
	toggle_active(Active)
			
func on_floor_input(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if not Active or Action_Type == action_types.directional:
		return
	if event is InputEventMouseButton and event.pressed:
		target = event_position

func _process(delta: float) -> void:
	if not Active:
		return
		
	handle_gravity(delta)
	HandleJump(delta)			
	
	match Action_Type:
		action_types.directional:
			handle_directional_action(delta)
		action_types.move_to_click:
			handle_move_to_click_action(delta)
							
	move()

	
func handle_directional_action(delta :float):
	var direction = get_direction()
	var currentSpeed = get_speed()
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * currentSpeed, Acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * currentSpeed, Acceleration * delta)
		if Geometry:
			var prev_y = Geometry.rotation.y
			Geometry.look_at(Vector3(parent.position.x, parent.position.y, parent.position.z) + direction)
			var target_y = Geometry.rotation.y
			Geometry.rotation.y = lerp_angle(prev_y, target_y, delta * Turn_Speed)
		if Handle_Camera:
			if use_pivot:		
				if Camera_Smooth_Distance and abs(pivot.position.x) < Camera_Smooth_Distance:	
					pivot.position.x = move_toward(pivot.position.x, direction.x * currentSpeed * -1, Camera_Smooth_Speed * delta)
				if Camera_Smooth_Distance and abs(pivot.position.z) < Camera_Smooth_Distance:	
					pivot.position.z = move_toward(pivot.position.z, direction.z * currentSpeed * -1, Camera_Smooth_Speed * delta)
			else:
				if Camera_Smooth_Distance and abs(camera.position.x) < Camera_Smooth_Distance:	
					camera.position.x = move_toward(camera.position.x, direction.x * currentSpeed * -1, Camera_Smooth_Speed * delta)
				if Camera_Smooth_Distance and abs(camera.position.z) < Camera_Smooth_Distance:	
					camera.position.z = move_toward(camera.position.z, direction.z * currentSpeed * -1, Camera_Smooth_Speed * delta)
	else:		
		velocity.x = move_toward(velocity.x, 0, Deacceleration * delta)		
		velocity.z = move_toward(velocity.z, 0, Deacceleration * delta)		
		if Camera_Smooth_Distance and Handle_Camera:
			if use_pivot:		
				pivot.position.x = move_toward(pivot.position.x, Horizontal_Offset, Camera_Smooth_Speed * delta)
				pivot.position.z = move_toward(pivot.position.z, Horizontal_Offset, Camera_Smooth_Speed * delta)
			else:
				camera.position.x = move_toward(camera.position.x, Horizontal_Offset, Camera_Smooth_Speed * delta)
				camera.position.z = move_toward(camera.position.z, Horizontal_Offset, Camera_Smooth_Speed * delta)		

func handle_move_to_click_action(delta :float):
	var currentSpeed = get_speed()
	
	if target:
		if Geometry:
			var prev_y = Geometry.rotation.y
			Geometry.look_at(Vector3(target.x, parent.position.y, target.z) )
			var target_y = Geometry.rotation.y
			Geometry.rotation.y = lerp_angle(prev_y, target_y, delta * Turn_Speed)
			
		var direction = parent.global_position.direction_to(target)
		
		if direction:
			velocity.x = move_toward(velocity.x, direction.x * currentSpeed, Acceleration * delta)
			velocity.z = move_toward(velocity.z, direction.z * currentSpeed, Acceleration * delta)		
		else:
			velocity.x = move_toward(velocity.x, 0, Deacceleration * delta)		
			velocity.z = move_toward(velocity.z, 0, Deacceleration * delta)	
			
		if transform.origin.distance_to(target) < .5:
			target = Vector3.ZERO			
	
func toggle_active(state : bool):	
	Active = state
	if Handle_Camera:
		if state:
			camera.make_current()
		else:
			camera.clear_current()
