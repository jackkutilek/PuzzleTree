@tool
extends EditorImportPlugin


func _get_importer_name():
	return "ldtk.project"

func _get_visible_name():
	return "LDTK Project"

func _get_recognized_extensions():
	return ["ldtk"]

func _get_import_options(preset, index):
	return []

func _get_import_order():
	return 0

func _get_preset_count():
	return 0

func _get_save_extension():
	return "tres"

func _get_resource_type():
	return "Resource"


func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]):
	var project = Resource.new()
	project.set_script(preload("res://addons/PuzzleTree/ldtk_loader/ldtk_script.gd"))
	
	var file = FileAccess.open(source_file, FileAccess.READ)
	var file_text = file.get_as_text()
	file.close()
	
	var test_json_conv = JSON.new()
	test_json_conv.parse(file_text)
	var data = test_json_conv.get_data()
	project.set("data", data)

	var filename = save_path + "." + _get_save_extension()
	var result = ResourceSaver.save(project, filename)

	return result
