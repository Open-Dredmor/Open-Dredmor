extends Control

static func init_container():
	return Control.new()

const RANDOM_NAMES = [
	"Eyebrows",
	"Krong",
	"Lutefisk",
	"Diggle",
	"Brax",
	"Mordred",
	"Zorkmid",
	"Gorgon"
]

func _ready():
	call_deferred("_bootstrap_and_launch")

func _bootstrap_and_launch():
	if OD.Loading != null:
		await OD.Loading.step("Initializing audio...", 8.0)
	OD.Audio.setup(get_tree().get_root())
	await OD.Database.ingest_async(12.0, 65.0)
	if OD.Loading != null:
		await OD.Loading.step("Rolling random character & skills...", 72.0)
	OD.DungeonSettings.reset()
	OD.DungeonSettings.set_debug_teleport(true)

	var heroes = ["hero", "heroine"]
	OD.DungeonSettings.set_hero(heroes[randi() % heroes.size()])
	OD.DungeonSettings.set_character_name(RANDOM_NAMES[randi() % RANDOM_NAMES.size()])

	var all_skills = OD.Database.character_creation_skill_list()
	var chosen_skills = OD.DataStructure.choose(all_skills, min(7, all_skills.size()))
	var skill_ids = []
	for skill in chosen_skills:
		skill_ids.append(skill.id)
	OD.DungeonSettings.set_starting_skill_ids(skill_ids)

	if OD.Loading != null:
		await OD.Loading.step("Entering the dungeon...", 78.0)
	OD.Scenes.goto(OD.Scenes.GAME)
