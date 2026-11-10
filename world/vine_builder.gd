class_name VineBuilder
extends RefCounted

const SEGMENTS = 12
const SIDES = 5

static func build(length: float, bend: float, thickness: float, taper: float, wiggle: float, phase: float) -> ArrayMesh:
	var points: Array[Vector3] = []
	for i in SEGMENTS + 1:
		var t = float(i) / SEGMENTS
		var x = (t - 0.5) * length
		var y = -4.0 * bend * t * (1.0 - t)
		var z = sin(t * TAU * 1.5 + phase) * wiggle
		points.append(Vector3(x, y, z))
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in points.size():
		var t = float(i) / SEGMENTS
		var next = points[min(i + 1, SEGMENTS)]
		var prev = points[max(i - 1, 0)]
		var tangent = (next - prev).normalized()
		var side = tangent.cross(Vector3.UP).normalized()
		if side.length() < 0.1:
			side = tangent.cross(Vector3.FORWARD).normalized()
		var up = side.cross(tangent)
		var r = thickness * lerp(1.0, taper, t)
		for j in SIDES + 1:
			var a = TAU * j / SIDES
			var normal = side * cos(a) + up * sin(a)
			st.set_normal(normal)
			st.set_uv(Vector2(float(j) / SIDES, t * length))
			st.add_vertex(points[i] + normal * r)
	var ring = SIDES + 1
	for i in SEGMENTS:
		for j in SIDES:
			var a = i * ring + j
			var b = a + 1
			var c = a + ring
			var d = c + 1
			st.add_index(a)
			st.add_index(b)
			st.add_index(c)
			st.add_index(b)
			st.add_index(d)
			st.add_index(c)
	return st.commit()
