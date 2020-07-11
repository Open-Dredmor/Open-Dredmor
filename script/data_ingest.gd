extends Node

func skills(xml_path):
	var result = {
		skills = {
			lookup = {},
			list = []
		},
		abilities = {
			lookup = {},
			list = []
		}
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
				if (node_kind == "skill" or node_kind == "ability") and entry_kind != null:
					result[entry_kind].lookup[entry_key] = entry_data.duplicate()
					result[entry_kind].list.append(entry_key)
					entry_data = {}
				match node_kind:
					"skill":						
						entry_kind = "skills"
						entry_key = xml.get_named_attribute_value("id")
						var attribute_count = xml.get_attribute_count()						
						for ii in range(attribute_count):
							entry_data[xml.get_attribute_name(ii)] = xml.get_attribute_value(ii)
					"ability":
						entry_kind = "abilities"
						entry_key = xml.get_named_attribute_value("name")
						var attribute_count = xml.get_attribute_count()						
						for ii in range(attribute_count):
							entry_data[xml.get_attribute_name(ii)] = xml.get_attribute_value(ii)
					"secondarybuff","tag":
						if ! entry_data.has(node_kind):
							entry_data[node_kind] = []
						var child = {}
						var attribute_count = xml.get_attribute_count()						
						for ii in range(attribute_count):
							child[xml.get_attribute_name(ii)] = xml.get_attribute_value(ii)
						entry_data[node_kind].append(child)
					_:
						var child = {}
						var attribute_count = xml.get_attribute_count()						
						for ii in range(attribute_count):
							child[xml.get_attribute_name(ii)] = xml.get_attribute_value(ii)
						entry_data[node_kind] = child
									
				continue
			XMLParser.NODE_TEXT:
				continue
			_:
				continue			
	print("There is probably an orphaned skill or ability that now needs to be added")
	return result
