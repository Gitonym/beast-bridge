using Godot;
using System;
using System.Collections.Generic;
using System.Linq;

public partial class WFC : Node3D
{
	Vector3I size;
	float cellSize;

	List<CellItem>[] grid;
	List<CellItem> cellItems;

	Stack<HistoryItem> history;
	Stack<int> modified;

	float lastPrintTime = 0.0f;
	RandomNumberGenerator rng =  new RandomNumberGenerator();
	ulong usedState;

	const int maxIterations = 1500;
	int iterations = 0;
	const ulong timeOut = 0;
	ulong startTime;

	public WFC(Vector3I size, float cellSize, List<CellItem> cellItems)
	{
		RandomizeSeed();
		this.size = size;
		this.cellSize = cellSize;
		this.cellItems = cellItems;
		this.modified = new Stack<int>();
		this.history = new Stack<HistoryItem>();
		InitGrid();
	}

	public void SetSeed(ulong seed = 0)
	{
		if (seed == 0)
		{
			return;
		}
		GD.Print("Set Seed to: ", seed);
		rng.Seed = seed;
	}

	public void SetState(ulong state)
	{
		GD.Print("State has been set to: ", state);
		rng.State = state;
	}

	public void CollapseGrid()
	{
		iterations = 0;
		startTime = Time.GetTicksMsec();
		usedState = rng.State;
		GD.Print("State: ", rng.State);

		while (!IsGridCollapsed())
		{
			iterations += 1;
			PrintProgressbar();
			ulong t = Time.GetTicksMsec();
			if (maxIterations > 0 && iterations >= maxIterations || timeOut > 0 && Time.GetTicksMsec() - startTime >= timeOut)
			{
				Retry();
				return;
			}
			if (modified.Count == 0)
			{
				CollapseCell(GetMinEntropy());
			}
			Propagate();
		}
		GD.PrintRich("[color=green]Success[/color] after ", iterations, " iterations and ", Time.GetTicksMsec() - startTime, " milliseconds. Used state: ", usedState);
	}

	public void SpawnItems()
	{
		if (!IsGridCollapsed())
		{
			GD.PrintErr("The items can only be spawned once the grid has been collapsed!");
			return;
		}
		for (int i = 0; i < grid.GetLength(0); i++)
		{
			CellItem currentItem = grid[i][0];
			if (currentItem.scenePath == "")
			{
				continue;
			}
			Node3D instance = (Node3D)GD.Load<PackedScene>(currentItem.scenePath).Instantiate();
			Vector3I i3d = Get3DIndex(i);
			instance.Position = new Vector3(i3d.X, i3d.Y, i3d.Z) * cellSize;

			if (currentItem.rotation == Vector3I.Forward)
			{
				instance.Rotate(Vector3.Up, Mathf.DegToRad(90));
			}
			else if (currentItem.rotation == Vector3I.Left)
			{
				instance.Rotate(Vector3.Up, Mathf.DegToRad(180));
			}
			if (currentItem.rotation == Vector3I.Back)
			{
				instance.Rotate(Vector3.Up, Mathf.DegToRad(-90));
			}
			AddChild(instance);
		}
	}

	private void InitGrid()
	{
		CellItem grassItem = GetItemByName("grass");
		CellItem airItem = GetItemByName("air");

		int gridSize = Get1DIndex(size - Vector3I.One) + 1;
		grid = new List<CellItem>[gridSize];

		for (int i = 0; i < gridSize; i++)
		{
			Vector3I i3d = Get3DIndex(i);
			grid[i] = new List<CellItem>(cellItems);

			// Set the top to be air
			//if (i3d.Y == size.Y-1)
			//{
			//	SetCell(i, airItem);
			//}
			// Set ring at the bottom to be grass
			if (i3d.Y == 0 && (i3d.X == 0 || i3d.X == size.X-1 || i3d.Z == 0 || i3d.Z == size.Z-1))
			{
				SetCell(i, grassItem);
			}
			// Set middle top to be grass
			//if (i3d == new Vector3I(12, 8, 12))
			//{
			//	SetCell(i, grassItem);
			//}
		}
	}

