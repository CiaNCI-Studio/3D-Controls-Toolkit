@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_custom_type("Controler3D", "Node3D",  preload("BaseControler3D.gd"), preload("icons/Base3D.svg"))
	add_custom_type("FirstPersonControl3D", "ControlBase3D",  preload("FirstPersonControler3D.gd"), preload("icons/FirstPerson3D.svg"))
	add_custom_type("ThirdPersonControler3D", "ControlBase3D",  preload("ThirdPersonControler3D.gd"), preload("icons/ThirdPerson3D.svg"))
	add_custom_type("SideScrollingControler3D", "ControlBase3D",  preload("SideScrollingControler3D.gd"), preload("icons/SideScroller3D.svg"))
	add_custom_type("TopDownControler3D", "ControlBase3D",  preload("TopDownControler3D.gd"), preload("icons/TopDown3D.svg"))

func _exit_tree() -> void:
	remove_custom_type("FirstPersonControler3D")
	remove_custom_type("ThirdPersonControler3D")
	remove_custom_type("SideScrollingControler3D")
	remove_custom_type("TopDownControler3D")
	remove_custom_type("Controler3D")
