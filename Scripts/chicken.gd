extends Node3D

@onready var mesh1 = $Sketchfab_model/a2a4d0ccce7040fc8fb1faf42bcbd7b8_fbx/RootNode/chicken/chicken_Mat_0
@onready var mesh2 = $Sketchfab_model/a2a4d0ccce7040fc8fb1faf42bcbd7b8_fbx/RootNode/chicken/chicken_Mat_02

func hideMesh():
	mesh1.cast_shadow = mesh1.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	mesh2.cast_shadow = mesh2.SHADOW_CASTING_SETTING_SHADOWS_ONLY
