extends BaseControler3D
class_name SideScrollingControler3D

@export_category("Movement")
@export var Turn_Speed = 10

@export_category("Camera")
@export var Handle_Camera : bool = true
@export var Camera_Smooth_Distance : float = 1
@export var Camera_Smooth_Speed : float = 5
@export var Camera_LookAt_Player: bool = true
@export var Camera_Lock_Y_Rotation: bool = true
@export var Camera_Max_Boundary: Vector2 = Vector2.ZERO
@export var Camera_Min_Boundary: Vector2 = Vector2.ZERO
@export var Spring_Length : float = 8
@export var Angle : float = -20
@export var Horizontal_Offset : float = 0
@export var Vertical_Offset : float = 0
@export var Custom_Camera : Camera3D

var pivot : Node3D 
var camera : Camera3D 
var camera_rest_position : Vector3
var use_pivot = true

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
				
	toggle_active(Active)

func _process(delta: float) -> void:
	if not Active:
		return
		
	handle_gravity(delta)
	HandleJump(delta)			
	var direction = get_direction()
	var currentSpeed = get_speed()
			
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * currentSpeed, Acceleration * delta)
		if Geometry:
			var prev_y = Geometry.rotation.y
			Geometry.look_at(Vector3(parent.position.x, parent.position.y, parent.position.z) + direction)
			var target_y = Geometry.rotation.y
			Geometry.rotation.y = lerp_angle(prev_y, target_y, delta * Turn_Speed)
		if Handle_Camera:
			if use_pivot:		
				if Camera_Smooth_Distance and abs(pivot.position.x) < Camera_Smooth_Distance:	
					pivot.position.x = move_toward(pivot.position.x, direction.x * currentSpeed * -1, Camera_Smooth_Speed * delta)
			else:
				if Camera_Smooth_Distance and abs(camera.position.x) < Camera_Smooth_Distance:	
					camera.position.x = move_toward(camera.position.x, direction.x * currentSpeed * -1, Camera_Smooth_Speed * delta)
	else:		
		velocity.x = move_toward(velocity.x, 0, Deacceleration * delta)		
		if Camera_Smooth_Distance and Handle_Camera:		
			if use_pivot:		
				pivot.position.x = move_toward(pivot.position.x, Horizontal_Offset, Camera_Smooth_Speed * delta)
			else:
				camera.position.x = move_toward(camera.position.x, Horizontal_Offset, Camera_Smooth_Speed * delta)
					
	if Handle_Camera:
		if Camera_LookAt_Player:
			camera.look_at(parent.global_position)
			if Camera_Lock_Y_Rotation:
				camera.rotation.y = 0
			camera.rotation.z = 0
		if Camera_Max_Boundary and Camera_Min_Boundary:
			if use_pivot:	
				if pivot.global_position.x > Camera_Max_Boundary.x and Camera_Max_Boundary.x != 0:
					pivot.global_position.x = Camera_Max_Boundary.x
				elif pivot.global_position.x < Camera_Min_Boundary.x and Camera_Min_Boundary.x != 0:
					pivot.global_position.x = Camera_Min_Boundary.x
				if pivot.global_position.y > Camera_Max_Boundary.y and Camera_Max_Boundary.y != 0:
					pivot.global_position.y = Camera_Max_Boundary.y
				elif pivot.global_position.y < Camera_Min_Boundary.y and Camera_Min_Boundary.y != 0:
					pivot.global_position.y = Camera_Min_Boundary.y										
			else:
				if camera.global_position.x > Camera_Max_Boundary.x and Camera_Max_Boundary.x != 0:
					camera.global_position.x = Camera_Max_Boundary.x
				elif camera.global_position.x < Camera_Min_Boundary.x and Camera_Min_Boundary.x != 0:
					camera.global_position.x = Camera_Min_Boundary.x
				if camera.global_position.y > Camera_Max_Boundary.y and Camera_Max_Boundary.y != 0:
					camera.global_position.y = Camera_Max_Boundary.y
				elif camera.global_position.y < Camera_Min_Boundary.y and Camera_Min_Boundary.y != 0:
					camera.global_position.y = Camera_Min_Boundary.y				
	
	move()

	
func toggle_active(state : bool):
	Active = state
	if Handle_Camera:
		if state:		
			camera.make_current()
		else:		
			camera.clear_current()
