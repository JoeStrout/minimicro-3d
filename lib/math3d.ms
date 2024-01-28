print "Running math3d"

import "importUtil"
ensureImport "matrixUtil"
ensureImport "mathUtil"

// CONVENTIONS:
// We represent points as 4d row (not column!) vectors.  This allows us
// to represent a *list* of points as one big matrix, with one row per point,
// which is far more convenient than one column per point.
//
// But using row vectors instead of column vectors has several implications:
//	1. Our transformation matrices are transposed compared to sources
//		that use column vectors.
//	2. Our transformation matrices must be multiplied on the RIGHT with
//		the point (or set of points) the trasnform, not on the left.
//	3. In the same way, when composing two transformations, T1, and T2,
//		if you want T1 to be done first, it must be on the right: T2*T1.


// The frustum matrix implements a perspective projection.  It maps a
// frustum (truncated pyramid) shaped volume of space in camera-relative
// coordinates, to a perfect cube called homogenous clip space.  In this
// space, anything outside the range [-1, 1] on X, Y, or Z is technically
// outside the field of view.
//
// The parameters to this function are a bit of a pain to come up with.
// Considure using perspectiveMatrix instead, which does the same thing
// but with more convenient parameters.
// This is equivalent to the OpenGL call, glFrustum.
frustumMatrix = function(left, right, bottom, top, nearVal=0.1, farVal=1000)
	a = (right + left) / (right - left)
	b = (top + bottom) / (top - bottom)
	c = -(farVal + nearVal) / (farVal - nearVal)
	d = -2 * (farVal * nearVal) / (farVal - nearVal)
	e = 2 * nearVal / (right - left)
	f = 2 * nearVal / (top - bottom)
	return Matrix.fromList( [
		[e, 0, a, 0],
		[0, f, b, 0],
		[0, 0, c,-1],
		[0, 0, d, 0] ] )
end function

// This is equivalent to the OpenGL call, gluPerspective.
// A pretty good reference for this stuff is:
// https://unspecified.wordpress.com/2012/06/21/calculating-the-gluperspective-matrix-and-other-opengl-matrix-maths/
perspectiveMatrix = function(fovY=30, aspect=1.5, zNear=0.1, zFar=1000)
	b = 1 / tan(fovY/2)			// (called "f" in some references)
	a = b / aspect
	zdiff = zNear - zFar
	c = (zFar + zNear) / zdiff
	d = 2 * zFar * zNear / zdiff
	return Matrix.fromList( [
		[a, 0, 0, 0],
		[0, b, 0, 0],
		[0, 0, c,-1],
		[0, 0, d, 0] ])
end function

scaleMatrix = function(xScale=1, yScale=null, zScale=null)
	if yScale == null then yScale = xScale
	if zScale == null then zScale = yScale
	return Matrix.fromList( [
		[xScale, 0, 0, 0],
		[0, yScale, 0, 0],
		[0, 0, zScale, 0],
		[0, 0, 0, 1] ])
end function

translationMatrix = function(dx=0, dy=0, dz=0)
	return Matrix.fromList( [
		[1, 0, 0, 0],
		[0, 1, 0, 0],
		[0, 0, 1, 0],
		[dx, dy, dz, 1] ])
end function
	
scaleAndTranslate = function(xScale, yScale, zScale, dx=0, dy=0, dz=0)
	return Matrix.fromList( [
		[xScale, 0, 0, 0],
		[0, yScale, 0, 0],
		[0, 0, zScale, 0],
		[dx, dy, dz, 1] ])
end function

radPerDeg = pi/180

xRotationMatrix = function(degrees)
	radians = degrees * radPerDeg
	cosAng = cos(radians); sinAng = sin(radians)
	return Matrix.fromList( [
		[1, 0, 0, 0],
		[0, cosAng, -sinAng, 0],
		[0, sinAng, cosAng, 0],
		[0, 0, 0, 1] ])
end function
		
yRotationMatrix = function(degrees)
	radians = degrees * radPerDeg
	cosAng = cos(radians); sinAng = sin(radians)
	return Matrix.fromList( [
		[cosAng, 0, sinAng, 0],
		[0, 1, 0, 0],
		[-sinAng, 0, cosAng, 0],
		[0, 0, 0, 1] ])
