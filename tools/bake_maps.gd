extends Node
## Bakes static map rasters (hill shading, heat maps, elevation) into assets/maps/.
## Run:  godot --headless --path . tools/bake_maps.tscn


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/maps")
	for id in CityData.CITY_IDS:
		var t := Time.get_ticks_msec()
		var city := CityMap.new(id)
		MapLayer.hillshade_image(city).save_png("res://assets/maps/%s_hillshade.png" % id)
		city.build_heat_image("pop").save_png("res://assets/maps/%s_pop.png" % id)
		city.build_heat_image("jobs").save_png("res://assets/maps/%s_jobs.png" % id)
		MapLayer.elev_image(city).save_png("res://assets/maps/%s_elev.png" % id)
		city.build_depth_image().save_png("res://assets/maps/%s_depth.png" % id)
		print(id, " baked in ", Time.get_ticks_msec() - t, " ms")
	get_tree().quit()
