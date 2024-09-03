extends CharacterBody3D
class_name BaseController3D
## The base 3d modular movement controller
##
## This class contains many virtual functions that are to be implemented by your own
## movement controller implementation. 
## This class also contains the states and state machine for the movement controller. 
## The settings and essential member variables are also contained within this class.
## [br]
## [i]Note: If extending this controller, and you want to add functionality available to all states
## (regardless of the implementation) then you need to add it here[/i]


## The horizontal velocity of the movement controller
var hvel : Vector3 :
	get:
		return hvel
	set(value):
		hvel = value


## The Vector2 of the movement input of the player
var inputAxis : Vector2 = Vector2.ZERO :
	get:
		return inputAxis
	set(value):
		inputAxis = value


## The initial settings of the movement controller, do not change this value. 
## This should never be accessed unless to reset [code]settings[/code]
## [br]
## [i]Note: This would be a constant but exported values cannot be constants 
## so this has to be a variable[/i]
@export var _START_SETTINGS : Controller3DSettings :
	get:
		return _START_SETTINGS


## The current settings of the movement controller
@onready var settings : Controller3DSettings = _START_SETTINGS :
	get:
		return settings
	set(value):
		settings = value


## The initial states of the movement controller, do not change this value
## This should never be accessed unless to reset [code]states[/code]
## [br]
## [i]Note: This would be a constant but exported values cannot be constants 
## so this has to be a variable[/i]
@export var _START_STATES : Array[BaseMovementState] :
	get:
		return _START_STATES


## The current states of the movement controller
@onready var states : Array[BaseMovementState] = _START_STATES


## The index of the initial state within the states array
@export var starting_state_index : int = 0 :
	get:
		return starting_state_index
	set(value):
		starting_state_index = value


## The timer used for coyote time, initialised with the time in the settings
@onready var coyoteTimer : float = _START_SETTINGS.COYOTE_TIME :
	get:
		return coyoteTimer
	set(value):
		coyoteTimer = value


## The previous state of the state machine
var past_state : BaseMovementState :
	get:
		return past_state
	set(new_state):
		past_state = new_state


## The current state of the state machine
var current_state : BaseMovementState :
	get:
		return current_state
	set(new_state):
		current_state = new_state


# Called when the node enters the scene tree for the first time
func _ready() -> void:
	# Initialise the settings snap length to the one specified in inspector
	_START_SETTINGS.SNAP_LENGTH = floor_snap_length
	settings.SNAP_LENGTH = floor_snap_length


## Changes the current state of the state machine to the state type [param new_state], returning
## the instance of that type within [code]settings[/code]. If that state type doesn't exist
## then the current state doesn't change and [code]null[/code] is returned.
func change_state(new_state : BaseMovementState) -> BaseMovementState:
	# Get the new state from the array of states
	new_state = get_state(new_state)
	if new_state != null: # If the state exists, change the current state and state and start it
		current_state = new_state
		current_state.start(self)
		return current_state
	else:
		return null


## Gets the instance of the the same type as [param new_state] from the array of states and returns
## it. If that state type doesn't exist, then [code]null[/code] is returned. 
func get_state(new_state : BaseMovementState) -> BaseMovementState:
	for i in states: # Parse through the array of states
		if i.get_script().instance_has(new_state): # If the current state is an instance of the desired type
			return i # Return the instance of the state
	return null # Otherwise, return null


## Calls [code]process_state()[/code] on the current state and updates [code]past_state[/code] to
## be the current state
func process_sm(delta : float) -> void:
	# Call current state method
	current_state.process_state(delta, self)
	# Update the previous state
	past_state = current_state


## Virtual function for handling when the controller is outside the desired bounds of the level
func process_bounds() -> void:
	pass


## Virtual function for handling the velocity and movement of the controller
func process_vel(delta : float, decel : float) -> void:
	pass


## Virtual function for handling crouching 
func process_crouch(delta : float, force_crouch : bool = false) -> void:
	pass


## Virtual function for handling head bobbing
func process_steps(delta : float) -> void:
	pass


## Virtual function for pushing the controller in a desired [param direction]
## with a [param force]
func push(force : float, direction : Vector3) -> void:
	pass
