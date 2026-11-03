"""Check the city scene without changing it.

Run: blender --background --python-exit-code 1 --python tools/blender/verify-city-scene.py
"""
import bpy
from pathlib import Path

root = Path(__file__).resolve().parents[2]
scene_path = root / 'assets/environment/city-scene.blend'
bpy.ops.wm.open_mainfile(filepath=str(scene_path))
scene = bpy.context.scene
for name in ('BACKSTREET_COMPLETION', 'SIDE_STREETS', 'CURVED_CITY_ELEMENTS', 'URBAN_MURAL', 'BACKSTREET_SHAPE_VARIATION'):
    assert bpy.data.collections.get(name), f'Missing collection: {name}'
for name in ('MainCamera', 'UnderBridgeReview', 'SouthStreetCamera'):
    assert bpy.data.objects.get(name), f'Missing camera: {name}'
for name, body in (('Letter_RADIO', '喫茶'), ('Rear_sign_SOUND', 'レコード')):
    obj = bpy.data.objects.get(name)
    assert obj and obj.type == 'FONT' and obj.data.body == body, f'Missing text: {name}'
    assert obj.data.font and obj.data.font.packed_file, f'Font is not packed: {name}'
missing = [img.name for img in bpy.data.images if img.source == 'FILE' and img.filepath and not img.packed_file and not Path(bpy.path.abspath(img.filepath)).exists()]
assert not missing, f'Missing images: {missing}'
print('PASS: city scene collections, cameras, Japanese fonts, and image dependencies')
