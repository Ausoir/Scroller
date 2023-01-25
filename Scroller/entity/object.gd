extends Node2D

var item_name
var col: int = 0
var dat

func is_col(bit):
	return col & bit > 0

func get_type():
	return -1
