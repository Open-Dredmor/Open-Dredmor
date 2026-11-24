import datetime
import json
import os
import struct
import xml.etree.ElementTree as ET


STEAM_ROOT = "airef/steam-install"
INSPECTION_DIR = "airef/inspection"
RETAIL_JSON_PATH = "airef/retail.json"
PACK_DIRS = [
    ("base", ""),
    ("expansion", "expansion"),
    ("expansion2", "expansion2"),
    ("expansion3", "expansion3"),
]


def ensure_dir(dir_path):
    if not os.path.isdir(dir_path):
        os.makedirs(dir_path, exist_ok=True)


def write_json(file_path, payload):
    with open(file_path, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, ensure_ascii=False)


def read_png_dimensions(file_path):
    try:
        with open(file_path, "rb") as handle:
            header = handle.read(24)
        if len(header) >= 24 and header[:8] == b"\x89PNG\r\n\x1a\n" and header[12:16] == b"IHDR":
            width, height = struct.unpack(">II", header[16:24])
            return width, height
    except OSError:
        return None, None
    return None, None


def read_spr_header(file_path):
    try:
        with open(file_path, "rb") as handle:
            header = handle.read(16)
        if len(header) >= 10 and header[:3] == b"SPR":
            frame_count = header[3]
            width, height, delay = struct.unpack(">HHH", header[4:10])
            return {
                "frame_count": frame_count,
                "width": width,
                "height": height,
                "delay": delay,
            }
    except OSError:
        return None
    return None


def resolve_asset_exists(asset_rel_path):
    if not asset_rel_path:
        return False
    normalized = asset_rel_path.lstrip("/")
    for _, pack_sub in PACK_DIRS:
        candidate = os.path.join(STEAM_ROOT, pack_sub, normalized) if pack_sub else os.path.join(STEAM_ROOT, normalized)
        if os.path.isfile(candidate):
            return True
    return False


def element_to_dict(elem):
    result = {"tag": elem.tag}
    if elem.attrib:
        result["attrs"] = dict(elem.attrib)
    text_val = (elem.text or "").strip()
    if text_val:
        result["text"] = text_val
    children = [element_to_dict(child) for child in list(elem)]
    if children:
        result["children"] = children
    return result


def collect_xml_schema_observations(root_elem, tag_map):
    for elem in root_elem.iter():
        entry = tag_map.setdefault(elem.tag, set())
        for attr_name in elem.attrib.keys():
            entry.add(attr_name)


def parse_xsd_schema(xsd_path):
    if not os.path.isfile(xsd_path):
        return {}
    tree = ET.parse(xsd_path)
    root = tree.getroot()
    ns = {"xs": "http://www.w3.org/2001/XMLSchema"}

    simple_types = {}
    for st in root.findall("xs:simpleType", ns):
        st_name = st.attrib.get("name", "")
        enum_vals = [
            ev.attrib.get("value")
            for ev in st.findall(".//xs:enumeration", ns)
            if "value" in ev.attrib
        ]
        restriction = st.find("xs:restriction", ns)
        simple_types[st_name] = {
            "base": restriction.attrib.get("base") if restriction is not None else None,
            "enumerations": enum_vals,
        }

    attr_groups = {}
    for ag in root.findall("xs:attributeGroup", ns):
        ag_name = ag.attrib.get("name", "")
        attrs = [
            {
                "name": attr.attrib.get("name"),
                "type": attr.attrib.get("type"),
                "use": attr.attrib.get("use"),
            }
            for attr in ag.findall("xs:attribute", ns)
        ]
        attr_groups[ag_name] = attrs

    top_elements = []
    for elem in root.findall("xs:element", ns):
        top_elements.append(elem.attrib.get("name"))

    complex_types = {}
    for ct in root.findall("xs:complexType", ns):
        ct_name = ct.attrib.get("name", "")
        attrs = [
            {
                "name": attr.attrib.get("name"),
                "type": attr.attrib.get("type"),
                "use": attr.attrib.get("use"),
            }
            for attr in ct.findall(".//xs:attribute", ns)
        ]
        complex_types[ct_name] = attrs

    return {
        "top_elements": top_elements,
        "simple_types": simple_types,
        "attribute_groups": attr_groups,
        "complex_types": complex_types,
    }


