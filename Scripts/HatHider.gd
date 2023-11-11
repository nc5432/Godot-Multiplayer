extends Node3D

@export var meshes: Array[MeshInstance3D]

func hideMesh():
	for mesh in meshes:
		mesh.cast_shadow = mesh.SHADOW_CASTING_SETTING_SHADOWS_ONLY
