extends CanvasLayer

const MAIN_MENU := "res://Scenes/menuscene.tscn"
const SaveSlot := preload("res://GDscripts/level_one_save.gd")

@export var player: CharacterBody2D

var save_slot := SaveSlot.new()

@onready var save_tab: Button = %SaveTab
@onready var save_panel: VBoxContainer = %SavePanel
@onready var save_status: Label = %SaveStatus
@onready var volume_panel: VBoxContainer = %VolumePanel
@onready var volume_slider: HSlider = %VolumeSlider
@onready var volume_value: Label = %VolumeValue


func _ready() -> void:
	hide()
	var volume := 0.0 if AudioServer.is_bus_mute(0) else AudioServer.get_bus_volume_linear(0)
	volume_slider.set_value_no_signal(volume * 100.0)
	_update_volume_label(volume_slider.value)
	if not is_instance_valid(player):
		%SaveButton.disabled = true
		return
	match save_slot.read():
		OK:
			_show_saved_status()
		ERR_FILE_NOT_FOUND:
			save_status.text = "暂无存档"
		_:
			save_status.text = "读取存档失败"


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if visible:
		hide()
		get_tree().paused = false
	else:
		get_tree().paused = true
		show()
		_on_save_tab_pressed()
		save_tab.grab_focus()


func _on_save_tab_pressed() -> void:
	save_tab.button_pressed = true
	volume_panel.hide()
	save_panel.show()


func _on_volume_tab_pressed() -> void:
	save_panel.hide()
	volume_panel.show()
	volume_slider.grab_focus()


func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_mute(0, value == 0.0)
	AudioServer.set_bus_volume_linear(0, maxf(value / 100.0, 0.0001))
	_update_volume_label(value)


func _update_volume_label(value: float) -> void:
	volume_value.text = "%d%%" % roundi(value)


func _on_save_pressed() -> void:
	if save_slot.write(player.position) != OK:
		save_status.text = "保存失败，请重试"
		return
	_show_saved_status()


func _show_saved_status() -> void:
	var timestamp := save_slot.saved_at
	save_status.text = "已保存" if timestamp.is_empty() else "已保存 · %s" % timestamp


func _on_return_pressed() -> void:
	var tree := get_tree()
	var result := tree.change_scene_to_file(MAIN_MENU)
	if result == OK:
		tree.paused = false
	else:
		_on_save_tab_pressed()
		save_status.text = "无法返回主菜单，请重试"
