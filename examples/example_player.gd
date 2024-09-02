extends CharacterBody3D

@onready var first_person_controler_3d: FirstPersonControler3D = $FirstPersonControler3D
@onready var third_person_controler_3d: ThirdPersonControler3D = $ThirdPersonControler3D
@onready var side_scrolling_controler_3d: SideScrollingControler3D = $SideScrollingControler3D
@onready var top_down_controler_3d: TopDownControler3D = $TopDownControler3D

func _input(event: InputEvent) -> void:
	if event is InputEventKey:		
		if (event as InputEventKey).keycode == KEY_1:
			disable_all()
			first_person_controler_3d.toggle_active(true)
		elif (event as InputEventKey).keycode == KEY_2:
			disable_all()
			third_person_controler_3d.toggle_active(true)
		elif (event as InputEventKey).keycode == KEY_3:
			disable_all()
			side_scrolling_controler_3d.toggle_active(true)		
		elif (event as InputEventKey).keycode == KEY_4:
			disable_all()
			top_down_controler_3d.toggle_active(true)
			
func disable_all():
	rotation = Vector3.ZERO
	first_person_controler_3d.toggle_active(false)
	third_person_controler_3d.toggle_active(false)
	side_scrolling_controler_3d.toggle_active(false)
	top_down_controler_3d.toggle_active(false)
