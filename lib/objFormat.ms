import "importUtil"
ensureImport "math3d"
ensureImport "stringUtil"
ensureImport "renderers"
ensureImport "obj3d"

splitToNums = function(s, delta=0)
	r = s.split(" ")
	for i in r.indexes
		r[i] = val(r[i]) + delta
	end for
	return r
end function

read = function(path)
	data = file.readLines(path)
	if not data then return null

	points = []
	lines = []
	faces = []
	for dataLine in data
		pos = dataLine.indexOf("#")
		if pos != null then dataLine = dataLine[:pos]
		dataLine = dataLine.trim
		if not dataLine then continue
		if dataLine[:2] == "v " then		// Vertex line
			points.push splitToNums(dataLine[2:])
		else if dataLine[:2] == "l " then	// Polyline line
			lines.push splitToNums(dataLine[2:], -1)	// make indexes 0-based
		else if dataLine[:2] == "f " then	// Face (polygon)
			poly = []
			for f in dataLine[2:].split
				if not f then continue
				print f
				poly.push f.split("/")[0].val - 1	// (0-based indexes here too)
			end for
			faces.push poly
		end if
	end for	

	obj = Obj3d.make(points)
	if lines then
		r = new renderers.LineRenderer
		r.indexes = lines
		obj.renderers.push r
	end if
	if faces then
		r = new renderers.DeferredPolyRenderer
		r.polys = faces
		obj.renderers.push r
	end if
	return obj
end function
