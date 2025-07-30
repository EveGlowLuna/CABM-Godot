extends Control

@onready var character = $MainUI/Sprite2D
@onready var msgbar = $MainUI/MsgBar
@onready var animation = $MainUI/MsgBar/AnimationPlayer
@onready var character_opt = $MainUI/ToolBar/MarginContainer/HBoxContainer/OptionButton
@onready var mainui = $MainUI
@onready var historyui = $HistoryUI
@onready var histories = $HistoryUI/PanelContainer/MarginContainer/VBoxContainer/MarginContainer/ItemList

var texture
var is_returning = false
var is_finished = true
var ccfg = CharacterHelper.new()
var memerizer = Memerizer.new()

func _on_ready() -> void:
	# 这样的话，无论如何也可以从MainUI开始了
	mainui.visible = true
	historyui.visible = false
	# 对话框进入
	msgbar.position = Vector2(-350.0, 0.0)
	animation.play("dlg_in")
	# 角色相关
	# 选角色
	ccfg.select_character(ConfigManager.default_character)
	memerizer.init(ConfigManager.default_character)
	# 测试
	print(ccfg.character_data_path)
	print(ccfg.character_image_path)
	# 角色列表
	character_opt.clear()
	var chars = CharacterHelper.get_characters()
	for i in range(chars.size()):
		character_opt.add_item(chars[i])
		if chars[i] == ccfg.character_id:
			character_opt.select(i)
	
	
	# Sprite2D相关
	texture = load(ccfg.character_image_path)
	if texture is Texture2D:  # 检查是否加载成功
		character.texture = texture
		var max_height = get_viewport().size.y * (4.0 / 5.0)
		var scale_factor = max_height / texture.get_height()
		character.scale = Vector2(scale_factor, scale_factor)
		print("宽度：", character.texture.get_width() * character.scale.x)
		var width = character.texture.get_width() * character.scale.x
		print("高度", character.texture.get_height() * character.scale.y)
		character.position = Vector2(get_viewport().size.x / 2, get_viewport().size.y - max_height / 2)
		print(character.position)

func _on_color_rect_resized() -> void:
	if texture:
		var max_height = get_viewport().size.y * (4.0 / 5.0)
		var scale_factor = max_height / texture.get_height()
		character.scale = Vector2(scale_factor, scale_factor)
		print("宽度：", character.texture.get_width() * character.scale.x)
		var width = character.texture.get_width() * character.scale.x
		print("高度", character.texture.get_height() * character.scale.y)
		character.position = Vector2(get_viewport().size.x / 2, get_viewport().size.y - max_height / 2)
		print(character.position)


func add_history(content: String, chr: String):
	"""
	将历史记录添加进记忆和日志
	用户的消息可以用ConfigManager.user_name
	AI的消息用角色的英文名
	args:
		content: 对话内容
		chr: 角色（用户还是AI角色）
	"""
	histories.add_item("[%s] %s: %s" % [Time.get_datetime_string_from_system(),content,chr])
	await memerizer.add_memory(content, chr)
	