end function
		
zRotationMatrix = function(degrees)
	radians = degrees * radPerDeg
	cosAng = cos(radians); sinAng = sin(radians)
	return Matrix.fromList( [
		[cosAng, -sinAng, 0, 0],
		[sinAng, cosAng, 0, 0],
		[0, 0, 1, 0],
		[0, 0, 0, 1] ])
end function

yawPitchRollMatrix = function(yawDegrees=0, pitchDegrees=0, rollDegrees=0)
	alpha = yawDegrees * radPerDeg
	beta = pitchDegrees * radPerDeg
	gamma = rollDegrees * radPerDeg
	s1 = sin(alpha); s2 = sin(beta); s3 = sin(gamma)
	c1 = cos(alpha); c2 = cos(beta); c3 = cos(gamma)
	return Matrix.fromList( [
		[c1*c3+s1*s2*s3, c2*s3, c1*s2*s3-c3*s1, 0],
		[c3*s1*s2 - c1*s3, c2*c3, c1*c3*s2+s1*s3, 0],
		[c2*s1, -s2, c1*c2, 0],
		[0, 0, 0, 1] ])	
end function

point = function(x, y, z)
	return Matrix.fromList([[x, y, z, 1]])
end function

offset = function(dx, dy, dz)
	return Matrix.fromList([[dx, dy, dz, 0]])
end function

// Get the X coordinate of the first row of this matrix.
// (If you want all the X values, use m.column(0).)
Matrix.x = function; return self.elem[0][0]; end function
Matrix.setX = function(x); self.elem[0][0] = x; end function

// Get the Y coordinate of the first row of this matrix.
// (If you want all the Y values, use m.column(1).)
Matrix.y = function; return self.elem[0][1]; end function
Matrix.setY = function(y); self.elem[0][1] = y; end function

// Get the Z coordinate of the first row of this matrix.
// (If you want all the Z values, use m.column(1).)
Matrix.z = function; return self.elem[0][2]; end function
Matrix.setZ = function(z); self.elem[0][2] = z; end function

// A point that represents the origin (0,0,0) in standard homegenous coordinates.
// (DO NOT MODIFY THIS VALUE.)
zero = point(0, 0, 0)

// Standard clip-to-screen transformation matrix (for the Mini Micro screen).
// Not sure why the Y inversion is necessary.  ToDo: study this more!
clipToScreen = scaleAndTranslate(480, -320, 1, 480, 320, 0)

// Get the 8 points of an axis-aligned cube.
// Points are listed front (+Z) first, back (-Z) last, and 
// within each face, in clockwise order from top-left (-X, +Y).
cubePoints = function(center=null, size=1)
	if center == null then center = zero
	h = size / 2
	x = center.x
	y = center.y
	z = center.z
	return Matrix.fromList([
		[x-h, y+h, z+h, 1],
		[x+h, y+h, z+h, 1],
		[x+h, y-h, z+h, 1],
		[x-h, y-h, z+h, 1],
		[x-h, y+h, z-h, 1],
		[x+h, y+h, z-h, 1],
		[x+h, y-h, z-h, 1],
		[x-h, y-h, z-h, 1] ])
end function

Matrix.divideByW = function
	for pt in self.elem
		w = pt[3]
		pt[0] /= w
		pt[1] /= w
		pt[2] /= w
		pt[3] = 1
	end for
end function

Matrix.round = function(decimalPlaces=0)
	for row in self.elem
		for i in row.indexes
			row[i] = round(row[i], decimalPlaces)
		end for
	end for
end function

Matrix.size = function
	return [self.rows, self.columns]
end function

Matrix.times = function(m2)
	if m2 isa Matrix then m2 = m2.elem
	if m2 isa list then
		// matrix multiplication
		if m2.len != self.columns then
			print "Matrix.times error: incompatible sizes " + 
			  self.size + " and " + [m2.len, len(m2[0])]
			exit
		end if
		result = Matrix.ofSize(self.rows, m2[0].len)
		for r in result.rowRange
			resultRow = result.elem[r]
			for c in result.colRange
				sum = 0
				for i in self.colRange
					sum = sum + self.elem[r][i] * m2[i][c]
				end for
				resultRow[c] = sum
			end for
		end for
	else
		// simple multiplication by a scalar
		result = self.clone
		result.elemMultiplyBy m2
	end if
	return result
