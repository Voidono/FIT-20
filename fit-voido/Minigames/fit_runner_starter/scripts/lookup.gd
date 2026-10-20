class_name Lookup
extends RefCounted
## Finds a node of a scene by its name. Tries the scene-unique name (%Name) first, then searches the children by
## name, so a missing "Access as Unique Name" flag cannot break a scene. If a node really is missing, it says so once
## with the scene path, instead of letting a null crash somewhere else later.


## Required node: pushes a clear error when it is missing.
static func node(from: Node, node_name: String) -> Node:
	var found: Node = optional(from, node_name)
	if found == null:
		push_error("%s: node '%s' not found (is it in the scene tree and spelled the same?)" % [from.get_path(), node_name])
	return found


## Optional node: returns null quietly.
static func optional(from: Node, node_name: String) -> Node:
	var found: Node = from.get_node_or_null("%" + node_name)
	if found == null:
		found = from.find_child(node_name, true, false)
	return found
