extends Node

func choose(array, amount = 1):
	if array.size() == 0:
		return null
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
	
func merge(dict_a, dict_b):
	var result = dict_a.duplicate()
	var copy_b = dict_b.duplicate()
	for key in copy_b.keys():
		if result.has(key):
			
			if typeof(result[key]) != TYPE_ARRAY:
				var copy_a_content = result[key]
				result[key] = [copy_a_content]
			if typeof(copy_b[key]) == TYPE_ARRAY:
				result[key] += copy_b[key]
			else:
				result[key].append(copy_b[key])			
		else:
			result[key] = copy_b[key]
	return result

# Makes accessing dictionaried XML simpler, might be cleaner to move this into the data ingest
func arrayify(input):
	if typeof(input) != TYPE_ARRAY:
		return [input]
	return input

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
