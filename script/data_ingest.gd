extends Node

func xml(xml_path):
	print("Ingesting " + xml_path)
	
	var result = {}
	
	var xml_file_check = File.new()
	if ! xml_file_check.file_exists(Load.resolve(xml_path)):
		print("Unable to find referenced file [" + xml_path + "]")
	var xml = Load.xml(xml_path)	
	var manual_close_nodes = {}
	while xml.read() == OK:		
		var node_type = xml.get_node_type()
		print(node_type)
		match node_type:
			XMLParser.NODE_ELEMENT_END:
				var node_kind = xml.get_node_name()
				if ! manual_close_nodes.has(node_kind):
					manual_close_nodes[node_kind] = true
	manual_close_nodes = manual_close_nodes.keys()
	print("Manual_close_nodes " + str(manual_close_nodes))
	
	var depth_queue = DataStructure.NewQueue()
	xml = Load.xml(xml_path)
	while xml.read() == OK:		
		var node_type = xml.get_node_type()
		print(node_type)
		match node_type:
			XMLParser.NODE_ELEMENT_END:
				var node_kind = xml.get_node_name()
				depth_queue.pop()
			XMLParser.NODE_ELEMENT:
				var node_kind = xml.get_node_name()
				
				var current_node = {}
				var attribute_count = xml.get_attribute_count()						
				for ii in range(attribute_count):
					var attribute_name = xml.get_attribute_name(ii)
					current_node[attribute_name] = xml.get_attribute_value(ii)
					
				var depth_tree = depth_queue.tree()
				var target_node = result
				for ii in range(depth_tree.size()):
					target_node = target_node[depth_tree[ii]]
					if typeof(target_node) == TYPE_ARRAY:
						target_node = target_node[target_node.size()-1]
				if target_node.has(node_kind):
					if typeof(target_node[node_kind]) != TYPE_ARRAY:
						target_node[node_kind] = [target_node[node_kind]]
					target_node[node_kind].append(current_node)
				else:
					target_node[node_kind] = current_node
				if manual_close_nodes.has(node_kind):
					depth_queue.push(node_kind)
			_:
				pass
	print('result ready')
	return result[result.keys()[0]]

