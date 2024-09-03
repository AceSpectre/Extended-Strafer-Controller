extends Resource
class_name BaseMovementState
## The base class for movement states for [BaseController3D]
##
## This contains a collection of virtual functions that provide an interface for the state
## machine within [BaseController3D], alongside virtual functions that are intended to be called
## within the virtual fucntions defined in [BaseController3D].

## Virtual function called when the state is transitioned to
@warning_ignore("unused_parameter")
func start(controller : BaseController3D) -> void:
	pass


## Virtual function called every physics frame when this state is the current state
@warning_ignore("unused_parameter")
func process_state(delta : float, controller : BaseController3D) -> void:
	pass


## Virtual function for handling the velocity and movement of the controller
@warning_ignore("unused_parameter")
func process_vel(delta : float, controller : BaseController3D) -> void:
	pass


## Virtual function for handling the headbobbing of the controller
@warning_ignore("unused_parameter")
func process_steps(delta: float, controller : BaseController3D, target : Vector2) -> Vector2:
	return target


## Returns the name of this state
func get_state_name() -> String:
	return get_script().get_script_property_list()[0]["name"]
