using Godot;
using System;
using System.Collections.Generic;

public partial class wfcs : Node3D {

	WFC wfc;
	List<CellItem> cellItems = new List<CellItem>();
	
	public override void _Ready()
	{
		CreateTiles();
		wfc = new WFC(new Vector3I(60, 10, 60), 4.0f, cellItems);
		//wfc.SetState(2011864834308092530);
		wfc.SetSeed(16110029907191006272);	//16110029907191006272
		AddChild(wfc);
		wfc.CollapseGrid();
		wfc.SpawnItems();
	}

	private void CreateTiles()
	{
		// base
		cellItems.Add(new CellItem("air", "", "air", "air", "air", "air", "air", "air", 1.0f));
		cellItems.Add(new CellItem("ground", "res://wfc/tiles/ground.glb", "ground", "ground", "ground", "ground", "ground", "ground", 1.0f));
		cellItems.Add(new CellItem("grass", "res://wfc/tiles/grass.glb", "grass", "grass", "grass", "grass", "air", "ground", 1.0f));
		
		// paths
		cellItems.Add(new CellItem("path_cross", "res://wfc/tiles/path_cross.glb", "path", "path", "path", "path", "air", "ground", 0.0f));
		cellItems.AddRange(CellItem.NewMirrored("path_straight", "res://wfc/tiles/path_straight.glb", "path", "grass", "path", "grass", "air", "ground", 0.0f));
		cellItems.AddRange(CellItem.NewCardinal("path_bend", "res://wfc/tiles/path_bend.glb", "path", "path", "grass", "grass", "air", "ground", 0.0f));
		cellItems.AddRange(CellItem.NewCardinal("path_end", "res://wfc/tiles/path_end.glb", "path", "grass", "grass", "grass", "air", "ground", 0.1f));
		cellItems.AddRange(CellItem.NewCardinal("path_t", "res://wfc/tiles/path_t.glb", "path", "path", "grass", "path", "air", "ground", 0.0f));
		
		// slope
		cellItems.AddRange(CellItem.NewCardinal("grass_slope_top", "res://wfc/tiles/grass_slope_top.glb", "grass", "slope_top_r", "air", "slope_top_r", "air", "edge_r"));
		cellItems.AddRange(CellItem.NewCardinal("grass_slope_bottom", "res://wfc/tiles/grass_slope_bottom.glb", "ground", "slope_bottom_r", "air", "slope_bottom_r", "edge_r", "slope_bottom"));
		cellItems.AddRange(CellItem.NewCardinal("grass_slope_top_corner", "res://wfc/tiles/grass_slope_top_corner.glb", "slope_top_f", "slope_top_r", "air", "air", "air", "corner_r", 0.5f));
		cellItems.AddRange(CellItem.NewCardinal("grass_slope_bottom_corner", "res://wfc/tiles/grass_slope_bottom_corner.glb", "slope_bottom_f", "slope_bottom_r", "air", "air", "corner_r", "slope_bottom_corner_r", 0.5f));
		cellItems.AddRange(CellItem.NewCardinal("slope_wall", "res://wfc/tiles/slope_wall.glb", "ground", "edge_r", "air", "edge_r", "edge_r", "edge_r"));
		cellItems.AddRange(CellItem.NewCardinal("slope_corner", "res://wfc/tiles/slope_corner.glb", "edge_r", "edge_r", "air", "air", "corner_r", "corner_r"));
		
		// connectors
		cellItems.AddRange(CellItem.NewCardinal("slope_grass_connector", "res://wfc/tiles/ground.glb", "ground", "slope_grass_connector", "grass", "slope_grass_connector", "slope_bottom", "ground"));
		cellItems.AddRange(CellItem.NewCardinal("slope_grass_corner_connector", "res://wfc/tiles/ground.glb", "slope_grass_connector", "slope_grass_connector", "grass", "grass", "slope_bottom_corner_r", "ground"));
	
		// walls
		cellItems.AddRange(CellItem.NewCardinal("wall", "res://wfc/tiles/wall.glb", "air", "wall_edge_r", "air", "wall_edge_r", "air", "wall", 2.0f));
		cellItems.AddRange(CellItem.NewCardinal("door", "res://wfc/tiles/door.glb", "air", "wall_edge_r", "air", "wall_edge_r", "air", "wall", 0.5f));
		cellItems.AddRange(CellItem.NewCardinal("wall_inside_corner", "res://wfc/tiles/wall_inside_corner.glb", "air", "air", "wall_edge_f", "wall_edge_r", "air", "wall", 2.0f));
		cellItems.AddRange(CellItem.NewCardinal("wall_outside_corner", "res://wfc/tiles/wall_outside_corner.glb", "wall_edge_f", "wall_edge_r", "air", "air", "air", "wall", 0.5f));
	
		// socket
		cellItems.AddRange(CellItem.NewCardinal("foundation_edge", "res://wfc/tiles/ground.glb", "foundation_inside", "foundation_edge", "grass", "foundation_edge", "wall", "ground", 2.0f));
		cellItems.AddRange(CellItem.NewCardinal("foundation_corner", "res://wfc/tiles/ground.glb", "foundation_edge", "foundation_edge", "grass", "grass", "wall", "ground", 2.0f));
		cellItems.Add(new CellItem("foundation_inside", "res://wfc/tiles/ground.glb", "foundation_inside", "foundation_inside", "foundation_inside", "foundation_inside", "air", "ground", 2.0f));
	}
}
