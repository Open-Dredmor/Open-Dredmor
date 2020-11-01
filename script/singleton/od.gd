extends Node

var ActionQueue
var Assets
var Actions
var Audio
var Chrome
var Database
var DataStructure
var DungeonSettings
var EventLog
var GameDataKind
var Load
var Log
var Math
var Resource
var Scenes
var Settings


func reset():
	ActionQueue = load('res://script/singleton/action_queue.gd').new()
	Actions = load('res://script/instance/action/actions.gd').new()
	Math = load('res://script/singleton/od_math.gd').new()
