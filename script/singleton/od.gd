extends Node

var ActionQueue
var Animation
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
var Rect
var Resource
var Scenes
var Settings


func _singleton(file):
	var node = load('res://script/singleton/' + file + '.gd').new()
	node.name = file
	add_child(node)
	return node

func reset():
	DungeonSettings = _singleton('dungeon_settings')
	DungeonSettings.reset()
	Settings = _singleton('settings')
	ActionQueue = _singleton('action_queue')
	Actions = load('res://script/instance/action/actions.gd').new()
	Actions.name = 'actions'
	add_child(Actions)
	Animation = load('res://script/instance/animation/animation.gd')
	Assets = _singleton('assets')
	Audio = _singleton('audio')
	Chrome = _singleton('chrome')
	Database = _singleton('database')
	DataStructure = _singleton('data_structure')	
	EventLog = _singleton('event_log')
	GameDataKind = _singleton('game_data_kind')
	Load = _singleton('load')
	Log = _singleton('log')
	Math = _singleton('math')
	Rect = load('res://script/instance/rect.gd')
	Resource = _singleton('resource')
	Scenes = _singleton('scenes')	
