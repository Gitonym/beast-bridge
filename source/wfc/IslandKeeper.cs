using Godot;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using ImGuiNET;


public partial class IslandKeeper : Node3D
{
    [Export] private float cellSize = 4.0f;
    [Export] private float islandGridCellWidth = 100;
    [Export] private Vector3I gridSize = new Vector3I(20, 10, 20);

    private Dictionary<Vector2I, WFC> islandGrid = [];
    private Node3D player;
    List<CellItem> cellItems = new List<CellItem>();

    public override void _Ready()
    {
        base._Ready();
        player = GetNode<Node3D>("%Player");
        CreateTiles();
    }

    public override void _Process(double delta)
    {
        base._Process(delta);
        DrawUI();
    }

    public override void _PhysicsProcess(double delta)
    {
        base._PhysicsProcess(delta);
        SpawnIsland(GetIslandCellIndex(player.GlobalPosition));
    }

    private Vector2I GetIslandCellIndex(Vector3 position)
    {
        float positionX = position.X;
        float positionZ = position.Z;

        float offsetPositionX = positionX + islandGridCellWidth / 2.0f;
        float offsetPositionZ = positionZ + islandGridCellWidth / 2.0f;

        int islandGridPositionX = (int)MathF.Floor(offsetPositionX / islandGridCellWidth);
        int islandGridPositionZ = (int)MathF.Floor(offsetPositionZ / islandGridCellWidth);

        return new Vector2I(islandGridPositionX, islandGridPositionZ);
    }

    private bool CheckIfIslandExists(Vector2I index)
    {
        return islandGrid.ContainsKey(index) && islandGrid[index] != null;
    }

    private void SpawnIsland(Vector2I index)
    {
        //if (index.X == 0 && index.Y == 0) { return; }
        if (CheckIfIslandExists(index)) { return; }
        islandGrid[index] = GenerateIsland(index);
    }

    private WFC GenerateIsland(Vector2I index)
    {
        WFC wfc = new WFC(gridSize, cellSize, cellItems);

        //wfc.SetSeed((ulong)(index.X + index.Y));
        //wfc.SetState(17855032261213824483);

        void ConstrainGrid()
        {
            CellItem grassItem = wfc.GetItemByName("grass");
            CellItem airItem = wfc.GetItemByName("air");
            int gridSize = wfc.Get1DIndex(wfc.size - Vector3I.One) + 1;

            for (int index1d = 0; index1d < gridSize; index1d++)
            {
                Vector3I index3d = wfc.Get3DIndex(index1d);

                // Set the top to be air
                if (index3d.Y == index3d.Y - 1)
                {
                    wfc.SetCell(index1d, airItem);
                }

                // Set ring at the bottom to be grass
                if (index3d.Y == 0 && (index3d.X == 0 || index3d.X == wfc.size.X - 1 || index3d.Z == 0 || index3d.Z == wfc.size.Z - 1))
                {
                    wfc.SetCell(index1d, grassItem);
                }
            }
        }

        wfc.SetConstrainGrid(ConstrainGrid);
        AddChild(wfc);
        wfc.Position = new Vector3(islandGridCellWidth * index.X, 0, islandGridCellWidth * index.Y);
        Task.Run(() => DistributedGenerate(wfc));
        return wfc;
    }

    private void DistributedGenerate(WFC wfc)
    {
        GD.Print("Time to collapse:\t", GetExecutionTimeUsec(() => { while (!wfc.CollapseGrid()) { } }) / 1000000.0, " Seconds");
        GD.Print("Time to spawn:\t\t", GetExecutionTimeUsec(wfc.SpawnItems) / 1000000.0, " Seconds");   // after the grid collapsed spawn the chosen cellItems and add them to the scene tree
        GD.Print("\n\n");
    }

    // Executes the function and returns the time it took to execute in microseconds (1/1000000 Seconds)
    private ulong GetExecutionTimeUsec(Action function)
    {
        ulong startTime = Time.GetTicksUsec();
        function();
        ulong endTime = Time.GetTicksUsec();
        return endTime - startTime;
    }

