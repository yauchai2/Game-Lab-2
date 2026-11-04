"""Create a separate, static-batched city scene for Blender 4.3.

From the repository root:
    blender -b --python-exit-code 1 --python tools/blender/batch-city-scene.py
Use `-- --source path --output path --report path` to select other files.
The source is never overwritten. The output is a candidate, so rerender and
check it after changes; this is not an engine performance benchmark.
"""
import argparse
import json
import math
from pathlib import Path
import sys

import bpy

ROOT = Path(__file__).resolve().parents[2]
COLLECTIONS = (
    'BACKSTREET_SHAPE_VARIATION', 'BILLBOARD_DETAIL', 'PLAZA_SCULPTURE',
    'DISTANT_CONTEXT_DETAIL', 'PLATFORM_DETAIL', 'CITY_VISUAL', 'DETAIL_PASS',
    'STREET_PASS', 'DISTRICT_REFINEMENT', 'PUBLIC_SPACE', 'ENVIRONMENT_PASS',
    'FACADE_DESIGN', 'CURVED_CITY_ELEMENTS', 'BACKSTREET_DETAIL_PASS',
    'SIDE_STREETS', 'BACKSTREET_COMPLETION', 'HORIZON_AND_SIGN_CLEANUP',
    'BUILDING_DETAIL_PASS', 'ARCHITECTURE_RECOMPOSITION', 'VIDEO_ARCHITECTURE_V2',
    'FACADE_DEPTH_PASS', 'VIDEO_URBAN_DETAIL_20261104', 'SKYLINE_REFINEMENT_20261104',
    'NORTH_CROSS_STREET_20261104', 'OUTER_STREETS_20261104',
    'OUTER_SHOP_SIGNS_20261104', 'ROUND_LANDMARK_20261104', 'PLAZA_FINISH_20261104',
    'PLAZA_BILLBOARD_STUDY_20261104', 'SOUTH_HORIZON_REPAIR_20261104',
    'SOUTH_STREET_LOOP_20261104', 'SOUTH_EDGE_FINISH_20261104',
)
PRESERVE_PREFIXES = ('Ground', 'UpperDeck', 'RailDeck', 'BridgePier',
                     'Building_', 'Train_', 'Corner_')
CELL_SIZE = 25

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--source', type=Path, default=ROOT / 'assets/environment/city-scene.blend')
parser.add_argument('--output', type=Path, default=ROOT / 'assets/environment/city-scene-lightweight.blend')
parser.add_argument('--report', type=Path)
argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
args = parser.parse_args(argv)
if args.source.resolve() == args.output.resolve():
    raise ValueError('Source and output must be different files')

bpy.ops.wm.open_mainfile(filepath=str(args.source.resolve()))
scene = bpy.context.scene
bpy.context.view_layer.update()
major_forms = bpy.data.collections.get('OUTLINE_MAJOR_FORMS')
groups = {}
visited = set()

for collection_name in COLLECTIONS:
    collection = bpy.data.collections.get(collection_name)
    if collection is None:
        continue
    for obj in list(collection.objects):
        if obj.name in visited:
            continue
        visited.add(obj.name)
        if (obj.type != 'MESH' or obj.hide_render or not obj.visible_get()
                or obj.modifiers or obj.parent or obj.animation_data
                or obj.data.shape_keys or obj.vertex_groups or len(obj.keys()) > 0):
            continue
        if (obj.name.startswith(PRESERVE_PREFIXES) or obj.matrix_world.determinant() < 0
                or (major_forms and obj.name in major_forms.objects)):
            continue
        if (len(obj.data.vertices) != 8 or len(obj.data.polygons) != 6
                or len(obj.material_slots) != 1 or any(p.use_smooth for p in obj.data.polygons)):
            continue
        material = obj.material_slots[0].material
        if not material or not material.use_nodes:
            continue
        # Object-dependent or textured shaders may change appearance when merged.
        if any(node.type.startswith('TEX_') or node.type in {'TEX_COORD', 'OBJECT_INFO', 'ATTRIBUTE', 'VERTEX_COLOR'}
               for node in material.node_tree.nodes):
            continue
        key = (material.name, math.floor(obj.location.x / CELL_SIZE),
               math.floor(obj.location.y / CELL_SIZE))
        group = groups.setdefault(key, {'vertices': [], 'faces': [], 'objects': [], 'material': material})
        offset = len(group['vertices'])
        group['vertices'].extend(tuple(obj.matrix_world @ vertex.co) for vertex in obj.data.vertices)
        group['faces'].extend(tuple(offset + index for index in face.vertices) for face in obj.data.polygons)
        group['objects'].append(obj)

output_collection = bpy.data.collections.new('STATIC_BATCHES_20261104')
scene.collection.children.link(output_collection)
removed = []
created = 0
for key, group in groups.items():
    if len(group['objects']) < 6:
        continue
    mesh = bpy.data.meshes.new('RegionBatchMesh')
    mesh.from_pydata(group['vertices'], [], group['faces'])
    mesh.update()
    mesh.materials.append(group['material'])
    obj = bpy.data.objects.new('RegionBatch_%s_%s_%s' % key, mesh)
    output_collection.objects.link(obj)
    for item in group['objects']:
        removed.append(item.name)
        bpy.data.objects.remove(item, do_unlink=True)
    created += 1

scene.camera = bpy.data.objects['MainCamera']
scene['status'] = 'Experimental static-batched candidate; separately preserved editable scene is authoritative.'
scene['batch_removed_objects'] = len(removed)
scene['batch_created_objects'] = created
args.output.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(args.output.resolve()))
if args.report:
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps({
        'source': str(args.source), 'target': str(args.output),
        'removed': len(removed), 'created': created, 'cell_size_m': CELL_SIZE,
        'removed_names': removed,
    }, indent=2))
print('BATCH_RESULT', len(removed), created, flush=True)
