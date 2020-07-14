extends Node

var warnings = {}

func _default_key_handler(_node_kind, xml):
	return xml.get_named_attribute_value("name")

func _branch_key_handler(_node_kind,xml):
	return xml.get_named_attribute_value('id')

func branches(xml_path):
	return xml_to_dictionary({
		xml_path = xml_path,
		skip_node = 'branchDB',
		top_level_nodes = [
			'branch'
		],
		list_nodes = [
			'tile',
			'blocker',
			'breakable'
		],
		pre_entry_key_handler = "_branch_key_handler"
	})
	
func _crafting_recipe_key_handler(entry_data):
	return entry_data.output[0].name

func crafting_recipes(xml_path):
	return xml_to_dictionary({
		xml_path = xml_path,
		skip_node = 'craftDB',
		top_level_nodes = [
			'craft'
		],
		list_nodes = [
			'input',
			'output'
		],
		post_entry_key_handler = "_crafting_recipe_key_handler"
	})
	
func items(xml_path):
	return xml_to_dictionary({
		xml_path = xml_path,
		skip_node = 'itemDB',
		top_level_nodes = [
			'item'
		],
		list_nodes = [
			'power',			
			'secondarybuff',
			'primarybuff'
		],
		child_override_nodes = [
			'artifact'
		],
		pre_entry_key_handler = "_default_key_handler"
	})

func magic_box_rooms(xml_path):
	return xml_to_dictionary({
		xml_path = xml_path,
		skip_node = 'roomdb',
		top_level_nodes = [
			'room'
		],
		list_nodes = [
			'row',
			'element',
			'magicblocker'
		],
		pre_entry_key_handler = '_default_key_handler'
	})
	
func monsters(xml_path):
	return xml_to_dictionary({
		xml_path = xml_path,
		skip_node = 'monDB',
		top_level_nodes = [
			'monster',
		],
		list_nodes = [
			'drop',
			'onhit',
			'secondarybuff',			
			'spell'
		],
		pre_entry_key_handler = "_default_key_handler"
	})

func quest_targets(xml_path):
	return xml_to_dictionary({
		xml_path = xml_path,
		skip_node = 'questDB',
		top_level_nodes = [
			'item',
			'blocker'
		],
		pre_entry_key_handler = "_default_key_handler"
	})
	
#TODO <script> needs ability to support nested dictionaries
func rooms(xml_path):
	return xml_to_dictionary({
		xml_path = xml_path,
		skip_node = 'roomdb',
		top_level_nodes = [
			'room'
		],
		list_nodes = [
			'action',
			'condition',
			'customblocker',
			'custombreakable',
			'customengraving',
			'element',
			'horde',
			'loot',
			'monster',
			'row',		
			'script',
			'trap',				
		],
		pre_entry_key_handler = "_default_key_handler"
	})

func _skill_key_handler(node_kind,xml):
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
			'loadout',
			'primarybuff',
			'secondarybuff',
			'tag',
			'targetHitEffectBuff',
			'targetKillBuff'
		],
		pre_entry_key_handler = "_skill_key_handler"
	})

func sounds(xml_path):
	return xml_to_dictionary({
		xml_path = xml_path,
		skip_node = 'sounds',
		top_level_nodes = [
			'sound'
		],
		pre_entry_key_handler = "_default_key_handler"
	})
	
func speeches(xml_path):
	return xml_to_dictionary({
		xml_path = xml_path,
		skip_node = 'speeches',
		top_level_nodes = [
			'profile'
		],
		list_nodes = [
			'speech'
		],
		pre_entry_key_handler = "_default_key_handler"
	})

func spells(xml_path):
	return xml_to_dictionary({
		xml_path = xml_path,
		skip_node = 'spellDB',
		top_level_nodes = [
			'spell'
		],
		list_nodes = [
			'effect',
			'option',			
			'primarybuff',
			'resistbuff',
			'secondarybuff',			
			'targetHitEffectBuff'
		],
		fix_name_nodes = {
			primaryBuff = 'primarybuff'
		},
		pre_entry_key_handler = "_default_key_handler"
	})

func templates(xml_path):
	return xml_to_dictionary({
		xml_path = xml_path,
		skip_node = 'templatedb',
		top_level_nodes = [
			'template',
		],
		list_nodes = [
			'row',
		],
		pre_entry_key_handler = "_default_key_handler"
	})

func _text_key_handler(_node_kind, xml):
	if xml.has_attribute('name'):
		return xml.get_named_attribute_value('name')
	return xml.get_named_attribute_value('text')

func text(xml_path):
	return xml_to_dictionary({
		xml_path = xml_path,
		skip_node = 'text',
		top_level_nodes = [
			'adjective',
			'architecture',
			'decor',
			'firstname',
			'ichor',
			'insult',
			'material',
			'noun',
			'phoneme',
			'quality',
			'questionblock',			
			'random',
			'startPhoneme',
			'title',
			'tooltip',
			'verb',
			'wizardname',
			'wizardspiel',
			'wizardtag',
			'wizardtitle',
		],
		pre_entry_key_handler = "_text_key_handler"
	})	

