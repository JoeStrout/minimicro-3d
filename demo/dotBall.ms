// A bunch of dots on the surface of a sphere... they don't
// look like a sphere until you start spinning it, and then
// suddenly your brain figures it out!

import "math3d"
import "tc"

randomPointOnSphere = function(radius=1)
	u = rnd
	v = rnd
	theta = 2 * pi * u
	phi = acos(2 * v - 1)
	x = radius * sin(phi) * cos(theta)
	y = radius * sin(phi) * sin(theta)
	z = radius * cos(phi)
	return math3d.point(x, y, z)
end function

points = []
for i in range(0, 150)
	points.push randomPointOnSphere.elem[0]
end for
points = Matrix.fromList(points)

t = Transform.make
t.position = math3d.point(0, 0, -6)

ang = 0
while not key.available
	t.rotate(0.2, 3, -0.1)
	clipSpace = points.times(t.matrix)
	projected = clipSpace.times(math3d.perspectiveMatrix)
	projected.divideByW
	screenPts = projected.times(math3d.clipToScreen)
	gfx.scale = 3; gfx.scrollX = 960; gfx.scrollY = 640
	for p in screenPts.elem
		b = 255 - (p[2] - 0.96)*4000   // brightness
		gfx.setPixel p[0], p[1], color.rgb(b/2, b, b/2)
	end for
	flc		// (flip and clear)
end while
key.clear
