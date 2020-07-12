extends Node

func _skill_entry_key_handler(node_kind,xml):
	match node_kind:
		"skill":
			return xml.get_named_attribute_value("id")
		"ability":
			return xml.get_named_attribute_value("name")
		_:
			print("_skill_entry_key Unhandled node_kind " + node_kind)
			return null
			
func skills(xml_path):
	return xml_to_dictionary({
		xml_path = xml_path,
		skip_node = 'skillDB',
		top_level_nodes = [
			'skill',
			'ability'
		],
		list_nodes = [
			'secondarybuff',
			'tag'
		],
		pre_entry_key_handler = "_skill_entry_key_handler"
	})
	
func _crafting_recipe_entry_key_handler(entry_data):
	return entry_data.output.name

func crafting_recipes(xml_path):
	return xml_to_dictionary({
		xml_path = xml_path,
		skip_node = 'craftDB',
		top_level_nodes = [
			'craft'
		],
		list_nodes = [
			'input'
		],
		post_entry_key_handler = "_crafting_recipe_entry_key_handler"
	})
			

func xml_to_dictionary(options):
	var xml_path = options.xml_path
	var skip_node = options.skip_node if options.has('skip_node') else null
	var top_level_nodes = options.top_level_nodes if options.has('top_level_nodes') else null
	var list_nodes = options.list_nodes if options.has('list_nodes') else null
	var pre_entry_key_handler = options.pre_entry_key_handler if options.has('pre_entry_key_handler') else null
	var post_entry_key_handler = options.post_entry_key_handler if options.has('post_entry_key_handler') else null
	
	var result = {}
	for node in top_level_nodes:
		result[node] = {
			lookup = {},
			list = []
		}
	var xml = Load.xml(xml_path)
	var entry_kind = null
	var entry_key = null
	var entry_data = {}
	while xml.read() == OK:
		var node_type = xml.get_node_type()
		match node_type:
			XMLParser.NODE_ELEMENT:
				var node_kind = xml.get_node_name()
				if entry_kind != null and top_level_nodes.has(node_kind):
					if post_entry_key_handler != null:
						entry_key = call(post_entry_key_handler,entry_data)
					result[entry_kind].lookup[entry_key] = entry_data.duplicate()
					result[entry_kind].list.append(entry_key)
					entry_data = {}
				if node_kind == skip_node:
					pass
				elif top_level_nodes.has(node_kind):
					entry_kind = node_kind
					if pre_entry_key_handler != null:
						entry_key = call(pre_entry_key_handler,node_kind,xml)
					var attribute_count = xml.get_attribute_count()						
					for ii in range(attribute_count):
						entry_data[xml.get_attribute_name(ii)] = xml.get_attribute_value(ii)
				elif list_nodes.has(node_kind):
					if ! entry_data.has(node_kind):
						entry_data[node_kind] = []
					var child = {}
					var attribute_count = xml.get_attribute_count()						
					for ii in range(attribute_count):
						child[xml.get_attribute_name(ii)] = xml.get_attribute_value(ii)
					entry_data[node_kind].append(child)
				else:
					var child = {}
					var attribute_count = xml.get_attribute_count()						
					for ii in range(attribute_count):
						child[xml.get_attribute_name(ii)] = xml.get_attribute_value(ii)
					entry_data[node_kind] = child
	# The loop exits without storing the last entry in the file
	result[entry_kind].lookup[entry_key] = entry_data.duplicate()
	result[entry_kind].list.append(entry_key)
	return result
