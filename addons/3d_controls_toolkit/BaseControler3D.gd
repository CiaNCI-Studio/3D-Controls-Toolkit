extends Node3D
class_name BaseControler3D

#Types
enum movement_types {
	MoveAndSlide,
	MoveAndCollide,
	None
}

#Signals
signal sprint_start
signal sprint_end
signal jump_start
signal jump_wall_start
signal jump_hang_start
signal jump_cancel
signal jump_end
signal double_jump_start
signal hit_ceiling
signal wall_slide_start
signal wall_slide_end
signal wall_hang_start
signal wall_hang_end
signal dash_start
signal dash_end
signal sprint_charge(value : int)
signal dash_charge(value : int)

@export var Active : bool = true

@export_category("Inputs")
@export var Input_Up = "up"
@export var Input_Down = "down"
@export var Input_Left = "left"
@export var Input_Right = "right"
@export var Input_Sprint = "sprint"
@export var Input_Jump = "jump"
@export var Input_Dash = "dash"
@export var Input_Cancel = "ui_cancel"

@export_category("Movement")
@export var Speed_Walk = 10.0
@export var Acceleration = 40
@export var Deacceleration = 60
@export var Movement_Type : movement_types = movement_types.MoveAndSlide
@export var Handle_Gravity : bool = true
@export var Handle_Mouse_Capture : bool = true

@export_category("Sprint")
@export var Can_Sprint : bool = true
@export var Speed_Sprint = 20.0
@export var Sprint_Time = 3
@export var Sprint_Recover_Time = 6


@export_category("Dash")
@export var Can_Dash : bool = false
@export var Air_Dash : bool = false
@export var Dash_Time : float = 0.05
@export var Dash_Hang_Time : float = 0.3
@export var Dash_Cooldown : float = 3
@export var Dash_Speed : float = 300
@export var Dash_Gravity : float = 0

@export_category("Jump")
@export var Can_Jump : bool = true
@export var Jump_Height = 2.0
@export var Jump_Time_To_Peak = 0.4
@export var Jump_Time_To_Descend = 0.2
@export var Coyote_Time = 0.2
@export var Jump_Buffer_Time = 0.2
@export var Air_Control : bool = true
@export var Variable_Jump : bool = true
@export var Double_Jump : bool = false

@export_category("Wall")
@export var Wall_Jump : bool = false
@export var Wall_Jump_Diagonal : bool = false
@export var Wall_Hang : bool = false
@export var Wall_Slide : bool = false
@export var Wall_Slide_Gravity : float = 100
@export var Wall_Top_Raycast : RayCast3D  
@export var Wall_Middle_Raycast : RayCast3D  

@export_category("Geometry")
@export var Geometry : Node3D

var sprinting = false
var jumping = false
var velocity : Vector3 = Vector3.ZERO
var coyote_timer : float = 0
var jump_buffer_timer : float = 0
var last_direction : Vector3
var wall_sliding : bool = false
var wall_hanging : bool = false
var wall_hang_jumping : bool = false
var dashing : bool = false
var dashTimer : float = 0
var dashCooldownTimer : float = 0
var last_facing : Vector3 = Vector3.ZERO
var dashHangTimer : float = 0
var doubleJumpExecuted : bool = false
var sprintTimer : float = 0
var sprintRecoverTimer : float = 0
var sprintCharge : int = 100
var dashCharge : int = 100
var retriggerSprint : bool = true


@onready var jump_velocity = (2.0 * Jump_Height) / Jump_Time_To_Peak
@onready var jump_gravity = (-2.0 * Jump_Height) / (Jump_Time_To_Peak * Jump_Time_To_Peak)
@onready var fall_gravity = (-2.0 * Jump_Height) / (Jump_Time_To_Descend * Jump_Time_To_Descend)
@onready var parent = get_parent() as CharacterBody3D

func get_gravity() -> Vector3:
	if Can_Jump:
		return Vector3(0,  jump_gravity if velocity.y > 0.0 else fall_gravity, 0)
	else:
		return parent.get_gravity()

