using Godot;
using System;
using System.Collections.Generic;
using ImGuiNET;
using System.Linq;

public partial class Visualization : Node3D
{

    private CellItem chosen;
    List<CellItem> cellItems;
    private const float CELL_WIDTH = 4;
    private const float SEPERATION = 4;

    public override void _Ready()
    {
        base._Ready();
        cellItems = CreateTiles();
        chosen = cellItems[1];
        SpawnGridVisualization();
    }

    public override void _Process(double delta)
    {
        base._Process(delta);
        DrawUI();
    }

    private void SpawnGridVisualization()
    {
        SpawnCellItem(chosen, Vector3.Zero);
        SpawnEveryCombinationInEveryDirection();
    }


    private void SpawnCellItem(CellItem cellItemToSpawn, Vector3 offset)
    {
        if (cellItemToSpawn.scenePath == "" || cellItemToSpawn.scenePath == null)
        {
            return;
        }

        Node3D instance = (Node3D)GD.Load<PackedScene>(cellItemToSpawn.scenePath).Instantiate();
        AddChild(instance);
        instance.Translate(offset);
        
		if (cellItemToSpawn.rotation == Vector3I.Forward)
        {
            instance.Rotate(Vector3.Up, Mathf.DegToRad(90));
        }
        else if (cellItemToSpawn.rotation == Vector3I.Left)
        {
            instance.Rotate(Vector3.Up, Mathf.DegToRad(180));
        }
        else if (cellItemToSpawn.rotation == Vector3I.Back)
        {
            instance.Rotate(Vector3.Up, Mathf.DegToRad(-90));
        }

    }

    private void SpawnEveryCombinationInEveryDirection()
    {
        foreach (Vector3 currentDirection in new Vector3[] { Vector3.Right, Vector3.Forward, Vector3.Left, Vector3.Back, Vector3.Up, Vector3.Down })
        {
            SpawnEveryCombinationInDirection(currentDirection);
        }
    }

    private void SpawnEveryCombinationInDirection(Vector3 direction)
    {
        Vector3 offset = Vector3.Zero;
        foreach (CellItem currentItem in cellItems)
        {

            if (chosen.keys[direction] == currentItem.keys[direction * (-1)])
            {
                offset += direction * CELL_WIDTH * SEPERATION;
                SpawnCellItem(chosen, offset);
                SpawnCellItem(currentItem, offset + (direction * CELL_WIDTH));
            }

        }
    }

    private void RemoveAllBlocks()
    {
        foreach (Node child in GetChildren())
        {
            child.QueueFree();
        }
    }

    private void DrawUI()
    {
        ImGui.Begin("Inspector");

        int selectedIndex = 0;
        String[] cellNames = new String[cellItems.Count];
        for (int i = 0; i < cellItems.Count; i++)
        {
            cellNames[i] = cellItems[i].name.ToString();
            if (cellItems[i] == chosen)
            {
                selectedIndex = i;
            }
        }

        if (ImGui.Combo("Choose", ref selectedIndex, cellNames, cellNames.Length))
        {
            GD.Print($"Selected: {cellNames[selectedIndex]}");
            chosen = cellItems[selectedIndex];
            RemoveAllBlocks();
            SpawnGridVisualization();
        }

        ImGui.Text("");
        ImGui.Text("Rules");
        ImGui.Text("Right:" + chosen.keys[Vector3.Right]);
        ImGui.Text("Forward:" + chosen.keys[Vector3.Forward]);
        ImGui.Text("Left:" + chosen.keys[Vector3.Left]);
        ImGui.Text("Back:" + chosen.keys[Vector3.Back]);
        ImGui.Text("Up:" + chosen.keys[Vector3.Up]);
        ImGui.Text("Down:" + chosen.keys[Vector3.Down]);
        ImGui.Text("");

        if (ImGui.Button("Clear"))
        {
            RemoveAllBlocks();
        }

        ImGui.End();
    }


