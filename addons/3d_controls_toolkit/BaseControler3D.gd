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

@export var Active : bool = true
@export_category("Inputs")
@export var Input_Up = "up"
@export var Input_Down = "down"
@export var Input_Left = "left"
@export var Input_Right = "right"
@export var Input_Sprint = "sprint"
@export var Input_Jump = "jump"
@export var Input_Cancel = "ui_cancel"
@export_category("Movement")
@export var Speed_Walk = 10.0
@export var Speed_Sprint = 20.0
@export var Acceleration = 40
@export var Deacceleration = 60
@export var Movement_Type : movement_types = movement_types.MoveAndSlide
@export var Handle_Gravity : bool = true
@export var Handle_Mouse_Capture : bool = true
@export_category("Jump")
@export var Can_Jump : bool = true
@export var Jump_Height = 2.0
@export var Jump_Time_To_Peak = 0.4
@export var Jump_Time_To_Descend = 0.2
@export var Coyote_Time = 0.2
@export var Jump_Buffer_Time = 0.2
@export var Air_Control : bool = true
@export var Variable_Jump : bool = true

@export_category("Geometry")
@export var Geometry : Node3D

var sprinting = false
var jumping = false
var velocity : Vector3 = Vector3.ZERO
var coyote_timer : float = 0
var jump_buffer_timer : float = 0
var last_direction : Vector3

@onready var jump_velocity = (2.0 * Jump_Height) / Jump_Time_To_Peak
@onready var jump_gravity = (-2.0 * Jump_Height) / (Jump_Time_To_Peak * Jump_Time_To_Peak)
@onready var fall_gravity = (-2.0 * Jump_Height) / (Jump_Time_To_Descend * Jump_Time_To_Descend)
@onready var parent = get_parent() as CharacterBody3D

func get_gravity() -> Vector3:
	if Can_Jump:
		if not jumping:
			return parent.get_gravity()
		else:
			return Vector3(0,  jump_gravity if velocity.y > 0.0 else fall_gravity, 0)
	else:
		return parent.get_gravity()

func handle_gravity(delta : float):
	if Handle_Gravity:
		velocity += get_gravity() * delta
	
func HandleJump(delta : float) -> void:
	
	if not Can_Jump or not Active:
		return
		
	if parent.is_on_floor():
		coyote_timer = Coyote_Time;
		jumping = false
	elif coyote_timer > 0: 
		coyote_timer -= delta
	else:
		coyote_timer = 0 
		
	if jump_buffer_timer > 0: 
		jump_buffer_timer -= delta
	else:
		jump_buffer_timer = 0 
	
	var do_jump = false
		
	if Input.is_action_just_pressed(Input_Jump) and coyote_timer > 0 and not jumping:
		do_jump = true
	elif Input.is_action_just_pressed(Input_Jump) and not parent.is_on_floor() and Jump_Buffer_Time > 0:
		jump_buffer_timer = Jump_Buffer_Time
	elif Input.is_action_just_pressed(Input_Jump) and parent.is_on_floor() and Jump_Buffer_Time <= 0:
		do_jump = true
		
	if parent.is_on_floor() and jump_buffer_timer > 0 and not jumping:
		jump_buffer_timer = 0 
		do_jump = true			
	
	if do_jump:
		jumping = true
		velocity.y = jump_velocity
		
	if (Input.is_action_just_released(Input_Jump) and Variable_Jump and jumping) or (parent.is_on_ceiling() and velocity.y > 0) :
		velocity.y = 0
		
func get_direction(refernce : Node3D = parent) -> Vector3:
	if (not jumping or Air_Control):
		var input_dir = Input.get_vector(Input_Left, Input_Right, Input_Up, Input_Down)
		last_direction = (refernce.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()		
	return last_direction

func get_speed() -> float:
	var currentSpeed = Speed_Walk
	if Input_Sprint != "" and Input.is_action_pressed(Input_Sprint):
		currentSpeed = Speed_Sprint
	return currentSpeed
			
func move():
	if Active:
		if Movement_Type == movement_types.MoveAndSlide:
			parent.velocity = velocity
			parent.move_and_slide()
		elif Movement_Type == movement_types.MoveAndCollide:
			parent.move_and_collide(velocity)


























# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
