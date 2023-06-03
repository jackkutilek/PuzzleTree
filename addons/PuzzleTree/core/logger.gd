extends Node

var log_level:int = 0

func log(level:int, message: String):
	if log_level >= level:
		print(message)
