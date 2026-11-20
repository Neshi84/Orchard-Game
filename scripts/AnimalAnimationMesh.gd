extends RefCounted

const MESH_COLUMNS := 48
const MESH_ROWS := 32

static func build(size: Vector2) -> ArrayMesh:
	# Subdivide the original sprite so the shader can move each part independently.
	var vertices := PackedVector2Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for row in range(MESH_ROWS + 1):
		for column in range(MESH_COLUMNS + 1):
			var uv := Vector2(float(column) / MESH_COLUMNS, float(row) / MESH_ROWS)
			uvs.append(uv)
			vertices.append((uv - Vector2(0.5, 0.5)) * size)
	for row in range(MESH_ROWS):
		for column in range(MESH_COLUMNS):
			var top := row * (MESH_COLUMNS + 1) + column
			var bottom := top + MESH_COLUMNS + 1
			indices.append_array([top, top + 1, bottom, top + 1, bottom + 1, bottom])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, Mesh.ARRAY_FLAG_USE_2D_VERTICES)
	return mesh
