import "importUtil"
ensureImport "math3d"
ensureImport "obj3d"

drawLine = function(pt1, pt2)
	if pt1 isa Matrix then
		gfx.line pt1.elem[0], pt1.elem[1], pt2.elem[0], pt2.elem[1]
	else
		gfx.line pt1[0], pt1[1], pt2[0], pt2[1]
	end if	
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
	globals.projected = worldPts.times(math3d.perspectiveMatrix)
	if projected.elem[0][2] < -1 then return	// (origin is behind near clip plane)
	drawX = projected.elem[1][2] > -1
	drawY = projected.elem[2][2] > -1
	drawZ = projected.elem[3][2] > -1
	projected.divideByW
	globals.screenPts = projected.times(math3d.clipToScreen)
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

