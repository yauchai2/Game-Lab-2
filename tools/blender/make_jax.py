"""Build the Jax low-poly model from primitives and export assets/characters/jax.glb.

Run:  python tools/blender/make_jax.py        (needs `pip install bpy`)
Optional: add --preview to also render assets/characters/jax-preview.png
Blender: +Y is the model's front; Z is up. Units are metres.
"""
import math
import os
import sys

import bpy
from mathutils import Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_GLB = os.path.join(ROOT, "assets", "characters", "jax.glb")
OUT_PNG = os.path.join(ROOT, "docs", "art", "jax-preview.png")

PALETTE = {
    "navy": "292D3B", "chalk": "E7DFC9", "sea": "35676B", "coral": "CC6657",
    "iron": "9AA3AD", "skin": "E9CBB5", "hair": "302D2B", "eye": "4C3930",
    "teeth": "F4F0E4",
}

bpy.ops.wm.read_factory_settings(use_empty=True)
mats = {}


def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def mat(name):
    if name not in mats:
        h = PALETTE[name]
        r, g, b = (srgb_to_linear(int(h[i:i + 2], 16) / 255) for i in (0, 2, 4))
        m = bpy.data.materials.new(name)
        m.use_nodes = True
        m.diffuse_color = (r, g, b, 1)
        bsdf = m.node_tree.nodes["Principled BSDF"]
        bsdf.inputs["Base Color"].default_value = (r, g, b, 1)
        bsdf.inputs["Roughness"].default_value = 1.0
        mats[name] = m
    return mats[name]


def finish(obj, name, color, parent):
    obj.name = name
    obj.data.materials.append(mat(color))
    obj.parent = parent
    obj.matrix_parent_inverse = parent.matrix_world.inverted()
    return obj


def box(name, color, parent, x0, x1, y0, y1, z0, z1):
    bpy.ops.mesh.primitive_cube_add(size=1)
    o = bpy.context.object
    o.scale = (x1 - x0, y1 - y0, z1 - z0)
    o.location = ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
    bpy.ops.object.transform_apply(location=True, scale=True)
    return finish(o, name, color, parent)


def spike(name, base, direction, length, radius, parent):
    d = Vector(direction).normalized()
    bpy.ops.mesh.primitive_cone_add(vertices=5, radius1=radius, radius2=0, depth=length)
    o = bpy.context.object
    o.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
    o.location = Vector(base) + d * length / 2
    bpy.ops.object.transform_apply(location=True, rotation=True)
    return finish(o, name, "hair", parent)


def empty(name, loc, parent=None):
    e = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(e)
    e.location = loc
    if parent:
        e.parent = parent
        e.matrix_parent_inverse = parent.matrix_world.inverted()
    return e


root = empty("Jax", (0, 0, 0))
bpy.context.view_layer.update()

# Legs: pivot at the hip so Godot can swing them.
for side, sx in (("L", -1), ("R", 1)):
    hip = empty(f"Leg{side}", (sx * 0.12, 0, 0.90), root)
    bpy.context.view_layer.update()
    cx = sx * 0.12
    box(f"Pants{side}", "navy", hip, cx - 0.115, cx + 0.115, -0.12, 0.12, 0.12, 0.90)
    box(f"Sole{side}", "navy", hip, cx - 0.12, cx + 0.12, -0.10, 0.22, 0.0, 0.07)
    box(f"Shoe{side}", "chalk", hip, cx - 0.11, cx + 0.11, -0.08, 0.21, 0.07, 0.15)
    box(f"Heel{side}", "sea", hip, cx - 0.11, cx + 0.11, -0.10, -0.04, 0.07, 0.12)
box("Pocket", "navy", root, -0.245, -0.225, 0.0, 0.10, 0.55, 0.72)
box("Waist", "navy", root, -0.19, 0.19, -0.11, 0.11, 0.88, 1.00)

# Torso: white long sleeve underneath, coral tee over it.
box("Undershirt", "chalk", root, -0.17, 0.17, -0.10, 0.10, 0.97, 1.45)
box("Tee", "coral", root, -0.185, 0.185, -0.115, 0.115, 1.05, 1.45)

