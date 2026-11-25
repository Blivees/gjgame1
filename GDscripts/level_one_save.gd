extends RefCounted

const PATH := "user://level_one.save"
const SECTION := "level_one"

var position: Vector2
var saved_at: String


func read() -> Error:
	var file := ConfigFile.new()
	var result := file.load(PATH)
	if result != OK:
		return result
	var saved_position: Variant = file.get_value(SECTION, "position", Vector2.INF)
	if not saved_position is Vector2 or not saved_position.is_finite():
		return ERR_FILE_CORRUPT
	position = saved_position
	saved_at = str(file.get_value(SECTION, "saved_at", ""))
	return OK


func write(player_position: Vector2) -> Error:
	var file := ConfigFile.new()
	var timestamp := Time.get_datetime_string_from_system(false, true).left(16)
	file.set_value(SECTION, "position", player_position)
	file.set_value(SECTION, "saved_at", timestamp)

	var temp_path := "%s.%d.tmp" % [PATH, OS.get_process_id()]
	var result := file.save(temp_path)
	if result == OK:
		result = DirAccess.rename_absolute(temp_path, PATH)
	if result != OK:
		if FileAccess.file_exists(temp_path):
			DirAccess.remove_absolute(temp_path)
		return result

	position = player_position
	saved_at = timestamp
	return OK