    private List<CellItem> CreateTiles()
    {
        List<CellItem> cellItems =
        [
            // base
            // Create a CellItem that has no rotations through the Cellitem constructor
            new CellItem("air", "", "air", "air", "air", "air", "air", "air", 0.0f),
            new CellItem("ground", "res://wfc/tiles/ground.glb", "ground", "ground", "ground", "ground", "ground", "ground", 0.0f),
            new CellItem("grass", "res://wfc/tiles/grass.glb", "grass", "grass", "grass", "grass", "air", "ground", 1.0f),
            // paths
            new CellItem("path_cross", "res://wfc/tiles/path_cross.glb", "path", "path", "path", "path", "air", "ground", 0.0f),
            // NewMirrored automatically creates two identical CellItems rotated by 90 degrees
            .. CellItem.NewMirrored("path_straight", "res://wfc/tiles/path_straight.glb", "path", "grass", "path", "grass", "air", "ground", 0.0f),
            // NewCardinal automatically creates four identical CellItems each rotated by 90 degrees
            .. CellItem.NewCardinal("path_bend", "res://wfc/tiles/path_bend.glb", "path", "path", "grass", "grass", "air", "ground", 0.0f),
            .. CellItem.NewCardinal("path_end", "res://wfc/tiles/path_end.glb", "path", "grass", "grass", "grass", "air", "ground", 0.1f),
            .. CellItem.NewCardinal("path_t", "res://wfc/tiles/path_t.glb", "path", "path", "grass", "path", "air", "ground", 0.0f),
            // slope
            .. CellItem.NewCardinal("grass_slope_top", "res://wfc/tiles/grass_slope_top.glb", "grass", "slope_top_r", "air", "slope_top_r", "air", "edge_r", 0.0f),
            .. CellItem.NewCardinal("grass_slope_bottom", "res://wfc/tiles/grass_slope_bottom.glb", "ground", "slope_bottom_r", "air", "slope_bottom_r", "edge_r", "slope_bottom", 0.0f),
            .. CellItem.NewCardinal("grass_slope_top_corner", "res://wfc/tiles/grass_slope_top_corner.glb", "slope_top_f", "slope_top_r", "air", "air", "air", "corner_r", 0.0f),
            .. CellItem.NewCardinal("grass_slope_bottom_corner", "res://wfc/tiles/grass_slope_bottom_corner.glb", "slope_bottom_f", "slope_bottom_r", "air", "air", "corner_r", "slope_bottom_corner_r", 0.0f),
            .. CellItem.NewCardinal("slope_wall", "res://wfc/tiles/slope_wall.glb", "ground", "edge_r", "air", "edge_r", "edge_r", "edge_r", 0.0f),
            .. CellItem.NewCardinal("slope_corner", "res://wfc/tiles/slope_corner.glb", "edge_r", "edge_r", "air", "air", "corner_r", "corner_r", 0.0f),
            //.. CellItem.NewCardinal("slope_inside_corner", "/res://scenes/tiles/inside_corner.tscn", "edge_f", "edge_r", "air", "air", "ground", "corner_r", 0.0f),
            // connectors
            .. CellItem.NewCardinal("slope_grass_connector", "res://wfc/tiles/ground.glb", "ground", "slope_grass_connector", "grass", "slope_grass_connector", "slope_bottom", "ground", 0.0f),
            .. CellItem.NewCardinal("slope_grass_corner_connector", "res://wfc/tiles/ground.glb", "slope_grass_connector", "slope_grass_connector", "grass", "grass", "slope_bottom_corner_r", "ground", 0.0f),
            // walls
            .. CellItem.NewCardinal("wall", "res://wfc/tiles/wall.glb", "air", "wall_edge_r", "air", "wall_edge_r", "air", "wall", 0.0f),
            .. CellItem.NewCardinal("door", "res://wfc/tiles/door.glb", "air", "wall_edge_r", "air", "wall_edge_r", "air", "wall", 0.0f),
            .. CellItem.NewCardinal("wall_inside_corner", "res://wfc/tiles/wall_inside_corner.glb", "air", "air", "wall_edge_f", "wall_edge_r", "air", "wall", 0.0f),
            .. CellItem.NewCardinal("wall_outside_corner", "res://wfc/tiles/wall_outside_corner.glb", "wall_edge_f", "wall_edge_r", "air", "air", "air", "wall", 0.5f),

            // foundation
            .. CellItem.NewCardinal("foundation_edge", "res://wfc/tiles/ground.glb", "foundation_inside", "foundation_edge", "grass", "foundation_edge", "wall", "ground", 1.0f),
            .. CellItem.NewCardinal("foundation_corner", "res://wfc/tiles/ground.glb", "foundation_edge", "foundation_edge", "grass", "grass", "wall", "ground", 0.0f),
            new CellItem("foundation_inside", "res://wfc/tiles/ground.glb", "foundation_inside", "foundation_inside", "foundation_inside", "foundation_inside", "air", "ground", 2.0f),
        ];

        return cellItems;
    }
}
