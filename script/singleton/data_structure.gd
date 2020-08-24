extends Node

func choose(array, amount):
	if amount == 1:
		return array[randi() % array.size()]
	var pick_lookup = {}
	var picks = []
	while pick_lookup.size() < amount:
		var pick_index = randi() % array.size()
		if not pick_lookup.has(pick_index):
			pick_lookup[pick_index] = true
			picks = array[pick_index]
	return picks
	
class QueueItem:
	var data = null
	var next = null
	var previous = null

class Queue:
	var _head;
	var _tail;
	var _size = 0
		
	func push(item):
		var link = QueueItem.new()
		link.data = item
		if _size == 0:
			_head = link
			_tail = link
		else:
			_tail.next = link
			link.previous = _tail
			_tail = link
		_size += 1
	
	func last():
		if _tail == null:
			return null
		return _tail.data
	
	func pop():
		if _size == 0:
			return null
		var result = _tail
		_tail = _tail.previous
		if _tail != null:
			_tail.next = null
		_size -= 1
		return result.data
		
	func tree():
		if _size == 0:
			return []
		var result = []
		var current = _head
		while current != null:
			result.append(current.data)
			current = current.next			
		return result
		
	func size():
		return _size

func NewQueue():
	return Queue.new()
