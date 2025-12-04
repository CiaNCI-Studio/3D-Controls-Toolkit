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
@export var Wall_Group : String = ""
@export var Wall_Jump : bool = false
@export var Wall_Jump_Diagonal : bool = false
@export var Wall_Hang : bool = false
@export var Wall_Slide : bool = false
@export var Wall_Slide_Gravity : float = 100
@export var Wall_Top_Raycast : RayCast3D  
@export var Wall_Middle_Raycast : RayCast3D  

@export_category("Geometry")
@export var Geometry : Node3D

var Sprinting = false
var Jumping = false
var Dashing : bool = false
var WallHangJumping : bool = false
var WallHanging : bool = false
var WallSliding : bool = false
var LastFacing : Vector3 = Vector3.ZERO

var _velocity : Vector3 = Vector3.ZERO
var _coyoteTimer : float = 0
var _jumpBufferTimer : float = 0
var _lastDirection : Vector3
var _dashTimer : float = 0
var _dashCooldownTimer : float = 0
var _dashHangTimer : float = 0
var _doubleJumpExecuted : bool = false
var _sprintTimer : float = 0
var _sprintRecoverTimer : float = 0
var _sprintCharge : int = 100
var _dashCharge : int = 100
var _retriggerSprint : bool = true


@onready var _jumpVelocity = (2.0 * Jump_Height) / Jump_Time_To_Peak
@onready var _jumpGravity = (-2.0 * Jump_Height) / (Jump_Time_To_Peak * Jump_Time_To_Peak)
@onready var _fallGravity = (-2.0 * Jump_Height) / (Jump_Time_To_Descend * Jump_Time_To_Descend)
@onready var _parent = get_parent() as CharacterBody3D

func GetGravity() -> Vector3:
	if Can_Jump:
		return Vector3(0,  _jumpGravity if _velocity.y > 0.0 else _fallGravity, 0)
	else:
		return _parent.get_gravity()

func HandleGravity(delta : float):
	if Handle_Gravity and not _parent.is_on_floor():
		_velocity += GetGravity() * delta
	else:
		_velocity.y = 0
	if Wall_Slide and WallSliding and not Jumping:
		_velocity = Vector3(0,Wall_Slide_Gravity * -1,0) * delta
	if Wall_Hang and WallHanging and not Jumping:
		_velocity.y = 0
	if Dashing or _dashHangTimer > 0:
		_velocity.y = 0
	
func HandleJump(delta : float) -> void:
	
	if not Can_Jump or not Active:
		return
		
	var jumpPreRequisites = _parent.is_on_floor() or (WallHanging and Wall_Jump) or (WallSliding and Wall_Jump)
		
	if jumpPreRequisites:
		_coyoteTimer = Coyote_Time;
		if Jumping:
			jump_end.emit()
		Jumping = false
	elif _coyoteTimer > 0: 
		_coyoteTimer -= delta
	else:
		_coyoteTimer = 0 
		
	if _parent.is_on_floor() or ((WallHanging and Wall_Jump) or (WallSliding and Wall_Jump)):
		_doubleJumpExecuted = false
		
	if _jumpBufferTimer > 0: 
		_jumpBufferTimer -= delta
	else:
		_jumpBufferTimer = 0 
	
	var doJump = false
		
	if Input.is_action_just_pressed(Input_Jump) and _coyoteTimer > 0 and not Jumping:
		doJump = true
	elif Input.is_action_just_pressed(Input_Jump) and Double_Jump and not _doubleJumpExecuted and not _parent.is_on_floor():
		_doubleJumpExecuted = true
		doJump = true
	elif Input.is_action_just_pressed(Input_Jump) and not jumpPreRequisites and Jump_Buffer_Time > 0:
		_jumpBufferTimer = Jump_Buffer_Time
	elif Input.is_action_just_pressed(Input_Jump) and jumpPreRequisites and Jump_Buffer_Time <= 0:
		doJump = true
		
	if jumpPreRequisites and _jumpBufferTimer > 0 and not Jumping:
		_jumpBufferTimer = 0 
		doJump = true
		
	if doJump:
		if WallSliding and Wall_Jump_Diagonal:
			_velocity = GetWallNormal() * _jumpVelocity
		if WallHanging:
			WallHanging = false
			wall_hang_end.emit()
			jump_hang_start.emit()
		elif WallSliding:
			WallSliding = false
			wall_slide_end.emit()
			jump_wall_start.emit()
		elif _doubleJumpExecuted:
			double_jump_start.emit()
		else:
			jump_start.emit()
		_velocity.y = _jumpVelocity
		Jumping = true
		
	if (_parent.is_on_ceiling() and _velocity.y > 0) :
		hit_ceiling.emit()
		_velocity.y = 0
		return
	if (Input.is_action_just_released(Input_Jump) and Variable_Jump and Jumping):
		jump_cancel.emit()
		_velocity.y = 0
		return

func HandleWallHang():
	if not Wall_Hang or not Wall_Top_Raycast:
		WallHanging = false
		return
	if IsOnWall() and not Wall_Top_Raycast.is_colliding() and not _parent.is_on_floor() and not Jumping:
		var direction = GetDirection()
		if not WallHanging:
			wall_hang_start.emit()
		WallHanging =  direction.length() > 0
	else:
		if WallHanging:
			wall_hang_end.emit()
		WallHanging = false

