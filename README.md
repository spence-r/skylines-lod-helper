# skylines-lod-helper

This script is for Cities:Skylines asset creators who use 3dsMax.

It speeds up the process of exporting textures for custom LOD models, and for exporting LODs from objects that all share the same texture(s). 

## What it does

- Batches multiple render-to-texture operations in one click
- Automatically prepares your LOD model for baking: assign bake properties, apply and set up Projection modifier (if it doesn't exist already), apply common bake properties (disable the ray miss check, set padding and output size)
- Saves you from manually performing the same steps dozens of times when baking many assets from one set of textures

## Installation

Install the script (Scripting -> Run Script) like you would any other macroscript.

Then, add it to your UI (Customize -> Customize User Interface, category 'SpenceTools') - assign a hotkey or add it to your toolbar. 

## Instructions

Both LOD and high-detail meshes need to be ready for baking before you use this script:
- They should have good UVs (overlapping UVs on the LOD mesh should be outside the 0-1 space)
- There should be enough coverage between the LOD model and the high-detail mesh and they should both exist at the same position.

## Tutorial

A video tutorial is available in the repository or on [YouTube](https://www.youtube.com/watch?v=jeifW5tn62M)
If you prefer, you can follow these instructions (they are located in the header of the script file, too)

- Set up the output path and adjust padding, bake size, cage push amount if desired.
- Use the buttons to select your mesh/LOD mesh from the scene. The names should match the format expected by Cities:Skylines [meshName, meshName_lod] and must be different from each other.
- Select an input map for each channel with the ... buttons.
- Uncheck any maps you don't need to bake (alpha, color etc)
- When you are ready to bake press Bake Maps.
- Maps are saved to the output location you specified, in the format: ObjectName_MapType (object Box001, diffuse map = Box001_d)


## Troubleshooting
The script attempts to detect some common errors, and will alert you with a message in the log area (located above the bake button).

There are some potential problems with baking that this script won't solve: 
- If the baked result looks incorrect or misaligned then reset transforms of both LOD and high-detail mesh.
- The objects in Max should match the naming convention expected by Cities:Skylines - meshName and meshName_lod for the corresponding LOD. If they don't match this format, you will have to rename the baked textures or they won't be imported by the game.
- If you have any artifacts or problems with the baked output, check the cage in the Projection modifier attached to the LOD mesh - it may need to be pushed outwards (increase the 'Amount' slider). If you still have artifacts in the bake, then check the antialiasing/filter maps settings also (F10 -> Renderer). 


## Other Notes

Only tested with 3dsMax 2018.

This was only built for personal use, it's not an official tool or otherwise associated with the game or endorsed by its developers in any way.

This was my first time building anything with Maxscript, so please let me know if you have any suggestions or find any bugs or anything else!
