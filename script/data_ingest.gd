extends Node

func xml(xml_path):
	print("Ingesting " + xml_path)
	
	var result = {}
		
	var xml = Load.xml(xml_path)	
	var manual_close_nodes = {}
	var reading = true
	var err
	
	while reading:		
		var node_type = xml.get_node_type()
		match node_type:
			XMLParser.NODE_ELEMENT_END:
				var node_kind = xml.get_node_name()
				if ! manual_close_nodes.has(node_kind):
					manual_close_nodes[node_kind] = 1
				else:
					manual_close_nodes[node_kind] = manual_close_nodes[node_kind] + 1
		err = xml.read()
		if err != OK:
			if err != ERR_FILE_EOF:
				print("An error occurred while reading XML: "+str(err))
			reading = false
	manual_close_nodes = manual_close_nodes.keys()
	
	xml.seek(0)
	var depth_queue = DataStructure.NewQueue()	
	reading = true
	err = null
	while reading:		
		var node_type = xml.get_node_type()		
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
		err = xml.read()
		if err != OK:
			reading = false	
	return result

