extends BaseControler3D
class_name FirstPersonControler3D

enum rotation_types {
	Camera_Only,
	Camera_And_Geometry
}

@export_category("Movement")
@export var Mouse_Sensitivity = 0.01
@export var Turn_Speed = 10
@export var Rotation_Type : rotation_types = rotation_types.Camera_And_Geometry

@export_category("Camera")
@export var Horizontal_Offset : float = 0
@export var Vertical_Offset : float = 0
@export var Custom_Camera : Camera3D
@export_range(1, 360) var Max_Camera_Angle : int = 90
@export_range(-360, 0) var Min_Camera_Angle : int = -90

var pivot : Node3D 
var camera : Camera3D 

func _ready() -> void:	
	pivot = Node3D.new()
	add_child(pivot)
	pivot.position.x = Horizontal_Offset
	pivot.position.y = Vertical_Offset
	if Custom_Camera:
		camera = Custom_Camera
		camera.reparent(pivot)
	else:
		camera = Camera3D.new()
		pivot.add_child(camera)	
	if not Geometry:
		for child in parent.get_children():
			if child is MeshInstance3D:
				Geometry = child
				continue
	toggle_active(Active)
	
func _input(event):
	if not Active:
		return
	if Handle_Mouse_Capture:
		if event is InputEventMouseButton:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif Input.is_action_just_pressed(Input_Cancel):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE	
			
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:        
		pivot.rotate_y(-(event as InputEventMouseMotion).relative.x * Mouse_Sensitivity)            
		if Geometry and Rotation_Type == rotation_types.Camera_And_Geometry:
			Geometry.rotate_y(-(event as InputEventMouseMotion).relative.x * Mouse_Sensitivity)
		camera.rotate_x(-(event as InputEventMouseMotion).relative.y * Mouse_Sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(Min_Camera_Angle), deg_to_rad(Max_Camera_Angle))
					
func _process(delta: float) -> void:
	if not Active:
		return
	
	handle_gravity(delta)
	HandleJump(delta)			
	var direction = get_direction(pivot)
	var currentSpeed = get_speed()
		
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * currentSpeed, Acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * currentSpeed, Acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, Deacceleration * delta)
		velocity.z = move_toward(velocity.z, 0, Deacceleration * delta)
		
	move()
	
func toggle_active(state : bool):
	Active = state
	if state:		
		camera.make_current()
	else:		
		camera.clear_current()