end function

Matrix.print = function(fieldWidth=10, precision=null, columnSep="", rowSep=null)
	if rowSep == null then rowSep = text.delimiter
	for row in self.elem
		line = []
		for elem in row
			s = mathUtil.numToStr(elem, precision)
			if s.len >= fieldWidth and s.indexOf(".") != null then s = s[:fieldWidth-1]
			if s.len < fieldWidth then s = " "*(fieldWidth-s.len) + s
			line.push s
		end for
		print line.join(columnSep), rowSep
	end for
end function

drawLine = function(pt1, pt2)
	if pt1 isa Matrix then
		gfx.line pt1.elem[0], pt1.elem[1], pt2.elem[0], pt2.elem[1]
	else
		gfx.line pt1[0], pt1[1], pt2[0], pt2[1]
	end if	
end function

// Transform: represents a position, rotation, and (uniform) scale.
Transform = {}
Transform.position = point(0,0,0)
Transform.rotation = offset(0,0,0)	// (Euler angles)
Transform.scale = 1

Transform._matrix = null	// private, please ignore
Transform.changeCount = 0	// incremented whenever matrix is rebuilt

// Whenever you change position, rotation, or scale of a Transform,
// be sure to call noteChange before the next update.
Transform.noteChange = function
	self._matrix = null
end function

Transform.matrix = function
	if not self._matrix then
		pos = self.position.elem[0]
		rot = self.rotation.elem[0]
		scale = self.scale
		self._matrix = scaleMatrix(scale, scale, scale).
		   times(yawPitchRollMatrix(rot[1], rot[0], rot[2])).
		   times(translationMatrix(pos[0], pos[1], pos[2]))
		self.changeCount = (self.changeCount + 1) % 1000000
	end if
	return self._matrix
end function

// Obj3D: represents a 3D object.  It has a transform, determining its
// position, rotation, and scale in the world; and a set of points in
// local coordinates, which it can convert to world and screen coordinates.
// It also has a set of renderers (which often reference those points)
// for actually drawing stuff to the screen.
Obj3D = {}
Obj3D.transform = null			// a Transform object
Obj3D.localPoints = null		// a Matrix with one 4-element row for each point
Obj3D.worldPoints = null		// points auto-converted into world coordinates
Obj3D.screenPoints = null		// ...and then screen coordinates
Obj3D.renderers = null			// a List of Renderer objects

Obj3D._lastTfmChg = null		// (private, please ignore)
Obj3D._lastCamChg = null		// (same)

Obj3D.make = function(points=null)
	noob = new Obj3D
	noob.transform = new Transform
	if points isa list then points = Matrix.fromList(points)
	if points isa Matrix and points.columns == 3 then
		// convert to homogenous coordinates by appending "1" for w
		for row in points.elem; row.push 1; end for
		points.columns = 4
		points.rowRange = range(0, 3)
	end if
	noob.localPoints = points
	noob.renderers = []
	return noob
end function

Obj3D.render = function
	// Update our world and screen points, as needed
	if self.localPoints then
		t = self.transform.matrix
		if self.worldPoints == null or self._lastTfmChg != self.transform.changeCount then
//			print "Recomputing worldPoints"
			self.worldPoints = self.localPoints.times(t)
			self._lastTfmChg = null
		end if
		if self._lastTfmChg != self.transform.changeCount then // ToDo: check for camera changes too!
//			print "Recomputing screenPoints"
			projected = self.worldPoints.times(perspectiveMatrix)
			projected.divideByW
			self.screenPoints = projected.times(clipToScreen)
		end if
		self._lastTfmChg = self.transform.changeCount
		// ToDo: update self._lastCamChg too
	end if
	for rend in self.renderers
		rend.render self
	end for
end function

// Renderer: base class of anything that can render part of an Obj3D
// (or something related to an Obj3D, like a bounding box or axes).
Renderer = {}
Renderer.render = function(obj3D); end function		// Override me!

