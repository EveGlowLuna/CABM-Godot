extends CanvasLayer

@onready var rect = $ColorRect
@onready var anim_player = $AnimationPlayer

func _ready():
	rect.visible = true
	var screen_size = get_viewport().get_visible_rect().size

	# 创建动画
	var animation = Animation.new()
	animation.length = 1.0

	# === 核心修正：使用 add_property_track() ===
	# 正确方式：直接指定节点路径和属性名
	var track_idx = animation.add_property_track(rect.get_path(), "position")
	
	# 设置关键帧
	var start_pos = Vector2(screen_size.x, 0)
	var end_pos = Vector2(-screen_size.x, 0)
	
	animation.track_insert_key(track_idx, 0.0, start_pos)
	animation.track_insert_key(track_idx, 1.0, end_pos)

	# 添加到动画库
	var lib = AnimationLibrary.new()
	lib.add_animation("slide", animation)
	anim_player.add_animation_library("default", lib)

	# 播放动画
	anim_player.play("slide")
