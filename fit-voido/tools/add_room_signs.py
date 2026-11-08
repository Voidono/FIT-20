"""Attach room plaques to the current door nodes without moving the map."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
for floor in (2, 3, 4):
    path = root / f"scenes/mapsides/t_{floor}.tscn"
    text = path.read_text(encoding="utf-8")
    if 'id="room_sign"' in text:
        print(f'Floor {floor} already has room signs; edit them in Godot.')
        continue
    resource = '[ext_resource type="PackedScene" path="res://scenes/templates/room_sign.tscn" id="room_sign"]\n'
    text = text.replace('\n[sub_resource ', '\n' + resource + '\n[sub_resource ', 1)
    additions = []
    if floor in (2, 3):
        for match in re.finditer(r'\[node name="([^"]+)" type="Sprite2D" parent="Doors"[^\n]*\]\n(.*?)(?=\n\[node|\Z)', text, re.S):
            name, properties = match.groups()
            if not (name.startswith("210door") or name.startswith("Door")):
                continue
            upper = name.startswith("210door")
            order = {"210door":10, "210door2":11, "210door3":13, "210door4":12,
                     "210door5":4, "210door6":3, "210door7":2, "210door8":1,
                     "Door1":17, "Door2":16, "Door3":15, "Door4":14,
                     "Door5":8, "Door6":7, "Door7":6, "Door8":5}[name]
            number = str(floor * 100 + order)
            title = "VĂN PHÒNG KHOA" if floor == 2 and order == 10 else "PHÒNG LÀM VIỆC" if upper else "PHÒNG HỌC"
            parent = f"Doors/{name}"
            scale_y = 1.230769 if "0.8125001" in properties else 1.0
            additions += [f'[node name="RoomNumberSign" parent="{parent}" instance=ExtResource("room_sign")]',
                          f'position = Vector2(0, {-52 * scale_y:.5f})',
                          f'scale = Vector2(1, {scale_y})', f'room_number = "{number}"',
                          f'room_title = "{title}"', f'subtitle = "NHÀ C · TẦNG {floor}"', '']
            if upper:
                boss = parent + "/FacultyBossDoor"
                additions += [f'[node name="Sign" parent="{boss}" index="1"]', 'visible = false', '']
    else:
        for parent, number, title in [("SceneDoor", "417", "PHÒNG MÁY"), ("SceneDoor2", "416", "GIẢNG VIÊN"), ("Room419Door", "419", "TRUYỀN THÔNG")]:
            additions += [f'[node name="RoomNumberSign" parent="{parent}" instance=ExtResource("room_sign")]',
                          'position = Vector2(0, -52)', f'room_number = "{number}"',
                          f'room_title = "{title}"', 'subtitle = "KHOA CNTT · NHÀ C"', '']
    path.write_text(text.rstrip() + '\n\n' + '\n'.join(additions) + '\n', encoding="utf-8")
    print(f'Added room signs to floor {floor}')
