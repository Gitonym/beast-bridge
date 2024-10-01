using Godot;
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;

// This class represent a 3D grid that contain items
// The items have keys through which some neighbours are valid and some not
// This class 'collapses' the grid so each cell has only one item and all neighbours are valid
// Implementation of the Tiled Wave Function Collapse Algorythm
public partial class WFC : Node3D
{
	public Vector3I size;													// Keeps track of the size of each dimension of the grid
	float cellSize;													// The Edgelength of one cell or cellItem

	List<CellItem>[] grid;											// The grid
	List<CellItem> cellItems;										// All possible cellItems
	List<CellItem>[] constrainedGrid;								// A copy of the grid post constraints applied so they dont have to be recalculated in case of retry
	Action ConstrainGrid = null;									// The function that is called to constrain the grid

	Stack<HistoryItem> history;										// Keeps track of changes made for backtracking to past states
	Stack<int> modified;											// Keeps track of which cells have been modified to propagate the changes

	RandomNumberGenerator rng =  new RandomNumberGenerator();		// Used to make the algorythm deterministic through seeds
	ulong usedState;

	float lastPrintTime = 0.0f;										// Keeps track when the Progressbar was printed last
	const int maxIterations = 200;									// The max number of iterations before it restarts from scratch. Set to 0 for no restart because of iterations
	int iterations = 0;												// The current number of iterations
	const ulong timeOut = 0;										// The max number of Milliseconds before it restarts from scratch. The algorythm is no longer deterministic if this timeout is reached. Set to 0 for no restart because of timeout
	ulong startTime;												// The time at which the current collapse started at

	// Constructor
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

	// Returns a 1D index calculated from the 3D index
	public int Get1DIndex(Vector3I index)
	{
		return index.X + index.Y * size.X + index.Z * size.X * size.Y;
	}

	// Returns a 3D index calculated from the 1D index
	public Vector3I Get3DIndex(int index)
	{
		int x = index % size.X;
		int y = (index % (size.X * size.Y)) / size.X;
		int z = index / (size.X * size.Y);
		return new Vector3I(x, y, z);
	}

	public void SetConstrainGrid(Action func)
	{
		ConstrainGrid = func;
	}

	// Sets a cell to a specific CellItem
	public void SetCell(int index, CellItem item)
	{
		grid[index] = new List<CellItem> {item};
		modified.Push(index);
	}

	// Searches the CellItems for an item with the given name and returns it
	// returns null if no item with that name was found
	public CellItem GetItemByName(StringName name)
	{
		foreach (CellItem item in cellItems)
		{
			if (item.name == name)
			{
				return item;
			}
		}
		GD.PrintErr("No CellItem with the name '" + name + "' has been found");
		return null;
	}

	// Sets the seed to the provided seed. SetSeed(0) does nothing.
	public void SetSeed(ulong seed = 0)
	{
		if (seed == 0)
		{
			return;
		}
		GD.Print("Set Seed to: ", seed);
		rng.Seed = seed;
	}

	// Sets the state of the RandomNumberGenerator to state.
	// Useful to regenerate results that were reached only after a retry
	public void SetState(ulong state)
	{
		GD.Print("State has been set to: ", state);
		rng.State = state;
	}

	// Collapses the grid so each cell of the grid contains only one cellItem
	// and every CellItem only has valid neighbours (the keys of the two neighbouring CellItems match)
	// This starts the Wave Function Collapse
	public bool CollapseGrid()
	{
		LoadConstrainedGrid();
		ConstrainGridAndPropagate();
		SaveConstrainedGrid();
		iterations = 0;
		startTime = Time.GetTicksMsec();
		usedState = rng.State;
		GD.Print("State: ", rng.State);

		while (!IsGridCollapsed())
		{
			iterations += 1;
			PrintProgressbar();

			// Check for timeout
			if (maxIterations > 0 && iterations >= maxIterations || timeOut > 0 && Time.GetTicksMsec() - startTime >= timeOut)
			{
				return false;
			}
			if (modified.Count == 0)
			{
				CollapseCell(GetMinEntropy());
			}
			if (!Propagate())
			{
				return false;
			}
		}
		// Prints some info after the collapse succeeded
		GD.PrintRich("[color=green]Success[/color] after ", iterations, " iterations and ", Time.GetTicksMsec() - startTime, " milliseconds. Used state: ", usedState);
		return true;
	}


