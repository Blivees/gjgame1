extends Control

const GAME_SCENE := "res://Scenes/level1.tscn"


func _ready() -> void:
	$Buttons/StartGame.grab_focus()


func _on_start_game_pressed() -> void:
	var result := get_tree().change_scene_to_file(GAME_SCENE)
	if result != OK:
		push_error("Could not open %s (%s)." % [GAME_SCENE, error_string(result)])


func _on_quit_game_pressed() -> void:
	get_tree().quit()
