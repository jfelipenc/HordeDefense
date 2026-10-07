extends TestCase

func test_portrait_base_resolution() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 1080, "width")
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 1920, "height")

func test_stretch_settings() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items", "stretch mode")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "keep_height", "aspect")

func test_mobile_renderer() -> void:
	assert_eq(ProjectSettings.get_setting("rendering/renderer/rendering_method"), "mobile", "renderer")

func test_portrait_orientation() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/handheld/orientation"), 1, "portrait")

func test_etc2_astc_import_enabled_for_android() -> void:
	assert_eq(ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc"), true, "etc2/astc")