def walk_steam_files():
    manifest = []
    for dirpath, dirnames, filenames in os.walk(STEAM_ROOT):
        dirnames[:] = sorted(
            [
                dname
                for dname in dirnames
                if dname != "Dungeons of Dredmor.app"
            ]
        )
        for fname in sorted(filenames):
            if fname.endswith(".import"):
                continue
            full_path = os.path.join(dirpath, fname)
            rel_path = os.path.relpath(full_path, STEAM_ROOT)
            parts = rel_path.split(os.sep)
            pack_name = "base"
            if parts[0] in ("expansion", "expansion2", "expansion3"):
                pack_name = parts[0]
            ext = os.path.splitext(fname)[1].lstrip(".").lower()
            manifest.append(
                {
                    "path": rel_path,
                    "full_path": full_path,
                    "pack": pack_name,
                    "ext": ext,
                    "size_bytes": os.path.getsize(full_path),
                }
            )
    return manifest


def parse_items_and_encrusts(observed_tags):
    items = []
    encrusts = []
    scrolls = []
    by_pack = {}
    by_type = {}
    by_category = {}
    known_categories = (
        "weapon",
        "armour",
        "food",
        "potion",
        "wand",
        "trap",
        "toolkit",
        "gem",
        "mushroom",
        "booze",
        "components",
        "reagent",
        "ore",
        "ingot",
        "lockpick",
        "craft",
    )

    for pack_name, pack_sub in PACK_DIRS:
        item_db_path = os.path.join(STEAM_ROOT, pack_sub, "game", "itemDB.xml") if pack_sub else os.path.join(STEAM_ROOT, "game", "itemDB.xml")
        if os.path.isfile(item_db_path):
            root = ET.parse(item_db_path).getroot()
            collect_xml_schema_observations(root, observed_tags.setdefault("itemDB", {}))
            for elem in list(root):
                if elem.tag == "item":
                    attrs = dict(elem.attrib)
                    icon_file = attrs.get("iconFile", "")
                    item_type = attrs.get("type", "unknown")
                    children_list = [element_to_dict(child) for child in list(elem)]
                    child_tags = [child.tag for child in list(elem)]
                    category = "misc"
                    for cand in known_categories:
                        if cand in child_tags:
                            category = cand
                            break
                    if category == "weapon" and "thrown" in (
                        child.attrib for child in list(elem) if child.tag == "weapon"
                    ):
                        for child in list(elem):
                            if child.tag == "weapon" and "thrown" in child.attrib:
                                category = "thrown"
                                break
                    item_record = {
                        "pack": pack_name,
                        "name": attrs.get("name", ""),
                        "iconFile": icon_file,
                        "icon_exists": resolve_asset_exists(icon_file),
                        "level": attrs.get("level"),
                        "type": item_type,
                        "category": category,
                        "attrs": attrs,
                        "children": children_list,
                    }
                    items.append(item_record)
                    by_pack[pack_name] = by_pack.get(pack_name, 0) + 1
                    by_type[item_type] = by_type.get(item_type, 0) + 1
                    by_category[category] = by_category.get(category, 0) + 1
                else:
                    items.append(
                        {
                            "pack": pack_name,
                            "non_item_tag": elem.tag,
                            "attrs": dict(elem.attrib),
                            "children": [element_to_dict(child) for child in list(elem)],
                        }
                    )

        encrust_path = os.path.join(STEAM_ROOT, pack_sub, "game", "encrustDB.xml") if pack_sub else os.path.join(STEAM_ROOT, "game", "encrustDB.xml")
        if os.path.isfile(encrust_path):
            root = ET.parse(encrust_path).getroot()
            collect_xml_schema_observations(root, observed_tags.setdefault("encrustDB", {}))
            for elem in list(root):
                encrusts.append({"pack": pack_name, **element_to_dict(elem)})

        scroll_path = os.path.join(STEAM_ROOT, pack_sub, "game", "scrollDB.xml") if pack_sub else os.path.join(STEAM_ROOT, "game", "scrollDB.xml")
        if os.path.isfile(scroll_path):
            root = ET.parse(scroll_path).getroot()
            collect_xml_schema_observations(root, observed_tags.setdefault("scrollDB", {}))
            for elem in list(root):
                scrolls.append({"pack": pack_name, **element_to_dict(elem)})

    return {
        "counts": {
            "items": len(items),
            "encrusts": len(encrusts),
            "scrolls": len(scrolls),
            "by_pack": by_pack,
            "by_type": by_type,
            "by_category": by_category,
        },
        "items": items,
        "encrusts": encrusts,
        "scrolls": scrolls,
    }


