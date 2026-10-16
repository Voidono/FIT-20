class_name Fmt
extends RefCounted
## Small text helpers shared by the HUD and the debug overlay.


static func time(sec: float) -> String:
	var s: float = maxf(sec, 0.0)
	var minutes: int = int(s / 60.0)
	var rest: float = s - float(minutes) * 60.0
	return "%02d:%04.1f" % [minutes, rest]


static func signed(v: float, decimals: int = 1) -> String:
	var text: String = ("%." + str(decimals) + "f") % absf(v)
	return ("+" if v >= 0.0 else "-") + text
