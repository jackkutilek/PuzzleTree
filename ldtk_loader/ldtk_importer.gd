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
	project.take_over_path(source_file)
	
	var full_path = str("%s.%s" % [save_path, get_save_extension()])
	var result = ResourceSaver.save(full_path, project)
	return result
