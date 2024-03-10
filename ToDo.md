- ~~add Matrix.appendRows and .appendColumns for concatenating matrices~~

- move our updated matrixUtil.ms into the official sys disk

- ~~split Obj3d out into its own module~~

- ~~split rendering stuff into its own module, too~~

- ~~figure out why we need to flip Y, contrary to sense~~

- ~~add camera (with its own transform, or similar properties)~~

- ~~add deferred gfx, so we can depth-sort~~
  - fix depth-sorting in edge cases

- add polygon renderer
  - add basic lighting (based on angle between face and light(s))
  
- add sprite renderer (with basic lighting)

- make a couple of demos where you can directly manipulate camera or scene object

- add Obj3d function to apply a transform directly to localPoints

- add objFormat.write, to convert an Obj3d to OBJ format

- adjust Battlezone models to have better scale and origin

- provide attribution for models from Kenney Games 3D assets

- add polygons to 3 other Battlezone models

- track down Mini Micro bug when runtime error occurs in an import module (possibly several deep)
