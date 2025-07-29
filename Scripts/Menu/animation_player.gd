extends AnimationPlayer


func _on_start_btn_mouse_entered() -> void:
	play("sbtn_hover_in")


func _on_start_btn_mouse_exited() -> void:
	play("sbtn_hover_out")
