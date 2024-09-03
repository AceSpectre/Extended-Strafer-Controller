extends Object
class_name StraferMath
## A collection of mathematical functions used by the Strafer states


## Returns [code]input_vec[/code] with its magnitude clamped between
## [code]min_mag[/code] and [code]max_mag[/code]
static func clampVectorMagnitude(input_vec : Vector3, min_mag : float, max_mag : float) -> Vector3:
	# If outside given magnitude range, set the magnitude to the closest boundary (min or max)
	if input_vec.length() <= min_mag:
		return input_vec.normalized() * min_mag
	if input_vec.length() >= max_mag:
		return input_vec.normalized() * max_mag
	
	return input_vec

## Returns [code]vectorA[/code] lerped to [code]vectorB[/code] by the amount [code]amount[/code]
## while maintaining its original magnitude
static func lerpVector3KeepingMagnitude(vectorA : Vector3, vectorB: Vector3, amount : float = 0.5) -> Vector3:
	# Lerp vectorA to vectorB by the defined amount
	var normalAverage : Vector3 = lerp(vectorA.normalized(), vectorB.normalized(), amount)
	# Return the lerped vector with the same magnitude as the original vector
	return normalAverage.normalized() * vectorA.length()
