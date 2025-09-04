extends Control

@export var bg_color: Color = Color.BLACK
@export var to_scene: PackedScene
@export var title_color: Color = Color.WHITE
@export var text_color: Color = Color.WHITE
@export var title_font: Font
@export var text_font: Font
@export var Music: AudioStream
@export var Use_Video_Audio: bool = false
@export var Video: VideoStream
@export var use_transitions: bool = false

const SECTION_TIME := 2.0
const LINE_TIME := 0.3
const BASE_SPEED := 100.0
const SPEED_UP_MULTIPLIER := 10.0

var scroll_speed: float = BASE_SPEED
var speed_up := false

@onready var colorrect = $ColorRect
@onready var videoplayer = $VideoPlayer
@onready var line = $CreditsContainer/Line
var started := false
var finished := false

var section: Array
var section_next := true
var section_timer := 0.0
var line_timer := 0.0
var curr_line := 0
var lines: Array = []

var credits = [
	[
		"A game by "
	],[
		"Programming",
		"",
	],[
		"Art",
		"",
	],[
		"Music",
		""
	],[
		"Sound Effects",
		""
	],[
		"Testers",
		"",
	],[
		"Tools used",
		"Developed with Godot Engine",
		"https://godotengine.org/license",
	],
]

func _ready():
	colorrect.color = bg_color
	videoplayer.stream = Video
	if use_transitions:
		$AnimationPlayer.play("Start")
	if not Use_Video_Audio:
		var stream := AudioStreamPlayer.new()
		stream.stream = Music
		add_child(stream)
		videoplayer.volume_db = -80
		stream.play()
	else:
		videoplayer.volume_db = 0
	videoplayer.play()

func _process(delta: float) -> void:
	scroll_speed = BASE_SPEED * delta
	if section_next:
		section_timer += delta * (SPEED_UP_MULTIPLIER if speed_up else 1.0)
		if section_timer >= SECTION_TIME:
			section_timer -= SECTION_TIME
			if credits.size() > 0:
				started = true
				section = credits.pop_front()
				curr_line = 0
				add_line()
	else:
		line_timer += delta * (SPEED_UP_MULTIPLIER if speed_up else 1.0)
		if line_timer >= LINE_TIME:
			line_timer -= LINE_TIME
			if section.size() > 0:
				add_line()
			else:
				section_next = true


	if speed_up:
		scroll_speed *= SPEED_UP_MULTIPLIER

	if lines.size() > 0:
		for l in lines:
			l.position.y -= scroll_speed
			if l.position.y < -l.get_line_height():
				lines.erase(l)
				l.queue_free()
	elif started:
		finish()

func finish():
	if not finished:
		finished = true
		if use_transitions:
			$AnimationPlayer.play("Finish")
			await $AnimationPlayer.animation_finished
		if to_scene != null:
			get_tree().change_scene_to_file(to_scene.resource_path)
		else:
			get_tree().quit()

func add_line():
	var new_line = line.duplicate()
	new_line.text = section.pop_front()
	lines.append(new_line)

	if curr_line == 0:
		if title_font:
			new_line.add_theme_font_override("font", title_font)
		new_line.add_theme_color_override("font_color", title_color)
	else:
		if text_font:
			new_line.add_theme_font_override("font", text_font)
		new_line.add_theme_color_override("font_color", text_color)

	$CreditsContainer.add_child(new_line)
	curr_line += 1

	if section.is_empty():
		section_next = true
	else:
		section_next = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		finish()
	elif event.is_action_pressed("ui_down") and not event.is_echo():
		speed_up = true
	elif event.is_action_released("ui_down") and not event.is_echo():
		speed_up = false
