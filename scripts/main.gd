extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const BuildBlockScript = preload("res://scripts/placed_block.gd")

var player: CharacterBody3D
var world_root: Node3D
var build_mode := false
var selected_material := 0
var status_label: Label
var mobile_controls: Control
var object_count := 0

var materials: Array[StandardMaterial3D] = []

func _ready() -> void:
    _create_materials()
    _create_environment()
    _create_player()
    _create_test_objects()
    _create_ui()
    _update_status()

func _create_materials() -> void:
    for color in [Color(0.34,0.39,0.45), Color(0.18,0.48,0.72), Color(0.72,0.34,0.16), Color(0.28,0.62,0.40)]:
        var mat := StandardMaterial3D.new()
        mat.albedo_color = color
        mat.roughness = 0.82
        materials.append(mat)

func _create_environment() -> void:
    world_root = Node3D.new()
    world_root.name = "Sandbox"
    add_child(world_root)

    var env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.035, 0.055, 0.085)
    sky_mat.sky_horizon_color = Color(0.22, 0.27, 0.32)
    sky_mat.ground_bottom_color = Color(0.035, 0.04, 0.045)
    sky_mat.ground_horizon_color = Color(0.16, 0.18, 0.20)
    sky.sky_material = sky_mat
    environment.sky = sky
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.48, 0.54, 0.62)
    environment.ambient_light_energy = 0.55
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.fog_enabled = true
    environment.fog_light_color = Color(0.30, 0.36, 0.43)
    environment.fog_density = 0.006
    environment.fog_sky_affect = 0.35
    env.environment = environment
    add_child(env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -28, 0)
    sun.light_energy = 1.45
    sun.shadow_enabled = true
    sun.directional_shadow_max_distance = 55.0
    add_child(sun)

    _make_static_box("Ground", Vector3(0,-0.5,0), Vector3(70,1,70), Color(0.19,0.21,0.23))
    _make_static_box("BackWall", Vector3(0,4,-24), Vector3(48,8,1), Color(0.24,0.27,0.29))
    _make_static_box("LeftWall", Vector3(-24,4,0), Vector3(1,8,48), Color(0.21,0.24,0.27))
    _make_static_box("RightWall", Vector3(24,4,0), Vector3(1,8,48), Color(0.21,0.24,0.27))
    _make_static_box("Platform", Vector3(0,0.12,0), Vector3(12,0.24,12), Color(0.28,0.30,0.32))

    for x in [-16.0, 16.0]:
        for z in [-16.0, 16.0]:
            _make_static_box("Support", Vector3(x,3.0,z), Vector3(0.7,6,0.7), Color(0.31,0.34,0.36))
    _make_static_box("Beam", Vector3(0,6.3,-16), Vector3(33,0.45,0.65), Color(0.27,0.30,0.32))

func _make_static_box(label: String, pos: Vector3, size: Vector3, color: Color) -> void:
    var body := StaticBody3D.new()
    body.name = label
    body.position = pos
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.9
    mesh.material_override = mat
    body.add_child(mesh)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    world_root.add_child(body)

func _create_player() -> void:
    player = CharacterBody3D.new()
    player.set_script(PlayerScript)
    player.position = Vector3(0,0.2,8)
    add_child(player)

func _create_test_objects() -> void:
    for i in range(5):
        _spawn_rigid_box(Vector3(-5 + i * 2.2, 1.2, -2), Vector3(1.1,1.1,1.1), materials[i % materials.size()])
    _spawn_breakable_crate(Vector3(0,1.0,-6))
    _spawn_rigid_box(Vector3(3,2.0,-5), Vector3(1.4,0.35,1.4), materials[1])
    _spawn_rigid_box(Vector3(3,3.0,-5), Vector3(1.4,0.35,1.4), materials[2])

func _spawn_rigid_box(pos: Vector3, size: Vector3, mat: Material) -> RigidBody3D:
    var body := RigidBody3D.new()
    body.position = pos
    body.mass = max(0.5, size.x * size.y * size.z)
    body.continuous_cd = true
    body.linear_damp = 0.12
    body.angular_damp = 0.18
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    mesh.material_override = mat
    body.add_child(mesh)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    world_root.add_child(body)
    object_count += 1
    return body

func _spawn_breakable_crate(pos: Vector3) -> void:
    var crate := StaticBody3D.new()
    crate.name = "BreakableCrate"
    crate.position = pos
    crate.add_to_group("breakable")
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(2,2,2)
    mesh.mesh = box
    mesh.material_override = materials[2]
    crate.add_child(mesh)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(2,2,2)
    collision.shape = shape
    crate.add_child(collision)
    world_root.add_child(crate)

