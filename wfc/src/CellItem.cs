using Godot;
using System;
using System.Collections.Generic;

// This class represents any item that can occupy a cell in the WFC grid.
// Keeps track of the mesh and the current rotation also provides Functions to easily create other rotations of the item
public partial class CellItem : Node
{
    public StringName name;                         // A unique name for the item
    public string scenePath;                        // The scene this item represents. This scene will be spawned after the WFC grid is collapsed
    public Vector3 rotation;                        // The rotation in which the scene should be spawned
    public float weight;                            // The likelyhood this item will be chosen when WFC needs to make an assumption
    public Dictionary<Vector3, StringName> keys;    // The key for each direction. The keys of neighbours need to match to be valid neighbours

    // A dict to easily replace one rotation suffix with the next rotation suffix
    private static Dictionary<string, string> nextRotationSuffix = new Dictionary<string, string> {
		{"_x", "_z"},
		{"_z", "_x"},
		{"_r", "_f"},
		{"_f", "_l"},
		{"_l", "_b"},
		{"_b", "_r"}
    };

    // A dict to easily rotate by 90 degress
    private static Dictionary<Vector3, Vector3> nextRotation = new Dictionary<Vector3, Vector3> {
        {Vector3.Right, Vector3.Forward},
        {Vector3.Forward, Vector3.Left},
        {Vector3.Left, Vector3.Back},
        {Vector3.Back, Vector3.Right}
    };

    // Constructor
    public CellItem(StringName name, string scenePath, StringName keyRight, StringName keyForward, StringName keyLeft, StringName keyBack, StringName keyUp, StringName keyDown, float weight = 1.0f)
    {
        this.name = name;
        this.scenePath = scenePath;
        this.keys = new Dictionary<Vector3, StringName> {
            { Vector3.Right, keyRight },
            { Vector3.Forward, keyForward },
            { Vector3.Left, keyLeft },
            { Vector3.Back, keyBack },
            { Vector3.Up, keyUp },
            { Vector3.Down, keyDown }
        };
        this.weight = weight;
        this.rotation = Vector3.Right;
    }

    // Constructor with specific rotation
    public CellItem(StringName name, string scenePath, StringName keyRight, StringName keyForward, StringName keyLeft, StringName keyBack, StringName keyUp, StringName keyDown, float weight, Vector3 rotation)
    :this(name, scenePath, keyRight, keyForward, keyLeft, keyBack, keyUp, keyDown, weight)
    {
        this.rotation = rotation;
    }

    // Creates a CellItem as specified through the parameters and creates another CellItem rotated by 90 degress
    public static CellItem[] NewMirrored(StringName name, string scenePath, StringName keyRight, StringName keyForward, StringName keyLeft, StringName keyBack, StringName keyUp, StringName keyDown, float weight = 1.0f)
    {
        CellItem x = new CellItem(name + "_x", scenePath, keyRight, keyForward, keyLeft, keyBack, keyUp, keyDown, weight, Vector3.Right);
        CellItem z = x.CreateRotation();
        return new CellItem[] {x, z};
    }

    // Creates a CellItem as specified by the parameters and creates another three CellItem each rotated by another 90 degress
    public static CellItem[] NewCardinal(StringName name, string scenePath, StringName keyRight, StringName keyForward, StringName keyLeft, StringName keyBack, StringName keyUp, StringName keyDown, float weight = 1.0f)
    {
        CellItem r = new CellItem(name + "_r", scenePath, keyRight, keyForward, keyLeft, keyBack, keyUp, keyDown, weight, Vector3.Right);
        CellItem f = r.CreateRotation();
        CellItem l = f.CreateRotation();
        CellItem b = l.CreateRotation();
        return new CellItem[] {r, f, l, b};
    }

    // Creates a new CellItem identical to self except rotated by 90 degress
    private CellItem CreateRotation()
    {
        return new CellItem(RotateKeySuffix(name), scenePath, RotateKeySuffix(keys[Vector3.Back]), RotateKeySuffix(keys[Vector3.Right]), RotateKeySuffix(keys[Vector3.Forward]), RotateKeySuffix(keys[Vector3.Left]), RotateKeySuffix(keys[Vector3.Up]), RotateKeySuffix(keys[Vector3.Down]), weight, nextRotation[rotation]);
    }

    // Takes a key, checks if it has a rotation suffix and changes that suffix with the next rotation suffix. Returns resulting key.
    private string RotateKeySuffix(string key)
    {
        foreach (var dir in nextRotationSuffix) {
            if (key.EndsWith(dir.Key)) {
                return Reverse(Reverse(key).Substring(2)) + dir.Value;
            }
        }
        return key;
    }

    // Returns s reversed
    private static string Reverse(string s)
    {
        char[] charArray = s.ToCharArray();
        System.Array.Reverse(charArray);
        return new string(charArray);
    }
}
