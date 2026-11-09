extends CharacterBody3D

const WALK_SPEED := 6.0
const JUMP_VELOCITY := 5.0
const LOOK_SENSITIVITY := 0.0022
const TOUCH_LOOK_SENSITIVITY := 0.004
const HOLD_DISTANCE := 4.0
const JOYSTICK_RADIUS := 72.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera: Camera3D
var ray: RayCast3D
var held_body: RigidBody3D
var touch_move := Vector2.ZERO
var move_finger := -1
var look_finger := -1
var move_origin := Vector2.ZERO
var screen_size := Vector2(1280, 720)

func _ready() -> void:
    name = "Player"
    _build_body()
    screen_size = get_viewport().get_visible_rect().size
    if not OS.has_feature("mobile"):
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_body() -> void:
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.38
    capsule.height = 1.8
    collision.shape = capsule
    collision.position.y = 0.9
    add_child(collision)

    var head := Node3D.new()
    head.name = "Head"
    head.position.y = 1.62
    add_child(head)

    camera = Camera3D.new()
    camera.current = true
    camera.fov = 78.0
    camera.near = 0.08
    head.add_child(camera)

    ray = RayCast3D.new()
    ray.target_position = Vector3(0, 0, -HOLD_DISTANCE)
    ray.collide_with_areas = false
    ray.collide_with_bodies = true
    camera.add_child(ray)

func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * LOOK_SENSITIVITY)
        camera.rotate_x(-event.relative.y * LOOK_SENSITIVITY)
        camera.rotation.x = clamp(camera.rotation.x, -1.48, 1.48)
    elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if not OS.has_feature("mobile") and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    elif event is InputEventScreenTouch:
        if event.pressed:
            var p := event.position
            var size := get_viewport().get_visible_rect().size
            # Left half: virtual movement stick. Right half: camera swipe.
            if p.x < size.x * 0.48 and move_finger == -1:
                move_finger = event.index
                move_origin = p
                touch_move = Vector2.ZERO
            elif p.x >= size.x * 0.48 and look_finger == -1 and p.y < size.y * 0.72:
                look_finger = event.index
        else:
            if event.index == move_finger:
                move_finger = -1
                touch_move = Vector2.ZERO
            if event.index == look_finger:
                look_finger = -1
    elif event is InputEventScreenDrag:
        if event.index == move_finger:
            var offset: Vector2 = event.position - move_origin
            touch_move = Vector2(offset.x, offset.y).limit_length(JOYSTICK_RADIUS) / JOYSTICK_RADIUS
        elif event.index == look_finger:
            rotate_y(-event.relative.x * TOUCH_LOOK_SENSITIVITY)
            camera.rotate_x(-event.relative.y * TOUCH_LOOK_SENSITIVITY)
            camera.rotation.x = clamp(camera.rotation.x, -1.48, 1.48)

func set_mobile_move(value: Vector2) -> void:
    touch_move = value

func add_mobile_look(value: Vector2) -> void:
    rotate_y(-value.x * TOUCH_LOOK_SENSITIVITY)
    camera.rotate_x(-value.y * TOUCH_LOOK_SENSITIVITY)
    camera.rotation.x = clamp(camera.rotation.x, -1.48, 1.48)

func _physics_process(delta: float) -> void:
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    if touch_move.length() > 0.05:
        input_dir = touch_move
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

    if not is_on_floor():
        velocity.y -= gravity * delta
    elif Input.is_action_just_pressed("jump"):
        velocity.y = JUMP_VELOCITY

    if direction.length() > 0.01:
        velocity.x = direction.x * WALK_SPEED
        velocity.z = direction.z * WALK_SPEED
    else:
        velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * 7.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, WALK_SPEED * 7.0 * delta)

    if held_body and is_instance_valid(held_body):
        var target := camera.global_position + (-camera.global_transform.basis.z * HOLD_DISTANCE)
        held_body.global_position = held_body.global_position.lerp(target, min(delta * 9.0, 1.0))
        held_body.linear_velocity = Vector3.ZERO
        held_body.angular_velocity = Vector3.ZERO

    move_and_slide()

func try_pickup() -> void:
    ray.force_raycast_update()
    if held_body:
        held_body.gravity_scale = 1.0
        held_body = null
        return
    if ray.is_colliding():
        var hit = ray.get_collider()
        if hit is RigidBody3D and not hit.is_in_group("ungrabbable"):
            held_body = hit
            held_body.gravity_scale = 0.0

func throw_held() -> void:
    if held_body and is_instance_valid(held_body):
        held_body.gravity_scale = 1.0
        held_body.apply_central_impulse(-camera.global_transform.basis.z * 9.0)
        held_body = null

func get_aim_hit() -> Dictionary:
    ray.force_raycast_update()
    if ray.is_colliding():
        return {"position": ray.get_collision_point(), "normal": ray.get_collision_normal(), "collider": ray.get_collider()}
    return {}