func handle_gravity(delta : float):
	if Handle_Gravity and not parent.is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0
	if Wall_Slide and wall_sliding and not jumping:
		velocity = Vector3(0,Wall_Slide_Gravity * -1,0) * delta
	if Wall_Hang and wall_hanging and not jumping:
		velocity.y = 0
	if dashing or dashHangTimer > 0:
		velocity.y = 0
	
func HandleJump(delta : float) -> void:
	
	if not Can_Jump or not Active:
		return
		
	var jumpPreRequisites = parent.is_on_floor() or (wall_hanging and Wall_Jump) or (wall_sliding and Wall_Jump)
		
	if jumpPreRequisites:
		coyote_timer = Coyote_Time;
		if jumping:
			jump_end.emit()
		jumping = false
	elif coyote_timer > 0: 
		coyote_timer -= delta
	else:
		coyote_timer = 0 
		
	if parent.is_on_floor() or ((wall_hanging and Wall_Jump) or (wall_sliding and Wall_Jump)):
		doubleJumpExecuted = false
		
	if jump_buffer_timer > 0: 
		jump_buffer_timer -= delta
	else:
		jump_buffer_timer = 0 
	
	var do_jump = false
		
	if Input.is_action_just_pressed(Input_Jump) and coyote_timer > 0 and not jumping:
		do_jump = true
	elif Input.is_action_just_pressed(Input_Jump) and Double_Jump and not doubleJumpExecuted and not parent.is_on_floor():
		doubleJumpExecuted = true
		do_jump = true
	elif Input.is_action_just_pressed(Input_Jump) and not jumpPreRequisites and Jump_Buffer_Time > 0:
		jump_buffer_timer = Jump_Buffer_Time
	elif Input.is_action_just_pressed(Input_Jump) and jumpPreRequisites and Jump_Buffer_Time <= 0:
		do_jump = true
		
	if jumpPreRequisites and jump_buffer_timer > 0 and not jumping:
		jump_buffer_timer = 0 
		do_jump = true
		
	if do_jump:
		if wall_hanging:
			jump_hang_start.emit()
		elif wall_sliding:
			jump_wall_start.emit()
		elif doubleJumpExecuted:
			double_jump_start.emit()
		else:
			jump_start.emit()
		if wall_sliding and Wall_Jump_Diagonal:
			velocity = GetWallNormal() * jump_velocity
		velocity.y = jump_velocity
		jumping = true
		
	if (parent.is_on_ceiling() and velocity.y > 0) :
		hit_ceiling.emit()
		velocity.y = 0
		return
	if (Input.is_action_just_released(Input_Jump) and Variable_Jump and jumping):
		jump_cancel.emit()
		velocity.y = 0
		return

func HandleWallHang():
	if not Wall_Hang or not Wall_Top_Raycast:
		wall_hanging = false
		return
	if IsOnWall() and not Wall_Top_Raycast.is_colliding() and not parent.is_on_floor() and not jumping:
		var direction = get_direction()
		if not wall_hanging:
			wall_hang_start.emit()
		wall_hanging =  direction.length() > 0
	else:
		if wall_hanging:
			wall_hang_end.emit()
		wall_hanging = false

func HandleDash(delta : float):
	
	var newDashCharge : int = dashCharge
	
	if not Can_Dash or not Input_Dash: 
		dashing = false
		dashHangTimer = 0
		return
		
	if dashHangTimer > 0:
		dashHangTimer -= delta
		
	if dashCooldownTimer > 0.0:
		dashCooldownTimer -= delta
		newDashCharge = int(remap(dashCooldownTimer, Dash_Cooldown, 0, 0, 100))
		if dashCooldownTimer <= 0.1:
			newDashCharge = 100

	if newDashCharge != dashCharge:
		dashCharge = newDashCharge
		dash_charge.emit(dashCharge)
		
	if dashHangTimer > 0:
		dashHangTimer -= delta
		
	if dashTimer >= 0:
		dashTimer -= delta
		if (dashTimer <= 0 and dashing) or (IsOnWall() and dashing): 
			dashing = false
			velocity = Vector3.ZERO
			dashHangTimer = Dash_Hang_Time
			dash_end.emit()
			dashCooldownTimer = Dash_Cooldown
		if dashing:
			velocity = last_facing * Dash_Speed
		return
	
	var dashPreRequisites = (parent.is_on_floor() or Air_Dash) and dashCooldownTimer <= 0.1 and not dashing and dashCharge == 100
	
	if dashPreRequisites and Input.is_action_just_pressed(Input_Dash):
		dashing = true
		dash_start.emit()
		dashCharge = 0
		dashTimer = Dash_Time
		
