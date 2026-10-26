class_name FitRunnerLauncher
extends RefCounted
## The one entry point for the host game. Installs the minigame's translations (it never changes your locale),
## instances the scene, applies the config.

const SCENE: PackedScene = preload("../../fit_runner.tscn")  # relative to this script, so the module can live anywhere


## Instance the minigame without adding it, so you can connect signals first.
static func create(config: FitRunnerConfig = null) -> FitRunner:
	FitRunnerStrings.install()
	var game := SCENE.instantiate() as FitRunner
	game.configure(config)
	return game


## create() + add_child() in one call.
static func launch(parent: Node, config: FitRunnerConfig = null) -> FitRunner:
	var game: FitRunner = create(config)
	parent.add_child(game)
	return game
