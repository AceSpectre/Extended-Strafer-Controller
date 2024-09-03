extends Resource
class_name Controller3DSettings
## A resources containing a basic collection of settings for implementations of 
## [BaseController3D]

## Mouse sensitivity
@export var MOUSE_SENS : float = 2.0

## Settings for the controller when on the ground
@export_group("Ground Settings")

## Lerp speed from the current direction to the wish direction
@export var CONTROL : float = 15.0

## Max speed of the controller on the floor
@export var MAX_SPEED : float = 16.0

## Max speed of the controller when crouching on the floor
@export var MAX_CROUCH_SPEED : float = 8.0

## Max possible speed of the controller
@export var MAX_POSSIBLE_SPEED : float = 25.0

## Max acceleration of the controller 
@export var MAX_ACCEL : float = 150.0

## Settings related to jumping and leaving the ground generally
@export_group("Jump Settings")

## Gravity of the controller
@export var GRAVITY : float = 32.0

## Jump force of the controller
@export var JUMP_FORCE : float = 12.0

## Coyote time of the controller 
## (the maximum amount of time after leaving the floor that the player can still jump)
@export var COYOTE_TIME : float = .2

## The desired snap length of the controller. On [code]_ready()[/code] this is set to the 
## [member CharacterBody3D.floor_snap_length].
var SNAP_LENGTH : float = 0.0
