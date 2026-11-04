"""Check packaged city files without changing them.

Run: blender --background --python-exit-code 1 --python tools/blender/verify-city-scene.py
This does not verify visual fidelity or engine physics.
"""
from pathlib import Path
import bpy

root = Path(__file__).resolve().parents[2]
collections = (
    'BACKSTREET_COMPLETION', 'SIDE_STREETS', 'CURVED_CITY_ELEMENTS',
    'URBAN_MURAL', 'VIDEO_URBAN_DETAIL_20261104', 'SKYLINE_REFINEMENT_20261104',
    'NORTH_CROSS_STREET_20261104', 'OUTER_STREETS_20261104',
    'OUTER_SHOP_SIGNS_20261104', 'ROUND_LANDMARK_20261104', 'PLAZA_FINISH_20261104',
    'PLAZA_BILLBOARD_STUDY_20261104', 'LANDMARK_ENTRY_REVIEW_20261104',
    'SOUTH_HORIZON_REPAIR_20261104', 'SOUTH_STREET_LOOP_20261104',
)
for filename in ('city-scene.blend', 'city-scene-lightweight.blend'):
    bpy.ops.wm.open_mainfile(filepath=str(root / 'assets/environment' / filename))
    for name in collections:
        assert bpy.data.collections.get(name), f'{filename}: missing collection {name}'
    for name in ('MainCamera', 'UnderBridgeReview', 'NorthStreetReview20261104',
                 'WestStreetReview20261104', 'EastStreetReview20261104', 'LandmarkWideReview20261104', 'SouthGapReview20261104',
                 'SouthOuterStreetReview20261104', 'SouthRearCrossReview20261104'):
        assert bpy.data.objects.get(name), f'{filename}: missing camera {name}'
    for name, body in (('Letter_RADIO', '喫茶'), ('Rear_sign_SOUND', 'レコード')):
        obj = bpy.data.objects.get(name)
        assert obj and obj.type == 'FONT' and obj.data.body == body, f'{filename}: missing text {name}'
        assert obj.data.font and obj.data.font.packed_file, f'{filename}: font not packed for {name}'
    images = [image for image in bpy.data.images if image.source == 'FILE' and image.users > 0]
    unpacked = [image.name for image in images if not image.packed_file]
    assert not unpacked, f'{filename}: images not packed: {unpacked}'
    assert bpy.data.objects.get('Plaza FM lettering'), f'{filename}: missing billboard lettering'
    assert bpy.data.objects.get('COL20261104_Landmark tower body'), f'{filename}: missing collision source'
    assert any('pixel-concrete-source-20261104' in image.name for image in images), f'{filename}: missing concrete texture'
    assert any('street-ribbon-mural-20261104' in image.name for image in images), f'{filename}: missing mural texture'
    print(f'PASS: {filename}: collections, cameras, Japanese fonts, packed images and collision source')
