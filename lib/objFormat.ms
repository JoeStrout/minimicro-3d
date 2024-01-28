import "importUtil"
ensureImport "math3d"
ensureImport "stringUtil"

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
	for dataLine in data
		pos = dataLine.indexOf("#")
		if pos != null then dataLine = dataLine[:pos]
		dataLine = dataLine.trim
		if not dataLine then continue
		if dataLine[:2] == "v " then		// Vertex line
			points.push splitToNums(dataLine[2:])
		end if
		if dataLine[:2] == "l " then		// Polyline line
			lines.push splitToNums(dataLine[2:], -1)	// make indexes 0-based
		end if
	end for	

	obj = math3d.Obj3D.make(points)
	r = new math3d.LineRenderer
	r.indexes = lines
	obj.renderers.push r
	return obj
end function
