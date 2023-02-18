extends GutTest

func test_stack_tiles():
	var tiles = PTTiles.new()
	var cell = Vector2(0,0)
	tiles.stack_tile_at_cell(0,cell)
	assert_eq(tiles.get_stack_at_cell(cell), "0.up ")

func test_stack_tiles_high():
	var tiles = PTTiles.new()
	var cell = Vector2(0,0)
	tiles.stack_tile_at_cell(0,cell)
	tiles.stack_tile_at_cell(1,cell)
	tiles.stack_tile_at_cell(2,cell)
	assert_eq(tiles.get_stack_at_cell(cell), "0.up 1.up 2.up ")

func test_stack_tiles_high_with_dir():
	var tiles = PTTiles.new()
	var cell = Vector2(0,0)
	tiles.stack_tile_at_cell(0,cell, Directions.LEFT)
	tiles.stack_tile_at_cell(1,cell, Directions.RIGHT)
	tiles.stack_tile_at_cell(2,cell, Directions.DOWN)
	assert_eq(tiles.get_stack_at_cell(cell), "0.left 1.right 2.down ")

func test_remove_tile():
	var tiles = PTTiles.new()
	var cell = Vector2(0,0)
	tiles.stack_tile_at_cell(0,cell)
	tiles.remove_tile_from_cell(0,cell)
	assert_eq(tiles.get_stack_at_cell(cell), ". ")

func test_remove_lowest_tile():
	var tiles = PTTiles.new()
	var cell = Vector2(0,0)
	tiles.stack_tile_at_cell(0,cell)
	tiles.stack_tile_at_cell(1,cell)
	tiles.remove_tile_from_cell(0,cell)
	assert_eq(tiles.get_stack_at_cell(cell), "1.up . ")

func test_stack_dir():
	var tiles = PTTiles.new()
	var cell = Vector2(0,0)
	tiles.stack_tile_at_cell(0,cell,Directions.LEFT)
	tiles.stack_tile_at_cell(0,cell,Directions.RIGHT)
	assert_eq(tiles.get_stack_at_cell(cell), "0.left 0.right ")

func test_remove_dir():
	var tiles = PTTiles.new()
	var cell = Vector2(0,0)
	tiles.stack_tile_at_cell(0,cell,Directions.LEFT)
	tiles.stack_tile_at_cell(0,cell,Directions.RIGHT)
	tiles.remove_tile_from_cell(0,cell,Directions.LEFT)
	assert_eq(tiles.get_stack_at_cell(cell), "0.right . ")

func test_remove_dir_complex():
	var tiles = PTTiles.new()
	var cell = Vector2(0,0)
	tiles.stack_tile_at_cell(0,cell,Directions.UP)
	tiles.stack_tile_at_cell(0,cell,Directions.LEFT)
	tiles.stack_tile_at_cell(0,cell,Directions.RIGHT)
	tiles.stack_tile_at_cell(0,cell,Directions.DOWN)
	tiles.remove_tile_from_cell(0,cell,Directions.DOWN)
	assert_eq(tiles.get_stack_at_cell(cell), "0.up 0.left 0.right . ")
	
