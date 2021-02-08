# lisp-tools
Tools developed in LISP for BricsCAD and AutoCAD


    *Initialisation *at the first programme start:

The directory path to the programme directory "PC_Tools" must be entered as the as the support path in the BricsCAD options, this is done semi-automatically by selecting the programme file .../PC_Tools/Pc_Tools.lsp

    The following functions are available:

PC_LINIE: grouped line functions, at the first start in the file, the dialogue window "/PC_Tools - Line tools/" always appears. in which the line tool is selected. The default value is always the last one used. o Lines, polylines: line segments can be drawn one after the other. segments can be drawn one after the other. intersected with the previous one.

      At the first point, pressing ENTER always returns to the
    the dialogue window "/PC_Tools - Line tools/", for all further points the
    the line tools specific dialogue window "/PC_Tools - Line tools/" appears.
    "/PC_Tools - Lines/"
    
  o *Mehrdfach* (Multiple): individual line segments can be drawn several times in a loop.
    
      At the first point, pressing ENTER always takes you back to the
      dialogue window "/PC_Tools - Line tools/", at the 2nd point of a line segment the function is terminated with ENTER.

PC_BKS_>WKS: Objects are selected in the BKS(User Coordinate System), these are transformed into the WKS (World Coordinate System).

PC_FLATTEN: Objects are selected in the BKS/UCS, transformed into the WKS/WCS transformed into the WKS/WCS, there with the BricsCAD function "FLATTEN" onto the z-planes 0.0, and then transformed back into the original BKS/UCS

PC_BLOCK: At the first start the dialogue window always appears "/PC_Tools - Insert Block/" always appears, on further starts it goes directly to the previously used settings, if the insertion point is only confirmed with ENTER, the dialogue window "/PC_Tools - Insert block/" will open.

  o *(1)* The names of all block definitions from the current drawing,
    which correspond to the block name filter *(2)* will be listed. All blocks that exist in the file can be selected.
    
  o *(3)* If the currently selected block definition contains *(1)* attributes, these will be listed. For each
    attribute, an x, x, z value of the insertion point can be set as the
    attribute value *(4)*.
    
  o *(5)* If activated, then the z-value for the block to be inserted is set to zero.
  
  o *(6)* Decimal places, for the attribute values *(4)*.
  
  o *(7)* Insertion factor, with which the blocks are inserted in the drawing.

  o *(8)+(9)* Insertion angle can be determined via 2 points ("Angle<" button) or input.
  
  o *(10)* The angle of insertion can be taken over from a line element, if this has been recognised by the object snap *(13)*.

  o *(11)* a relative angle can be added to the insertion angle (divided into 90° steps).
  
  o *(12)+(13)+(14)* object snap perpendicular or end point for line element as well as the input of the max. distance.
  
  o *(15)* A specified block template file *(16)* can be selected from the directory .../PC_Tools/BlockTemplates/.
    If this option is activated, then the last defined template file is
    automatically loaded in the next drawing at the start of the programme. The name of the defined block template file is written *(17)*.
    When loading the block template file the drawing units of blocks are automatically adapted to the current drawing.

  o *(18)* When loading the block template file, a check is made to see if there are any drawing units in the
    block references are already inserted in the model space of the template file. 
    If this is the case, their insertion layers are used as default insertion layers.

      + /"Current layer: "0" /(=> if no insertion layer from the template file has been defined then the current layer of the drawing is used.

      + /"Layer from template: "Einflayer_Hoehe_Boden" /(if e.g. in the template file a
        a block reference "Height_Floor" on the insertion layer "InsertFloor" exists)

PC_Flaeche (Floor): Points can be picked, from the 3rd point on a TIN surface is built up. Requirement:/BricsCAD V21 PRO/
