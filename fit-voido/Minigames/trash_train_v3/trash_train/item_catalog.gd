class_name TrashItemCatalog
extends Resource
## The list of item kinds a level can spawn. Assign it on the TrashLevel node (or on the TrashTrain root
## as a fallback). Each item's spawn_weight decides how often it appears.

@export var items: Array[TrashItemDef] = []


func find(item_id: StringName) -> TrashItemDef:
	for d in items:
		if d != null and d.id == item_id:
			return d
	return null


## Weighted random pick. `only` (e.g. a spawn zone's own list) restricts the choice; empty = whole catalog.
func pick(rng: RandomNumberGenerator, only: Array[TrashItemDef] = []) -> TrashItemDef:
	var pool: Array[TrashItemDef] = only if not only.is_empty() else items
	var total := 0.0
	for d in pool:
		if d != null:
			total += maxf(d.spawn_weight, 0.0)
	if pool.is_empty():
		return null
	if total <= 0.0:
		return pool[0]
	var r := rng.randf() * total
	for d in pool:
		if d == null:
			continue
		r -= maxf(d.spawn_weight, 0.0)
		if r <= 0.0:
			return d
	return pool.back()