def parse_crafts(observed_tags):
    crafts = []
    by_pack = {}
    by_tool = {}

    for pack_name, pack_sub in PACK_DIRS:
        craft_path = os.path.join(STEAM_ROOT, pack_sub, "game", "craftDB.xml") if pack_sub else os.path.join(STEAM_ROOT, "game", "craftDB.xml")
        if not os.path.isfile(craft_path):
            continue
        root = ET.parse(craft_path).getroot()
        collect_xml_schema_observations(root, observed_tags.setdefault("craftDB", {}))
        for elem in root.findall("craft"):
            tool_elem = elem.find("tool")
            tool_tag = tool_elem.attrib.get("tag", "") if tool_elem is not None else ""
            outputs = [dict(out.attrib) for out in elem.findall("output")]
            inputs = [dict(inp.attrib) for inp in elem.findall("input")]
            crafts.append(
                {
                    "pack": pack_name,
                    "hidden": elem.attrib.get("hidden"),
                    "tool_tag": tool_tag,
                    "inputs": inputs,
                    "outputs": outputs,
                }
            )
            by_pack[pack_name] = by_pack.get(pack_name, 0) + 1
            by_tool[tool_tag] = by_tool.get(tool_tag, 0) + 1

    return {
        "counts": {
            "crafts": len(crafts),
            "by_pack": by_pack,
            "by_tool": by_tool,
        },
        "crafts": crafts,
    }


def parse_skills(observed_tags):
    skills = []
    skills_by_id = {}
    orphan_abilities = []
    by_pack = {}
    by_type = {}

    for pack_name, pack_sub in PACK_DIRS:
        skill_path = os.path.join(STEAM_ROOT, pack_sub, "game", "skillDB.xml") if pack_sub else os.path.join(STEAM_ROOT, "game", "skillDB.xml")
        if not os.path.isfile(skill_path):
            continue
        root = ET.parse(skill_path).getroot()
        collect_xml_schema_observations(root, observed_tags.setdefault("skillDB", {}))
        for elem in root.findall("skill"):
            attrs = dict(elem.attrib)
            art_elem = elem.find("art")
            icon = art_elem.attrib.get("icon", "") if art_elem is not None else attrs.get("icon", "")
            skill_type = attrs.get("type", "unknown")
            skill_id = attrs.get("id")
            tags = [dict(tag_elem.attrib) for tag_elem in elem.findall("tag")]
            loadouts = [dict(load_elem.attrib) for load_elem in elem.findall("loadout")]
            record = {
                "pack": pack_name,
                "name": attrs.get("name", ""),
                "id": skill_id,
                "type": skill_type,
                "icon": icon,
                "icon_exists": resolve_asset_exists(icon),
                "achievement": attrs.get("achievement"),
                "description": attrs.get("description", ""),
                "art": dict(art_elem.attrib) if art_elem is not None else None,
                "tags": tags,
                "loadouts": loadouts,
                "abilities_count": 0,
                "abilities": [],
                "attrs": attrs,
            }
            skills.append(record)
            if skill_id is not None:
                skills_by_id[skill_id] = record
            by_pack[pack_name] = by_pack.get(pack_name, 0) + 1
            by_type[skill_type] = by_type.get(skill_type, 0) + 1

        for ab_elem in root.findall("ability"):
            ab_attrs = dict(ab_elem.attrib)
            ab_record = {
                "pack": pack_name,
                "attrs": ab_attrs,
                "children": [element_to_dict(child) for child in list(ab_elem)],
            }
            target_id = ab_attrs.get("skill")
            if target_id is not None and target_id in skills_by_id:
                skills_by_id[target_id]["abilities"].append(ab_record)
                skills_by_id[target_id]["abilities_count"] += 1
            else:
                orphan_abilities.append(ab_record)

    return {
        "counts": {
            "skills": len(skills),
            "total_abilities": sum(sk["abilities_count"] for sk in skills),
            "orphan_abilities": len(orphan_abilities),
            "by_pack": by_pack,
            "by_type": by_type,
        },
        "skills": skills,
        "orphan_abilities": orphan_abilities,
    }