func _create_ui() -> void:
    var ui := CanvasLayer.new()
    add_child(ui)
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.add_child(root)

    var title := Label.new()
    title.text = "MAYHEM ENGINE  /  PHYSICS SANDBOX"
    title.position = Vector2(24,18)
    title.add_theme_font_size_override("font_size", 16 if OS.has_feature("mobile") else 18)
    title.add_theme_color_override("font_color", Color(0.86,0.91,0.96))
    root.add_child(title)

    status_label = Label.new()
    status_label.position = Vector2(24,48)
    status_label.add_theme_font_size_override("font_size", 13)
    status_label.add_theme_color_override("font_color", Color(0.62,0.72,0.80))
    root.add_child(status_label)

    var cross := Label.new()
    cross.text = "+"
    cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    cross.position = Vector2(-7,-14)
    cross.add_theme_font_size_override("font_size", 26)
    cross.add_theme_color_override("font_color", Color(0.9,0.95,1))
    root.add_child(cross)

    var help := Label.new()
    help.text = "WASD: move   SPACE: jump   E: pick up / drop   Q: throw\nB: build mode   LMB: use tool / place   1-4: material   ESC: unlock mouse"
    help.position = Vector2(18, get_viewport().get_visible_rect().size.y - (72 if OS.has_feature("mobile") else 62))
    help.add_theme_font_size_override("font_size", 11 if OS.has_feature("mobile") else 13)
    help.add_theme_color_override("font_color", Color(0.72,0.78,0.83))
    root.add_child(help)

    _create_mobile_buttons(root)

func _create_mobile_buttons(root: Control) -> void:
    var build := _make_button(root, "BUILD", Vector2(-116,-148), Vector2(104,42))
    build.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    build.pressed.connect(_toggle_build)
    var spawn := _make_button(root, "SPAWN", Vector2(-116,-98), Vector2(104,42))
    spawn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    spawn.pressed.connect(_spawn_in_front)
    var grab := _make_button(root, "GRAB", Vector2(-230,-98), Vector2(104,42))
    grab.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    grab.pressed.connect(func(): player.try_pickup())
    var throw_btn := _make_button(root, "THROW", Vector2(-230,-48), Vector2(104,42))
    throw_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    throw_btn.pressed.connect(func(): player.throw_held())

    var jump_btn := _make_button(root, "JUMP", Vector2(-116,-48), Vector2(104,42))
    jump_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    jump_btn.button_down.connect(func(): player.velocity.y = 5.0)

    var pad := TouchScreenButton.new()
    pad.name = "TouchMoveHint"
    pad.position = Vector2(48, get_viewport().get_visible_rect().size.y - 150)
    pad.texture_normal = _make_pad_texture()
    pad.texture_pressed = _make_pad_texture()
    pad.action = ""
    root.add_child(pad)
    var hint := Label.new()
    hint.text = "MOVE"
    hint.position = pad.position + Vector2(35,35)
    hint.add_theme_font_size_override("font_size", 12)
    hint.add_theme_color_override("font_color", Color(0.8,0.86,0.9))
    root.add_child(hint)

func _make_pad_texture() -> Texture2D:
    var image := Image.create(110,110,false,Image.FORMAT_RGBA8)
    image.fill(Color(0.15,0.2,0.25,0.28))
    return ImageTexture.create_from_image(image)

func _make_button(parent: Control, text_value: String, pos: Vector2, size: Vector2) -> Button:
    var b := Button.new()
    b.text = text_value
    b.position = pos
    b.size = size
    b.add_theme_font_size_override("font_size", 14)
    b.modulate = Color(0.78,0.88,0.96,0.88)
    parent.add_child(b)
    return b

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_E:
                player.try_pickup()
            KEY_Q:
                player.throw_held()
            KEY_B:
                _toggle_build()
            KEY_1:
                selected_material = 0
            KEY_2:
                selected_material = 1
            KEY_3:
                selected_material = 2
            KEY_4:
                selected_material = 3
            KEY_F:
                _spawn_in_front()
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
            if build_mode:
                _place_block()
            else:
                _use_tool()

func _toggle_build() -> void:
    build_mode = not build_mode
    _update_status()

func _update_status() -> void:
    if status_label:
        status_label.text = "MODE: %s    OBJECTS: %d    MATERIAL: %d" % ["BUILD" if build_mode else "PHYSICS", object_count, selected_material + 1]

func _spawn_in_front() -> void:
    var pos: Vector3 = player.camera.global_position + (-player.camera.global_transform.basis.z * 4.0)
    _spawn_rigid_box(pos, Vector3.ONE, materials[selected_material])
    _update_status()

func _place_block() -> void:
    var hit: Dictionary = player.get_aim_hit()
    var pos: Vector3
    if hit.is_empty():
        pos = player.camera.global_position + (-player.camera.global_transform.basis.z * 5.0)
    else:
        pos = hit.position + hit.normal * 0.52
    var block := _spawn_rigid_box(pos, Vector3.ONE, materials[selected_material])
    block.set_script(BuildBlockScript)
    _update_status()

func _use_tool() -> void:
    var hit: Dictionary = player.get_aim_hit()
    if hit.is_empty():
        return
    var target = hit.collider
    if target is Node and target.is_in_group("breakable"):
        _break_crate(target, hit.position)
    elif target is RigidBody3D:
        target.apply_central_impulse(-player.camera.global_transform.basis.z * 4.0)

func _break_crate(crate: Node3D, impact: Vector3) -> void:
    var center := crate.global_position
    crate.queue_free()
    for x in range(3):
        for y in range(3):
            for z in range(3):
                var piece := _spawn_rigid_box(center + Vector3(x-1,y-1,z-1)*0.48, Vector3(0.46,0.46,0.46), materials[2])
                var away := (piece.global_position - impact).normalized()
                piece.apply_central_impulse(away * randf_range(1.5,4.0) + Vector3.UP * randf_range(0.5,2.0))
    _update_status()
