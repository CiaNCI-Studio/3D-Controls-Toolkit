# 3D Controls Toolkit

3D Controls plugin For Godot 4.3:
	
Includes:
	
	* First Person Controller
	* Third Person Controller
	* Side-Scrolling Controller
	* Top-Down Controller
	
Plug-and-Play* just add as a child of the Character3D node, and it will work.

* Requires the following actions on input map: "up", "down", "left", "right", optionally: "sprint", "jump"
those values can be changed on the node inspector.

Other configurations:

* General (For all control types):
	* Geometry = Player geometry, if not provided it will look for the first MeshInstance3D sibling, if doesn’t exist will not handle geometry movements.

* Jump (For all control types):
	* Jump Height
	* Jump time to peak = Time to reach the top of the jump
	* Jump time to descend = Time fall
	* Variable Jump = If the jump can be interrupted by releasing the jump action key
	* Air control on jump = If player can be controlled in middle-air
	* Coyote Time = time that player can jump after leaving a platform
	* Jump Buffer Time = time that player can activate jump before hit the ground

* Movement (For all control types):
	* Walk Speed
	* Sprint Speed
	* Acceleration
	* Deacceleration
	* Movement Type = "Move and Slide" or "Move and Collide" or "None" (Movement must be handled on player code)

* First Person:
	* Mouse Sensitivity
	* Turn Speed
	* Rotation Type = Rotate player or just the geometry
	* Horizontal Offset 
	* Vertical Offset
	* Custom Camera (Optional)
	* Max Camera Angle
	* Min Camera Angle

* Third Person:
	* Mouse Sensitivity
	* Turn Speed
	* Rotation Type
	* Horizontal Offset
	* Vertical Look at Offset
	* Start Angle
	* Custom Camera
	* Max Camera Angle
	* Min Camera Angle
	* Spring Length (camera)
	* Custom Camera (Optional)

* Side-Scrolling
	* Turn Speed
	* Handle Camera
	* Camera Smooth Distance
	* Camera Smooth Speed
	* Camera Look at Player
	* Camera Lock Y Rotation
	* Camera Max Boundary
	* Camera Min Boundary
	* Spring Length
	* Angle (Camera)
	* Horizontal Offset
	* Vertical Offset
	* Custom Camera (Optional)
	
* Top-Down
	* Action Type = Use actions to move or move to mouse click
	* Floor Group = Required to find floor StaticBody3D to handle mouse click on click mode.
	* Turn Speed
	* Handle Camera
	* Camera Smooth Distance
	* Camera Smooth Speed		
	* Spring Length
	* Angle (Camera)
	* Horizontal Offset
	* Vertical Offset
	* Custom Camera (Optional)
	
Check out CiaNCI Chanel on YouTube for more: https://www.youtube.com/@CiaNCIStudio