def parse_spells(observed_tags):
    spells = []
    by_pack = {}
    by_type = {}
    effect_types = {}

    for pack_name, pack_sub in PACK_DIRS:
        spell_path = os.path.join(STEAM_ROOT, pack_sub, "game", "spellDB.xml") if pack_sub else os.path.join(STEAM_ROOT, "game", "spellDB.xml")
        if not os.path.isfile(spell_path):
            continue
        root = ET.parse(spell_path).getroot()
        collect_xml_schema_observations(root, observed_tags.setdefault("spellDB", {}))
        for elem in root.findall("spell"):
            attrs = dict(elem.attrib)
            icon = attrs.get("icon", "")
            spell_type = attrs.get("type", "unknown")
            effects = []
            for eff in elem.findall("effect"):
                eff_type = eff.attrib.get("type", "unknown")
                effect_types[eff_type] = effect_types.get(eff_type, 0) + 1
                effects.append(element_to_dict(eff))
            other_children = [
                element_to_dict(child)
                for child in list(elem)
                if child.tag != "effect"
            ]
            spells.append(
                {
                    "pack": pack_name,
                    "name": attrs.get("name", ""),
                    "type": spell_type,
                    "icon": icon,
                    "icon_exists": resolve_asset_exists(icon),
                    "attrs": attrs,
                    "effects": effects,
                    "other_children": other_children,
                }
            )
            by_pack[pack_name] = by_pack.get(pack_name, 0) + 1
            by_type[spell_type] = by_type.get(spell_type, 0) + 1

    return {
        "counts": {
            "spells": len(spells),
            "by_pack": by_pack,
            "by_type": by_type,
            "effect_types": effect_types,
        },
        "spells": spells,
    }


def parse_monsters(observed_tags):
    monsters = []
    by_pack = {}
    by_taxa = {}

    for pack_name, pack_sub in PACK_DIRS:
        mon_path = os.path.join(STEAM_ROOT, pack_sub, "game", "monDB.xml") if pack_sub else os.path.join(STEAM_ROOT, "game", "monDB.xml")
        if not os.path.isfile(mon_path):
            continue
        root = ET.parse(mon_path).getroot()
        collect_xml_schema_observations(root, observed_tags.setdefault("monDB", {}))
        for elem in root.findall("monster"):
            attrs = dict(elem.attrib)
            taxa = attrs.get("taxa", "unknown")
            children = [element_to_dict(child) for child in list(elem)]
            sprite_paths = {}
            for child in list(elem):
                if child.tag in ("idleSprite", "attackSprite", "hitSprite", "dieSprite", "castSprite"):
                    for side_key in ("left", "right", "up", "down"):
                        if side_key in child.attrib:
                            sprite_paths[f"{child.tag}.{side_key}"] = child.attrib[side_key]
            monsters.append(
                {
                    "pack": pack_name,
                    "name": attrs.get("name", ""),
                    "level": attrs.get("level"),
                    "taxa": taxa,
                    "attrs": attrs,
                    "sprite_paths": sprite_paths,
                    "children": children,
                }
            )
            by_pack[pack_name] = by_pack.get(pack_name, 0) + 1
            by_taxa[taxa] = by_taxa.get(taxa, 0) + 1

    return {
        "counts": {
            "monsters": len(monsters),
            "by_pack": by_pack,
            "by_taxa": by_taxa,
        },
        "monsters": monsters,
    }