    // This function creates all different CellItems and adds them to the cellItems list
    private void CreateTiles()
    {
        // base
        // Create a CellItem that has no rotations through the Cellitem constructor
        cellItems.Add(new CellItem("air", "", "air", "air", "air", "air", "air", "air", 5.0f));
        cellItems.Add(new CellItem("ground", "res://wfc/tiles/ground.glb", "ground", "ground", "ground", "ground", "ground", "ground", 0.0f));
        cellItems.Add(new CellItem("grass", "res://wfc/tiles/grass.glb", "grass", "grass", "grass", "grass", "air", "ground", 10.0f));

        // paths
        //cellItems.Add(new CellItem("path_cross", "res://wfc/tiles/path_cross.glb", "path", "path", "path", "path", "air", "ground", 0.05f));
        // NewMirrored automatically creates two identical CellItems rotated by 90 degrees
        //cellItems.AddRange(CellItem.NewMirrored("path_straight", "res://wfc/tiles/path_straight.glb", "path", "grass", "path", "grass", "air", "ground", 1.0f));
        // NewCardinal automatically creates four identical CellItems each rotated by 90 degrees
        //cellItems.AddRange(CellItem.NewCardinal("path_bend", "res://wfc/tiles/path_bend.glb", "path", "path", "grass", "grass", "air", "ground", 1.0f));
        //cellItems.AddRange(CellItem.NewCardinal("path_end", "res://wfc/tiles/path_end.glb", "path", "grass", "grass", "grass", "air", "ground", -1.0f));
        //cellItems.AddRange(CellItem.NewCardinal("path_t", "res://wfc/tiles/path_t.glb", "path", "path", "grass", "path", "air", "ground", 0.05f));

        // slope
        cellItems.AddRange(CellItem.NewCardinal("grass_slope_top", "res://wfc/tiles/grass_slope_top.glb", "grass", "slope_top_r", "air", "slope_top_r", "air", "edge_r", 0.0f));
        cellItems.AddRange(CellItem.NewCardinal("grass_slope_bottom", "res://wfc/tiles/grass_slope_bottom.glb", "ground", "slope_bottom_r", "air", "slope_bottom_r", "edge_r", "slope_bottom", 0.0f));
        cellItems.AddRange(CellItem.NewCardinal("grass_slope_top_corner", "res://wfc/tiles/grass_slope_top_corner.glb", "slope_top_f", "slope_top_r", "air", "air", "air", "corner_r", 0.0f));
        cellItems.AddRange(CellItem.NewCardinal("grass_slope_bottom_corner", "res://wfc/tiles/grass_slope_bottom_corner.glb", "slope_bottom_f", "slope_bottom_r", "air", "air", "corner_r", "slope_bottom_corner_r", 0.0f));
        cellItems.AddRange(CellItem.NewCardinal("slope_wall", "res://wfc/tiles/slope_wall.glb", "ground", "edge_r", "air", "edge_r", "edge_r", "edge_r", 0.0f));
        cellItems.AddRange(CellItem.NewCardinal("slope_corner", "res://wfc/tiles/slope_corner.glb", "edge_r", "edge_r", "air", "air", "corner_r", "corner_r", 0.0f));

        // connectors
        cellItems.AddRange(CellItem.NewCardinal("slope_grass_connector", "res://wfc/tiles/ground.glb", "ground", "slope_grass_connector", "grass", "slope_grass_connector", "slope_bottom", "ground", 2.0f));
        cellItems.AddRange(CellItem.NewCardinal("slope_grass_corner_connector", "res://wfc/tiles/ground.glb", "slope_grass_connector", "slope_grass_connector", "grass", "grass", "slope_bottom_corner_r", "ground", 0.0f));

        // walls
        cellItems.AddRange(CellItem.NewCardinal("wall", "res://wfc/tiles/wall.glb", "air", "wall_edge_r", "air", "wall_edge_r", "air", "wall", 0.0f));
        cellItems.AddRange(CellItem.NewCardinal("door", "res://wfc/tiles/door.glb", "air", "wall_edge_r", "air", "wall_edge_r", "air", "wall", 0.0f));
        cellItems.AddRange(CellItem.NewCardinal("wall_inside_corner", "res://wfc/tiles/wall_inside_corner.glb", "air", "air", "wall_edge_f", "wall_edge_r", "air", "wall", 0.0f));
        //cellItems.AddRange(CellItem.NewCardinal("wall_outside_corner", "res://wfc/tiles/wall_outside_corner.glb", "wall_edge_f", "wall_edge_r", "air", "air", "air", "wall", 0.5f));

        // foundation
        cellItems.AddRange(CellItem.NewCardinal("foundation_edge", "res://wfc/tiles/ground.glb", "foundation_inside", "foundation_edge", "grass", "foundation_edge", "wall", "ground", 2.0f));
        cellItems.AddRange(CellItem.NewCardinal("foundation_corner", "res://wfc/tiles/ground.glb", "foundation_edge", "foundation_edge", "grass", "grass", "wall", "ground", 0.5f));
        cellItems.Add(new CellItem("foundation_inside", "res://wfc/tiles/ground.glb", "foundation_inside", "foundation_inside", "foundation_inside", "foundation_inside", "air", "ground", 2.0f));
    }

    private void DrawUI()
    {
		ImGui.Begin("Debug");
        Vector2I islandIndex = GetIslandCellIndex(player.GlobalPosition);
        ImGui.Text("Island Index: " + islandIndex.X + ", " + islandIndex.Y);
		ImGui.End();
    }
}