// AxesRenderer: ignores points, and just draws local x/y/z axes
// (in red, green, and blue respectively).
AxesRenderer = new Renderer
AxesRenderer.scale = 1
AxesRenderer.render = function(obj3D)
	// Because we're not requiring the object to have the points we need,
	// we have no choice but to compute these every time:
	s = self.scale
	globals.points = Matrix.fromList([
		[0,0,0,1],
		[s,0,0,1],
		[0,s,0,1],
		[0,0,s,1] ])
	globals.worldPts = points.times(obj3D.transform.matrix)
	globals.projected = worldPts.times(perspectiveMatrix)
	if projected.elem[0][2] < -1 then return	// (origin is behind near clip plane)
	drawX = projected.elem[1][2] > -1
	drawY = projected.elem[2][2] > -1
	drawZ = projected.elem[3][2] > -1
	projected.divideByW
	globals.screenPts = projected.times(clipToScreen)
	if drawX then
		gfx.color = "#FF0000"
		drawLine screenPts.elem[0], screenPts.elem[1]
	end if
	if drawY then
		gfx.color = "#00FF00"
		drawLine screenPts.elem[0], screenPts.elem[2]
	end if
	if drawZ then
		gfx.color = "#4444FF"
		drawLine screenPts.elem[0], screenPts.elem[3]
	end if
end function

// LineRenderer: draws a line between points on the object.
// The indexes property is a list of lists; each inner list is the
// indexes of points that should be connect.  For example:
//	[[0,1,2], [3,4]] draws lines from 0 to 1, from 1 to 2, and from 3 to 4.
// All lines drawn by one LineRenderer have the same color and width,
// but you can attach multiple LineRenderers to draw in multiple styles.
LineRenderer = new Renderer
LineRenderer.indexes = []
LineRenderer.color = color.white	// line color
LineRenderer.width = 1				// line width (thickness)
LineRenderer.render = function(obj3D)
	if not self.indexes then return
	c = self.color; w = self.width
	if self.indexes[0] isa list then
		for set in self.indexes
			prevPt = null
			for idx in set
				pt = obj3D.screenPoints.elem[idx]
				if prevPt then gfx.line prevPt[0], prevPt[1], pt[0], pt[1], c, w
				prevPt = pt
			end for
		end for
	else
		// we also allow indexes to be a simple list (single set).
		prevPt = null
		for idx in indexes
			pt = obj3D.screenPoints.elem[idx]
			if prevPt then gfx.line prevPt[0], prevPt[1], pt[0], pt[1], c, w
			prevPt = pt
		end for
	end if
end function


if locals == globals then
	clear; gfx.color = color.white
	
	// Here's how you can draw using the low-level steps, starting with
	// local coordinates (cube) and building up all the way to screen
	// coordinates (screenCube), and then manually drawing lines.
	cube = cubePoints
	t = new Transform
	t.position = point(1, 0.3, -2)
	t.noteChange	// (not strictly necessary right after creation)
	tCube = cube.times(t.matrix)
	projCube = tCube.times(perspectiveMatrix)
	projCube.divideByW
	screenCube = projCube.times(clipToScreen)
	for i in range(0, 3)
		drawLine screenCube.elem[i], screenCube.elem[(i+1)%4]
		drawLine screenCube.elem[i+4], screenCube.elem[(i+1)%4+4]
		drawLine screenCube.elem[i], screenCube.elem[i+4]
	end for
	
	// But here's the more typical approach: make an Obj3D, then configure
	// it with some local points and one or more Renderers; then call render
	// on it to actually draw.
	obj = Obj3D.make
	obj.transform = t
	obj.renderers.push new AxesRenderer
	obj.localPoints = cubePoints
	lr = new LineRenderer
	lr.indexes = [
		[0,1,2,3,0],
		[4,5,6,7,4],
		[0,4], [1,5], [2,6], [3,7] ]
	lr.width = 3; lr.color = color.yellow
	obj.renderers.push lr
	obj.render
	
	
	// And, reading from a file.
	math3d = locals	// (avoids re-importing this code)
	import "objFormat"
	tank = objFormat.read("battlezonemodels/Tank.obj")
	tank.transform.position = point(-3, 0, -7)
	tank.transform.scale = 1/50
	tank.transform.rotation = offset(0, -30, 0)
//	tank.renderers.push new AxesRenderer
//	tank.renderers[-1].scale = 50
	tank.render
	
end if
