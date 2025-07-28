extends Node
class_name ImageService


class ImageConfig:
	"""
	图像生成服务
	
	变量：
		model:模型
		prompt:提示词
		image_size:图像尺寸
		batch_size:生成数量(你的意思是他免费你就能为所欲为是吧)
		num_inference_steps:推理步数
		guidance_scale:引导比例
		nagative_prompt:负面提示词
		seed:随机种子
	"""
	var model: String
	var prompt: String
	var image_size: String
	var batch_size: int
	var num_inference_steps: int
	var guidance_scale: float
	var seed: int
	
	func _init(
		prompt: String = "",
		image_size: String = "",
		batch_size: int = -1,
		num_inference_steps: int = -1,
		guidance_scale: float = -1.0,
		seed: int = -1,
	):
		self.model = ConfigManager.image_model
		self.prompt = prompt if prompt else ConfigManager.prompt.pick_random()
		self.image_size = image_size if image_size else ConfigManager.image_size
		self.batch_size = batch_size if batch_size != -1 else ConfigManager.batch_size
		self.num_inference_steps = num_inference_steps if num_inference_steps != -1 else ConfigManager.num_inference_steps
		self.guidance_scale = guidance_scale if guidance_scale != -1.0 else ConfigManager.guidance_scale
		self.seed = seed if seed != -1 else randi()
	
	func todict() -> Dictionary:
		return {
			model: self.model,
			prompt: self.prompt,
			image_size: self.image_size,
			batch_size: self.batch_size,
			num_inference_steps: self.num_inference_steps,
			guidance_scale: self.guidance_scale,
			seed: self.seed,
		}

var cache_dir: String = "res://image_cache/"
var cur_background: String = ""

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(cache_dir)

func generate_image(config = null):
	if config == null:
		config = ImageConfig.new().todict()
	
	var headers = {
		"Authorization": "Bearer %s" % ConfigManager.api_key,
		"Content-Type": "application/json"
	}
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var error = http_request.request(
		ConfigManager.base_url,
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(config)
	)
	if error != OK:
		return handle_generation_error("发送请求失败")
	var result = await http_request.request_completed
	var response_code = result[1]
	var body = result[3]
	
	if response_code != 200:
		return handle_generation_error("API错误，状态码： %d" % response_code)
	
	var json = JSON.new()
	var parse_error = json.parse(body.get_string_from_utf8())
	if parse_error != OK:
		return handle_generation_error("响应解析失败")
	var data = json.get_data()
		
	if not data.has("images") or data["images"].is_empty():
		return handle_generation_error("响应中没有图像数据")
	
	var image_url = data["images"][0]["url"]
	var image_path = await download_image(image_url)
	if image_path.is_empty():
		return handle_generation_error("图像下载失败")
	
	cur_background = image_path
	
	return {
		"success": true,
		"image_path": image_url,
		"config": config,
		"seed": data.get("seed", config.get("seed", 0))
	}
		
func handle_generation_error(reason: String):
	var res = get_fallback_image()
	if get_fallback_image() != null:
		return res

func get_fallback_image():
	var image_files = get_files_from_directories(["res://caches/imgcache"])
	if image_files.size() < 1:
		return null
	else:
		return image_files.pick_random()

func download_image(url: String) -> String:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var error = http_request.request(url)
	if error != OK:
		return ""
	
	var result = await http_request.request_completed
	if result[1] != 200:
		return ""
	
	# 保存图像到缓存目录
	var cache_dir = "res://caches/imgcache"
	DirAccess.make_dir_recursive_absolute(cache_dir)
	
	var filename = "image_%s.png" % Time.get_unix_time_from_system()
	var image_path = cache_dir.path_join(filename)
	
	var image = Image.new()
	var load_error = image.load_png_from_buffer(result[3])
	if load_error != OK:
		return ""
	
	image.save_png(image_path)
	return image_path


# 获取多个目录下的所有文件路径
func get_files_from_directories(directories: Array[String], extensions: Array[String] = []) -> Array[String]:
	var file_list: Array[String] = []
	
	for dir_path in directories:
		# 确保目录以'res://'开头
		var full_path = dir_path if dir_path.begins_with("res://") else "res://" + dir_path
		_scan_directory(full_path, file_list, extensions)
	
	return file_list

# 递归扫描目录
func _scan_directory(current_path: String, file_list: Array, extensions: Array) -> void:
	var dir = DirAccess.open(current_path)
	if not dir:
		push_error("无法打开目录: " + current_path)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir():
			if file_name != "." and file_name != "..":
				# 递归子目录
				_scan_directory(current_path.path_join(file_name), file_list, extensions)
		else:
			# 检查文件扩展名
			if extensions.is_empty() or file_name.get_extension() in extensions:
				file_list.append(current_path.path_join(file_name))
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
