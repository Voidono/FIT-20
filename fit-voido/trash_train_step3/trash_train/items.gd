class_name TrashItems
extends RefCounted
## Static item catalogue: which kinds exist, which tier (weight class) each is, which bin takes it,
## and how its placeholder looks. Points and slowdown per TIER live in TrashTrainTuning.

enum Tier { NORMAL, HEAVY, GLITCH }
enum Bin { EWASTE, GENERAL }
enum Kind { FLOPPY, NOKIA, CRT, GLITCH, CUP, NOODLE, PAPER }

const BIN_NAMES := {Bin.EWASTE: "E-waste", Bin.GENERAL: "General"}  # debug text only
const BIN_COLORS := {Bin.EWASTE: Color("4f8df0"), Bin.GENERAL: Color("f0a030")}

# shape: 0 square, 1 circle, 2 diamond, 3 triangle
const DEFS := {
	Kind.FLOPPY: {"tier": Tier.NORMAL, "bin": Bin.EWASTE, "color": Color("4f8df0"), "shape": 0},
	Kind.NOKIA: {"tier": Tier.NORMAL, "bin": Bin.EWASTE, "color": Color("7a6cf0"), "shape": 0},
	Kind.CRT: {"tier": Tier.HEAVY, "bin": Bin.EWASTE, "color": Color("2b4fa8"), "shape": 0},
	Kind.GLITCH: {"tier": Tier.GLITCH, "bin": Bin.EWASTE, "color": Color("e04fe0"), "shape": 2},
	Kind.CUP: {"tier": Tier.NORMAL, "bin": Bin.GENERAL, "color": Color("f0a030"), "shape": 1},
	Kind.NOODLE: {"tier": Tier.NORMAL, "bin": Bin.GENERAL, "color": Color("f0d84a"), "shape": 1},
	Kind.PAPER: {"tier": Tier.NORMAL, "bin": Bin.GENERAL, "color": Color("ece6d0"), "shape": 3},
}
const RADIUS := {Tier.NORMAL: 10.0, Tier.HEAVY: 15.0, Tier.GLITCH: 11.0}


static func tier_of(kind: int) -> int:
	return DEFS[kind]["tier"]


static func bin_of(kind: int) -> int:
	return DEFS[kind]["bin"]


static func bin_color(bin: int) -> Color:
	return BIN_COLORS[bin]


static func radius_of(kind: int) -> float:
	return RADIUS[DEFS[kind]["tier"]]


static func kinds_in_tier(tier: int) -> Array[int]:
	var out: Array[int] = []
	for k in DEFS:
		if DEFS[k]["tier"] == tier:
			out.append(k)
	return out


## Call from inside a CanvasItem's _draw(). Placeholder art until the Aseprite sprites exist.
static func draw_placeholder(ci: CanvasItem, kind: int) -> void:
	var info: Dictionary = DEFS[kind]
	var r: float = RADIUS[info["tier"]]
	var fill: Color = info["color"]
	var edge := fill.darkened(0.5)
	match info["shape"]:
		0:
			var rect := Rect2(-r, -r, r * 2.0, r * 2.0)
			ci.draw_rect(rect, fill)
			ci.draw_rect(rect, edge, false, 2.0)
		1:
			ci.draw_circle(Vector2.ZERO, r, fill)
			ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, edge, 2.0)
		2:
			var d := PackedVector2Array([Vector2(0, -r), Vector2(r, 0), Vector2(0, r), Vector2(-r, 0)])
			ci.draw_colored_polygon(d, fill)
			ci.draw_polyline(PackedVector2Array([d[0], d[1], d[2], d[3], d[0]]), edge, 2.0)
		_:
			var t := PackedVector2Array([Vector2(0, -r), Vector2(r, r * 0.8), Vector2(-r, r * 0.8)])
			ci.draw_colored_polygon(t, fill)
			ci.draw_polyline(PackedVector2Array([t[0], t[1], t[2], t[0]]), edge, 2.0)
