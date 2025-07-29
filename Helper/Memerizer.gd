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
		if FileAccess.file_exists("res://data/memories/%d" % self.character):
			var file = FileAccess.open("res://data/memories/%d" % self.character, FileAccess.READ)
			if file == null:
				return []
			else:
				var json_text = file.get_as_text()
				file.close()
				
				var json = JSON.new()
				var parse_result = json.parse(json_text)
				if parse_result != OK:
					return []
				var results: Array
				var k: int
				for item in json.data:
					if keyword.has("keyword") and item["keyword"] is Array:
						if keyword in item["keyword"]:
							results.append(item)
							k += 1
							if k == 5:
								break
				if results == null:
					return []
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

var character:String


func init(character:String,):
	self.character = character
