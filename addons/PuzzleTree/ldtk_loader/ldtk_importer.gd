tool
extends EditorImportPlugin


func get_importer_name():
	return "ldtk.project"

func get_visible_name():
	return "LDTK Project"

func get_recognized_extensions():
	return ["ldtk"]

func get_import_options(preset):
	return []

func get_preset_count():
	return 0

func get_save_extension():
	return "tres"

func get_resource_type():
	return "Resource"


func import(source_file, save_path, options, r_platform_variants, r_gen_files):
	var project = Resource.new()
	project.set_script(preload("res://addons/PuzzleTree/ldtk_loader/ldtk_script.gd"))
	
	var file = File.new()
	var _err = file.open(source_file, File.READ)
	var file_text = file.get_as_text()
	file.close()
	
	var data = parse_json(file_text)
	project.set("data", data)
	
	var full_path = str("%s.%s" % [save_path, get_save_extension()])
	var result = ResourceSaver.save(full_path, project)
	return result
