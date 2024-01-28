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
globals.Transform = {}
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
	
	// But more typically, you'd probably use Obj3D, which handles most of
	// these details for you.
end if
