extends Control

const GAME_SCENE := "res://Scenes/level1.tscn"
const SaveSlot := preload("res://GDscripts/level_one_save.gd")

@onready var menu_status: Label = $MenuStatus


func _ready() -> void:
	$Buttons/StartGame.grab_focus()


func _on_start_game_pressed() -> void:
	_open_level()


func _on_load_game_pressed() -> void:
	var slot := SaveSlot.new()
	match slot.read():
		OK:
			_open_level(slot)
		ERR_FILE_NOT_FOUND:
			menu_status.text = "暂无存档"
		_:
			menu_status.text = "读取存档失败"


func _open_level(slot: SaveSlot = null) -> void:
	var scene := load(GAME_SCENE) as PackedScene
	if scene == null:
		menu_status.text = "无法进入 Level One"
		return

	var level := scene.instantiate()
	if slot != null:
		var player := level.get_node("Player") as CharacterBody2D
		player.position = slot.position

	var result := get_tree().change_scene_to_node(level)
	if result != OK:
		level.free()
		menu_status.text = "无法进入 Level One"


func _on_quit_game_pressed() -> void:
	get_tree().quit()
