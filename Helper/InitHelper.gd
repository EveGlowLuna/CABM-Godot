extends Node

# 需要复制的文件夹列表（res:// 下的路径）
const FOLDERS_TO_COPY := [
	"caches",
	"characters",
	"config",
	"data"
]

func _ready():
	# 检查user://下是否已存在任何目标文件夹
	var dir = DirAccess.open("user://")
	var skip_copy = false
	
	for folder in ["caches", "characters", "config", "data"]:
		if dir.dir_exists(folder):
			skip_copy = true
			break
	
	if !skip_copy:
		# 执行复制（这里直接调用之前实现的copy_all_folders_to_user()）
		if copy_all_folders_to_user():
			print("初始化复制完成")
		else:
			push_error("初始化复制失败")
	else:
		print("用户数据已存在，跳过复制")

# 主复制函数
func copy_all_folders_to_user() -> bool:
	for folder in FOLDERS_TO_COPY:
		var res_path = "res://" + folder
		var user_path = "user://" + folder
		
		if !copy_dir_recursive(res_path, user_path):
			push_error("复制失败: " + res_path)
			return false
	
	return true

# 递归复制目录
func copy_dir_recursive(from: String, to: String) -> bool:
	# 创建目标目录
	var dir = DirAccess.open("user://")
	if dir == null:
		push_error("无法打开 user:// 目录")
		return false
		
	if !dir.dir_exists(to):
		if dir.make_dir_recursive(to) != OK:
			push_error("无法创建目录: " + to)
			return false
	
	# 遍历源目录
	var from_dir = DirAccess.open(from)
	if from_dir == null:
		push_error("无法访问目录: " + from)
		return false
	
	var err = from_dir.list_dir_begin() # 开始遍历
	if err != OK:
		push_error("目录遍历失败: " + from)
		return false
	
	var file_name = from_dir.get_next()
	while file_name != "":
		var res_path = from.path_join(file_name)
		var user_path = to.path_join(file_name)
		
		if from_dir.current_is_dir():
			# 递归处理子目录（跳过 . 和 ..）
			if file_name != "." and file_name != "..":
				if !copy_dir_recursive(res_path, user_path):
					from_dir.list_dir_end()
					return false
		else:
			# 复制文件
			if !copy_file(res_path, user_path):
				from_dir.list_dir_end()
				return false
		
		file_name = from_dir.get_next()
	
	from_dir.list_dir_end()
	return true

# 复制单个文件
func copy_file(from: String, to: String) -> bool:
	if !FileAccess.file_exists(from):
		push_error("文件不存在: " + from)
		return false
	
	var data = FileAccess.get_file_as_bytes(from)
	if data.is_empty():
		push_error("文件读取失败: " + from)
		return false
	
	var file = FileAccess.open(to, FileAccess.WRITE)
	if file == null:
		push_error("无法写入文件: " + to)
		return false
	
	file.store_buffer(data)
	file.close()
	return true
