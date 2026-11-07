extends Node
## Original synthesized effects; the shared bus keeps them under Effects volume.
var footsteps: Array[AudioStream] = []
var click: AudioStreamWAV
var door: AudioStreamWAV
var _voice: AudioStreamPlayer

func _ready() -> void:
	for seed_value in [11, 23, 37]:
		footsteps.append(_sound(0.085, 95, 0.30, seed_value))
	click = _sound(0.035, 720, 0.12, 52)
	door = _sound(0.24, 135, 0.28, 64)
	_voice = AudioStreamPlayer.new()
	_voice.bus = &"sound effect"
	_voice.max_polyphony = 6
	_voice.volume_db = -14
	add_child(_voice)
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_watch)
	_scan(get_tree().root)

func _scan(node: Node) -> void:
	_watch(node)
	for child in node.get_children(): _scan(child)

func _watch(node: Node) -> void:
	if node is BaseButton:
		if not node.pressed.is_connected(_click): node.pressed.connect(_click)

func _click() -> void:
	_voice.stream = click
	_voice.play()

func play_door() -> void:
	_voice.stream = door
	_voice.play()

func _sound(duration: float, frequency: float, noise_amount: float, seed_value: int) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var rate := 22050
	var count := int(duration * rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var filtered := 0.0
	for i in count:
		var t := float(i) / rate
		var progress := float(i) / count
		filtered = lerpf(filtered, rng.randf_range(-1, 1), 0.2)
		var envelope := minf(1, t / 0.003) * pow(1 - progress, 3)
		var tone := sin(TAU * frequency * t * (1 - progress * 0.3))
		var value := (tone * 0.25 + filtered * noise_amount) * envelope
		bytes.encode_s16(i * 2, int(clampf(value, -1, 1) * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	return stream