func HandleWallSlide():
	if not Wall_Slide or velocity.y > 0 or wall_hanging:
		wall_sliding = false
		return
	if IsOnWall() and not parent.is_on_floor():
		var direction = get_direction()
		if not wall_sliding:
			wall_slide_start.emit()
		wall_sliding =  direction.length() > 0
	else:
		if wall_sliding:
			wall_slide_end.emit()
		wall_sliding = false

func get_direction(refernce : Node3D = parent) -> Vector3:
	if (not jumping or Air_Control):
		var input_dir = Input.get_vector(Input_Left, Input_Right, Input_Up, Input_Down)
		last_direction = (refernce.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()		
	return last_direction

func get_speed(delta : float) -> float:
	var currentSpeed = Speed_Walk
	if CheckSprint(delta):
		currentSpeed = Speed_Sprint
	return currentSpeed
			
func move():
	if Active:
		if wall_sliding or wall_hanging:
				velocity.x = 0
				velocity.z = 0
		if Movement_Type == movement_types.MoveAndSlide:
			parent.velocity = velocity
			parent.move_and_slide()
		elif Movement_Type == movement_types.MoveAndCollide:
			parent.move_and_collide(velocity)
			
func IsOnWall() -> bool:
	if Wall_Middle_Raycast:
		return Wall_Middle_Raycast.is_colliding()
	else:
		return parent.is_on_wall()
		
func GetWallNormal() -> Vector3:
	if Wall_Middle_Raycast:
		return Wall_Middle_Raycast.get_collision_normal()
	else:
		return parent.get_wall_normal()
		
func CheckSprint(delta : float) -> bool:
	
	var result = false
	var cancelSprint = false
	var newSprintCharge : int = sprintCharge
	
	if not Can_Sprint:
		return result
		
	if Input_Sprint != "" and Input.is_action_just_released(Input_Sprint):
		retriggerSprint = true
	
	if sprintRecoverTimer > 0:
		sprintRecoverTimer -= delta
		newSprintCharge = int(remap(sprintRecoverTimer, 0, Sprint_Recover_Time, 100, 0))
		if sprintRecoverTimer <= 0.1:
			newSprintCharge = 100
			
	if sprintTimer > 0.0:
		sprintTimer -= delta
		newSprintCharge = int(remap(sprintTimer, 0, Sprint_Time, 0, 100))
		if sprintTimer <= 0.1:
			sprintRecoverTimer = Sprint_Recover_Time * ((100 - sprintCharge)/100)
			newSprintCharge = 0
			retriggerSprint = false
			
	if newSprintCharge != sprintCharge:
		sprintCharge = newSprintCharge
		sprint_charge.emit(sprintCharge)
		
	if Input_Sprint != "" and Input.is_action_pressed(Input_Sprint) and sprintCharge > 0 and retriggerSprint: 
		if not sprinting:
			sprintRecoverTimer = 0
			sprintTimer = Sprint_Time * (float(sprintCharge)/100.0)
			sprint_start.emit()
			sprinting = true
		result = true
	else:
		if sprinting:
			sprintTimer = 0
			sprintRecoverTimer = Sprint_Recover_Time * ((100.0 - float(sprintCharge)) / 100.0)
			sprint_end.emit()
			sprinting = false
		result = false
		
	return result
