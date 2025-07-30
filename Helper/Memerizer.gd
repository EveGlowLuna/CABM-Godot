extends Node
class_name Memerizer

class Scanner:
	var result = []
	var model = ""
	var message = {}
	var character = ""
	
	func init(content: String, character: String, top_k: int = ConfigManager.top_k, model: String = ConfigManager.assistant_model):
		self.character = character
		self.message = [
			{
				"role": "system",
				"content": "任务：从用户句子中提取关键词。要求：只返回JSON数组，关键词可以来自用户输入，也可以是总结。示例：[\"天气\", \"公园\", \"预约\"]"
			},
			{
				"role": "user",
				"content": content
			}
		]
	
	func scan_memory() -> Array:
		var keyword = await self.get_scan_keyword()
		if FileAccess.file_exists("res://data/memories/%s" % self.character):
			var file = FileAccess.open("res://data/memories/%s" % self.character, FileAccess.READ)
			if file == null:
				return []
			else:
				var json_text = file.get_as_text()
				file.close()
				
				var json = JSON.new()
				var parse_result = json.parse(json_text)
				if parse_result != OK:
					return []
				var results: Array = []
				var k: int = 0
				for item in json.data:
					if keyword.has("keyword") and item["keyword"] is Array:
						if keyword in item["keyword"]:
							results.append(item)
							k += 1
							if k == ConfigManager.top_k:
								break
				return results
		else:
			return []
				
	
	func get_scan_keyword() -> Array:
		var response = JSON.parse_string(await ChatServiceHelper.get_complete_response(self.message, self.model))
		# 检查解析是否成功
		if response == null:
			print("JSON解析失败，当前值: ", response)
			return []
		else:
			# 确保返回的是数组
			if typeof(response) == TYPE_ARRAY:
				return response
			else:
				print("返回的不是数组: ", response)
				return []

var character: String
var data_path: String

func init(char: String):
	self.character = char
	self.data_path = "user://data/memories/%s.json" % self.character

func change_char(char: String):
	self.character = char
	self.data_path = "user://data/memories/%s.json" % self.character

# === 修改点1：add_memory 增加 role 参数 ===
func add_memory(content: String, role: String = "user", associated_keywords: Array = []) -> bool:
	# 1. 调用AI提取关键词（复用Scanner的逻辑）
	var scanner = Scanner.new()
	scanner.init(content, self.character)
	var ai_keywords = await scanner.get_scan_keyword()
	
	# 2. 合并关键词
	var all_keywords = []
	if ai_keywords is Array:
		all_keywords.append_array(ai_keywords)
	if associated_keywords is Array:
		all_keywords.append_array(associated_keywords)
	
	# 3. 构建记忆数据（新增 role 字段）
	var memory_data = {
		"timestamp": Time.get_unix_time_from_system(),
		"content": content,
		"keywords": all_keywords,
		"character": self.character,
		"role": role  # 新增：记录是用户说的还是角色说的
	}
	
	# 4. 追加到存储
	return await dynamic_append_data(memory_data)

# 动态追加数据的增强版方法
func dynamic_append_data(new_data: Dictionary, max_retries: int = 3) -> bool:
	var retry_count = 0
	var success = false
	
	while retry_count < max_retries and not success:
		# 1. 准备文件路径
		var dir_path = self.data_path.get_base_dir()
		if not DirAccess.dir_exists_absolute(dir_path):
			DirAccess.make_dir_recursive_absolute(dir_path)
		
		# 2. 读取现有数据（带文件锁）
		var existing_data = []
		var file = FileAccess.open(self.data_path, FileAccess.READ)
		if file != null:
			var json = JSON.new()
			var parse_result = json.parse(file.get_as_text())
			if parse_result == OK and json.data is Array:
				existing_data = json.data
			file.close()
		
		# 3. 追加新数据
		existing_data.append(new_data)
		
		# 4. 原子化写入（临时文件+重命名）
		var temp_path = self.data_path + ".tmp"
		var save_file = FileAccess.open(temp_path, FileAccess.WRITE)
		if save_file != null:
			save_file.store_string(JSON.stringify(existing_data, "\t"))
			save_file.close()
			
			# 5. 文件替换操作
			if FileAccess.file_exists(self.data_path):
				DirAccess.remove_absolute(self.data_path)
			success = DirAccess.rename_absolute(temp_path, self.data_path) == OK
		
		if not success:
			retry_count += 1
			await get_tree().create_timer(0.1 * retry_count).timeout # 指数退避
	
	return success

# === 修改点2：get_memory 返回的记忆带上 role ===
func get_memory(content: String = "") -> String:
	var result := PackedStringArray()
	
	# 获取最后10条记忆并格式化为字符串
	if FileAccess.file_exists(self.data_path):
		var file = FileAccess.open(self.data_path, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK and json.data is Array:
				var recent_memories = json.data.slice(-10 if json.data.size() > 10 else -json.data.size())
				for memory in recent_memories:
					var timestamp_str = _format_timestamp(memory.get("timestamp", 0))
					var role = memory.get("role", "unknown")
					var content_str = memory.get("content", "")
					result.append("[%s][%s] %s" % [timestamp_str, role.capitalize(), content_str])
			file.close()
	
	# 扫描关联记忆
	if content != "":
		var scanner = Scanner.new()
		scanner.init(content, self.character)
		var scanned_memories = await scanner.scan_memory()
		if not scanned_memories.is_empty():
			result.append("\n[相关记忆]")
			for memory in scanned_memories:
				var role = memory.get("role", "unknown")
				var content_str = memory.get("content", "")
				result.append("→ [%s] %s" % [role.capitalize(), content_str])
	
	return "\n".join(result) if not result.is_empty() else "暂无记忆"

# 时间戳转可读格式
func _format_timestamp(timestamp: int) -> String:
	var dt = Time.get_datetime_dict_from_unix_time(timestamp)
	return "%02d-%02d %02d:%02d" % [dt.month, dt.day, dt.hour, dt.minute]
