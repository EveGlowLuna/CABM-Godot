extends Control
"""
使用方法：
非流式输出：
```python
var messages = [
	{"role": "system", "content": "你是一个乐于助人的AI助手"},
	{"role": "user", "content": "你好，请介绍一下你自己"}
]
var response = await get_complete_response(messages)
print("AI回复: ", response) 
# 带自定义参数
var custom_response = await get_complete_response(
	messages, 
	"custom-model", 
	0.5,  # 温度
	1024  # 最大token数量
)
```
流式输出：
var messages = [
	{"role": "system", "content": "你是一个乐于助人的AI助手"},
	{"role": "user", "content": "你好，请介绍一下你自己"}
	]

# 定义回调函数
var callback = func(chunk: String):
	print("收到部分响应: ", chunk)
	# 这里可以实时更新UI

get_stream_response(messages, callback)

# 带自定义参数
get_stream_response(
	messages,
	callback,
	"custom-model",  # model
	0.5,            # temperature
	1024            # max_tokens
)

"""

# 非流式输出 - 一次性获取完整响应
func get_complete_response(messages: Array, model: String = ConfigManager.chat_model, temperature: float = 0.7, max_tokens: int = 2048) -> String:
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer %s" % ConfigManager.api_key
	]
	
	var body = {
		"model": model,
		"messages": messages,
		"temperature": temperature,
		"max_tokens": max_tokens,
		"stream": false
	}
	
	var http_request = HTTPRequest.new()
	get_tree().root.add_child(http_request)
	
	var error = http_request.request(
		ConfigManager.base_url,  # 直接使用base_url，不添加额外路径
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(body)
	)
	
	if error != OK:
		http_request.queue_free()
		return "HTTP请求创建失败: %s" % error
	
	var result = await http_request.request_completed
	http_request.queue_free()
	
	var response = result[3]
	var json = JSON.new()
	json.parse(response.get_string_from_utf8())
	var response_data = json.get_data()
	
	if response_data.has("error"):
		return "API错误: " + response_data.error.message
	
	return response_data.choices[0].message.content


# 流式输出 - 逐块获取响应