# Arms: pivot at the shoulder.
for side, sx in (("L", -1), ("R", 1)):
    sh = empty(f"Arm{side}", (sx * 0.24, 0, 1.40), root)
    bpy.context.view_layer.update()
    cx = sx * 0.24
    box(f"Sleeve{side}", "chalk", sh, cx - 0.05, cx + 0.05, -0.05, 0.05, 1.02, 1.40)
    box(f"TeeSleeve{side}", "coral", sh, cx - 0.062, cx + 0.062, -0.062, 0.062, 1.27, 1.43)
    box(f"Hand{side}", "skin", sh, cx - 0.05, cx + 0.05, -0.05, 0.05, 0.90, 1.02)

# Head: pivot at the neck.
head = empty("Head", (0, 0, 1.45), root)
bpy.context.view_layer.update()
box("Neck", "skin", head, -0.04, 0.04, -0.04, 0.04, 1.44, 1.50)
box("Face", "skin", head, -0.13, 0.13, -0.13, 0.13, 1.48, 1.74)
box("Cap", "navy", head, -0.145, 0.145, -0.145, 0.145, 1.62, 1.76)
box("Brim", "navy", head, -0.145, 0.145, 0.10, 0.25, 1.62, 1.65)
box("EyeL", "eye", head, -0.085, -0.035, 0.13, 0.14, 1.56, 1.60)
box("EyeR", "eye", head, 0.035, 0.085, 0.13, 0.14, 1.56, 1.60)
box("MouthBack", "eye", head, -0.075, 0.075, 0.13, 0.14, 1.495, 1.54)
box("Teeth", "teeth", head, -0.065, 0.065, 0.14, 0.145, 1.50, 1.53)
box("EarL", "skin", head, -0.15, -0.13, -0.03, 0.04, 1.54, 1.60)
box("EarR", "skin", head, 0.13, 0.15, -0.03, 0.04, 1.54, 1.60)
for i, (d, base) in enumerate((
    ((-1, 0.0, 0.35), (-0.14, 0.0, 1.66)), ((1, 0.0, 0.35), (0.14, 0.0, 1.66)),
    ((-0.7, -0.7, 0.3), (-0.10, -0.13, 1.66)), ((0.7, -0.7, 0.3), (0.10, -0.13, 1.66)),
    ((0, -1, 0.5), (0, -0.14, 1.68)), ((-0.8, 0.5, 0.2), (-0.13, 0.08, 1.63)),
    ((0.8, 0.5, 0.2), (0.13, 0.08, 1.63)),
)):
    spike(f"Spike{i}", base, d, 0.15, 0.05, head)

# Chunky iron chain around the neck.
bpy.ops.mesh.primitive_torus_add(major_radius=0.14, minor_radius=0.03,
                                 major_segments=8, minor_segments=4,
                                 location=(0, 0.01, 1.43))
chain = bpy.context.object
chain.rotation_euler = (math.radians(12), 0, 0)
chain.scale = (1.0, 0.85, 1.0)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
finish(chain, "Chain", "iron", root)

# Flat shading everywhere: big faces, no smoothing.
for o in bpy.data.objects:
    if o.type == "MESH":
        for p in o.data.polygons:
            p.use_smooth = False

os.makedirs(os.path.dirname(OUT_GLB), exist_ok=True)
bpy.ops.export_scene.gltf(filepath=OUT_GLB, export_format="GLB", export_yup=True)
tris = sum(len(p.vertices) - 2 for o in bpy.data.objects if o.type == "MESH" for p in o.data.polygons)
print(f"Exported {OUT_GLB} ({tris} triangles)")

if "--preview" in sys.argv:
    from PIL import Image

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "FLAT"
    scene.display.shading.color_type = "MATERIAL"
    scene.render.resolution_x, scene.render.resolution_y = 450, 700
    scene.world = bpy.data.worlds.new("w")
    scene.world.color = (0.62, 0.8, 0.95)
    cam_data = bpy.data.cameras.new("cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = 2.0
    cam = bpy.data.objects.new("cam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    cam.location = (0, 6, 0.88)
    cam.rotation_euler = (math.radians(90), 0, math.radians(180))
    tmp = []
    for ang in (0, 90, 180):  # front, side, back
        root.rotation_euler = (0, 0, math.radians(ang))
        scene.render.filepath = OUT_PNG + f".{ang}.png"
        bpy.ops.render.render(write_still=True)
        tmp.append(scene.render.filepath)
    sheet = Image.new("RGB", (450 * 3, 700))
    for i, f in enumerate(tmp):
        sheet.paste(Image.open(f).convert("RGB"), (450 * i, 0))
        os.remove(f)
    sheet.save(OUT_PNG)
    print("preview", OUT_PNG)