def parse_rooms_dat(dat_path):
    if not os.path.isfile(dat_path):
        return []
    rooms = []
    current = None
    with open(dat_path, "r", encoding="utf-8", errors="replace") as handle:
        for raw_line in handle:
            line = raw_line.rstrip("\r\n")
            if not line.strip():
                if current is not None:
                    rooms.append(current)
                    current = None
                continue
            if line.startswith("N:"):
                if current is not None:
                    rooms.append(current)
                current = {"name": line[2:], "rows": [], "extra_directives": []}
            elif current is not None:
                if line.startswith("P:"):
                    current["probability"] = line[2:]
                elif line.startswith("D:"):
                    dims = line[2:].split(",")
                    if len(dims) == 2:
                        current["width"] = int(dims[0])
                        current["height"] = int(dims[1])
                elif line.startswith("S:"):
                    current["sides"] = line[2:]
                elif line.startswith("R:"):
                    current["rows"].append(line[2:])
                else:
                    current["extra_directives"].append(line)
    if current is not None:
        rooms.append(current)
    return rooms


def parse_rooms_and_world(observed_tags):
    branches = []
    rooms_xml = []
    magic_box_rooms = []
    wizard_rooms = []
    quests = []
    man_templates = []
    tweaks = []
    texts = []
    tutorials = []
    manuals = []
    speeches = []

    single_xml_targets = [
        ("branchDB", "branchDB.xml", branches),
        ("rooms", "rooms.xml", rooms_xml),
        ("magicBoxRooms", "magicBoxRooms.xml", magic_box_rooms),
        ("wizardRoomDB", "wizardRoomDB.xml", wizard_rooms),
        ("quests", "quests.xml", quests),
        ("manTemplateDB", "manTemplateDB.xml", man_templates),
        ("tweakDB", "tweakDB.xml", tweaks),
        ("text", "text.xml", texts),
        ("tutorial", "tutorial.xml", tutorials),
        ("manual", "manual.xml", manuals),
        ("speech", "speech.xml", speeches),
    ]

    for pack_name, pack_sub in PACK_DIRS:
        for obs_key, xml_name, target_list in single_xml_targets:
            xml_path = os.path.join(STEAM_ROOT, pack_sub, "game", xml_name) if pack_sub else os.path.join(STEAM_ROOT, "game", xml_name)
            if not os.path.isfile(xml_path):
                continue
            root = ET.parse(xml_path).getroot()
            collect_xml_schema_observations(root, observed_tags.setdefault(obs_key, {}))
            for elem in list(root):
                target_list.append({"pack": pack_name, **element_to_dict(elem)})

    rooms_dat = parse_rooms_dat(os.path.join(STEAM_ROOT, "game", "rooms.dat"))

    return {
        "counts": {
            "branches": len(branches),
            "rooms_xml": len(rooms_xml),
            "rooms_dat": len(rooms_dat),
            "magic_box_rooms": len(magic_box_rooms),
            "wizard_rooms": len(wizard_rooms),
            "quests": len(quests),
            "man_templates": len(man_templates),
            "tweaks": len(tweaks),
            "text_entries": len(texts),
            "tutorial_entries": len(tutorials),
            "manual_entries": len(manuals),
            "speech_entries": len(speeches),
        },
        "branches": branches,
        "rooms_xml": rooms_xml,
        "rooms_dat": rooms_dat,
        "magic_box_rooms": magic_box_rooms,
        "wizard_rooms": wizard_rooms,
        "quests": quests,
        "man_templates": man_templates,
        "tweaks": tweaks,
        "text": texts,
        "tutorial": tutorials,
        "manual": manuals,
        "speech": speeches,
    }


def parse_audio(manifest, observed_tags):
    soundfx_xml = []
    sfx_path = os.path.join(STEAM_ROOT, "game", "soundfx.xml")
    if os.path.isfile(sfx_path):
        root = ET.parse(sfx_path).getroot()
        collect_xml_schema_observations(root, observed_tags.setdefault("soundfx", {}))
        for elem in list(root):
            soundfx_xml.append(element_to_dict(elem))

    sfx_files = []
    music_files = []
    for entry in manifest:
        if entry["ext"] == "wav":
            parts = entry["path"].split(os.sep)
            category = parts[1] if len(parts) > 2 else ""
            sfx_files.append(
                {
                    "path": entry["path"],
                    "pack": entry["pack"],
                    "category": category,
                    "size_bytes": entry["size_bytes"],
                }
            )
        elif entry["ext"] == "ogg":
            music_files.append(
                {
                    "path": entry["path"],
                    "pack": entry["pack"],
                    "size_bytes": entry["size_bytes"],
                }
            )

    return {
        "counts": {
            "soundfx_xml": len(soundfx_xml),
            "wav_files": len(sfx_files),
            "ogg_files": len(music_files),
        },
        "soundfx_xml": soundfx_xml,
        "sfx_files": sfx_files,
        "music_files": music_files,
    }


