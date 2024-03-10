import "importUtil"
ensureImport "math3d"
ensureImport "obj3d"

// Camera class
Camera = {}
Camera.near = 0.1
Camera.far = 1000
Camera.transform = null
Camera.make = function(x=0, y=0, z=0, yRotation=0)
	cam = new Camera
	cam.transform = Transform.make(x, y, z)
	return cam
end function

// Camera instance used by all renderers
camera = Camera.make

drawLine = function(pt1, pt2)
	if pt1 isa Matrix then
		gfx.line pt1.elem[0], pt1.elem[1], pt2.elem[0], pt2.elem[1]
	else
		gfx.line pt1[0], pt1[1], pt2[0], pt2[1]
	end if	
end function

// Renderer: base class of anything that can render part of an Obj3d
// (or something related to an Obj3d, like a bounding box or axes).
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
	points = Matrix.fromList([
		[0,0,0,1],
		[s,0,0,1],
		[0,s,0,1],
		[0,0,s,1] ])
	worldPts = points.times(obj3D.transform.matrix)
	camRelative = worldPts.times(camera.transform.invMatrix)
	projected = camRelative.times(math3d.perspectiveMatrix)
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
LineRenderer.indexes = null		// (list of lists; see above)  ToDo: RENAME!
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

// DeferredPolyRenderer: adds polygons to a shared list.  Then, after you've
// rendered all your objects that are going to use this renderer, you call
// DeferredPolyRenderer.sortAndDraw which sorts and draws the polygons all
// at once.
//
// Palygons on each object are defined much like LineRenderer: a list of lists,
// where each inner list specifies indexes of points in a polygon.
DeferredPolyRenderer = new Renderer
DeferredPolyRenderer.polys = null		// (list of lists; see above)
DeferredPolyRenderer.color = color.gray	// fill color (null to not draw)
DeferredPolyRenderer.edgeColor = color.white	// edge color
DeferredPolyRenderer.edgeWidth = 0				// edge width (0 to not draw)

// This is our shared list of polygons waiting to be sorted and drawn.
// Each entry is: [depth, [screen points], renderer]
DeferredPolyRenderer.drawList = []

// render: shove our polygons onto the shared drawList.
DeferredPolyRenderer.render = function(obj3D)
	if not self.polys then return
	for srcPoly in self.polys
		sumDepth = 0
		screenPts = []
		for idx in srcPoly
			p = obj3D.screenPoints.elem[idx]
			screenPts.push p
			sumDepth += p[2]
		end for
		DeferredPolyRenderer.drawList.push [sumDepth/srcPoly.len, screenPts, self]
	end for
end function

// sortAndDraw: sort all our polygons and draw them, in depth order, to gfx.
DeferredPolyRenderer.sortAndDraw = function
	DeferredPolyRenderer.drawList.sort 0, false
	for entry in DeferredPolyRenderer.drawList
		rend = entry[2]
		if rend.color then gfx.fillPoly entry[1], rend.color
		if rend.edgeColor and rend.edgeWidth > 0 then
			gfx.drawPoly entry[1], rend.edgeColor, rend.edgeWidth
		end if
	end for	
	DeferredPolyRenderer.drawList = []
end function


if locals == globals then
	renderers = {} + locals
	obj = Obj3d.make
	obj.transform.position = math3d.point(0, 0, -10)
	obj.renderers.push new AxesRenderer
	
	ensureImport "objFormat"
	cube = objFormat.read("/usr/models/cube.obj")
	cube.transform.position = math3d.point(5, 0.5, -5)
	cube.renderers[-1].edgeWidth = 1
	
	camera.transform.setPosition 4, 2, 0

	while true
		clear
		obj.render
		cube.render
		DeferredPolyRenderer.sortAndDraw
		k = key.get.code
		if k == 17 then // left
			camera.transform.rotate 0, 10, 0
		else if k == 18 then // right
			camera.transform.rotate 0, -10, 0
		else if k == ",".code then
			cube.transform.rotate 0, 10, 0
		else if k == ".".code then
			cube.transform.rotate 0, -10, 0
		else if k == 27 then  // escape
			break
		end if
	end while
end if
