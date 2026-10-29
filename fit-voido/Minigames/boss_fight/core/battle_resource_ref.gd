class_name BattleResourceRef
extends Node
## A node that just points at a resource. Lists of skills / difficulty presets are kept as child nodes
## of BossBattle/Library, so Godot updates the references when you move the folder (string paths
## would silently break) and the export always includes them.

@export var resource: Resource
