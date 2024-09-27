using Godot;
using System;
using System.Collections.Generic;

public partial class CellItem : Node
{
    public StringName name;
    public string scenePath;
    public Vector3 rotation;
    public float weight;
    public Dictionary<Vector3, StringName> keys;

    private static Dictionary<string, string> nextRotationSuffix = new Dictionary<String, String> {
		{"_x", "_z"},
		{"_z", "_x"},
		{"_r", "_f"},
		{"_f", "_l"},
		{"_l", "_b"},
		{"_b", "_r"}
    };

    private static Dictionary<Vector3, Vector3> nextRotation = new Dictionary<Vector3, Vector3> {
        {Vector3.Right, Vector3.Forward},
        {Vector3.Forward, Vector3.Left},
        {Vector3.Left, Vector3.Back},
        {Vector3.Back, Vector3.Right}
    };

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

    public CellItem(StringName name, string scenePath, StringName keyRight, StringName keyForward, StringName keyLeft, StringName keyBack, StringName keyUp, StringName keyDown, float weight, Vector3 rotation)
    :this(name, scenePath, keyRight, keyForward, keyLeft, keyBack, keyUp, keyDown)
    {
        this.weight = weight;
        this.rotation = rotation;
    }

    public static CellItem[] NewMirrored(StringName name, string scenePath, StringName keyRight, StringName keyForward, StringName keyLeft, StringName keyBack, StringName keyUp, StringName keyDown, float weight = 1.0f)
    {
        CellItem x = new CellItem(name + "_x", scenePath, keyRight, keyForward, keyLeft, keyBack, keyUp, keyDown, weight, Vector3.Right);
        CellItem z = x.CreateRotation();
        return new CellItem[] {x, z};
    }

    public static CellItem[] NewCardinal(StringName name, string scenePath, StringName keyRight, StringName keyForward, StringName keyLeft, StringName keyBack, StringName keyUp, StringName keyDown, float weight = 1.0f)
    {
        CellItem r = new CellItem(name + "_r", scenePath, keyRight, keyForward, keyLeft, keyBack, keyUp, keyDown, weight, Vector3.Right);
        CellItem f = r.CreateRotation();
        CellItem l = f.CreateRotation();
        CellItem b = l.CreateRotation();
        return new CellItem[] {r, f, l, b};
    }

    private CellItem CreateRotation()
    {
        return new CellItem(RotateKeySuffix(name), scenePath, RotateKeySuffix(keys[Vector3.Back]), RotateKeySuffix(keys[Vector3.Right]), RotateKeySuffix(keys[Vector3.Forward]), RotateKeySuffix(keys[Vector3.Left]), RotateKeySuffix(keys[Vector3.Up]), RotateKeySuffix(keys[Vector3.Down]), weight, nextRotation[rotation]);
    }

    private string RotateKeySuffix(string key)
    {
        foreach (var dir in nextRotationSuffix) {
            if (key.EndsWith(dir.Key)) {
                return Reverse(Reverse(key).Substring(2)) + dir.Value;
            }
        }
        return key;
    }

    private static string Reverse(string s)
    {
        char[] charArray = s.ToCharArray();
        System.Array.Reverse(charArray);
        return new string(charArray);
    }
}
