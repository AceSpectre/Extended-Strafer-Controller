extends BaseMovementState
class_name StraferAirState

## Original direction of jump
var jump_dir : Vector3

## Boolean for if a jump has occured
var has_jumped : bool = false

## Magnitude of speed of player when on the ground to cap insane speed increases
var jump_force : float = 0.0

## Amount of directional control when in air. 
## Increase air drag by tiny amounts to make strafing faster
@export var AIR_DRAG : float = 0.84

## Speed at which the jump direction is lerped towards [code]airhvel[/code]
@export var AIR_LERP_SPEED : float = 35.1

## Set jump direction and jump force using a given velocity [Vector3]
func set_jump_dir(controller : BaseController3D, new_dir : Vector3):
	jump_dir = new_dir
	jump_force = min(new_dir.length(), controller.settings.MAX_POSSIBLE_SPEED)


## Handle the air state
func process_state(delta : float, controller : BaseController3D) -> void:
	# Get the current slide state if it exists
	var slide_state : StraferSlideState = controller.get_state(StraferSlideState.new())
	
	# Decrement the coyoteTimer by deltaTime
	controller.coyoteTimer -= delta
	
	# If the timer is not below 0 and jump is pressed and the player hasn't jumped, then make the player jump
	if controller.coyoteTimer > 0 and Input.is_action_just_pressed("ui_accept") and !has_jumped:
		controller.velocity.y = controller.settings.JUMP_FORCE
		jump_dir = controller.velocity
		controller.coyoteTimer = 0
	
	# Velocity
	controller.process_vel(delta, AIR_DRAG)
	# Crouching
	controller.process_crouch(delta)
	# Bounds
	controller.process_bounds()
	# Headbob
	controller.process_steps(delta)
	
	# Check state exit
	if controller.is_on_floor():
		if slide_state != null and Input.is_action_pressed("crouch") and controller.velocity.length() > slide_state.VEL_TRANS_THRESHOLD:
			StraferGroundState.to_slide(controller)
		else:
			StraferAirState.to_ground(controller)


func process_vel(delta : float, controller : BaseController3D) -> void:
	# Gravity
	controller.velocity.y -= controller.settings.GRAVITY * delta
	
	#jump_dir = StraferMath.clampVectorMagnitude(jump_dir, 0.0, controller.settings.MAX_POSSIBLE_SPEED)
	
	# Calculate airhvel by lerping the jumpdir towards hvel
	var airhvel := StraferMath.lerpVector3KeepingMagnitude(jump_dir, Vector3(controller.hvel.x, jump_dir.y, controller.hvel.z))
	
	# Limit the magnitude of the airhvel using jumpforce
	airhvel = airhvel.normalized() * jump_force
	
	# If the player is pressing any input keys, lerp the jump direction towards airhvel
	if controller.inputAxis:
		jump_dir.x = lerp(jump_dir.x, airhvel.x, delta * AIR_LERP_SPEED)
		jump_dir.z = lerp(jump_dir.z, airhvel.z, delta * AIR_LERP_SPEED)
	
	# Lerp velocity towards airhvel
	controller.velocity.x = lerp(controller.velocity.x, airhvel.x, delta * AIR_LERP_SPEED)
	controller.velocity.z = lerp(controller.velocity.z, airhvel.z, delta * AIR_LERP_SPEED)


## Handle headbob
func process_steps(delta : float, controller : BaseController3D, target : Vector2) -> Vector2:
	return Vector2.ZERO


## Transition to ground dstate
static func to_ground(controller : BaseController3D) -> bool:
	var ground_state : StraferGroundState = controller.change_state(StraferGroundState.new())
	var air_state : StraferAirState = controller.get_state(StraferAirState.new())

	if ground_state != null:
		# Set the snap length back to the original snap length
		controller.floor_snap_length = controller.settings.SNAP_LENGTH
		if air_state != null:
			# Reset the state's variables
			air_state.jump_dir = Vector3.ZERO
			air_state.has_jumped = false
		return true
	else:
		return false
