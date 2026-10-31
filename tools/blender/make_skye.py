"""Build the Skye low-poly model from primitives and export assets/characters/skye.glb.

Run:  python tools/blender/make_skye.py        (needs `pip install bpy`)
Optional: add --preview to also render assets/characters/skye-preview.png
Blender: +Y is the model's front; Z is up. Units are metres.
"""
import math
import os
import sys

import bpy
from mathutils import Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_GLB = os.path.join(ROOT, "assets", "characters", "skye.glb")
OUT_PNG = os.path.join(ROOT, "docs", "art", "skye-preview.png")

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


root = empty("Skye", (0, 0, 0))
bpy.context.view_layer.update()

# Legs: pivot at the hip. Wide navy shorts, striped long socks, upturned thick-soled shoes.
for side, sx in (("L", -1), ("R", 1)):
    hip = empty(f"Leg{side}", (sx * 0.11, 0, 0.90), root)
    bpy.context.view_layer.update()
    cx = sx * 0.11
    box(f"Shorts{side}", "navy", hip, cx - 0.12, cx + 0.12, -0.12, 0.12, 0.72, 0.92)
    box(f"Leg{side}Skin", "skin", hip, cx - 0.06, cx + 0.06, -0.06, 0.06, 0.52, 0.72)
    for k, (z0, z1, c) in enumerate(((0.40, 0.52, "chalk"), (0.30, 0.40, "navy"), (0.20, 0.30, "chalk"))):
        box(f"Sock{side}{k}", c, hip, cx - 0.065, cx + 0.065, -0.065, 0.065, z0, z1)
    box(f"Sole{side}", "navy", hip, cx - 0.10, cx + 0.10, -0.10, 0.24, 0.0, 0.07)
    box(f"Shoe{side}", "chalk", hip, cx - 0.09, cx + 0.09, -0.08, 0.20, 0.07, 0.17)
    box(f"Toe{side}", "coral", hip, cx - 0.09, cx + 0.09, 0.16, 0.26, 0.10, 0.20)
box("Belt", "coral", root, -0.17, 0.17, -0.11, 0.11, 0.90, 0.95)

# Torso: sleeveless sea-green crop top (bare midriff), narrow upper body.
box("Midriff", "skin", root, -0.14, 0.14, -0.08, 0.08, 0.95, 1.10)
box("Top", "sea", root, -0.16, 0.16, -0.10, 0.10, 1.08, 1.38)

# Arms: pivot at the shoulder, bare skin.
for side, sx in (("L", -1), ("R", 1)):
    sh = empty(f"Arm{side}", (sx * 0.21, 0, 1.34), root)
    bpy.context.view_layer.update()
    cx = sx * 0.21
    box(f"Arm{side}Skin", "skin", sh, cx - 0.045, cx + 0.045, -0.045, 0.045, 0.98, 1.36)
    box(f"Glove{side}", "navy", sh, cx - 0.05, cx + 0.05, -0.05, 0.05, 0.94, 1.02)

# Head: pivot at the neck. Half-lidded eyes, side smirk, fan ponytail.
head = empty("Head", (0, 0, 1.38), root)
bpy.context.view_layer.update()
box("Neck", "skin", head, -0.035, 0.035, -0.035, 0.035, 1.37, 1.43)
box("Face", "skin", head, -0.12, 0.12, -0.12, 0.12, 1.41, 1.66)
box("HairTop", "hair", head, -0.13, 0.13, -0.13, 0.13, 1.60, 1.72)
box("HairBack", "hair", head, -0.13, 0.13, -0.14, -0.06, 1.44, 1.66)
box("Fringe", "hair", head, -0.12, 0.12, 0.08, 0.13, 1.58, 1.66)
box("EyeL", "eye", head, -0.08, -0.03, 0.12, 0.13, 1.51, 1.55)
box("EyeR", "eye", head, 0.03, 0.08, 0.12, 0.13, 1.51, 1.55)
box("LidL", "hair", head, -0.085, -0.025, 0.125, 0.135, 1.545, 1.57)
box("LidR", "hair", head, 0.025, 0.085, 0.125, 0.135, 1.545, 1.57)
box("Smirk", "eye", head, 0.00, 0.07, 0.12, 0.13, 1.45, 1.47)
box("Tie", "coral", head, -0.03, 0.03, -0.17, -0.12, 1.64, 1.70)
for i, d in enumerate(((-0.9, -0.8, -0.1), (-0.45, -1, 0.0), (0, -1, 0.15), (0.45, -1, 0.0), (0.9, -0.8, -0.1))):
    spike(f"Fan{i}", (0, -0.15, 1.66), d, 0.26, 0.05, head)

# Rifle slung on the back and a coral quiver pouch.
box("Rifle", "iron", root, 0.08, 0.14, -0.19, -0.12, 0.78, 1.34)
box("RifleGrip", "navy", root, 0.08, 0.14, -0.19, -0.12, 0.70, 0.80)
box("Pouch", "coral", root, -0.16, -0.04, -0.20, -0.11, 0.86, 1.02)

root.scale = (0.93, 0.93, 0.93)
bpy.context.view_layer.update()

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
