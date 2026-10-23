extends CanvasLayer

@onready var label = $StatusLabel

func _process(_delta: float) -> void:
	var mode_names = ["[Q] COMMENT_OUT (DELETE)", "[E] SUSPEND_PROC (FREEZE)", "[R] VAR_OVERRIDE (GRAVITY)"]
	label.text = "KERNEL_TIME: %s  |  FRAGMENTS: %d/4\nACTIVE_TOOL: %s (Left-Click Target)" % [
		GameManager.get_formatted_time(),
		GameManager.fragments_collected,
		mode_names[GameManager.current_mode]
	]