	private void Retry()
	{
		lastPrintTime = 0.0f;
		GD.PrintRich("[color=orange]Retrying[/color] after ", iterations, " iterations and ", Time.GetTicksMsec() - startTime ," milliseconds");
		iterations = 0;
		history = new Stack<HistoryItem>();
		modified = new Stack<int>();
		InitGrid();
		CollapseGrid();
	}

	private void Propagate()
	{
		while (modified.Count > 0)
		{
			int current1DIndex = modified.Pop();
			Vector3I current3DIndex = Get3DIndex(current1DIndex);

			foreach (Vector3I direction in new Vector3I[] {Vector3I.Right, Vector3I.Forward, Vector3I.Left, Vector3I.Back, Vector3I.Up, Vector3I.Down})
			{
				int neighbourIndex = Get1DIndex(current3DIndex + direction);
				if (!IsValidIndex(neighbourIndex))
				{
					continue;
				}
				if (!AreNeighbours(current1DIndex, neighbourIndex))
				{
					continue;
				}
				List<StringName> currentKeys = new List<StringName>();
				foreach (CellItem currentItem in grid[current1DIndex])
				{
					if (!currentKeys.Contains(currentItem.keys[direction]))
					{
						currentKeys.Add(currentItem.keys[direction]);
					}
				}

				//foreach (CellItem neighbour in grid[neighbourIndex])
				for (int i = grid[neighbourIndex].Count-1; i >= 0; i--)
				{
					CellItem neighbour = grid[neighbourIndex][i];
					if (!currentKeys.Contains(neighbour.keys[direction*(-1)]))
					{
						grid[neighbourIndex].Remove(neighbour);
						history.Push(new HistoryItem(HistoryitemVariant.propagation, neighbourIndex, neighbour, null));
						if (!modified.Contains(neighbourIndex))
						{
							modified.Push(neighbourIndex);
						}
						if (grid[neighbourIndex].Count == 0)
						{
							Backstep();
							return;
						}
					}
				}
			}
		}
	}

	private bool IsGridCollapsed()
	{
		for (int i = 0; i < grid.GetLength(0); i++)
		{
			if (grid[i].Count != 1)
			{
				return false;
			}
		}
		return true;
	}

	private void CollapseCell(int cellIndex)
	{
		bool col = IsGridCollapsed();
		int choiceIndex = GetWeightedRandomIndex(grid[cellIndex]);
		CellItem choice = grid[cellIndex][choiceIndex];
		List<CellItem> removed = grid[cellIndex];
		removed.Remove(choice);
		grid[cellIndex] = new List<CellItem> {choice};
		HistoryItem hi = new HistoryItem(HistoryitemVariant.assumption, cellIndex, choice, removed);
		history.Push(hi);
		modified.Push(cellIndex);
	}

	private void Backstep()
	{
		while (history.Count > 0)
		{
			HistoryItem hi = history.Pop();
			if (hi.variant == HistoryitemVariant.propagation)
			{
				RestorePropagation(hi);
			}
			else if (hi.variant == HistoryitemVariant.assumption)
			{
				RestoreAssumption(hi);
			}
		}
		GD.PrintErr("History empty, continuing from state which knowingly fails");
		Retry();
	}

	private void RestoreAssumption(HistoryItem hi)
	{
		history.Push(new HistoryItem(HistoryitemVariant.propagation, hi.index, hi.choice, null));
		grid[hi.index] = hi.removed;
		if (hi.removed.Count == 1)
		{
			modified.Push(hi.index);
		}
	}

	private void RestorePropagation(HistoryItem hi)
	{
		if (modified.Count > 0 && modified.Peek() == hi.index)
		{
			modified.Pop();
		}
		grid[hi.index].Add(hi.choice);
	}

	private bool AreNeighbours(int i1, int i2)
	{
		Vector3I i13d = Get3DIndex(i1);
		Vector3I i23d = Get3DIndex(i2);
		return (i13d - i23d).Length() <= 1;
	}

	private bool IsValidIndex(int index)
	{
		return index >= 0 && index < grid.GetLength(0);
	}

	private int GetWeightedRandomIndex(List<CellItem> items)
	{
		float[] weights = new float[items.Count];
		int i = 0;
		foreach (CellItem item in items)
		{
			weights[i] = item.weight;
			i =+ 1;
		}

		//this is required in case all the weights of the cell are = 0 then RandWeighted would return -1
		int res = (int)rng.RandWeighted(weights);
		if (res == -1 && items.Count > 0)
		{
			res = rng.RandiRange(0, items.Count-1);
		}
		return res;
	}

