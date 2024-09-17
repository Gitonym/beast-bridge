class_name WaveFunctionCollapseRule
extends Node


var rule: Array


func _init(neighbours: Array):
	rule = neighbours


func equals(other: WaveFunctionCollapseRule) -> bool:
	if self == other:
		return true
	
	for z in range(3):
		for y in range(3):
			for x in range(3):
				if not rule[x][y][z].equals(other.rule[x][y][z]):
					return false
	return true
