class_name FrCourseProfile
extends RefCounted
## Terrain height and slope along the track. Heights are cosine ramps between the
## (fraction, height) points in FrTuning.course_points, so slope is smooth.

var _t: FrTuning
var _h0: float = 0.0
var _h1: float = 0.0
var _u: float = 0.0
var _span: float = 1.0


func _init(tuning: FrTuning) -> void:
	_t = tuning


func _locate(x: float) -> void:
	var pts: PackedVector2Array = _t.course_points
	var length: float = _t.track_length
	var f: float = clampf(x / length, 0.0, 1.0)
	var n: int = pts.size()
	if n < 2:
		_h0 = 0.0
		_h1 = 0.0
		_u = 0.0
		_span = 1.0
		return
	var i: int = 0
	while i < n - 2 and f > pts[i + 1].x:
		i += 1
	var a: Vector2 = pts[i]
	var b: Vector2 = pts[i + 1]
	_h0 = a.y
	_h1 = b.y
	_span = maxf((b.x - a.x) * length, 0.000001)
	_u = clampf((f - a.x) / maxf(b.x - a.x, 0.000000001), 0.0, 1.0)


## Height above flat ground in px (positive = up).
func height_at(x: float) -> float:
	_locate(x)
	return _h0 + (_h1 - _h0) * (1.0 - cos(PI * _u)) * 0.5


## dHeight/dx, positive = uphill.
func slope_at(x: float) -> float:
	_locate(x)
	return (_h1 - _h0) * PI * sin(PI * _u) / (2.0 * _span)
