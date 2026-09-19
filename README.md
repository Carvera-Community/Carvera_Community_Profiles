This repository manages Carvera profiles such as machine/tool bits settings and post processors for different software profiles

Checkout the [Releases Page](https://github.com/Carvera-Community/Carvera_Community_Profiles/releases) for downloads.

----

# Fusion 360

## Install PostProcessor
1. Start Fusion 360.

2. Navigate to the Manufacture Workspace.

![F360 Workspace](/img/F360-Workspace.png)

3. Under the Manage group, select the Post Library button.

![F360 Post Library](/img/F360-Post-Library.png)

4. Navigate to the "My Posts->Local" folder.

5. Click the "Import" button.

![F360 Post Import](/img/F360-Post-Import.png)

6. Select the "Carvera.cps" file and finish the importing.

## Install Machine
1. Under the Manage group, select the Machine Library button.

![F360 Machine Library](/img/F360-Machine-Library.png)

2. Navigate to the "My Machines->Local" folder.

3. Click the "Import" button.

![F360 Machine Import](/img/F360-Machine-Import.png)

4. Import the machine definition `.f3d` files from `CAM_Post_Processors/Fusion360-profiles/`:
   - `Makera.Carvera.3-axis.Community.Version.1.17.f3d`
   - `Makera.Carvera.4-axis.Community.Version.1.18.f3d`

5. Optional variants (import if needed):
   - `Makera.Carvera.4-axis.Harmonic.Community.Version.1.18.f3d`
   - `Makera.Carvera.Air.3-axis.Community.Version.1.17.f3d`
   - `Makera.Carvera.Air.4-axis.Community.Version.1.18.f3d`

## Install Tool Library
1. Under the Manage group, select the Tool Library button.

![F360 Tool Library](/img/F360-Tool-Library.png)

2. Navigate to "All->Local".

3. Right click the "Local" folder and click the "New folder" button, create a new folder named "Carvera Tools".

4. Right click the new folder and then click the "Import libraries" button.

![F360 Tool Import](/img/F360-Tool-Import.png)

5. Import the `.tools` files from `CAM_Post_Processors/Fusion360-profiles/Tool Files/` (for example: `Makera Ball Endmills.tools`, `Makera Drill Bits.tools`, `Makera Engraving Bits.tools`, `Makera O Flute Bits.tools`, `Makera Corn Bits.tools`, `Makera Thread Mills.tools`, `Makera Other Tools.tools`, and `Makera ToolHolders.tools`).

## Using Fusion360 Profiles
1. When creating setups, select the imported Makera Carvera machine profile that matches your hardware (for example 3-axis, 4-axis, Air, or Harmonic).

![F360 Setup](/img/F360-Setup.png)

2. When doing post process, select the Makera Carvera machine and the `Carvera.cps` post file.

![F360 Post Process](/img/F360-Post-Process.png)




----
# VCarve Desktop

## Install PostProcessor
1. Start VCarve Desktop.

2. Navigate to the "Machine" menu and click "Post-Processor Management".

3. Click the "Install Post-Processor" button.

![VCarve Post](/img/VCarve-Post.png)

4. Select and import the "Carvera ATC (mm) (!.cnc).pp" file.

5. Repeat importing the "Carvera Wrap X2A ATC (mm) (!.cnc).pp" file and "Carvera Laser (mm) (!.cnc).pp" file.

## Create Machine
1. Navigate to the "Machine" menu and click "Machine Configuration Management".

2. Click the "Add a custom machine" button.

3. Fill in the information as shown below.

![VCarve Machine](/img/VCarve-Machine.png)

4. Select the post processors just imported and set the "Carvera ATC (mm)(*.cnc)" as default.

5. Click "Apply" then "OK" to save the configuration.

## Install Tool Database
1. Navigate to the "Toolpaths" menu and click "Tool Database".

2. Click the "Import a tool database" button.

![VCarve Tool Import](/img/VCarve-Tool-Import.png)

3. Select the "CarveraTools.vtdb" file.

4. Click the "Merge" button on the popup confirm dialog and finish the import.


## Using VCarve Desktop Profiles
When saving Tool paths, select Carvera Desktop CNC Machine and a suitable post processor for your job.
![VCarve Save](/img/VCarve-Save.png)

When working with 4th axis parts:
1: Set your Z to be the center of your stock, not the surface, or you'll have a bad day.

2: Vcarve pro rounding toolpaths assume that the stock starts flat.  Insert your stock, rotate it to flat (use a bubble level if you want), then in Carvera control press the "A" control at the top and then click "A=0" to zero out the rotation and set your start.  The toolpath will rotate the stock 45degress to bring the corner to the top when it starts and if all goes well, the bit will just kiss the corner as it starts.

3: The jaws on the headstock are invertible! if you have a smaller workpiece, you can flip the jaws around and grab much smaller things.  The Jaws are marked 1-4 (I added a paint pen number to see them easier to distinguish, but it is stamped on there as well), when putting them in normally (longer part of the jaw on the outside, you want to do them in order of 1-4.  If you are flipping them, you need to re-insert them into the headstock in reverse order, 4-1, otherwise they won't close evenly and your stock will be off center and you'll have a bad day.

Thanks to renderman on the discord for this information!


----
# LightBurn

## Setup Device
1. Start LightBurn.

2. Click the "Device" button.

3. Click the "Import" button in the popup dialog.

![LightBurn Device](/img/LightBurn-device.png)

4. Select the "LightBurn.lbdev" file and finish importing the Makera Carvera device.

## Using LightBurn Profiles
When saving GCode, select "Makera" as the current device.

![LightBurn Save](/img/LightBurn-Save.png)



