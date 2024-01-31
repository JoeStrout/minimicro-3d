import "importUtil"
ensureImport "math3d"
ensureImport "renderers"

// Obj3d: represents a 3D object.  It has a transform, determining its
// position, rotation, and scale in the world; and a set of points in
// local coordinates, which it can convert to world and screen coordinates.
// It also has a set of renderers (which often reference those points)
// for actually drawing stuff to the screen.
globals.Obj3d = {}
Obj3d.transform = null			// a Transform object
Obj3d.localPoints = null		// a Matrix with one 4-element row for each point
Obj3d.worldPoints = null		// points auto-converted into world coordinates
Obj3d.screenPoints = null		// ...and then screen coordinates
Obj3d.renderers = null			// a List of Renderer objects

Obj3d._lastTfmChg = null		// (private, please ignore)
Obj3d._lastCamChg = null		// (same)

Obj3d.make = function(points=null)
	noob = new Obj3d
	noob.transform = Transform.make
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

Obj3d.render = function
	// Update our world and screen points, as needed
	if self.localPoints then
		t = self.transform.matrix
		if self.worldPoints == null or self._lastTfmChg != self.transform.changeCount then
//			print "Recomputing worldPoints"
			self.worldPoints = self.localPoints.times(t)
			self._lastTfmChg = null
		end if
		cam = renderers.camera
		camInvMatrix = cam.transform.invMatrix
		if self._lastTfmChg != self.transform.changeCount or
		   self._lastCamChg != cam.transform.changeCount then
//			print "Recomputing screenPoints"
			camRelative = self.worldPoints.times(camInvMatrix)
			projected = camRelative.times(math3d.perspectiveMatrix)
			projected.divideByW
			self.screenPoints = projected.times(math3d.clipToScreen)
		end if
		self._lastTfmChg = self.transform.changeCount
		self._lastCamChg = cam.transform.changeCount
	end if
	for rend in self.renderers
		rend.render self
	end for
end function


if locals == globals then
	obj = Obj3d.make
	obj.transform.position = math3d.point(1, 0.3, -2)
	obj.renderers.push new renderers.AxesRenderer
	obj.localPoints = math3d.cubePoints
	lr = new renderers.LineRenderer
	lr.indexes = [
		[0,1,2,3,0],
		[4,5,6,7,4],
		[0,4], [1,5], [2,6], [3,7] ]
	lr.width = 3; lr.color = color.yellow
	obj.renderers.push lr
	obj.render	
end if
