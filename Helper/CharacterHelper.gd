extends Node
class_name CharacterHelper

var character_name: String
var character_id: String
var character_image_path: String
var character_data_path: String
var character_description: String
var character_prompt: String
var wel_msg: String

func select_character(character: String):
	self.character_name = character
	if FileAccess.file_exists("user://characters/%s.json" % self.character_name):
		var file = FileAccess.open("user://characters/%s.json" % self.character_name, FileAccess.READ)
		if file != null:
			var file_text = file.get_as_text()
			var json = JSON.new()
			var err = json.parse(file_text)
			if err == OK:
				var data = json.data
				if data is Dictionary:
					self.character_name = data["NAME"]
					self.character_id = data["ID"]
					self.character_image_path = "user://data/images/%s" % data["IMAGE"]
					self.character_data_path = "user://data/memories/%s.json" % data["ID"]
					self.wel_msg = data["WELCOME_MESSAGE"]

func generate_prompt(msg: String, usr_name = ConfigManager.user_name) -> Array:
	return [
		{"role": "system", "content": "你现在正在参与一场沉浸式视觉小说（GalGame）式互动。你的名字是%s（%s），%s，聊天的对象是%s请根据最近的10条消息和通过关键词集成的聊天记录，来生成回答。注意：\n%s\n%s\n接下来是最近的10条聊天记录和通过关键词搜索到的聊天记录。\n%s" % [self.character_name,self.character_description,self.character_prompt,ConfigManager.user_name,ConfigManager.default,ConfigManager.importance,await Memerizer.new().init(character_id).get_memory()]},
		{"role": "user", "content": msg}
	]
	
static func get_characters(directory_path: String = "user://characters/") -> Array:
	var filenames: Array[String] = []
	
	# 打开目录
	var dir = DirAccess.open(directory_path)
	if not dir:
		push_error("无法打开目录: " + directory_path)
		return filenames
	
	# 遍历目录
	dir.list_dir_begin()  # 开始遍历
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			# 移除.json后缀并添加到数组
			filenames.append(file_name.trim_suffix(".json"))
		file_name = dir.get_next()
	dir.list_dir_end()  # 结束遍历
	
	return filenames
