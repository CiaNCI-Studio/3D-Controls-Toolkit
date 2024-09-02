extends BaseControler3D
class_name ThirdPersonControler3D

@export_category("Movement")
@export var Mouse_Sensitivity = 0.05
@export var Turn_Speed = 10

@export_category("Camera")
@export var Spring_Length : float = 4
@export var Start_Angle : float = -20
@export var Horizontal_Offset : float = 0.4
@export var Vertical_Look_At_Offset : float = 0
@export var Custom_Camera : Camera3D
@export_range(1, 360) var Max_Camera_Angle : int = 90
@export_range(-360, 0) var Min_Camera_Angle : int = -90

var pivot : SpringArm3D 
var camera : Camera3D 

func _ready() -> void:
	pivot = SpringArm3D.new()
	add_child(pivot)
	pivot.global_rotation.x = deg_to_rad(Start_Angle)
	pivot.position.x = Horizontal_Offset
	pivot.add_excluded_object(parent)
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
	update()
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
		parent.rotate_y(deg_to_rad(-(event as InputEventMouseMotion).relative.x * Mouse_Sensitivity))
		if Geometry:
			Geometry.rotate_y(deg_to_rad((event as InputEventMouseMotion).relative.x * Mouse_Sensitivity))
		pivot.rotate_x(deg_to_rad(-(event as InputEventMouseMotion).relative.y * Mouse_Sensitivity))
		pivot.rotation.x = deg_to_rad(clamp(rad_to_deg(pivot.rotation.x), -90, 90))

func _process(delta: float) -> void:
	if not Active:
		return
			
	handle_gravity(delta)
	HandleJump(delta)			
	var direction = get_direction()
	var currentSpeed = get_speed()
			
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * currentSpeed, Acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * currentSpeed, Acceleration * delta)
		if Geometry:
			var prev_y = Geometry.rotation.y
			Geometry.look_at(Vector3(parent.position.x, parent.position.y + Vertical_Look_At_Offset, parent.position.z) + direction)
			var target_y = Geometry.rotation.y
			Geometry.rotation.y = lerp_angle(prev_y, target_y, delta * Turn_Speed)
	else:
		velocity.x = move_toward(velocity.x, 0, Deacceleration * delta)
		velocity.z = move_toward(velocity.z, 0, Deacceleration * delta)
		
	move()

func update():
	pivot.spring_length = Spring_Length	
	
func toggle_active(state : bool):
	Active = state
	if state:		
		camera.make_current()
	else:		
		camera.clear_current()
	update()
