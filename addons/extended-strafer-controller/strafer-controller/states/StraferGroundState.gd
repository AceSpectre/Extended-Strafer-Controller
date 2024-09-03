extends BaseMovementState
class_name StraferGroundState
## The modular ground state for [StraferController3D].

## The drag used when the movement controller is on the ground
@export var GROUND_DRAG : float = 0.86 :
	get:
		return GROUND_DRAG

## The speed threshold for transitioning to the [StraferSlideState]
@export var SLIDE_SPEED : float = 10.0 :
	get:
		return SLIDE_SPEED


## Handle the ground state
func process_state(delta : float, controller : BaseController3D) -> void:
	# Get the slide state from the controller
	var slide_state : StraferSlideState = controller.get_state(StraferSlideState.new())
	
	# If the jump button is pressed, handle the jump
	if Input.is_action_pressed("jump"):
		StraferGroundState.handle_jump(controller)
	
	# Handle movement this physics frame using GROUND_DRAG
	controller.process_vel(delta, GROUND_DRAG)
	
	# If crouch isn't pressed and the slide state exists, then we have ended a slide
	if !Input.is_action_pressed("crouch") and slide_state != null:
		slide_state.has_slid = false
	
	# If moving faster than SLIDE_SPEED and crouch is pressed and a slide state exists
	if controller.velocity.length() > SLIDE_SPEED and Input.is_action_pressed("crouch") and slide_state != null:
		# Transition to the slide start, start a slide if it hasn't been started
		StraferGroundState.to_slide(controller, !slide_state.has_slid)
	else:
		controller.process_crouch(delta)
	
	# Handle headbobbing 
	controller.process_steps(delta)
	
	# If not on floor, transition to air state
	if !controller.is_on_floor():
		StraferGroundState.to_air(controller)


## Handles controller movement
func process_vel(delta : float, controller : BaseController3D) -> void:
	# Set the controller's velocity to hvel
	controller.velocity.x = controller.hvel.x
	controller.velocity.z = controller.hvel.z	


## Function that handles jumping. Intended for [StraferController3D].
static func handle_jump(controller : BaseController3D) -> void:
	# Set the snap length to 0 and jump using the jump force from the settings
	controller.floor_snap_length = 0.0
	controller.velocity.y = controller.settings.JUMP_FORCE
	
	# Get the air state from the controller
	var air_state : StraferAirState = controller.change_state(StraferAirState.new())
	
	if air_state != null: # If it exists, set the jump direction and set has_jumped to true
		air_state.set_jump_dir(controller, controller.velocity)
		air_state.has_jumped = true


## Function that handles transitioning from the [StraferGroundState] to the [StraferAirState].
## Returns true if the corresponding [member BaseController3D.states] contains [StraferAirState],
## otherwise it returns false. 
static func to_air(controller : BaseController3D) -> bool:
	# Get the air state from the controller
	var air_state : StraferAirState = controller.change_state(StraferAirState.new())
	
	if air_state != null: # If the air state exists
		# Set the jump direction if the controller has just jumped
		if !air_state.has_jumped : air_state.set_jump_dir(controller, controller.velocity)
		# Start the coyote timer using the time set in the settings
		controller.coyoteTimer = controller.settings.COYOTE_TIME
		return true
	else:
		return false


## Function that handles transitioning from the [StraferGroundState] to the [StraferSlideState].
## Returns true if the corresponding [member BaseController3D.states] contains [StraferSlideState],
## otherwise it returns false. 
static func to_slide(controller : BaseController3D, start_slide : bool = false) -> bool:
	# Get the slide state from the controller
	var slide_state : StraferSlideState = controller.change_state(StraferSlideState.new())
	
	if slide_state != null: # If the slide state exists
		# Get the current movement direction and push the controller if this is the first slide
		var v : Vector3 = controller.velocity.normalized().slide(controller.get_floor_normal().normalized())
		if !slide_state.has_slid: controller.push(slide_state.slide_force, v)
		
		# Apply the floor snap and set the slide direction to the horizontal velocity
		controller.apply_floor_snap()
		slide_state.slide_dir = Vector3(controller.velocity.x, 0, controller.velocity.z).normalized()
		
		# If starting the slide, set has_slid to true
		if start_slide: slide_state.has_slid = true
		return true
	else:
		return false
