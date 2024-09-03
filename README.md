# ExtendedStraferController

Modular first person controller based on Quake's movement system

# Features

### Modular States
States are stored as resources and are not dependent on each other. This means they can be interchanged without concern for breaking the controller. 

Storing states as resources allows them to be changed dynamically witin the inspector. They can export variables consisting of their settings and can be saved and reused. 

The state machine works using an array of `BaseMovementState`. The starting state is specified using an index. 

State change requests can be made to the controller using the `change_state()` function, passing in a new instance of the type of state to change to. If the state does exist, this function returns the state instance within the array of states, otherwise it returns `null`. 

Transitions are defined as static functions within these states, for example the transition to the air state from the ground state is written within the ground state as `static func to_air()`. Defining state transitions statically allows transitions to be shared between states. For example, jumping in both the ground state and sliding state would have the same transition to the air state. 

This system allows the controller to pass on handling of certain features (e.g: processing the current velocity or headbobbing) to the current state without needing to know the type of the current state. The interface for the modular system is defined within `BaseController3D.gd` and `BaseMovementState.gd`

### Extended Strafer Controller

This modular system was built using [Kabariya's strafer controller](https://github.com/Kabariya/strafer) as a base. Three features have been added
- Sliding
- Maintaining the current direction when jumping (and not pressing any keys)
- Limiting the player's control over the controller in the air