func HandleDash(delta : float):
	
	var newDashCharge : int = _dashCharge
	
	if not Can_Dash or not Input_Dash: 
		Dashing = false
		_dashHangTimer = 0
		return
		
	if _dashHangTimer > 0:
		_dashHangTimer -= delta
		
	if _dashCooldownTimer > 0.0:
		_dashCooldownTimer -= delta
		newDashCharge = int(remap(_dashCooldownTimer, Dash_Cooldown, 0, 0, 100))
		if _dashCooldownTimer <= 0.1:
			newDashCharge = 100

	if newDashCharge != _dashCharge:
		_dashCharge = newDashCharge
		dash_charge.emit(_dashCharge)
		
	if _dashHangTimer > 0:
		_dashHangTimer -= delta
		
	if _dashTimer >= 0:
		_dashTimer -= delta
		if (_dashTimer <= 0 and Dashing) or (IsOnWall() and Dashing): 
			Dashing = false
			_velocity = Vector3.ZERO
			_dashHangTimer = Dash_Hang_Time
			dash_end.emit()
			_dashCooldownTimer = Dash_Cooldown
		if Dashing:
			_velocity = LastFacing * Dash_Speed
		return
	
	var dashPreRequisites = (_parent.is_on_floor() or Air_Dash) and _dashCooldownTimer <= 0.1 and not Dashing and _dashCharge == 100
	
	if dashPreRequisites and Input.is_action_just_pressed(Input_Dash):
		Dashing = true
		dash_start.emit()
		_dashCharge = 0
		_dashTimer = Dash_Time
		
func HandleWallSlide():
	if not Wall_Slide or _velocity.y > 0 or WallHanging:
		WallSliding = false
		return
	if IsOnWall() and not _parent.is_on_floor():
		var direction = GetDirection()
		if not WallSliding:
			wall_slide_start.emit()
		WallSliding =  direction.length() > 0
	else:
		if WallSliding:
			wall_slide_end.emit()
		WallSliding = false

func GetDirection(reference : Node3D = _parent) -> Vector3:
	if (not Jumping or Air_Control):
		var input_dir = Input.get_vector(Input_Left, Input_Right, Input_Up, Input_Down)
		_lastDirection = (reference.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()		
	return _lastDirection

func GetSpeed(delta : float) -> float:
	var currentSpeed = Speed_Walk
	if _CheckSprint(delta):
		currentSpeed = Speed_Sprint
	return currentSpeed
			
func move():
	if Active:
		if WallSliding or WallHanging:
				_velocity.x = 0
				_velocity.z = 0
		if Movement_Type == movement_types.MoveAndSlide:
			_parent.velocity = _velocity
			_parent.move_and_slide()
		elif Movement_Type == movement_types.MoveAndCollide:
			_parent.move_and_collide(_velocity)
			
func IsOnWall() -> bool:
	if Wall_Middle_Raycast:
		return Wall_Middle_Raycast.is_colliding() and not _parent.is_on_floor()
	else:
		return _parent.is_on_wall_only()
		
func GetWallNormal() -> Vector3:
	if Wall_Middle_Raycast:
		return Wall_Middle_Raycast.get_collision_normal()
	else:
		return _parent.get_wall_normal()
		
func _CheckSprint(delta : float) -> bool:
	
	var result = false
	var cancelSprint = false
	var newSprintCharge : int = _sprintCharge
	
	if not Can_Sprint:
		return result
		
	if Input_Sprint != "" and Input.is_action_just_released(Input_Sprint):
		_retriggerSprint = true
	
	if _sprintRecoverTimer > 0:
		_sprintRecoverTimer -= delta
		newSprintCharge = int(remap(_sprintRecoverTimer, 0, Sprint_Recover_Time, 100, 0))
		if _sprintRecoverTimer <= 0.1:
			newSprintCharge = 100
			
	if _sprintTimer > 0.0:
		_sprintTimer -= delta
		newSprintCharge = int(remap(_sprintTimer, 0, Sprint_Time, 0, 100))
		if _sprintTimer <= 0.1:
			_sprintRecoverTimer = Sprint_Recover_Time * ((100 - _sprintCharge)/100)
			newSprintCharge = 0
			_retriggerSprint = false
			
	if newSprintCharge != _sprintCharge:
		_sprintCharge = newSprintCharge
		sprint_charge.emit(_sprintCharge)
		
	if Input_Sprint != "" and Input.is_action_pressed(Input_Sprint) and _sprintCharge > 0 and _retriggerSprint: 
		if not Sprinting:
			_sprintRecoverTimer = 0
			_sprintTimer = Sprint_Time * (float(_sprintCharge)/100.0)
			sprint_start.emit()
			Sprinting = true
		result = true
	else:
		if Sprinting:
			_sprintTimer = 0
			_sprintRecoverTimer = Sprint_Recover_Time * ((100.0 - float(_sprintCharge)) / 100.0)
			sprint_end.emit()
			Sprinting = false
		result = false
		
	return result