def parse_sprites_and_animations(manifest):
    sprite_xmls = []
    spr_files = []
    pal_files = []

    xml_entries = [
        entry
        for entry in manifest
        if entry["ext"] == "xml" and "/game/" not in entry["path"] and not entry["path"].startswith("game/")
    ]
    spr_entries = [entry for entry in manifest if entry["ext"] == "spr"]
    pal_entries = [entry for entry in manifest if entry["ext"] == "pal"]

    total_items = len(xml_entries) + len(spr_entries) + len(pal_entries)
    processed = 0

    for entry in xml_entries:
        processed += 1
        if processed % 200 == 0 or processed == total_items:
            print(f"Sprites/Animations: {processed}/{total_items}")
        root = ET.parse(entry["full_path"]).getroot()
        frames = [
            {
                "attrs": dict(child.attrib),
                "text": (child.text or "").strip(),
            }
            for child in list(root)
        ]
        sprite_xmls.append(
            {
                "path": entry["path"],
                "pack": entry["pack"],
                "root_tag": root.tag,
                "root_attrs": dict(root.attrib),
                "frames_count": len(frames),
                "frames": frames,
            }
        )

    for entry in spr_entries:
        processed += 1
        if processed % 200 == 0 or processed == total_items:
            print(f"Sprites/Animations: {processed}/{total_items}")
        hdr = read_spr_header(entry["full_path"])
        spr_files.append(
            {
                "path": entry["path"],
                "pack": entry["pack"],
                "size_bytes": entry["size_bytes"],
                "header": hdr,
            }
        )

    for entry in pal_entries:
        processed += 1
        if processed % 200 == 0 or processed == total_items:
            print(f"Sprites/Animations: {processed}/{total_items}")
        pal_files.append(
            {
                "path": entry["path"],
                "pack": entry["pack"],
                "size_bytes": entry["size_bytes"],
            }
        )

    return {
        "counts": {
            "sprite_xmls": len(sprite_xmls),
            "spr_files": len(spr_files),
            "pal_files": len(pal_files),
        },
        "sprite_xmls": sprite_xmls,
        "spr_files": spr_files,
        "pal_files": pal_files,
    }


def parse_ui_and_assets(manifest):
    image_entries = [entry for entry in manifest if entry["ext"] in ("png", "jpg")]
    font_entries = [entry for entry in manifest if entry["ext"] == "ttf"]

    ui_assets = []
    tilesets = []
    fonts = []
    other_images_summary = {}
    ui_dir_summary = {}

    total_imgs = len(image_entries)
    for idx, entry in enumerate(image_entries, start=1):
        if idx % 2000 == 0 or idx == total_imgs:
            print(f"Images: {idx}/{total_imgs}")
        rel_path = entry["path"]
        parts = rel_path.split(os.sep)
        logical_parts = parts[1:] if parts[0] in ("expansion", "expansion2", "expansion3") else parts
        top_dir = logical_parts[0] if len(logical_parts) > 1 else ""

        width, height = (None, None)
        if entry["ext"] == "png" and top_dir in ("ui", "tilesets", "fonts", "menus", "achievements"):
            width, height = read_png_dimensions(entry["full_path"])

        if top_dir in ("ui", "menus"):
            sub_dir = logical_parts[1] if len(logical_parts) > 2 else ""
            ui_assets.append(
                {
                    "path": rel_path,
                    "pack": entry["pack"],
                    "subdir": sub_dir,
                    "width": width,
                    "height": height,
                    "size_bytes": entry["size_bytes"],
                }
            )
            bucket = f"{top_dir}/{sub_dir}" if sub_dir else top_dir
            ui_dir_summary[bucket] = ui_dir_summary.get(bucket, 0) + 1
        elif top_dir == "tilesets":
            tilesets.append(
                {
                    "path": rel_path,
                    "pack": entry["pack"],
                    "width": width,
                    "height": height,
                    "size_bytes": entry["size_bytes"],
                }
            )
        else:
            other_images_summary[top_dir] = other_images_summary.get(top_dir, 0) + 1

    for entry in font_entries:
        fonts.append(
            {
                "path": entry["path"],
                "pack": entry["pack"],
                "size_bytes": entry["size_bytes"],
            }
        )

    return {
        "counts": {
            "total_images": len(image_entries),
            "ui_and_menu_images": len(ui_assets),
            "tilesets": len(tilesets),
            "fonts": len(fonts),
            "by_top_dir": other_images_summary,
            "ui_dir_counts": ui_dir_summary,
        },
        "ui_assets": ui_assets,
        "tilesets": tilesets,
        "fonts": fonts,
    }


