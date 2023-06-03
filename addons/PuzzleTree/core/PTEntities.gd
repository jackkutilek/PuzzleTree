@tool
@icon("../icons/PTEntities.png")
extends Node2D

class_name PTEntities

@export var entities:Array = []



func clear_map():
	entities.clear()

func deep_clone(dict):
	if dict is int or dict is float or dict is bool or dict is String:
		return dict
	elif dict is Vector2:
		return Vector2(dict.x, dict.y)
	elif dict is Vector2i:
		return Vector2i(dict.x, dict.y)
	elif dict is Dictionary:
		var clone = {}
		for key in dict.keys():
			clone[key] = deep_clone(dict[key])
		return clone
	elif dict is Array:
		var clone = []
		for el in dict:
			clone.push_back(deep_clone(el))
		return clone
	
	assert(false)

func serialize():
	var data = []
	for entity in entities:
		data.push_back(deep_clone(entity))
	return data


func deserialize(data):
	entities.clear()
	for entity in data:
		entities.push_back(deep_clone(entity))
