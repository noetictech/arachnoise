extends Node

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal movement_vector_changed(vector: Vector2)
signal mode_changed(mode: int)
signal mapping_changed(linear_mode: bool)

# ---------------------------------------------------------------------------
# Mode constants
# ---------------------------------------------------------------------------
const MODE_NOTES  := 0
const MODE_CHORDS := 1

# ---------------------------------------------------------------------------
# Circle of fifths — steps from C, indexed by pitch class.
# C=0, G=1, D=2, A=3, E=4, B=5, F#=6, C#=7, Ab=8, Eb=9, Bb=10, F=11
# ---------------------------------------------------------------------------
const FIFTHS_STEPS: Array[int] = [
	0,   # C
	7,   # C#/Db
	2,   # D
	9,   # Eb
	4,   # E
	11,  # F
	6,   # F#/Gb
	1,   # G
	8,   # Ab
	3,   # A
	10,  # Bb
	5,   # B
]

# ---------------------------------------------------------------------------
# Chromatic (linear) mode — linear pitch class order, C through B.
# C=0, C#=1, D=2, Eb=3, E=4, F=5, F#=6, G=7, Ab=8, A=9, Bb=10, B=11
# ---------------------------------------------------------------------------
const CHROMATIC_STEPS: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]

# ---------------------------------------------------------------------------
# Defaults: C at north (90° math convention), clockwise = sharp direction.
# Each step clockwise = -30° in math convention (CCW from east).
# ---------------------------------------------------------------------------
var c_angle_deg: float = 90.0
var step_deg: float    = -30.0

var mode: int = MODE_NOTES
var linear_mode: bool = false

var _computed_angles: Array[float] = []
var _held_notes: Array[int] = []

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------
func _ready() -> void:
	_build_angles()

	if not MidiInputManager:
		push_error("KeyboardDirectionalController: MidiInputManager autoload not found")
		return

	MidiInputManager.note_on.connect(_on_note_on)
	MidiInputManager.note_off.connect(_on_note_off)
	MidiInputManager.chord_played.connect(_on_chord_played)

# ---------------------------------------------------------------------------
# Angle table
# ---------------------------------------------------------------------------
func build_angles(c_angle: float, step: float) -> void:
	c_angle_deg = c_angle
	step_deg    = step
	_build_angles()

func _build_angles() -> void:
	_computed_angles.resize(12)
	var steps := CHROMATIC_STEPS if linear_mode else FIFTHS_STEPS
	for pc in 12:
		_computed_angles[pc] = c_angle_deg + steps[pc] * step_deg

func set_linear_mode(enabled: bool) -> void:
	linear_mode = enabled
	_build_angles()
	_held_notes.clear()
	movement_vector_changed.emit(Vector2.ZERO)
	mapping_changed.emit(linear_mode)

func toggle_linear_mode() -> void:
	set_linear_mode(!linear_mode)

func print_angle_table() -> void:
	const NAMES := ["C","C#","D","Eb","E","F","F#","G","Ab","A","Bb","B"]
	var label := "linear/chromatic" if linear_mode else "circle of fifths"
	print("--- Keyline angle table (%s) ---" % label)
	for pc in 12:
		print("  %-3s  %6.1f°" % [NAMES[pc], _computed_angles[pc]])

# ---------------------------------------------------------------------------
# Note mode
# ---------------------------------------------------------------------------
func _on_note_on(pitch: int, velocity: int, _channel: int) -> void:
	if mode != MODE_NOTES:
		return
	if not _held_notes.has(pitch):
		_held_notes.append(pitch)
	_emit_from_notes(velocity)

func _on_note_off(pitch: int, _channel: int) -> void:
	if mode != MODE_NOTES:
		return
	_held_notes.erase(pitch)
	if _held_notes.is_empty():
		movement_vector_changed.emit(Vector2.ZERO)
	else:
		_emit_from_notes(64)

func _emit_from_notes(velocity: int) -> void:
	if _held_notes.is_empty():
		return
	var vec := Vector2.ZERO
	for pitch in _held_notes:
		var pc  := pitch % 12
		var ang := deg_to_rad(_computed_angles[pc])
		vec += Vector2(cos(ang), -sin(ang))
	vec = vec.normalized()
	movement_vector_changed.emit(vec * (velocity / 127.0))

# ---------------------------------------------------------------------------
# Chord mode
# ---------------------------------------------------------------------------
func _on_chord_played(_notes: Array[int], root: int, quality: String, _name: String) -> void:
	if mode != MODE_CHORDS:
		return
	var ang := deg_to_rad(_computed_angles[root])
	var dir := Vector2(cos(ang), -sin(ang))
	movement_vector_changed.emit(dir * _quality_speed(quality))

func _quality_speed(quality: String) -> float:
	match quality:
		"maj", "maj7":   return 1.0
		"min", "min7":   return 0.85
		"dom7":          return 0.9
		"sus4", "sus2":  return 0.75
		"aug", "aug7":   return 0.6
		"m7b5":          return 0.5
		"dim", "dim7":   return 0.35
		_:               return 0.7

# ---------------------------------------------------------------------------
# Mode switching
# ---------------------------------------------------------------------------
func set_mode(new_mode: int) -> void:
	mode = new_mode
	_held_notes.clear()
	movement_vector_changed.emit(Vector2.ZERO)
	mode_changed.emit(mode)

func toggle_mode() -> void:
	set_mode(MODE_CHORDS if mode == MODE_NOTES else MODE_NOTES)
