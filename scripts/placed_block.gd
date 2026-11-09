extends RigidBody3D

# Blocks placed in build mode remain fully physical.
# Use the standard Godot physics inspector to tune mass, damping and collision.
func _ready() -> void:
    add_to_group("player_built")
    mass = 2.0
    linear_damp = 0.08
    angular_damp = 0.12
