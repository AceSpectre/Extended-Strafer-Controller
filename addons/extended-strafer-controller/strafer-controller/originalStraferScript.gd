# Strafing mechanics for Godot 4.0
# Copyright (c) 2022 ic3bug
# MIT License
#class_name Player
extends CharacterBody3D

# Input
const MOUSE_SENS : float = 3.0

# Movement
const GRAVITY : float = 32.0
const MAX_SPEED : float = 20.0
const MAX_ACCEL : float = 150.0
const JUMP_FORCE : float = 12.0
const FRICTION : float = 0.86
# Increase air drag by tiny amounts 
# To make strafing faster
const AIR_DRAG : float = 0.98
# Amount of directional control
const CONTROL : float = 15.0
var hvel : Vector3
var dir : Vector3
var height : float
var crouch : float

# Stepping and camera bobbing
const STEP_SPEED : float = 25.0
const BOB_AMT : float = 0.33
var step : Vector2i = Vector2i(0,0)
var bob_enabled : bool = true
var bob_time : float = 0.0
var bob_current : Vector2

# State machine
var past_state : String = "air"
var current_state : String = "air"

func _ready():
	#Game.player = self
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta : float) -> void:
	process_sm(delta)

func process_bounds() -> void:
	if global_transform.origin.y <= -100.0:
		global_transform.origin = Vector3.ONE

# State machine
func process_sm(delta : float) -> void:
	# Show the state on screen
	$HUD/Log.text = current_state
	# Call current state method
	call(current_state, delta)
	# Check for transitions
	if current_state != past_state:
		match current_state:
			"ground":
				$AnimationPlayer.play("land")
	# Update the previous state
	past_state = current_state

# Air state
func air(delta):
	# Gravity
	velocity.y -= GRAVITY * delta
	# Velocity
	process_vel(delta, AIR_DRAG)
	# Crouching
	process_crouch(delta)
	# Wind rush
	process_rush()
	# Bounds
	process_bounds()
	
	# Check state exit
	if is_on_floor():
		current_state = "ground"

# Ground state
func ground(delta):
	# Jumping
	if Input.is_action_pressed("move_jump"):
		velocity.y = JUMP_FORCE
		$AnimationPlayer.play("jump")
		$Sounds/Huh.play()
	# Velocity
	process_vel(delta, FRICTION)
	# Crouching
	process_crouch(delta)
	# Footsteps
	process_steps(delta)
	# Wind rush
	process_rush()
	
	# Check state exit
	if !is_on_floor():
		current_state = "air"
	
# Process velocity
func process_vel(delta : float, decel : float) -> void:
	# Read input
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	# Amount of control
	dir = lerp(dir, (transform.basis * Vector3(input.x, 0, input.y)).normalized(), delta * CONTROL)
	# Air drag
	hvel = velocity
	hvel.y = 0.0
	hvel *= decel
	# Zero out horizontal velocity if speed is too small
	if hvel.length() < MAX_SPEED * 0.01:
		hvel = Vector3.ZERO
	# Acceleration
	# Here lies the strafing mechanic (bug)
	# Projection of the horizontal velocity to the direction
	var speed = hvel.dot(dir)
	# Whenever the amount of acceleration to add is clamped by the maximum acceleration constant
	# Player can make the speed faster by bringing the direction closer to horizontal velocity angle
	# More info here: https://youtu.be/v3zT3Z5apaM?t=165
	var max_speed = MAX_SPEED if crouch < 0.1 else MAX_SPEED * 0.25
	var accel : float = clamp(max_speed - speed, 0.0, MAX_ACCEL * delta)
	hvel += dir * accel
	
	# Apply horizontal velocity to final velocity
	velocity.x = hvel.x
	velocity.z = hvel.z
	
	# Apply velocity
	move_and_slide()

# Crouch walking
func process_crouch(delta : float) -> void:
	crouch = float(Input.is_action_pressed("move_crouch")) * 0.5
	if (height < 1.0 and $Ceiling.is_colliding()):
		crouch = 0.5
	height = lerp(height, clamp(1.0 - crouch, 0.5, 1.0), delta * 10.0)
	# Height
	$Ground.shape.length = height + 0.5
	$Collision.shape.height = height
	$Head.global_transform.origin = global_transform.origin + Vector3.UP * height * 0.5
	$Ceiling.global_transform.origin = $Head.global_transform.origin

func process_steps(delta : float) -> void:
	var speed_clamped = remap(hvel.length(), 0.0, MAX_SPEED, 0.0, 1.0)
	bob_time += delta * STEP_SPEED * speed_clamped
	var bob_target = Vector2(sin(bob_time) * BOB_AMT, cos(bob_time * 0.5) * BOB_AMT)
	
	# Step sounds
	if bob_target.y > 0.15 and step.x == 0:
		step = Vector2i(1, 0)
		$AnimationPlayer.play("step")
	if bob_target.y < -0.15 and step.y == 0:
		step = Vector2i(0, 1)
		$AnimationPlayer.play("step")
	
	# Reset the bobbing if speed is too small
	if speed_clamped <= 0.1:
		bob_time = 0.0
		bob_target = Vector2.ZERO
	
	# Calculate head bobbing
	if bob_enabled:
		bob_current = lerp(bob_current, bob_target, delta * 5.0)
		bob_current = lerp(bob_current, bob_target, delta * 5.0)
		$Head/Camera.transform.origin.x = bob_current.y
		$Head/Camera.transform.origin.y = bob_current.x
	
# Apply velocity
func push(force : float, direction : Vector3):
	velocity = direction * force

# Wind rush
func process_rush() -> void:
	var speed_clamped = remap(pow(velocity.length(), 2), 0.0, MAX_SPEED * 250.0, 0.0, 1.0)
	$Sounds/Rush.volume_db = linear_to_db(speed_clamped)

# Mouse input processing
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		# Head rotation
		$Head.rotation.x -= event.relative.y * MOUSE_SENS * 0.001
		$Head.rotation.x = clamp($Head.rotation.x, -1.5, 1.5)
		# Body rotation
		rotation.y -= event.relative.x * MOUSE_SENS * 0.001
		rotation.y = wrapf(rotation.y, 0.0, TAU)
