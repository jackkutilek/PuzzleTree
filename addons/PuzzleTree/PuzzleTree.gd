@tool
extends EditorPlugin

var import_plugin

func full_path(rel_path:String):
	return str(self.get_script().get_path().get_base_dir(), "/", rel_path)

func _enter_tree() -> void:
	import_plugin = load(full_path("project_loader/ptproject_importer.gd")).new()
	add_import_plugin(import_plugin)
	
	add_autoload_singleton("Directions", full_path("utils/directions.gd"))
	add_autoload_singleton("Inputs", full_path("utils/inputs.gd"))
	add_autoload_singleton("logger", full_path("core/logger.gd"))
	add_autoload_singleton("PTTileSets", full_path("core/PTTileSets.gd"))
	
	ProjectSettings.set_setting("editor/script/templates_search_path", "res://addons/PuzzleTree/script_templates/")
	ProjectSettings.save()


func _exit_tree() -> void:
	remove_import_plugin(import_plugin)
	import_plugin = null
	
	remove_autoload_singleton("Directions")
	remove_autoload_singleton("Inputs")
	remove_autoload_singleton("logger")
	remove_autoload_singleton("PTTileSets")