def main():
    ensure_dir(INSPECTION_DIR)
    print("1/9 Walking retail steam-install files...")
    manifest = walk_steam_files()
    print(f"Found {len(manifest)} non-.import files (excluding macOS app duplicate).")

    observed_tags = {}

    print("2/9 Parsing DredmorSchema.xsd...")
    xsd_schema = parse_xsd_schema(os.path.join(STEAM_ROOT, "DredmorSchema.xsd"))

    print("3/9 Parsing items, encrusts, and scrolls...")
    items_data = parse_items_and_encrusts(observed_tags)

    print("4/9 Parsing crafts...")
    crafts_data = parse_crafts(observed_tags)

    print("5/9 Parsing skills...")
    skills_data = parse_skills(observed_tags)

    print("6/9 Parsing spells...")
    spells_data = parse_spells(observed_tags)

    print("7/9 Parsing monsters...")
    monsters_data = parse_monsters(observed_tags)

    print("8/9 Parsing rooms, branches, quests, tweaks, and text...")
    world_data = parse_rooms_and_world(observed_tags)

    print("9/9 Parsing audio, sprites, UI assets, and writing outputs...")
    audio_data = parse_audio(manifest, observed_tags)
    sprites_data = parse_sprites_and_animations(manifest)
    ui_data = parse_ui_and_assets(manifest)

    observed_serializable = {
        db_name: {tag: sorted(list(attrs)) for tag, attrs in sorted(tag_dict.items())}
        for db_name, tag_dict in sorted(observed_tags.items())
    }
    schema_data = {
        "xsd": xsd_schema,
        "observed_xml_tags": observed_serializable,
    }

    manifest_clean = [
        {
            "path": entry["path"],
            "pack": entry["pack"],
            "ext": entry["ext"],
            "size_bytes": entry["size_bytes"],
        }
        for entry in manifest
    ]

    outputs = {
        "schema": ("schema.json", "Parsed DredmorSchema.xsd and all observed XML tags/attributes across all packs.", schema_data),
        "items": ("items.json", "All items (itemDB.xml), encrusts (encrustDB.xml), and scrolls (scrollDB.xml) across all packs.", items_data),
        "crafts": ("crafts.json", "All crafting recipes (craftDB.xml) across all packs.", crafts_data),
        "skills": ("skills.json", "All skill trees and abilities (skillDB.xml) across all packs.", skills_data),
        "spells": ("spells.json", "All spells and effects (spellDB.xml) across all packs.", spells_data),
        "monsters": ("monsters.json", "All monsters (monDB.xml) across all packs.", monsters_data),
        "rooms_and_world": ("rooms_and_world.json", "Branches, rooms.xml, rooms.dat, magicBoxRooms, wizardRoomDB, quests, manTemplateDB, tweakDB, text, tutorial, manual, speech.", world_data),
        "audio": ("audio.json", "soundfx.xml entries, all .wav sfx files, and all .ogg music tunes.", audio_data),
        "sprites_and_animations": ("sprites_and_animations.json", "All sprite animation XMLs, binary .spr headers, and .pal palette files.", sprites_data),
        "ui_and_assets": ("ui_and_assets.json", "All UI/menu PNGs with pixel dimensions, tilesets, fonts, and image directory counts.", ui_data),
        "files_manifest": ("files_manifest.json", "Complete file manifest of airef/steam-install (excluding .import and macOS .app duplicate).", {"total_files": len(manifest_clean), "files": manifest_clean}),
    }

    inspection_index = {}
    for key, (fname, desc, payload) in outputs.items():
        out_path = os.path.join(INSPECTION_DIR, fname)
        write_json(out_path, payload)
        inspection_index[key] = {
            "path": out_path,
            "description": desc,
            "size_bytes": os.path.getsize(out_path),
            "counts": payload.get("counts", {"total_files": payload.get("total_files")}),
        }

    ext_counts = {}
    pack_file_counts = {}
    for entry in manifest:
        ext_counts[entry["ext"]] = ext_counts.get(entry["ext"], 0) + 1
        pack_file_counts[entry["pack"]] = pack_file_counts.get(entry["pack"], 0) + 1

    simple_types = xsd_schema.get("xsd", xsd_schema).get("simple_types", {})
    attr_groups = xsd_schema.get("xsd", xsd_schema).get("attribute_groups", {})

    retail_index = {
        "generated_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "steam_install_root": STEAM_ROOT,
        "packs": {
            "base": {"subdir": "", "title": "Dungeons of Dredmor (Base Game)"},
            "expansion": {"subdir": "expansion", "title": "Realm of the Diggle Gods"},
            "expansion2": {"subdir": "expansion2", "title": "You Have To Name The Expansion Pack"},
            "expansion3": {"subdir": "expansion3", "title": "Conquest of the Wizardlands"},
        },
        "macos_bundle_note": "Dungeons of Dredmor.app/Contents/MacOS duplicates expansion/expansion2/expansion3 data and is excluded from primary counts.",
        "inspection_files": inspection_index,
        "summary": {
            "total_files": len(manifest),
            "by_pack": pack_file_counts,
            "by_extension": ext_counts,
            "items": items_data["counts"],
            "crafts": crafts_data["counts"],
            "skills": skills_data["counts"],
            "spells": spells_data["counts"],
            "monsters": monsters_data["counts"],
            "world": world_data["counts"],
            "audio": audio_data["counts"],
            "sprites": sprites_data["counts"],
            "ui_and_assets": ui_data["counts"],
        },
        "data_formats": {
            "xml_load_order": ["base", "expansion", "expansion2", "expansion3"],
            "asset_resolution": "Relative paths in XML (e.g. 'items/foo.png', 'skills/bar.png', 'sprites/monster/...') resolve relative to the pack root or base root.",
            "spr_binary_format": {
                "magic": "3 bytes 'SPR'",
                "frame_count": "1 byte uint8",
                "width": "2 bytes big-endian uint16",
                "height": "2 bytes big-endian uint16",
                "delay": "2 bytes big-endian uint16",
                "note": "Indexed pixel data with 256-color RGB palette(s) (768 bytes per palette).",
            },
            "pal_binary_format": "768 bytes raw RGB palette (256 colors x 3 bytes).",
            "rooms_dat_format": "Line-prefixed ASCII templates: N: name, P: weight, D: width,height, S: door sides (UDLR), R: row glyphs.",
        },
        "quick_lookups": {
            "damage_types": [attr["name"] for attr in attr_groups.get("damageValues", [])],
            "resistance_types": [attr["name"] for attr in attr_groups.get("resistanceValues", [])],
            "primary_buff_names": simple_types.get("primaryBuffName", {}).get("enumerations", []),
            "secondary_buff_names": simple_types.get("secondaryBuffName", {}).get("enumerations", []),
            "toolkit_tags": simple_types.get("toolkitTag", {}).get("enumerations", []),
            "skill_types": list(skills_data["counts"]["by_type"].keys()),
            "spell_types": list(spells_data["counts"]["by_type"].keys()),
            "effect_types": list(spells_data["counts"]["effect_types"].keys()),
            "monster_taxa": list(monsters_data["counts"]["by_taxa"].keys()),
            "item_types": list(items_data["counts"]["by_type"].keys()),
            "tweak_names": [tw.get("attrs", {}).get("name") for tw in world_data["tweaks"] if tw.get("attrs", {}).get("name")],
        },
    }

    write_json(RETAIL_JSON_PATH, retail_index)
    print(f"Done! Wrote {RETAIL_JSON_PATH} and {len(outputs)} files under {INSPECTION_DIR}/.")


if __name__ == "__main__":
    main()
