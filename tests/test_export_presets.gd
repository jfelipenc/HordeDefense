extends TestCase


func _presets() -> Dictionary:
	var cfg := ConfigFile.new()
	var err := cfg.load("res://export_presets.cfg")
	assert_eq(err, OK, "export_presets.cfg loads")
	var out := {}
	if err != OK:
		return out
	for section in cfg.get_sections():
		if section.begins_with("preset.") and not section.ends_with(".options"):
			out[cfg.get_value(section, "name")] = {"cfg": cfg, "section": section}
	return out


func test_windows_and_android_presets_exist() -> void:
	var p := _presets()
	assert_true(p.has("Windows Desktop"), "Windows Desktop preset")
	assert_true(p.has("Android"), "Android preset")
	if p.has("Windows Desktop"):
		assert_eq(p["Windows Desktop"].cfg.get_value(p["Windows Desktop"].section, "platform"), "Windows Desktop", "windows platform")
	if p.has("Android"):
		assert_eq(p["Android"].cfg.get_value(p["Android"].section, "platform"), "Android", "android platform")


func test_android_preset_is_a_phone_debug_build() -> void:
	var p := _presets()
	if not p.has("Android"):
		assert_true(false, "Android preset missing")
		return
	var cfg: ConfigFile = p["Android"].cfg
	var opts: String = p["Android"].section + ".options"
	assert_eq(cfg.get_value(opts, "package/unique_name"), "com.holdthehearth.game", "package id")
	assert_eq(cfg.get_value(opts, "architectures/arm64-v8a"), true, "arm64")
	assert_eq(cfg.get_value(opts, "gradle_build/use_gradle_build"), false, "plain apk template")
	assert_eq(cfg.get_value(p["Android"].section, "export_path"), "build/HoldTheHearth-debug.apk", "apk path")


func test_windows_preset_exports_to_build_dir() -> void:
	var p := _presets()
	if not p.has("Windows Desktop"):
		assert_true(false, "Windows preset missing")
		return
	assert_eq(p["Windows Desktop"].cfg.get_value(p["Windows Desktop"].section, "export_path"), "build/HoldTheHearth.exe", "exe path")
