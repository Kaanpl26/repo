extends Node
## Centralised localization.
## String tables live in res://localization/*.json as {"KEY": {"en": "...", "tr": "..."}}.
## They are loaded into Godot's TranslationServer so tr("KEY") and automatic
## Control translation work everywhere.

var tables: Array = ["ui"]   # "ui" plus one table per available case
const DIR := "res://localization/"

var keys: Dictionary = {}   # every known key -> true (used by tests)


func _ready() -> void:
	var translations := {}
	for code in Settings.LOCALES:
		var t := Translation.new()
		t.locale = code
		translations[code] = t
	var index = JSON.parse_string(FileAccess.get_file_as_string("res://data/cases/index.json"))
	for entry in index:
		if entry.get("available", false):
			tables.append(entry["id"])
	for table in tables:
		var data = JSON.parse_string(FileAccess.get_file_as_string(DIR + table + ".json"))
		if typeof(data) != TYPE_DICTIONARY:
			push_error("Localization table could not be read: " + table)
			continue
		for key in data:
			keys[key] = true
			for code in Settings.LOCALES:
				if data[key].has(code):
					translations[code].add_message(key, data[key][code])
	for code in translations:
		TranslationServer.add_translation(translations[code])
	TranslationServer.set_locale(Settings.locale if Settings.locale != "" else "en")


func has_key(key: String) -> bool:
	return keys.has(key)