func _tutorial_key_handler(entry_data):
	return entry_data.info.name
	
func tutorials(xml_path):
	return xml_to_dictionary({
		xml_path = xml_path,
		skip_node = 'tutorialfile',
		top_level_nodes = [
			'tutorial',
		],
		list_nodes = [
			'ability',
			'equip',
			'script',
			'skill',
		],
		post_entry_key_handler = "_tutorial_key_handler"
	})

# This data file doesn't fit the layout of the others.
# I prefer to keep the xml_to_dictionary simpler and have this be a one off.

func tweaks(xml_path):
	var result = {
		none = {
			lookup = {},
			list = []
		},
		easy = {
			lookup = {},
			list = []
		},
		medium = {
			lookup = {},
			list = []
		},
		hard = {
			lookup = {},
			list = []
		}
	}
	var xml_file_check = File.new()
	if ! xml_file_check.file_exists(Load.resolve(xml_path)):
		print("Unable to find referenced file [" + xml_path + "]")
	var xml = Load.xml(xml_path)
	var difficulty = 'none'
	while xml.read() == OK:
		var node_type = xml.get_node_type()
		match node_type:
			XMLParser.NODE_ELEMENT:
				var node_kind = xml.get_node_name()
				match node_kind:
					'tweak':
						var attribute_count = xml.get_attribute_count()						
						for ii in range(attribute_count):
							var attribute_name = xml.get_attribute_name(ii)
							result[difficulty].lookup[attribute_name] = xml.get_attribute_value(ii)
							result[difficulty].list.append(attribute_name)
					_:
						difficulty = node_kind
						
	return result

func xml_to_dictionary(options):
	var xml_path = options.xml_path
	var skip_node = options.skip_node if options.has('skip_node') else null
	var top_level_nodes = options.top_level_nodes if options.has('top_level_nodes') else null
	var list_nodes = options.list_nodes if options.has('list_nodes') else null
	var child_override_nodes = options.child_override_nodes if options.has('child_override_nodes') else null
	var fix_name_nodes = options.fix_name_nodes if options.has('fix_name_nodes') else null
	var pre_entry_key_handler = options.pre_entry_key_handler if options.has('pre_entry_key_handler') else null
	var post_entry_key_handler = options.post_entry_key_handler if options.has('post_entry_key_handler') else null
	
	var result = {}
	for node in top_level_nodes:
		result[node] = {
			lookup = {},
			list = []
		}
	var xml_file_check = File.new()
	if ! xml_file_check.file_exists(Load.resolve(xml_path)):
		print("Unable to find referenced file [" + xml_path + "]")
	var xml = Load.xml(xml_path)
	var entry_kind = null
	var entry_key = null
	var entry_data = {}
	while xml.read() == OK:
		var node_type = xml.get_node_type()
		match node_type:
			XMLParser.NODE_ELEMENT_END:
				pass
				#print("Close " + xml.get_node_name())
			XMLParser.NODE_ELEMENT:
				var node_kind = xml.get_node_name()
				if fix_name_nodes != null and fix_name_nodes.has(node_kind):
					node_kind = fix_name_nodes[node_kind]
				if entry_kind != null and top_level_nodes.has(node_kind):
					if post_entry_key_handler != null:
						entry_key = call(post_entry_key_handler,entry_data)
					result[entry_kind].lookup[entry_key] = entry_data.duplicate()
					result[entry_kind].list.append(entry_key)
					entry_data = {}
				if node_kind == skip_node:
					pass
				elif top_level_nodes != null and top_level_nodes.has(node_kind):
					entry_kind = node_kind
					if pre_entry_key_handler != null:
						entry_key = call(pre_entry_key_handler,node_kind,xml)
					var attribute_count = xml.get_attribute_count()						
					for ii in range(attribute_count):
						entry_data[xml.get_attribute_name(ii)] = xml.get_attribute_value(ii)
				elif list_nodes != null and list_nodes.has(node_kind):
					if ! entry_data.has(node_kind):
						entry_data[node_kind] = []
					var child = {}
					var attribute_count = xml.get_attribute_count()						
					for ii in range(attribute_count):
						child[xml.get_attribute_name(ii)] = xml.get_attribute_value(ii)
					entry_data[node_kind].append(child)
				else:
					if entry_data.has(node_kind) and (child_override_nodes == null or !child_override_nodes.has(node_kind)):
						var warning = xml_path + " should denote " + node_kind + " as a list node. Otherwise values will be overwritten and lost."
						if ! warnings.has(warning):
							print(warning +  "Second found on " + entry_key if entry_key != null else 'null')
							warnings[warning] = true
					var child = {}
					var attribute_count = xml.get_attribute_count()						
					for ii in range(attribute_count):
						child[xml.get_attribute_name(ii)] = xml.get_attribute_value(ii)
					entry_data[node_kind] = child
	# The loop exits without storing the last entry in the file
	result[entry_kind].lookup[entry_key] = entry_data.duplicate()
	result[entry_kind].list.append(entry_key)
	return result
