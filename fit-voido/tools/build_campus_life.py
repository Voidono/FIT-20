"""Build editor-visible ambient scenes/dialogue from the authored campus cast.

Run from the project root. Only generated scenes/ambient/*_life.tscn and
Dialogues/campus_banter.dialogue are overwritten; map placements remain editable.
"""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
cast = json.loads((root / "scenes/ambient/campus_cast.json").read_text(encoding="utf-8"))
dialogue = ["# Optional campus conversations. No progression mutations.\n"]
for location, people in cast.items():
    lines = ['[gd_scene format=3]', '',
             '[ext_resource type="PackedScene" path="res://scenes/Character/dialogue_npc.tscn" id="npc"]',
             '[ext_resource type="Script" path="res://scenes/ambient/ambient_npc.gd" id="ambient"]',
             '[ext_resource type="Resource" path="res://Dialogues/campus_banter.dialogue" id="banter"]']
    for person in people:
        asset = person['asset']
        texture = f'{asset}_down_Idle' if asset in ('NPC_1', 'NPC_2') else 'boykopho2' if asset == 'boykopho' else asset
        lines.append(f'[ext_resource type="Texture2D" path="res://assets/DrawAsset/NPC/{texture}.png" id="tex_{person["id"]}"]')
    lines += ['', f'[node name="{location.title()}Life" type="Node2D"]', 'y_sort_enabled = true', '']
    for person in people:
        ident = person['id']
        x, y = person['pos']
        asset = person['asset']
        skin = asset if asset in ('NPC_1', 'NPC_2', 'boykopho') else ''
        cues = [f'{ident}_{i + 1}' for i in range(len(person['lines']))]
        lines += [f'[node name="{ident}" parent="." instance=ExtResource("npc")]',
                  'script = ExtResource("ambient")', f'position = Vector2({x}, {y})',
                  f'npc_sprite = ExtResource("tex_{ident}")', f'npc_skin = "{skin}"',
                  'dialogue = ExtResource("banter")', f'cue = "{cues[0]}"',
                  'conversation_cues = PackedStringArray(' + ', '.join(json.dumps(c) for c in cues) + ')',
                  f'npc_name = {json.dumps(person["name"], ensure_ascii=False)}',
                  'prompt_text = "Tám chuyện"', 'walk_bob_height = 0.0',
                  'flip_sprite = false', 'animation_fps = 7', 'speed = 28.0',
                  'min_wait = 1.8', 'max_wait = 4.5', 'body_capsule_radius = 7.0',
                  'body_capsule_height = 16.0']
        movement = person.get('move', '') if skin else ''
        lines.append('mode = ' + {'': '0', 'wander': '1', 'patrol': '2'}[movement])
        if movement == 'patrol':
            lines += ['ping_pong = true', 'patrol_points = Array[Vector2]([' + ', '.join(f'Vector2({a}, {b})' for a, b in person['route']) + '])']
        if movement == 'wander':
            lines.append(f'wander_radius = {person["radius"]}.0')
        lines.append('')
        for cue, exchange in zip(cues, person['lines']):
            dialogue += ['~ ' + cue, *exchange, '=> END', '']
    (root / f'scenes/ambient/{location}_life.tscn').write_text('\n'.join(lines), encoding='utf-8')
(root / 'Dialogues/campus_banter.dialogue').write_text('\n'.join(dialogue), encoding='utf-8')
print(f'Built {sum(map(len, cast.values()))} NPCs and {sum(len(p["lines"]) for ps in cast.values() for p in ps)} conversations.')
