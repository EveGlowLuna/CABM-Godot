extends CodeEdit

func _ready() -> void:
	var highlighter = create_ini_highlighter()
	self.syntax_highlighter = highlighter
	_load_conf()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_S and event.is_command_or_control_pressed():
			accept_event()
			_save_conf()

func _load_conf():
	var file = FileAccess.open("user://config/config.cfg", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		self.text = content
		print("成功加载配置文件")
	else:
		self.editable = false
		self.text = "加载配置文件失败，请前往C:\\Users\\您的用户名\\AppData\\Roaming\\Godot\\app_userdata\\CABM删除所有文件，然后重试。"
		print("加载配置文件失败")

func _save_conf():
	var text = self.text
	var file = FileAccess.open("user://config/config.cfg", FileAccess.WRITE)
	
	if file:
		file.store_string(text)
		file.close()
	else:
		print("保存失败")

func create_ini_highlighter() -> CodeHighlighter:
	var highlighter := CodeHighlighter.new()
	
	# 定义颜色
	var color_section := Color("#CE917D")    # 棕色 - [section]
	var color_key := Color("#98C379")        # 绿色 - key
	var color_value := Color("#E5C07B")      # 黄色 - value
	var color_string := Color("#CE917D")     # 棕色 - 字符串（和节名同色）
	var color_comment := Color("#7F848E")   # 灰色 - 注释
	var color_equals := Color("#ABB2BF")    # 浅灰 - =
	var color_default := Color("#FFFFFF")   # 默认白色文本
	
	# 0. 默认文本颜色（防止其他规则漏匹配）
	highlighter.add_color_region("", "", color_default, false)  # 全局默认
	
	# 1. 字符串（双引号包裹的内容，优先匹配）
	highlighter.add_color_region('"', '"', color_string, false)  # 不跨行
	
	# 2. 注释（# 或 ; 开头）
	highlighter.add_color_region("#", "", color_comment, false)  # 到行末
	highlighter.add_color_region(";", "", color_comment, false)  # 到行末
	
	# 3. 节名 [section]
	highlighter.add_color_region("[", "]", color_section, false)  # 不跨行
	
	# 4. 键名（等号左边）
	# 由于无法直接匹配非等号内容，这里用 `add_keyword_color` 手动标记常见键名
	# 或者接受部分限制（比如键名不能含 =#;）
	highlighter.add_color_region("", "=", color_key, false)  # 到第一个 = 为止
	
	# 5. 等号单独高亮
	highlighter.add_keyword_color("=", color_equals)
	
	# 6. 值（等号右边到行末，但排除注释）
	highlighter.add_color_region("=", "\n", color_value, false)
	
	return highlighter
