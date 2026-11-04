extends RefCounted
## Current art direction (2026-11-04): sunlit street-pop; docs/art/style-guide.md.
## Colours are design choices, not sampled measurements of the reference videos.
const INK := Color("243C38")
const PAPER := Color("FFF1D6")
const TEAL := Color("237F78")
const MINT := Color("69CBB1")
const CORAL := Color("EC684B")
const YELLOW := Color("F4CD38")
const OLIVE := Color("8C9B51")
const LEAF := Color("8EC94F")
const CONCRETE := Color("C8C6AE")
const ROAD := Color("62675B")
const SKY := Color("249ED3")
const RARITY := [PAPER, MINT, YELLOW]

static func material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 1.0
	result.metallic = 0.0
	result.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	result.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	return result
