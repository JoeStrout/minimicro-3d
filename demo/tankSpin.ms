// Simple demo that loads an OBJ model, and makes it spin steadily
// around its Y axis until the user presses any key.

import "obj3d"
import "objFormat"
import "tc"

point = @math3d.point
offset = @math3d.offset

clear
flc		// (flip and clear; from /sys/lib/tc)
gfx.scale = 1; gfx.scrollX = 0; gfx.scrollY = 0
flc		// (doing this just in case another demo has left one of the displays scaled)
gfx.scale = 1; gfx.scrollX = 0; gfx.scrollY = 0

tank = objFormat.read("/usr/models/Tank.obj")
tank.transform.position = point(0, 0, -7)
tank.transform.scale = 1/50

ang = 0
while not key.available
	tank.transform.rotation = offset(0, -ang, 0)
	tank.transform.noteChange
	tank.render
	ang = (ang + 2) % 360
	flc		// (flip and clear)
end while
key.clear
