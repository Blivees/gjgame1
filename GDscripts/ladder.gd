extends TileMapLayer
## 挂在“梯子瓦片层”上。负责判断某个世界坐标是否压在梯子瓦片上。
##
## 用法：
## 1. 在场景里新建一个 TileMapLayer 作为梯子层（建议命名 LadderLayer），把本脚本挂上去；
## 2. 如果整层画的都是梯子，ladder_coords 留空即可；
## 3. 如果梯子瓦片和地面瓦片混在同一层，把梯子瓦片对应的图集坐标填进 ladder_coords。

# 仅认可这些图集坐标为梯子；留空 = 该层所有瓦片都算梯子。
@export var ladder_coords: Array[Vector2i] = []

## 判断世界坐标 world_position 处是否落在梯子瓦片上
func is_on_ladder(world_position: Vector2) -> bool:
	# 全局坐标先转到本层局部坐标，再换算成格子坐标
	var local_pos := to_local(world_position)
	var coords := local_to_map(local_pos)

	# 该格子没有瓦片
	if get_cell_source_id(coords) == -1:
		return false

	# 整层都是梯子，或该格子在梯子白名单内
	if ladder_coords.is_empty():
		return true
	return get_cell_atlas_coords(coords) in ladder_coords
