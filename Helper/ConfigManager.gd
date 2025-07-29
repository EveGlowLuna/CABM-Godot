extends Node

#[chat_config]
var chat_model = "deepseek-ai/DeepSeek-V3"
var assistant_model = "Qwen/Qwen3-8B"
var max_tokens = 4096
var top_k = 5
var temperature = 1.0
var stream = true

#[stream_config]
var pause_on_paragraph = true
var paragraph_delimiters = ["。", ".", "！", "!", "？", "?"]
var buffer_size = 1024
var continue_prompt = "点击屏幕继续"
var enable_streaming = true

#[image_config]
var image_model = "Kwai-Kolors/Kolors"
var image_size = "1024x1024"
var batch_size = 1
var num_inference_steps = 20
var guidance_scale = 7.5

# [user_config]
var user_name = "落阳"

#[system_prompts]
var default = "你需要用一段话（1到5句话）回复用户，禁止换行，禁止使用markdown。每**句**话的开头需要用【】加上当前的心情，且必须是其中之一，**只写序号**：1.平静 2.兴奋 3.愤怒 4.失落"

#[image_prompts]
var prompt = ["繁星点缀的夜空下，一片宁静的湖泊倒映着群山和森林，远处有篝火和小屋",
	"阳光透过云层，照耀在广阔的草原上，野花盛开，远处有山脉和小溪",
	"雪花飘落的冬日森林，松树覆盖着白雪，小路蜿蜒，远处有小木屋和炊烟",
	"雨后的城市街道，霓虹灯反射在湿润的路面上，行人撑着伞，远处是城市天际线",
	"一间温馨的二次元风格卧室，阳光透过薄纱窗帘洒在木地板上,床上散落着卡通抱枕，墙边有摆满书籍和手办的原木色书架.书桌上亮着一盏小台灯，电脑屏幕泛着微光，窗外隐约可见樱花树。画面线条柔和，色彩清新，带有动画般的细腻阴影和高光。",
	]

#[app_config]
var max_history_length = 4

func _ready() -> void:
	get_config()

#[api_config]
var base_url = ""
var api_key = ""

func save_config() -> void:
	var config = ConfigFile.new()
	
	# 将各个配置节保存到 ConfigFile 对象中
	# [chat_config]
	config.set_value("chat_config", "chat_model", chat_model)
	config.set_value("chat_config", "assistant_model", assistant_model)
	config.set_value("chat_config", "max_tokens", max_tokens)
	config.set_value("chat_config", "top_k", top_k)
	config.set_value("chat_config", "temperature", temperature)
	config.set_value("chat_config", "stream", stream)
	
	# [stream_config]
	config.set_value("stream_config", "pause_on_paragraph", pause_on_paragraph)
	config.set_value("stream_config", "paragraph_delimiters", paragraph_delimiters)
	config.set_value("stream_config", "buffer_size", buffer_size)
	config.set_value("stream_config", "continue_prompt", continue_prompt)
	config.set_value("stream_config", "enable_streaming", enable_streaming)
	
	# [image_config]
	config.set_value("image_config", "image_model", image_model)
	config.set_value("image_config", "image_size", image_size)
	config.set_value("image_config", "batch_size", batch_size)
	config.set_value("image_config", "num_inference_steps", num_inference_steps)
	config.set_value("image_config", "guidance_scale", guidance_scale)
	
	# [user_config]
	config.set_value("user_config", "user_name", user_name)
	
	# [system_prompts]
	config.set_value("system_prompts", "default", default)
	
	# [image_prompts]
	config.set_value("image_prompts", "prompt", prompt)
	
	
	# [app_config]
	config.set_value("app_config", "max_history_length", max_history_length)
	
	# [api_config]
	config.set_value("api_config", "base_url", base_url)
	config.set_value("api_config", "api-key", api_key)
	
	# 保存到文件
	var err = config.save("res://config/config.cfg")
	if err != OK:
		push_error("Failed to save config file: %s" % error_string(err))

func get_config() -> void:
	var config = ConfigFile.new()
	
	# 加载配置文件
	var err = config.load("res://config/config.cfg")
	if err != OK:
		push_error("Failed to load config file: %s" % error_string(err))
		return
	
	# 从 ConfigFile 对象中读取各个配置节
	# [chat_config]
	chat_model = config.get_value("chat_config", "chat_model", chat_model)
	assistant_model = config.get_value("chat_config", "assistant_model", assistant_model)
	max_tokens = config.get_value("chat_config", "max_tokens", max_tokens)
	top_k = config.get_value("chat_config", "top_k", top_k)
	temperature = config.get_value("chat_config", "temperature", temperature)
	stream = config.get_value("chat_config", "stream", stream)
	
	# [stream_config]
	pause_on_paragraph = config.get_value("stream_config", "pause_on_paragraph", pause_on_paragraph)
	paragraph_delimiters = config.get_value("stream_config", "paragraph_delimiters", paragraph_delimiters)
	buffer_size = config.get_value("stream_config", "buffer_size", buffer_size)
	continue_prompt = config.get_value("stream_config", "continue_prompt", continue_prompt)
	enable_streaming = config.get_value("stream_config", "enable_streaming", enable_streaming)
	
	# [image_config]
	image_model = config.get_value("image_config", "image_model", image_model)
	image_size = config.get_value("image_config", "image_size", image_size)
	batch_size = config.get_value("image_config", "batch_size", batch_size)
	num_inference_steps = config.get_value("image_config", "num_inference_steps", num_inference_steps)
	guidance_scale = config.get_value("image_config", "guidance_scale", guidance_scale)
	
	# [user_config]
	user_name = config.get_value("user_config", "user_name", user_name)
	
	# [system_prompts]
	default = config.get_value("system_prompts", "default", default)
	
	# [image_prompts]
	prompt = config.get_value("image_prompts", "prompt", prompt)
	
	
	# [app_config]
	max_history_length = config.get_value("app_config", "max_history_length", max_history_length)
	
	# [api_config]
	base_url = config.get_value("api_config", "base_url", base_url)
	api_key = config.get_value("api_config", "api-key", api_key)
