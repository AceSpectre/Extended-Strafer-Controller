extends BaseMovementState
class_name StraferSlideState

## Force applied to controller using [code]push()[/code] when transitioning to the slide state
@export var slide_force : float = 6.0

## Force applied to controller using [code]push()[/code] when jumping while sliding
@export var slide_jump_force : float = 1.0

## Drag used when slide starts
@export var SLIDE_DRAG : float = 1.0

## Lerp speed using when lerping the drag
@export var SLIDE_LERP_SPEED : float = .08

## Allowed dot product difference to the controller's direction without ending the slide [br]
## The dot product between [code]slide_dir[/code] and [code]controller.velocity.noramlized()[/code]
## going below this value will end the slide state.
@export var ALLOWED_DIR_DOT_PROD : float = .7

## Velocity transition threshold for when a slide can be activiated when crouch is pressed
@export var VEL_TRANS_THRESHOLD : float = 9.0

## Current drag value used by the slide state
var current_drag : float

## Current slide direction of the slide state, set by states transitioning to this state
var slide_dir : Vector3

## Boolean to determine if this is the first slide in a series of slides (not really working correctly)
var has_slid : bool = false

## Sets the [code]current_drag[/code] to the [code]SLIDE_DRAG[/code]
func start(controller : BaseController3D) -> void:
	if !has_slid:
		current_drag = SLIDE_DRAG


## Handles the slide state
func process_state(delta : float, controller : BaseController3D) -> void:
	controller.process_crouch(delta, true)
	controller.process_vel(delta, current_drag)
	controller.process_steps(delta)
	controller.apply_floor_snap()
	
	# Get normal to the floor
	var floorNormal := controller.get_floor_normal()
	floorNormal.y = 0
	
	# If not on a slope or if going up the slope, process slides normally
	if controller.get_floor_angle() <= 0.2 or controller.velocity.angle_to(floorNormal) >= PI/2:
		current_drag = lerp(current_drag, 0.0, delta * SLIDE_LERP_SPEED)
	else:
		# If on a slope, modify the lerp speed by a factor determined by how "down the slope" the controller is moving
		var lerp_factor : float = (controller.velocity.angle_to(floorNormal) / PI/2) / 2
		current_drag= lerp(current_drag, 0.0, delta * SLIDE_LERP_SPEED * lerp_factor)
	
	# If velocity goes below the normal max speed or 
	# if the dot product goes under the allowed direction dot product, transition to the ground state
	if controller.velocity.length() <= controller.settings.MAX_SPEED or slide_dir.dot(controller.velocity.normalized()) < ALLOWED_DIR_DOT_PROD:
		controller.change_state(StraferGroundState.new())
	
	# Handle jump and push controller if jump is pressed
	if Input.is_action_pressed("jump"):
		StraferGroundState.handle_jump(controller)
		controller.push(slide_jump_force, slide_dir.normalized())
	
	# If not on floor, try applying a floor snap and transition to air state
	if !controller.is_on_floor():
		controller.apply_floor_snap()
		StraferGroundState.to_air(controller)
		controller.velocity.y = 0


## Handles controller movement
func process_vel(delta : float, controller : BaseController3D) -> void:
	controller.velocity.x = controller.hvel.x
	controller.velocity.z = controller.hvel.z
	# The controller bounces when jumping -> sliding on a slope, apply a negative velocity to prevent this
	controller.velocity.y = -10


## Don't apply any headbob while sliding
func process_steps(delta : float, controller : BaseController3D, target : Vector2) -> Vector2:
	return Vector2.ZERO
