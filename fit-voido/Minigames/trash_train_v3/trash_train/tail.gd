class_name TrashTail
extends Node2D
## The followers. Items sit at fixed arc-length distances along the runner's recent path
## (no physics joints). Taking items out of the middle makes the rest slide forward to close the gap;
## a cut truncates the array. Followers are pooled Area2Ds (TrashTailItem) so NPCs can hit them.
##
## Cost per physics frame: one walk back along the path history, O(history + items).

signal changed

const SAMPLE_STEP := 5.0  # px of travel between recorded path points
const POP_TIME := 0.2  # seconds of "pop" squash after pick-up

var tuning: TrashTrainTuning
var target: Node2D  # the runner

var _hist := PackedVector2Array()  # oldest .. newest recorded runner positions
var _hist_len := 0.0  # summed length of the segments inside _hist
var _items: Array[TrashTailItem] = []  # index 0 = closest to the runner
var _pool: Array[TrashTailItem] = []
var _clock := 0.0


func setup(t: TrashTrainTuning, follow: Node2D) -> void:
	tuning = t
	target = follow
	process_priority = 10  # run after the runner has moved this physics frame
	z_index = 100  # above ground pickups, below the runner (z 200)
	reset()


func reset() -> void:
	for i in _items.size():
		_release(_items[i])
	_items.clear()
	_hist.clear()
	_hist.append(target.global_position)
	_hist_len = 0.0
	changed.emit()


# --- queries ---------------------------------------------------------------

func count() -> int:
	return _items.size()


func is_full() -> bool:
	return tuning.tail_cap > 0 and _items.size() >= tuning.tail_cap


func def_at(i: int) -> TrashItemDef:
	return _items[i].def


func position_at(i: int) -> Vector2:
	return _items[i].global_position


func count_accepted(accepts: Array[StringName]) -> int:
	var n := 0
	for i in _items.size():
		if _items[i].def.goes_in(accepts):
			n += 1
	return n


func carried_points() -> float:
	var sum := 0.0
	for i in _items.size():
		sum += tuning.points_for(_items[i].def.tier)
	return sum


func speed_multiplier() -> float:
	var slow := 0.0
	for i in _items.size():
		slow += tuning.slow_for(_items[i].def.tier)
	return maxf(tuning.min_speed_ratio, 1.0 - slow)


# --- changes ---------------------------------------------------------------

## Returns false (and does nothing) when the tail is full.
func add_item(def: TrashItemDef) -> bool:
	if is_full():
		return false
	var it := _acquire(def)
	it.dist = (_items.size() + 1) * tuning.tail_spacing
	it.pop = 1.0
	_items.append(it)
	_after_change()
	return true


## A bin takes ONLY the kinds it accepts, wherever they are in the tail (empty list = everything).
## Returns the item kinds taken.
func take_accepted(accepts: Array[StringName]) -> Array[TrashItemDef]:
	var kept: Array[TrashTailItem] = []
	var taken: Array[TrashItemDef] = []
	for i in _items.size():
		var it := _items[i]
		if it.def.goes_in(accepts):
			taken.append(it.def)
			_release(it)
		else:
			kept.append(it)
	if not taken.is_empty():
		_items = kept
		_after_change()
	return taken


## Cut the tail at index: this item and everything behind it is removed.
## Returns [{def, pos}] so the caller can scatter them on the ground.
func cut_at(index: int) -> Array[Dictionary]:
	var dropped: Array[Dictionary] = []
	if index < 0 or index >= _items.size():
		return dropped
	for i in range(index, _items.size()):
		var it := _items[i]
		dropped.append({"def": it.def, "pos": it.global_position})
		_release(it)
	_items.resize(index)
	_after_change()
	return dropped


func _after_change() -> void:
	for i in _items.size():
		_items[i].index = i
		_items[i].z_index = -i  # closer to the runner draws on top
	_place_items()
	changed.emit()


# --- per frame -------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if target == null or tuning == null:
		return
	_clock += delta
	_record(target.global_position)
	var slide := tuning.tail_gap_speed * delta
	var prev := 0.0
	for i in _items.size():
		var it := _items[i]
		var want := maxf((i + 1) * tuning.tail_spacing, prev)
		it.dist = maxf(move_toward(it.dist, want, slide), prev)  # never overtakes the item in front
		prev = it.dist
		it.pop = maxf(0.0, it.pop - delta / POP_TIME)
	_place_items()


func _record(p: Vector2) -> void:
	var n := _hist.size()
	if n == 0:
		_hist.append(p)
		return
	var d := p.distance_to(_hist[n - 1])
	if d < SAMPLE_STEP:
		return
	_hist.append(p)
	_hist_len += d
	# drop the oldest points once the rest still covers every item plus a little spare
	var need := (_items.size() + 3) * tuning.tail_spacing
	while _hist.size() > 2:
		var seg0 := _hist[0].distance_to(_hist[1])
		if _hist_len - seg0 < need:
			break
		_hist.remove_at(0)
		_hist_len -= seg0


## Single sweep from the runner back along the path; items are in increasing-distance order.
func _place_items() -> void:
	var n := _items.size()
	if n == 0:
		return
	var idx := _hist.size() - 1
	var from := target.global_position
	var to := _hist[idx]
	var seg := from.distance_to(to)
	var walked := 0.0
	for i in n:
		var it := _items[i]
		while walked + seg < it.dist and idx > 0:
			walked += seg
			idx -= 1
			from = to
			to = _hist[idx]
			seg = from.distance_to(to)
		var t := 1.0 if seg <= 0.0001 else clampf((it.dist - walked) / seg, 0.0, 1.0)
		it.global_position = from.lerp(to, t)
		var w := sin(_clock * tuning.wobble_speed - i * 0.9) * tuning.wobble_amount
		it.scale = Vector2(1.0 + w, 1.0 - w) * (1.0 + it.pop * 0.6)


func _acquire(def: TrashItemDef) -> TrashTailItem:
	var it: TrashTailItem
	if _pool.is_empty():
		it = TrashTailItem.new()
		add_child(it)
	else:
		it = _pool.pop_back()
	it.use(def)
	return it


func _release(it: TrashTailItem) -> void:
	it.park()
	_pool.append(it)