	// Spawns the scenes of the cellItems at their location and rotation
	// The grid has to be collapsed to spawn the items
	public void SpawnItems()
	{
		// Check if grid is collapsed
		if (!IsGridCollapsed())
		{
			GD.PrintErr("The items can only be spawned once the grid has been collapsed! Call 'WFC.CollapseGrid()'");
			return;
		}

		// iterate over each cell of the grid
		for (int index = 0; index < grid.GetLength(0); index++)
		{
			SpawnCell(index);
		}
	}

	private void SpawnCell(int index)
	{
		
		CellItem currentItem = grid[index][0];
		// Skip any cellItem that has an empty scenePath (common for air)
		if (currentItem.scenePath == "") return;
		Node3D instance = (Node3D)GD.Load<PackedScene>(currentItem.scenePath).Instantiate();
		Vector3I i3d = Get3DIndex(index);
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

	// Counts the number of times a CellItem appears in a collapsed grid. Also counts all of the CellItems rotations.
	// Returns a dict in this format: {"all": 0, "name": 0, "name_x": 0, ...}
	public Dictionary<StringName, int> CountCellItemAppearances(StringName name)
	{
		if (!IsGridCollapsed())
		{
			GD.PrintErr("Occurences of CellItems can only be counted in a fully collapsed grid");
			return null;
		}

		StringName[] possibleNames = new StringName[] {name, name + "_x", name + "_z", name + "_r", name + "_f", name + "_l", name + "_b"};
		Dictionary<StringName, int> appearances = new Dictionary<StringName, int>
		{
			{"all", 0},
			{possibleNames[0], 0},
			{possibleNames[1], 0},
			{possibleNames[2], 0},
			{possibleNames[3], 0},
			{possibleNames[4], 0},
			{possibleNames[5], 0},
			{possibleNames[6], 0}
		};

		foreach (List<CellItem> cell in grid)
		{
			foreach (StringName currentName in possibleNames)
			{
				if (cell[0].name == currentName)
				{
					appearances[currentName] += 1;
					appearances["all"] += 1;
				}
			}
		}
		return appearances;
	}

	// Moves all items to the left and regenerates the right edge
	public void SlideRightAndGenerate(int edgeWidth)
	{
		// Delete all spawned CellItem scenes
		foreach (Node child in GetChildren())
		{
			RemoveChild(child);
			child.QueueFree();
		}

		for (int z = 0; z < size.Z; z++)
		{
			for (int y = 0; y < size.Y; y++)
			{
				for (int x = 1; x < size.X; x++)
				{
					Vector3I index3d = new Vector3I(x, y, z);
					int index = Get1DIndex(index3d);
					Vector3I newIndex3d = new Vector3I(x-1, y, z);
					int newIndex = Get1DIndex(newIndex3d);
					// Move grid to the left by one
					if (size.X - x >= edgeWidth)
					{
						grid[newIndex] = grid[index];
					}
					// put all CellItems into the right edge
					if (size.X - index3d.X <= edgeWidth)
					{
						grid[index] = cellItems.ToList();
					}
					// put last cells before border into modified
					if (size.X - index3d.X == edgeWidth+1)
					{
						modified.Push(index);
					}
				}
			}
		}
		// propagate the border
		Propagate();

		// Save the grid post propogation
		SaveConstrainedGrid();

		// Recollapse
		while (!CollapseGrid())
		{
			Retry();
		}

		Position += Vector3.Right * cellSize;

		// Spawn Items
		SpawnItems();
	}

	// Restores the constrained grid as the grid
	private void LoadConstrainedGrid()
	{
		if (constrainedGrid != null)
		{
			for (int i = 0; i < grid.Count(); i++)
			{
				grid[i] = constrainedGrid[i].ToList();
			}
		}
	}

	// Saves the current grid as a constrained grid
	private void SaveConstrainedGrid()
	{
		constrainedGrid = new List<CellItem>[grid.Count()];
		for (int i = 0; i < grid.Count(); i++)
		{
			constrainedGrid[i] = grid[i].ToList();
		}
	}

	// If ConstrainGrid was set and no constrainedGrid was yet saved: calculates and saves the constrained grid
	private void ConstrainGridAndPropagate()
	{
		if (constrainedGrid == null && ConstrainGrid != null)
		{
			ConstrainGrid();
			Propagate();
		}
	}

	// Adds all CellItems to all cell of the grid
	// Sets constraints such as: Top cells are air, bottom cells are grass
	private void InitGrid()
	{
		int gridSize = Get1DIndex(size - Vector3I.One) + 1;
		grid = new List<CellItem>[gridSize];

		for (int i = 0; i < gridSize; i++)
		{
			grid[i] = new List<CellItem>(cellItems);
		}
	}

	// Resets variables fo the next attempt and starts that attempt
	// Also prints some info of the last attempt
	public void Retry()
	{
		lastPrintTime = 0.0f;
		GD.PrintRich("[color=orange]Retrying[/color] after ", iterations, " iterations and ", Time.GetTicksMsec() - startTime ," milliseconds");
		iterations = 0;
		history = new Stack<HistoryItem>();
		modified = new Stack<int>();
	}

	// Looks at the last modified cell and checks if the neighbouring cells need to be modified
	// if so adds those cells indices to modified aswell
	// initiates backstepping if it removed the last possible neighbour of a cell
	private bool Propagate()
	{
		// While a modified cell exists that has not been propagated yet
		while (modified.Count > 0)
		{
			int current1DIndex = modified.Pop();
			Vector3I current3DIndex = Get3DIndex(current1DIndex);

			// Look at the neighbour in each cardinal direction of the current cell
			foreach (Vector3I direction in new Vector3I[] {Vector3I.Right, Vector3I.Forward, Vector3I.Left, Vector3I.Back, Vector3I.Up, Vector3I.Down})
			{
				int neighbourIndex = Get1DIndex(current3DIndex + direction);

				// Ignore neighbours outside of the grid
				if (!IsValidIndex(neighbourIndex))
				{
					continue;
				}

				// Ignore cells that are not neighbours because they wrapped to the next line of the grid
				if (!AreNeighbours(current1DIndex, neighbourIndex))
				{
					continue;
				}

				// Keep track of all valid keys in that direction
				List<StringName> currentKeys = new List<StringName>();
				foreach (CellItem currentItem in grid[current1DIndex])
				{
					if (!currentKeys.Contains(currentItem.keys[direction]))
					{
						currentKeys.Add(currentItem.keys[direction]);
					}
				}

				// Look at every CellItem in the neighbouring cell
				for (int i = grid[neighbourIndex].Count-1; i >= 0; i--)
				{
					CellItem neighbour = grid[neighbourIndex][i];

					// If the neighbouring CellItem has no fitting key, remove it
					// also add neighbouring cell to modified
					// also create an entry to the history
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
							return Backstep();
						}
					}
				}
			}
		}
		return true;
	}

	// Returns true if all cells of the grid contain only one CellItem, false otherwise
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

	// Removes all CellItem from the given index except one
	// The one item is chosen randomly taking the cellItem weights into account
	private void CollapseCell(int cellIndex)
	{
		int choiceIndex = GetWeightedRandomIndex(grid[cellIndex]);
		CellItem choice = grid[cellIndex][choiceIndex];
		List<CellItem> removed = grid[cellIndex];
		removed.Remove(choice);
		grid[cellIndex] = new List<CellItem> {choice};
		HistoryItem hi = new HistoryItem(HistoryitemVariant.assumption, cellIndex, choice, removed);
		history.Push(hi);
		modified.Push(cellIndex);
	}

	// Restores older and older stated of the grid until an assumption has been restored
	private bool Backstep()
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
				return true;
			}
		}
		// If the code reaches here then the inital state of the grid is wrong
		GD.Print("History empty");
		return false;
	}

	// Takes an assumption and restores the grid to the state of before the assumption
	// restores the state in such a way that the previous assumption cannot be made again
	private void RestoreAssumption(HistoryItem hi)
	{
		history.Push(new HistoryItem(HistoryitemVariant.propagation, hi.index, hi.choice, null));
		grid[hi.index] = hi.removed;
		if (hi.removed.Count == 1)
		{
			modified.Push(hi.index);
		}
	}

	// Takes a propagation and restores the state of the grid as it was before the propagation
	private void RestorePropagation(HistoryItem hi)
	{
		if (modified.Count > 0 && modified.Peek() == hi.index)
		{
			modified.Pop();
		}
		grid[hi.index].Add(hi.choice);
	}

	// Returns true if the two given indices are neighbours, false otherwise
	private bool AreNeighbours(int i1, int i2)
	{
		Vector3I i13d = Get3DIndex(i1);
		Vector3I i23d = Get3DIndex(i2);
		return (i13d - i23d).Length() <= 1;
	}

	// Returns true if the given index is valid (the grid is big enough to have that index), false otherwise
	private bool IsValid3DIndex(Vector3I index)
	{
		return index.X >= 0 && index.X < size.X && index.Y >= 0 && index.Y < size.Y && index.Z >= 0 && index.Z < size.Z; 
	}

	// Returns true if the given 1D index is a valid index for the grid, false otherwise
	private bool IsValidIndex(int index)
	{
		return index >= 0 && index < grid.GetLength(0);
	}

	// Takes a list of CellItems and returns a random index corresponsing to one CellItem of that list
	// Takes the weights of the CellItems into account
	private int GetWeightedRandomIndex(List<CellItem> items)
	{
		// Collect the weights of all CellItems into an array
		float[] weights = new float[items.Count];
		int i = 0;
		foreach (CellItem item in items)
		{
			weights[i] = item.weight;
			i += 1;
		}

		// generate the random index based on weights. This returns -1 if no weights or all weights are 0
		int res = (int)rng.RandWeighted(weights);
		// this is required in case all the weights of the cell are = 0 then RandWeighted would return -1
		// in that case just choose a random index where all indices are equally likely
		if (res == -1 && items.Count > 0)
		{
			res = rng.RandiRange(0, items.Count-1);
		}
		return res;
	}

	// Returns the index of the cell with the lowest entropy
	// entropy = sum of reciprocals of the weight for each cellItem in that cell
	// ignores collapsed cells
	private int GetMinEntropy()
	{
		float minEntropy = -1.0f;
		List<int> minCells = new List<int>();

		for (int i = 0; i < grid.GetLength(0); i++)
		{
			// skip if the cell is already collapsed
			if (grid[i].Count <= 1)
			{
				continue;
			}
			float entropy = GetEntropy(i);
			// keep track of this cell if it has the lowest or equally low entropy
			if (entropy < minEntropy || minEntropy < 0.0f)
			{
				minEntropy = entropy;
				minCells = new List<int> {i};
			} else if (entropy == minEntropy)
			{
				minCells.Add(i);
			}
		}
		// return a random cell from the ones with the lowest entropy
		return minCells[rng.RandiRange(0, minCells.Count-1)];
	}

	// Returns the entropy of the cell with the given index
	private float GetEntropy(int index)
	{
		float entropy = 0.0f;
		foreach (CellItem item in grid[index])
		{
			entropy += 1/item.weight;
		}
		return entropy;
	}

	// Sets the seed to a random one
	private void RandomizeSeed()
	{
		rng.Randomize();
		GD.Print("Random Seed: ", rng.Seed);
	}

	// Prints the progress of the grids collapse
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

	// Returns a string of a progressbar. The progressbar is full if fraction=1.0 and empty if fraction = 0.0. Behaves as expected for values inbetween 0.0 and 1.0.
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

	// Returns how many CellItems can still be chosen in teh entire grid
	private int GetNumberOfRemainingOptions()
	{
		int remainingOptions = 0;
		foreach (List<CellItem> cell in grid)
		{
			remainingOptions += cell.Count();
		}
		return remainingOptions;
	}

	// Returns the number of collapsed (cell with exactly one Cellitem) cells
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

// This sctruct represents a modification made to the grid so it can be used later to restore the grid to before the modification
struct HistoryItem {
	public HistoryitemVariant variant;		// Type of modification made assumption/propagation
	public int index;						// The index of the grid where the modification was made
	public CellItem choice;					// assumption: the cellItem that was randomly chosen to keep, propagation: The CellItem that was removed because of mismatchin keys
	public List<CellItem> removed;			// assumption: the cellItems that were not chosen and removed, propagation: null

	// Constructor
	public HistoryItem(HistoryitemVariant variant, int index, CellItem choice, List<CellItem> removed)
	{
		this.variant = variant;
		this.index = index;
		this.choice = choice;
		this.removed = removed;
	}
}

// The two types of HistoryItem
enum HistoryitemVariant
{
	assumption,		// Is when a cell needs to be collapsed and one of multiple valid CellItems is chosen at random
	propagation		// Is when a neighbour is removed because of mismatching keys
}