	private int GetMinEntropy()
	{
		float minEntropy = -1.0f;
		List<int> minCells = new List<int>();

		for (int i = 0; i < grid.GetLength(0); i++)
		{
			if (grid[i].Count <= 1)
			{
				continue;
			}
			float entropy = GetEntropy(i);
			if (entropy < minEntropy || minEntropy < 0.0f)
			{
				minEntropy = entropy;
				minCells = new List<int> {i};
			} else if (entropy == minEntropy)
			{
				minCells.Add(i);
			}
		}
		return minCells[rng.RandiRange(0, minCells.Count-1)];
	}

	private float GetEntropy(int index)
	{
		float entropy = 0.0f;
		foreach (CellItem item in grid[index])
		{
			entropy += 1/item.weight;
		}
		return entropy;
	}

	private void SetCell(int index, CellItem item)
	{
		grid[index] = new List<CellItem> {item};
		modified.Push(index);
	}

	private CellItem GetItemByName(StringName name)
	{
		foreach (CellItem item in cellItems)
		{
			if (item.name == name)
			{
				return item;
			}
		}
		// TODO: throw an error
		GD.PrintErr("No CellItem with the name '" + name + "' has been found");
		return null;
	}

	private int Get1DIndex(Vector3I index)
	{
		return index.X + index.Y * size.X + index.Z * size.X * size.Y;
	}

	private Vector3I Get3DIndex(int index)
	{
		int x = index % size.X;
		int y = (index % (size.X * size.Y)) / size.X;
		int z = index / (size.X * size.Y);
		return new Vector3I(x, y, z);
	}

	private void RandomizeSeed()
	{
		rng.Randomize();
		GD.Print("Random Seed: ", rng.Seed);
	}

	private void PrintProgressbar()
	{
		if (Time.GetTicksMsec() - lastPrintTime <= 100)
		{
			return;
		}
		int numberOfCells = grid.Count();
		int collapsedCells = GetNumberOfCollapsedCells();
		float collapsedFraction = (float)collapsedCells / (float)numberOfCells;
		string collapsedProgressbar = FloatToProgressbar(collapsedFraction);

		int totalOptions = numberOfCells * cellItems.Count();
		int remainingOptions = GetNumberOfRemainingOptions();
		float optionsFraction = (float)remainingOptions / (float)totalOptions;
		string optionsProgressbar = FloatToProgressbar(optionsFraction);

		GD.Print("Collapsed: ", collapsedProgressbar, " ", (int)(collapsedFraction * 100), "%", "\t\tOptions: ", optionsProgressbar, " ", (int)(optionsFraction * 100), "%");
		lastPrintTime = Time.GetTicksMsec();
	}

	private string FloatToProgressbar(float fraction)
	{
		const char barFull = '▓';
		const char barEmpty = '░';
		const char barStart = '[';
		const char barEnd = ']';
		string progressBar = "";

		for (float i = 0; i < 1; i += 0.1f)
		{
			if (fraction >= i)
			{
				progressBar += barFull;
			}
			else
			{
				progressBar += barEmpty;
			}
		}

		return barStart + progressBar + barEnd;
	}

	private int GetNumberOfRemainingOptions()
	{
		int remainingOptions = 0;
		foreach (List<CellItem> cell in grid)
		{
			remainingOptions += cell.Count();
		}
		return remainingOptions;
	}

	private int GetNumberOfCollapsedCells()
	{
		int numberOfCollapsedCells = 0;
		foreach (List<CellItem> cell in grid)
		{
			if (cell.Count == 1)
			{
				numberOfCollapsedCells += 1;
			}
		}
		return numberOfCollapsedCells;
	}
}

struct HistoryItem {
	public HistoryitemVariant variant;
	public int index;
	public CellItem choice;
	public List<CellItem> removed;

	public HistoryItem(HistoryitemVariant variant, int index, CellItem choice, List<CellItem> removed)
	{
		this.variant = variant;
		this.index = index;
		this.choice = choice;
		this.removed = removed;
	}
}

enum HistoryitemVariant
{
	assumption,
	propagation
}