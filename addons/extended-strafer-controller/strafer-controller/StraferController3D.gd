# Extended Modular Strafing Controller for Godot 4.2
# Original project: Strafing mechanics for Godot 4.0 https://github.com/Kabariya/strafer/tree/main
# Copyright (c) 2024 AceSpectre
# Copyright (c) 2022 ic3bug
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
extends BaseController3D
class_name StraferController3D

# Stepping and camera bobbing
## Head bobbing step speed
const STEP_SPEED : float = 20.0

## Head bobbing amount
const BOB_AMT : float = 0.2

## Is head bobbing enabled
@export var bob_enabled : bool = true

## Current x position on the sin wave for headbobbing, reset when movement stops
var bob_time : float = 0.0

## Current (x,y) headbob position as a [Vector2]
var bob_current : Vector2

## Is currently crouching
var crouching : bool = false

## The current desired direction of the player (equivalent of wishDir from Quake)
var dir : Vector3 :
	get:
		return dir
	set(value):
		dir = value

#New variables unique to StraferController3D
## Default states used when no states are provided
var _STRAFER_DEFAULT_STATES : Array[BaseMovementState] = [StraferAirState.new(), StraferGroundState.new(), StraferSlideState.new()]

## Player's curent x,z orientation as a [Node3D]
@onready var orientation : Node3D = $Orientation

## Collision of the controller
@onready var collision : CollisionShape3D = $Collision

## Node that rotates the camera
@onready var head : Node3D = $Head

## [ShapeCast3D] checks if there is space to uncrouch
@onready var ceiling : ShapeCast3D = $Ceiling

## SeparationRayCast to soften landings 
@onready var ground : CollisionShape3D = $Ground

## Height of the collision shape
@onready var height : float = collision.shape.height

## Player's camera
@onready var camera : Camera3D = $Head/CameraRecoil/Camera


func _ready() -> void:
	# Call parent class ready function
	super()
	
	# If no starting states provided, set states to default states
	if _START_STATES == []:
		states = _STRAFER_DEFAULT_STATES
	
	# Set starting state to state at provided starting state index
	current_state = states[starting_state_index]
	past_state = current_state
	
	# Remove this line as necessary, should be handled by GameManager not player
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta : float) -> void:
	# Get vector for current keyboard WASD input
	inputAxis = Input.get_vector("left", "right", "forward", "backward")
	# Handle the state machine
	process_sm(delta)


## If falling into the void, set position to [constant Vector3.ONE]
func process_bounds() -> void:
	if global_transform.origin.y <= -100.0:
		global_transform.origin = Vector3.ONE


## Process velocity
func process_vel(delta : float, decel : float) -> void:
	# Amount of control
	dir = lerp(dir, (orientation.transform.basis * Vector3(inputAxis.x, 0, inputAxis.y)).normalized(), delta * settings.CONTROL)
	# Air drag
	hvel = velocity
	hvel.y = 0.0
	hvel *= decel
	# Zero out horizontal velocity if speed is too small
	if hvel.length() < settings.MAX_SPEED * 0.01:
		hvel = Vector3.ZERO
	# Acceleration
	# Here lies the strafing mechanic (bug)
	# Projection of the horizontal velocity to the direction
	var speed := hvel.dot(dir)
	# Whenever the amount of acceleration to add is clamped by the maximum acceleration constant
	# Player can make the speed faster by bringing the direction closer to horizontal velocity angle
	# More info here: https://youtu.be/v3zT3Z5apaM?t=165
	var max_speed := settings.MAX_SPEED if !(crouching and is_on_floor()) else settings.MAX_CROUCH_SPEED
	var accel : float = clamp(max_speed - speed, 0.0, settings.MAX_ACCEL * delta)
	hvel += dir * accel
	
	# Pass over changing current velocity to current state
	current_state.process_vel(delta, self)
	
	# Apply velocity
	move_and_slide()


## Crouch walking
func process_crouch(delta : float, force_crouch : bool = false) -> void:
	var target_height : float
	# Determine if currently crouching
	crouching = Input.is_action_pressed("crouch") or (height < 1.9 and ceiling.is_colliding()) or force_crouch
	
	# Set target height based on crouching
	target_height = 1.0 if crouching else 2.0 
	
	# Lerp height accordingly
	height = lerp(height, clamp(target_height, 1.0, 2.0), delta * 20.0)
	collision.shape.height = height
	collision.position.y = lerp(collision.position.y, clamp(target_height/2, 0.5, 1), delta * 20.0)
	head.position.y = lerp(head.position.y, height - 0.2, delta * 15.0)


## Process headbobbbing
func process_steps(delta : float) -> void:
	# Get speed factor to move the x position along the sin/cos waves
	var speed_clamped := remap(velocity.length(), 0.0, settings.MAX_SPEED, 0.0, 1.0)
	# Move bob_time and get bob target
	bob_time += delta * STEP_SPEED * speed_clamped
	var bob_target := Vector2(sin(bob_time) * BOB_AMT, cos(bob_time * 0.5) * BOB_AMT)
	
	# Step sounds
	#if bob_target.y > 0.15 and step.x == 0:
		#step = Vector2i(1, 0)
	#if bob_target.y < -0.15 and step.y == 0:
		#step = Vector2i(0, 1)
	
	# Reset the bobbing if speed is too small
	if speed_clamped <= 0.1:
		bob_time = 0.0
		bob_target = Vector2.ZERO
	
	# Half bobbing if crouching
	if crouching:
		bob_target = bob_target / 2.0
	
	# Pass off final target calculation to current state
	bob_target = current_state.process_steps(delta, self, bob_target)
	
	# Calculate head bobbing
	if bob_enabled:
		bob_current = lerp(bob_current, bob_target, delta * 5.0)
		bob_current = lerp(bob_current, bob_target, delta * 5.0)
		camera.transform.origin.y = bob_current.x


## Push controller in a direction with a force
func push(force : float, direction : Vector3) -> void:
	velocity = velocity + (direction * force)
	if get_state(StraferAirState.new()) != null:
		get_state(StraferAirState.new()).jump_dir = velocity


## Mouse input processing
func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Head rotation
		$Head.rotation.x -= event.relative.y * settings.MOUSE_SENS * 0.001
		$Head.rotation.x = clamp($Head.rotation.x, -1.5, 1.5)
		# Body rotation
		$Head.rotation.y -= event.relative.x * settings.MOUSE_SENS * 0.001
		orientation.rotation.y -= event.relative.x * settings.MOUSE_SENS * 0.001
		#rotation.y = wrapf(rotation.y, 0.0, TAU)
