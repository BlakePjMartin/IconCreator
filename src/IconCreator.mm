unprotect('IconCreator');

module IconCreator()
	option object;

	local
		  graphics := Array([])					# an array of all the graphical elements - the elements are ordered from front view to back view
		, selID	:= 0								# ID of currently selected graphical element - 0 means no selection
		, extent := [[-100, -100], [100, 100]]	# extent of the icon
		, zoom := 1.1

		# keeps track of the start position when a graphical element is dragged
		, dragStart := [0, 0]

		# keeps track of what is on the main display ("Icon" or "Code") - start at "Code" since during startup the value will be switched
		, curView := "Code"

		# keeps track of canvas options
		, gridSize := 1.0  # origins, extents, and points must be multiples of gridSize
		, addGridLines := true
		, gridLines := 50.0

		# stores states of the system to enable undo/redo actions
		, states  := Array([])
		, curState := 0
		;

#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
#
# Helper functions
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
$include <src/PrintNumber.mm>


#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
#
# Icon properties
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

	#------------------------------------------------------------------------------------------------
	export
	IconGridSize::static := proc(self ::IconCreator, {stateSet ::boolean := false}, $)
	#------------------------------------------------------------------------------------------------
		description "Updates the grid size for the icon.";

		# get the current value in the text area
		# do this if not setting a state
		if not(stateSet) then
			local tempVal := parse(DocumentTools:-GetProperty('txtGridSize', 'value'));
			if type(tempVal, 'numeric') then
				self:-gridSize := parse(sprintf("%s", PrintNumber(tempVal)));
			end if;

			# take a state snapshot
			State_Add(self);
		end if:

		DocumentTools:-SetProperty('txtGridSize', 'value', PrintNumber(self:-gridSize));

		return;
	end proc;

	#------------------------------------------------------------------------------------------------
	export
	IconExtent::static := proc(self ::IconCreator, {stateSet ::boolean := false}, $)
	#------------------------------------------------------------------------------------------------
		description "Updates the extent for the icon.";

		# get the current value in the text area
		# do this if not setting a state
		if not(stateSet) then
			local tempVal := ReadSet_GetList('txtIconExtent');

			if type(tempVal, [[numeric, numeric], [numeric, numeric]]) then
				tempVal := parse(sprintf("[[%s, %s], [%s, %s]]", op(PrintNumber~(ListTools:-Flatten(tempVal)))));
				self:-extent := tempVal;
			end if;
			DisplayIcon(self);

			# take a state snapshot
			State_Add(self);
		end if:

		DocumentTools:-SetProperty('txtIconExtent', 'value', sprintf("{%s, %s},\n{%s, %s}", op(PrintNumber~(ListTools:-Flatten(self:-extent)))));

		return;
	end proc;

	#------------------------------------------------------------------------------------------------
	export
	IconGridLines::static := proc(self ::IconCreator, {stateSet ::boolean := false}, $)
	#------------------------------------------------------------------------------------------------
		description "Updates the grid lines for the icon display.";

		# check the check box value
		self:-addGridLines := parse(DocumentTools:-GetProperty('chkAddGridLines', 'value'));

		# enable/disable the text area
		DocumentTools:-SetProperty('txtGridLines', 'enabled', self:-addGridLines);

		# get the current value in the text area
		# do this if not setting a state
		if not(stateSet) then
			local tempVal := op(ReadSet_GetList('txtGridLines'));

			if type(tempVal, numeric) then
				tempVal := parse(sprintf("%s", PrintNumber(tempVal)));
				self:-gridLines := tempVal;
			end if;
			DisplayIcon(self);

			# take a state snapshot
			State_Add(self);
		end if:

		DocumentTools:-SetProperty('txtGridLines', 'value', sprintf("%s", PrintNumber(self:-gridLines)));

		return;
	end proc;


#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
#
# Modelica code
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

	#------------------------------------------------------------------------------------------------
	export
	ToggleMainView::static := proc(self ::IconCreator, {stateSet ::boolean := false}, $)
	#------------------------------------------------------------------------------------------------
		description "Handles the action when the user clicks on the check box to view the Modelica code or icon.";

		# update the value internally - switch between "Icon" and "Code"
		# do this if we are not setting state data
		if not(stateSet) then
			self:-curView := ifelse(self:-curView = "Icon", "Code", "Icon");
		end if:

		# update the embedded components that are displayed and their attributes
		DocumentTools:-SetProperty('pltCanvas', 'visible', ifelse(self:-curView = "Icon", true, false));
		DocumentTools:-SetProperty('cerModelica', 'visible', ifelse(self:-curView = "Icon", false, true));
		DocumentTools:-SetProperty('btnView', 'caption', ifelse(self:-curView = "Icon", "View Modelica Code", "View Icon Display"));

		# set the icon display or the Modelica code
		if self:-curView = "Icon" then
			DisplayIcon(self);
			Context_Menu(self);
		elif self:-curView = "Code" then
			DocumentTools:-SetProperty('tblContextMenu', 'visible', false, 'refresh' = true);
			DocumentTools:-SetProperty('cerModelica', 'value', GenerateModelica(self));
		end if:

		# take a state snapshot
		# do this if we are not setting state data
		if not(stateSet) then
			State_Add(self);
		end if:


		return;
	end proc;

	#------------------------------------------------------------------------------------------------
	export
	GenerateModelica::static := proc(self ::IconCreator, $)
	#------------------------------------------------------------------------------------------------
		description "Generates Modelica code for the icon from the currently stored data.";

		local mo := sprintf(
			"annotation(\n\t"
			"Diagram(\n\t\t"
			"coordinateSystem(preserveAspectRatio = false, extent = {{%s, %s}, {%s, %s}}),\n\t\t"
			"graphics),\n\t"
			"Icon(\n\t\t"
			"coordinateSystem(preserveAspectRatio = false, extent = {{%s, %s}, {%s, %s}})"
			, op(PrintNumber~(ListTools:-Flatten(self:-extent)))
			, op(PrintNumber~(ListTools:-Flatten(self:-extent)))
			);

		# check if there are graphical elements to display
		local
			  numGraphics := ArrayTools:-NumElems(self:-graphics)
			, i
			;

		if numGraphics > 0 then
			mo := cat(mo, ",\n\t\tgraphics = {\n");

			# cycle through each of the graphics
			for i to numGraphics do
				mo := cat(mo, GraphicModelica(self:-graphics[numGraphics + 1 - i]));
			end do:

			mo := cat(mo[1..-3], "}");
		end if:

		mo := cat(mo, "));");

		return mo;
	end proc;


#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
#
# Context menu (right hand side table)
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

	#------------------------------------------------------------------------------------------------
	export
	ReadSet_GetList::static := proc(textArea ::symbol, $)
	#------------------------------------------------------------------------------------------------
		description "Reads a text area (set notation) and returns a list of the result";

		local tempVal := DocumentTools:-GetProperty(textArea, 'value');
		tempVal := StringTools:-SubstituteAll(tempVal, "{", "["):
		tempVal := StringTools:-SubstituteAll(tempVal, "}", "]");
		try
			tempVal := [parse(tempVal)];
		catch:
			tempVal := false;
		end try:

		return tempVal;
	end proc;

	#------------------------------------------------------------------------------------------------
	export
	Context_Menu::static := proc(	  self ::IconCreator
									, {action ::{"valUpdate", "displayUpdate"} := "displayUpdate"}
									, $)
	#------------------------------------------------------------------------------------------------
		description "Handles all actions on the context menu (right-click menu).";

		if action = "displayUpdate" then
			CM_UpdateDisplay(self);
		elif action = "valUpdate" then
			CM_UpdateValue(self);
			DisplayIcon(self);
			# take a state snapshot
			State_Add(self);
		end if;

		return;
	end proc;

	#------------------------------------------------------------------------------------------------
	local
	CM_UpdateValue::static := proc(self ::IconCreator, $)
	#------------------------------------------------------------------------------------------------
		description "Update the values through the context menu.";

		local
		  curVal
		, newVal
		, tmpGraphics := self:-graphics[self:-selID]
		, selType := Get_objType(tmpGraphics)
		;

		# Visible
		newVal := parse(DocumentTools:-GetProperty('cbxVisible', 'value'));
		curVal := Get_visible(tmpGraphics);
		if newVal <> curVal then
			Set_visible(tmpGraphics, newVal);
			print("Visible");
			return;
		end if:

		# Origin
		newVal := op(ReadSet_GetList('txtOrigin'));
		curVal := Get_origin(tmpGraphics);
		if newVal <> curVal then
			if type(newVal, [numeric, numeric]) then
				newVal := parse(sprintf("[%s, %s]", op(PrintNumber~(newVal))));
				Set_origin(tmpGraphics, newVal);
			end if;
			DocumentTools:-SetProperty('txtOrigin', 'value', sprintf("{%s, %s}", op(PrintNumber~(Get_origin(tmpGraphics)))));
			print("Origin");
			return;
		end if:

		# Rotation
		newVal := op(ReadSet_GetList('txtRotation'));
		curVal := Get_rotation(tmpGraphics);
		if newVal <> curVal then
			if type(newVal, numeric) then
				newVal := parse(sprintf("%s", PrintNumber(newVal)));
				Set_rotation(tmpGraphics, newVal);
			end if;
			DocumentTools:-SetProperty('txtRotation', 'value', sprintf("%s", PrintNumber(Get_rotation(tmpGraphics))));
			print("Rotation");
			return;
		end if:

		# Line Pattern
		newVal := StringTools:-DeleteSpace(DocumentTools:-GetProperty('cmbLinePattern', 'value'));
		curVal := Get_pattern(tmpGraphics);
		if newVal <> curVal then
			Set_pattern(tmpGraphics, newVal);
			print("Line Pattern");
			return;
		end if:


		# check for updates based on other common elements
		if member(selType, {"Rectangle", "Polygon", "Ellipse"}) then

			# Line Colour
			newVal := op(ReadSet_GetList('txtLineColour'));
			curVal := Get_lineColor(tmpGraphics);
			if newVal <> curVal then
				if type(newVal, [numeric, numeric, numeric]) then
					newVal := parse(sprintf("[%s, %s, %s]", op(PrintNumber~(newVal))));
					Set_lineColor(tmpGraphics, op(newVal));
				end if;
				DocumentTools:-SetProperty('txtLineColour', 'value', sprintf("{%s, %s, %s}", op(PrintNumber~(Get_lineColor(tmpGraphics)))));
				print("Line Colour");
				return;
			end if:

			# Fill Colour
			newVal := op(ReadSet_GetList('txtFillColour'));
			curVal := Get_fillColor(tmpGraphics);
			if newVal <> curVal then
				if type(newVal, [numeric, numeric, numeric]) then
					newVal := parse(sprintf("[%s, %s, %s]", op(PrintNumber~(newVal))));
					Set_fillColor(tmpGraphics, op(newVal));
				end if;
				DocumentTools:-SetProperty('txtFillColour', 'value', sprintf("{%s, %s, %s}", op(PrintNumber~(Get_fillColor(tmpGraphics)))));
				print("Fill Colour");
				return;
			end if:

			# Fill Pattern
			newVal := StringTools:-DeleteSpace(DocumentTools:-GetProperty('cmbFillPattern', 'value'));
			curVal := Get_fillPattern(tmpGraphics);
			if newVal <> curVal then
				Set_fillPattern(tmpGraphics, newVal);
				print("Fill Pattern");
				return;
			end if:

			# Line Thickness
			newVal := op(ReadSet_GetList('txtLineThickness'));
			curVal := Get_lineThickness(tmpGraphics);
			if newVal <> curVal then
				if type(newVal, numeric) then
					newVal := parse(sprintf("%s", PrintNumber(newVal)));
					Set_lineThickness(tmpGraphics, newVal);
				end if;
				DocumentTools:-SetProperty('txtLineThickness', 'value', sprintf("%s", PrintNumber(Get_lineThickness(tmpGraphics))));
				print("Line Thickness");
				return;
			end if:

		end if:


		# check for updates based on specific grpahical object types
		if selType = "Rectangle" then

			# Border Pattern
			newVal := DocumentTools:-GetProperty('cmbBorderPattern', 'value');
			curVal := Get_borderPattern(tmpGraphics);
			if newVal <> curVal then
				Set_borderPattern(tmpGraphics, newVal);
				print("Border Pattern");
				return;
			end if:

			# Radius
			newVal := op(ReadSet_GetList('txtRadius'));
			curVal := Get_radius(tmpGraphics);
			if newVal <> curVal then
				if type(newVal, numeric) then
					newVal := parse(sprintf("%s", PrintNumber(newVal)));
					Set_radius(tmpGraphics, newVal);
				end if;
				DocumentTools:-SetProperty('txtRadius', 'value', sprintf("%s", PrintNumber(Get_radius(tmpGraphics))));
				print("Radius");
				return;
			end if:

			# Extent
			newVal := ReadSet_GetList('txtExtent');
			curVal := Get_extent(tmpGraphics);
			if newVal <> curVal then
				if type(newVal, [[numeric, numeric], [numeric, numeric]]) then
					newVal := parse(sprintf("[[%s, %s], [%s, %s]]", op(PrintNumber~(ListTools:-Flatten(newVal)))));
					Set_extent(tmpGraphics, newVal[1], newVal[2]);
				end if:
				DocumentTools:-SetProperty('txtExtent', 'value', sprintf("{%s, %s},\n{%s, %s}", op(PrintNumber~(ListTools:-Flatten(Get_extent(tmpGraphics))))));
				print("Extent");
				return;
			end if:


		elif selType = "Ellipse" then

			# Start Angle
			newVal := op(ReadSet_GetList('txtStartAngle'));
			curVal := Get_startAngle(tmpGraphics);
			if newVal <> curVal then
				if type(newVal, numeric) then
					newVal := parse(sprintf("%s", PrintNumber(newVal)));
					Set_startAngle(tmpGraphics, newVal);
				end if;
				DocumentTools:-SetProperty('txtStartAngle', 'value', sprintf("%s", PrintNumber(Get_startAngle(tmpGraphics))));
				print("Start Angle");
				return;
			end if:

			# End Angle
			newVal := op(ReadSet_GetList('txtEndAngle'));
			curVal := Get_endAngle(tmpGraphics);
			if newVal <> curVal then
				if type(newVal, numeric) then
					newVal := parse(sprintf("%s", PrintNumber(newVal)));
					Set_endAngle(tmpGraphics, newVal);
				end if;
				DocumentTools:-SetProperty('txtEndAngle', 'value', sprintf("%s", PrintNumber(Get_endAngle(tmpGraphics))));
				print("End Angle");
				return;
			end if:

			# Extent
			newVal := ReadSet_GetList('txtExtent');
			curVal := Get_extent(tmpGraphics);
			if newVal <> curVal then
				if type(newVal, [[numeric, numeric], [numeric, numeric]]) then
					newVal := parse(sprintf("[[%s, %s], [%s, %s]]", op(PrintNumber~(ListTools:-Flatten(newVal)))));
					Set_extent(tmpGraphics, newVal[1], newVal[2]);
				end if:
				DocumentTools:-SetProperty('txtExtent', 'value', sprintf("{%s, %s},\n{%s, %s}", op(PrintNumber~(ListTools:-Flatten(Get_extent(tmpGraphics))))));
				print("Extent");
				return;
			end if:


		elif selType = "Polygon" then

			# Smooth
			newVal := DocumentTools:-GetProperty('cmbSmooth', 'value');
			curVal := Get_smooth(tmpGraphics);
			if newVal <> curVal then
				Set_smooth(tmpGraphics, newVal);
				print("Smooth");
				return;
			end if:

			# Points
			newVal := ReadSet_GetList('txtPoints');
			curVal := Get_points(tmpGraphics);
			if newVal <> curVal then
				if type(newVal, list([numeric, numeric])) then
					newVal := [parse(cat(op(map(x -> sprintf("[%s, %s],", op(PrintNumber~(x))), newVal)))[1..-2])];
					Set_points(tmpGraphics, newVal);
				end if:
				DocumentTools:-SetProperty('txtPoints', 'visiblerows', 1+numelems(Get_points(tmpGraphics)), 'refresh' = true);
				DocumentTools:-SetProperty('txtPoints', 'value', cat(op(map(x -> sprintf("{%s, %s},\n", op(PrintNumber~(x))), Get_points(tmpGraphics))))[1..-3]);
				print("Points");
				return;
			end if:


		elif selType = "Line" then

			# Colour
			newVal := op(ReadSet_GetList('txtLineColour'));
			curVal := Get_color(tmpGraphics);
			if newVal <> curVal then
				if type(newVal, [numeric, numeric, numeric]) then
					newVal := parse(sprintf("[%s, %s, %s]", op(PrintNumber~(newVal))));
					Set_color(tmpGraphics, op(newVal));
				end if;
				DocumentTools:-SetProperty('txtLineColour', 'value', sprintf("{%s, %s, %s}", op(PrintNumber~(Get_color(tmpGraphics)))));
				print("Line Colour");
				return;
			end if:

			# Line Thickness
			newVal := op(ReadSet_GetList('txtLineThickness'));
			curVal := Get_thickness(tmpGraphics);
			if newVal <> curVal then
				if type(newVal, numeric) then
					newVal := parse(sprintf("%s", PrintNumber(newVal)));
					Set_thickness(tmpGraphics, newVal);
				end if;
				DocumentTools:-SetProperty('txtLineThickness', 'value', sprintf("%s", PrintNumber(Get_thickness(tmpGraphics))));
				print("Line Thickness");
				return;
			end if:

			# Smooth
			newVal := DocumentTools:-GetProperty('cmbSmooth', 'value');
			curVal := Get_smooth(tmpGraphics);
			if newVal <> curVal then
				Set_smooth(tmpGraphics, newVal);
				print("Smooth");
				return;
			end if:

			# Arrow
			newVal := StringTools:-Split(StringTools:-DeleteSpace(DocumentTools:-GetProperty('cmbArrow', 'value')), ",");
			curVal := Get_arrow(tmpGraphics);
			if newVal <> curVal then
				Set_arrow(tmpGraphics, op(newVal));
				print("Arrow");
				return;
			end if:

			# Arrow Size
			newVal := op(ReadSet_GetList('txtArrowSize'));
			curVal := Get_arrowSize(tmpGraphics);
			if newVal <> curVal then
				if type(newVal, positive) then
					newVal := parse(sprintf("%s", PrintNumber(newVal)));
					Set_arrowSize(tmpGraphics, newVal);
				end if;
				DocumentTools:-SetProperty('txtArrowSize', 'value', sprintf("%s", PrintNumber(Get_arrowSize(tmpGraphics))));
				print("Arrow Size");
				return;
			end if:

			# Points
			newVal := ReadSet_GetList('txtPoints');
			curVal := Get_points(tmpGraphics);
			if newVal <> curVal then
				if type(newVal, list([numeric, numeric])) then
					newVal := [parse(cat(op(map(x -> sprintf("[%s, %s],", op(PrintNumber~(x))), newVal)))[1..-2])];
					Set_points(tmpGraphics, newVal);
				end if:
				DocumentTools:-SetProperty('txtPoints', 'visiblerows', 1+numelems(Get_points(tmpGraphics)), 'refresh' = true);
				DocumentTools:-SetProperty('txtPoints', 'value', cat(op(map(x -> sprintf("{%s, %s},\n", op(PrintNumber~(x))), Get_points(tmpGraphics))))[1..-3]);
				print("Points");
				return;
			end if:

		end if:


		print("Nothing!");
		return;
	end proc;


	#------------------------------------------------------------------------------------------------
	local
	CM_UpdateDisplay::static := proc(self ::IconCreator, $)
	#------------------------------------------------------------------------------------------------
		description "Update the context menu values and display.";

		local
			  selType		# string for the type of graphical object that has been selected
			, tmpGraphics	# object for graphical object selected
			, x				# indexing variable
			;

		# hide the context menu table
		DocumentTools:-SetProperty('tblContextMenu', 'visible', false);

		# determine what is currently selected
		if self:-selID = 0 then
			selType := "Canvas";
		else
			tmpGraphics := self:-graphics[self:-selID];
			selType := Get_objType(tmpGraphics);
		end if;

		# updates displayed rows and values based on the selection
		if selType = "Canvas" then
			DocumentTools:-SetProperty('cbxVisible', 'value', false);
			DocumentTools:-SetProperty('txtOrigin', 'value', "");
			DocumentTools:-SetProperty('txtRotation', 'value', "");
			DocumentTools:-SetProperty('txtLineColour', 'value', "");
			DocumentTools:-SetProperty('txtFillColour', 'value', "");
			DocumentTools:-SetProperty('cmbLinePattern', 'value', "None");
			DocumentTools:-SetProperty('cmbFillPattern', 'value', "None");
			DocumentTools:-SetProperty('txtLineThickness', 'value', "");
			DocumentTools:-SetProperty('cmbBorderPattern', 'value', "None");
			DocumentTools:-SetProperty('txtRadius', 'value', "");
			DocumentTools:-SetProperty('txtExtent', 'value', "");
			DocumentTools:-SetProperty('txtStartAngle', 'value', "");
			DocumentTools:-SetProperty('txtEndAngle', 'value', "");
			DocumentTools:-SetProperty('cmbSmooth', 'value', "None");
			DocumentTools:-SetProperty('txtPoints', 'visiblerows', 1, 'refresh' = true);
			DocumentTools:-SetProperty('txtPoints', 'value', "");
			DocumentTools:-SetProperty('cmbArrow', 'value', "None, None");
			DocumentTools:-SetProperty('txtArrowSize', 'value', "");

		else
			DocumentTools:-SetProperty('cbxVisible', 'value', Get_visible(tmpGraphics));
			DocumentTools:-SetProperty('txtOrigin', 'value', sprintf("{%s, %s}", op(PrintNumber~(Get_origin(tmpGraphics)))));
			DocumentTools:-SetProperty('txtRotation', 'value', sprintf("%s", PrintNumber(Get_rotation(tmpGraphics))));
			DocumentTools:-SetProperty('cmbLinePattern', 'value',
				ifelse(Get_pattern(tmpGraphics) = "DashDot"
					, "Dash Dot"
					, ifelse(Get_pattern(tmpGraphics) = "DashDotDot"
						, "Dash Dot Dot"
						, Get_pattern(tmpGraphics)
						)
					)
				);

			if member(selType, {"Rectangle", "Ellipse", "Polygon"}) then
				DocumentTools:-SetProperty('txtLineColour', 'value', sprintf("{%s, %s, %s}", op(PrintNumber~(Get_lineColor(tmpGraphics)))));
				DocumentTools:-SetProperty('txtFillColour', 'value', sprintf("{%s, %s, %s}", op(PrintNumber~(Get_fillColor(tmpGraphics)))));
				DocumentTools:-SetProperty('cmbFillPattern', 'value',
					ifelse(Get_fillPattern(tmpGraphics) = "CrossDiag"
						, "Cross Diag"
						, ifelse(Get_fillPattern(tmpGraphics) = "HorizontalCylinder"
							, "Horizontal Cylinder"
							, ifelse(Get_fillPattern(tmpGraphics) = "VerticalCylinder"
								, "Vertical Cylinder"
								, Get_fillPattern(tmpGraphics)
								)
							)
						)
					);
				DocumentTools:-SetProperty('txtLineThickness', 'value', sprintf("%s", PrintNumber(Get_lineThickness(tmpGraphics))));
			end if:

			if selType = "Rectangle" then
				DocumentTools:-SetProperty('cmbBorderPattern', 'value', Get_borderPattern(tmpGraphics));
				DocumentTools:-SetProperty('txtRadius', 'value', sprintf("%s", PrintNumber(Get_radius(tmpGraphics))));
				DocumentTools:-SetProperty('txtExtent', 'value', sprintf("{%s, %s},\n{%s, %s}", op(PrintNumber~(ListTools:-Flatten(Get_extent(tmpGraphics))))));

				# display the rows from the context menu table
				DocumentTools:-SetProperty('tblContextMenu', 'visible'[2..3], true);
				DocumentTools:-SetProperty('tblContextMenu', 'visible'[6..9], true);
				DocumentTools:-SetProperty('tblContextMenu', 'visible'[10], true, 'refresh' = true);

			elif selType = "Ellipse" then
				DocumentTools:-SetProperty('txtStartAngle', 'value', sprintf("%s", PrintNumber(Get_startAngle(tmpGraphics))));
				DocumentTools:-SetProperty('txtEndAngle', 'value', sprintf("%s", PrintNumber(Get_endAngle(tmpGraphics))));
				DocumentTools:-SetProperty('txtExtent', 'value', sprintf("{%s, %s},\n{%s, %s}", op(PrintNumber~(ListTools:-Flatten(Get_extent(tmpGraphics))))));

				# display the rows from the context menu table
				DocumentTools:-SetProperty('tblContextMenu', 'visible'[2..3], true);
				DocumentTools:-SetProperty('tblContextMenu', 'visible'[6..10], true);
				DocumentTools:-SetProperty('tblContextMenu', 'visible'[13], true);
				DocumentTools:-SetProperty('tblContextMenu', 'visible'[14], true, 'refresh' = true);

			elif selType = "Polygon" then
				DocumentTools:-SetProperty('cmbSmooth', 'value', Get_smooth(tmpGraphics));
				DocumentTools:-SetProperty('txtPoints', 'visiblerows', 1+numelems(Get_points(tmpGraphics)), 'refresh' = true);
				DocumentTools:-SetProperty('txtPoints', 'value', cat(op(map(x -> sprintf("{%s, %s},\n", op(PrintNumber~(x))), Get_points(tmpGraphics))))[1..-3]);

				# display the rows from the context menu table
				DocumentTools:-SetProperty('tblContextMenu', 'visible'[2], true);
				DocumentTools:-SetProperty('tblContextMenu', 'visible'[4..10], true);
				DocumentTools:-SetProperty('tblContextMenu', 'visible'[15], true, 'refresh' = true);

			elif selType = "Line" then
				DocumentTools:-SetProperty('txtLineColour', 'value', sprintf("{%s, %s, %s}", op(PrintNumber~(Get_color(tmpGraphics)))));
				DocumentTools:-SetProperty('txtLineThickness', 'value', sprintf("%s", PrintNumber(Get_thickness(tmpGraphics))));
				DocumentTools:-SetProperty('cmbSmooth', 'value', Get_smooth(tmpGraphics));
				DocumentTools:-SetProperty('cmbArrow', 'value', StringTools:-Join(Get_arrow(tmpGraphics), ", "));
				DocumentTools:-SetProperty('txtArrowSize', 'value', sprintf("%s", PrintNumber(Get_arrowSize(tmpGraphics))));
				DocumentTools:-SetProperty('txtPoints', 'visiblerows', 1+numelems(Get_points(tmpGraphics)), 'refresh' = true);
				DocumentTools:-SetProperty('txtPoints', 'value', cat(op(map(x -> sprintf("{%s, %s},\n", op(PrintNumber~(x))), Get_points(tmpGraphics))))[1..-3]);

				# display the rows from the context menu table
				DocumentTools:-SetProperty('tblContextMenu', 'visible'[2], true);
				DocumentTools:-SetProperty('tblContextMenu', 'visible'[4], true);
				DocumentTools:-SetProperty('tblContextMenu', 'visible'[6..8], true);
				DocumentTools:-SetProperty('tblContextMenu', 'visible'[15..16], true);
				DocumentTools:-SetProperty('tblContextMenu', 'visible'[17],true, 'refresh' = true);

			end if:

		end if:

		return;
	end proc;


#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
#
# Interacting with the canvas
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

	#------------------------------------------------------------------------------------------------
	export
	Drag::static := proc(self ::IconCreator, $)
	#------------------------------------------------------------------------------------------------
		description "Handles what happens when the user drags on the canvas";

		# if it's the start of a drag, call Click to update where the dragged action started from
		local tempPt := [DocumentTools:-GetProperty('pltCanvas', 'startx'), DocumentTools:-GetProperty('pltCanvas', 'starty')];
		if self:-dragStart <> tempPt then
			if self:-selID <> 0 then
				if not(ClickedBoundary(self:-graphics[self:-selID], op(tempPt))) then
					Click(self);
				end if:
			else
				Click(self);
			end if:

			self:-dragStart := tempPt;
		end if:

		# if nothing is selected then do nothing
		if self:-selID = 0 then
			return;
		end if;

		# drag the graphical element and update the display
		Dragged(
			  self:-graphics[self:-selID]
			, tempPt
			, [DocumentTools:-GetProperty('pltCanvas', 'endx'), DocumentTools:-GetProperty('pltCanvas', 'endy')]
			, self:-gridSize
			);
		DisplayIcon(self);

		# update the context menu
		#Context_Menu(self);  # added this in the Drag End code for the plot object to reduce context menu flickering

		return;
	end proc;

	#------------------------------------------------------------------------------------------------
	export
	DragEnd::static := proc(self ::IconCreator, $)
	#------------------------------------------------------------------------------------------------
		description "Handles what happens when the user ends the drag on the canvas";

		# update the context menu
		Context_Menu(self);

		# take a state snapshot
		State_Add(self);

		return;
	end proc;

	#------------------------------------------------------------------------------------------------
	export
	Click::static := proc(self ::IconCreator, $)
	#------------------------------------------------------------------------------------------------
		description "Handles what happens when the user clicks on the canvas";

		# get the user click info
		local
			  xClick := DocumentTools:-GetProperty('pltCanvas', 'startx')
			, yClick := DocumentTools:-GetProperty('pltCanvas', 'starty')
			;

		# check if the click is within a bounding box for any of the graphical elements
		local i;

		self:-selID := 0;
		for i to ArrayTools:-NumElems(self:-graphics) do
			if Clicked(self:-graphics[i], xClick, yClick) then
				self:-selID := i;
				break;
			end if:
		end do:

		# update the visualization
		DisplayIcon(self);

		# udpate the context menu
		Context_Menu(self);

		return;
	end proc;


#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
#
# Buttons
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

	#------------------------------------------------------------------------------------------------
	local
	State_Add::static := proc(self ::IconCreator, $)
	#------------------------------------------------------------------------------------------------
		description "Takes a snapshot of the current state of the app and adds it to the array of states.";

		# perform a check if the current state is equal to the number of states saved
		# if not then the user has undone some actions and some states need to be removed before adding a new one
		if self:-curState < ArrayTools:-NumElems(self:-states) then
			ArrayTools:-Remove(self:-states, self:-curState+1..-1);
		end if:

		# add a snapshot to the end of the state Array
		ArrayTools:-Extend(self:-states,
			[table([
				"graphics" = copy(self:-graphics, 'deep'),
				"selID" = self:-selID,
				"extent" = self:-extent,
				"dragStart" = self:-dragStart,
				"curView" = self:-curView,
				"gridSize" = self:-gridSize,
				"addGridLines" = self:-addGridLines,
				"gridLines" = self:-gridLines
			])]
		);

		# increment the current position
		self:-curState++;

		return;
	end proc;

	#------------------------------------------------------------------------------------------------
	local
	State_Set::static := proc(self ::IconCreator, $)
	#------------------------------------------------------------------------------------------------
		description "Sets the current state of the app from the stored information.";

		# set the state of the app from the snapshot data
		self:-graphics := copy(self:-states[self:-curState]["graphics"], 'deep');
		self:-selID := self:-states[self:-curState]["selID"];
		self:-extent := self:-states[self:-curState]["extent"];
		IconExtent(self, 'stateSet' = true);
		self:-dragStart := self:-states[self:-curState]["dragStart"];
		self:-curView := self:-states[self:-curState]["curView"];
		self:-gridSize := self:-states[self:-curState]["gridSize"];
		IconGridSize(self, 'stateSet' = true);
		self:-addGridLines := self:-states[self:-curState]["addGridLines"];
		self:-gridLines := self:-states[self:-curState]["gridLines"];
		IconGridLines(self, 'stateSet' = true);

		# update the icon display, the context menu, and the current view
		DisplayIcon(self);
		Context_Menu(self);
		ToggleMainView(self, 'stateSet' = true);


		return;
	end proc;

	#------------------------------------------------------------------------------------------------
	export
	Undo::static := proc(self ::IconCreator, $)
	#------------------------------------------------------------------------------------------------
		description "Undo the previous action.";

		if self:-curState > 1 then
			self:-curState--;
			State_Set(self);
		end if:

		return;
	end proc;

	#------------------------------------------------------------------------------------------------
	export
	Redo::static := proc(self ::IconCreator, $)
	#------------------------------------------------------------------------------------------------
		description "Redo the previous action.";

		if self:-curState < ArrayTools:-NumElems(self:-states) then
			self:-curState++;
			State_Set(self);
		end if:

		return;
	end proc;

	#------------------------------------------------------------------------------------------------
	export
	Move::static := proc(self ::IconCreator, dir ::{"up", "left", "down", "right"}, $)
	#------------------------------------------------------------------------------------------------
		description "Moves the selected graphical element from a button click.";

		# if nothing is selected then do nothing
		if self:-selID = 0 then
			return;
		end if;

		# move the origin
		Set_origin(self:-graphics[self:-selID], Get_origin(self:-graphics[self:-selID]) +~
			ifelse(dir = "up", [0, self:-gridSize],
				ifelse(dir = "left", [-self:-gridSize, 0],
					ifelse(dir = "down", [0, -self:-gridSize],
						[self:-gridSize, 0]
					)
				)
			)
		);

		# update the display
		DisplayIcon(self);

		# udpate the context menu
		Context_Menu(self);

		# take a state snapshot
		State_Add(self);

		return;
	end proc;

	#------------------------------------------------------------------------------------------------
	export
	Depth::static := proc(	  self ::IconCreator
							, dir ::{"toFront", "forward", "backward", "toBack"}
							, $)
	#------------------------------------------------------------------------------------------------
		description "Changes the level at which the selected graphical element is displayed.";

		# if nothing is selected then do nothing
		if self:-selID = 0 then
			return;
		end if;

		# change the order of the graphics array to get the new depths
		local
			  movePos := 	ifelse(dir = "toFront", 1,
								ifelse(dir = "forward", self:-selID - 1,
									ifelse(dir = "backward", self:-selID + 1,
										ArrayTools:-NumElems(self:-graphics)
									)
								)
							)
			, tmpVal := copy(self:-graphics[self:-selID], 'deep')
			;

		# add a check that we are not trying to change the depth to a value outside of what is allowed
		if movePos < 1 or movePos > ArrayTools:-NumElems(self:-graphics) then
			return;
		end if:

		ArrayTools:-Remove(self:-graphics, self:-selID);
		ArrayTools:-Insert(self:-graphics, movePos, tmpVal);

		# update the selected grpahical element to be the one that was just moved
		self:-selID := movePos:

		# update the display
		DisplayIcon(self);

		# take a state snapshot
		State_Add(self);

		return;
	end proc;

	#------------------------------------------------------------------------------------------------
	export
	Delete::static := proc(self ::IconCreator, $)
	#------------------------------------------------------------------------------------------------
		description "Delete the currently selected graphical element.";

		# if nothing is selected then do nothing
		if self:-selID = 0 then
			return;
		end if;

		# change the order of the graphics array to get the new depths
		ArrayTools:-Remove(self:-graphics, self:-selID);

		# update the selected grpahical element to be the one that was just moved
		self:-selID := 0:

		# update the display
		DisplayIcon(self);

		# udpate the context menu
		Context_Menu(self);

		# take a state snapshot
		State_Add(self);

		return;
	end proc;

	#------------------------------------------------------------------------------------------------
	export
	Duplicate::static := proc(self ::IconCreator, $)
	#------------------------------------------------------------------------------------------------
		description "Duplicate the currently selected graphical element.";

		# if nothing is selected then do nothing
		if self:-selID = 0 then
			return;
		end if;

		# add a copy of the graphical element to the start of the graphics array
		ArrayTools:-Insert(self:-graphics, 1, copy(self:-graphics[self:-selID], 'deep'));

		# update the selected grpahical element to be the one that was just added
		self:-selID := 1:

		# update the origin of the duplicated object to be a multiples of the grid size so that it does not display directly on top
		Set_origin(self:-graphics[self:-selID], Get_origin(self:-graphics[self:-selID]) +~ 5 * self:-gridSize);

		# update the display
		DisplayIcon(self);

		# udpate the context menu
		Context_Menu(self);

		# take a state snapshot
		State_Add(self);

		return;
	end proc;

	#------------------------------------------------------------------------------------------------
	export
	ZoomIn::static := proc(self ::IconCreator, $)
	#------------------------------------------------------------------------------------------------
		description "Decrease the zoom level stored internally to create a zoom in effect.";

		# reduce by 0.1 (10%) to a minimum of 0.1
		self:-zoom := max(0.1, self:-zoom - 0.1);

		# update the display
		DisplayIcon(self);

		return;
	end proc;

	#------------------------------------------------------------------------------------------------
	export
	ZoomOut::static := proc(self ::IconCreator, $)
	#------------------------------------------------------------------------------------------------
		description "Increase the zoom level stored internally to create a zoom out effect.";

		# increase by 0.1 (10%) to a maximum of 2.5
		self:-zoom := min(2.5, self:-zoom + 0.1);

		# update the display
		DisplayIcon(self);

		return;
	end proc;


#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
#
# Visualization
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

	#------------------------------------------------------------------------------------------------
	export
	DisplayIcon::static := proc(self ::IconCreator, $)
	#------------------------------------------------------------------------------------------------
		description "Creates a display of the icon.";

		# disp will contain all the information for the plotting
		local disp := NULL;

		# add the border to show currently selected item
		if self:-selID <> 0 then
			disp := disp, DisplaySelected(self:-graphics[self:-selID]);
		end if;

		# get the display for each of the graphical elements
		local
			  i
			, num := ArrayTools:-NumElems(self:-graphics)
			;

		for i to num do
			disp := disp, Display(self:-graphics[i]);
		end do:

		# get the background view
		disp := disp, DisplayIconBorder(self);

		# get the grid lines
		disp := disp, DisplayGridLines(self);

		# plot the icon
		DocumentTools:-SetProperty('pltCanvas', 'value', PLOT(disp));

		return;
	end proc:

	#------------------------------------------------------------------------------------------------
	local
	DisplayIconBorder::static := proc(self ::IconCreator, $)
	#------------------------------------------------------------------------------------------------
		description "Creates a display of the icon border.";

		local
			  borderColor := [0.94117647, 0.90196078, 0.54901961]	# this color is "Khaki"
			, size := self:-extent								# size of the icon
			, view := size *~ self:-zoom						# total view size (including the border)
			, disp := NULL										# the background display
			;

		# check if the icon border should be drawn
		if parse(DocumentTools:-GetProperty('chkExtentBorder', 'value')) then
			disp := disp, CURVES([
							[size[1][1], size[1][2]],
							[size[2][1], size[1][2]],
							[size[2][1], size[2][2]],
							[size[1][1], size[2][2]],
							[size[1][1], size[1][2]]
						], THICKNESS(4), COLOUR(RGB, op(borderColor)));

		end if:

		# add additional options
		disp := disp, SCALING(CONSTRAINED), VIEW(view[1][1]..view[2][1], view[1][2]..view[2][2]);

		return disp;
	end proc:

	#------------------------------------------------------------------------------------------------
	local
	DisplayGridLines::static := proc(self ::IconCreator, $)
	#------------------------------------------------------------------------------------------------
		description "Creates a display of the grid lines.";

		local
			  gridColor := [0.75294118, 0.75294118, 0.75294118]	# this color is "gray"
			, size := self:-extent									# size of the icon
			, view := size *~ self:-zoom							# total view size (including the border)
			, disp := NULL											# the background display
			;

		# add grid lines if they are being displayed
		if self:-addGridLines then

			# remove the numbering from the axes style
			disp := disp, AXESTICKS(
								[seq( i * self:-gridLines = "", i = ceil(view[1][1]/self:-gridLines) .. floor(view[2][1]/self:-gridLines))],
								[seq( i * self:-gridLines = "", i = ceil(view[1][2]/self:-gridLines) .. floor(view[2][2]/self:-gridLines))]
							);

			# add axes style to ensure that the gridlines are displayed
			disp := disp, AXESSTYLE(BOX);

			# add vertical lines
			disp := disp, _AXIS[1](_GRIDLINES(DEFAULT, LINESTYLE(3)));

			# add horizontal lines
			disp := disp, _AXIS[2](_GRIDLINES(DEFAULT, LINESTYLE(3)));

		else

			disp := disp, AXESSTYLE(NONE);

		end if:

		return disp;
	end proc:


#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
#
# Adding graphical elements
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

	#------------------------------------------------------------------------------------------------
	export
	AddRectangle::static := proc(self ::IconCreator, $)
	#------------------------------------------------------------------------------------------------
		description "Adds a Rectangle grpahical element to the icon."
					"Makes the newly added Rectangle the current selection.";

		# add a Rectangle with default size to the front of the array (make it front view)
		ArrayTools:-Insert(self:-graphics, 1, Rectangle([-50, -50], [50, 50]));

		# update the selected ID
		self:-selID := 1;

		# update the display
		DisplayIcon(self);

		# update the context menu
		Context_Menu(self);

		# take a state snapshot
		State_Add(self);

		return;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	AddEllipse::static := proc(self ::IconCreator, $)
	#------------------------------------------------------------------------------------------------
		description "Adds a Ellipse grpahical element to the icon."
					"Makes the newly added Ellipse the current selection.";

		# add a Ellipse with default size to the front of the array (make it front view)
		ArrayTools:-Insert(self:-graphics, 1, Ellipse([-50, -50], [50, 50]));

		# update the selected ID
		self:-selID := 1;

		# update the display
		DisplayIcon(self);

		# update the context menu
		Context_Menu(self);

		# take a state snapshot
		State_Add(self);

		return;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	AddLine::static := proc(self ::IconCreator, $)
	#------------------------------------------------------------------------------------------------
		description "Adds a Line grpahical element to the icon."
					"Makes the newly added Line the current selection.";

		# add a Line with default size to the front of the array (make it front view)
		ArrayTools:-Insert(self:-graphics, 1, Line([[-50, -50], [50, 50]]));

		# update the selected ID
		self:-selID := 1;

		# update the display
		DisplayIcon(self);

		# update the context menu
		Context_Menu(self);

		# take a state snapshot
		State_Add(self);

		return;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	AddPolygon::static := proc(self ::IconCreator, $)
	#------------------------------------------------------------------------------------------------
		description "Adds a Polygon grpahical element to the icon."
					"Makes the newly added Polygon the current selection.";

		# add a Polygon with default size to the front of the array (make it front view)
		ArrayTools:-Insert(self:-graphics, 1, Polygon([[-50, 0], [-25, -50], [25, -50], [50, 0], [0, 50]]));

		# update the selected ID
		self:-selID := 1;

		# update the display
		DisplayIcon(self);

		# update the context menu
		Context_Menu(self);

		# take a state snapshot
		State_Add(self);

		return;
	end proc:


#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
#
# Module apply and copy
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

	#------------------------------------------------------------------------------------------------
	export
	ModuleApply::static := proc()
	#------------------------------------------------------------------------------------------------
		description "Defines what happens when calling IconCreator()";

		return Object(IconCreator, _passed);
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	ModuleCopy::static := proc(self ::IconCreator, proto ::IconCreator, $)
	#------------------------------------------------------------------------------------------------
		description "Defines what happens when calling Object(IconCreator)";

		DocumentTools:-SetProperty('txtIconExtent', 'value', "iconExtent");
		IconExtent(self);
		DocumentTools:-SetProperty('txtGridSize', 'value', "gridSize");
		IconGridSize(self);
		DocumentTools:-SetProperty('chkAddGridLines', 'value', true);
		DocumentTools:-SetProperty('txtGridLines', 'value', "gridLineSize");
		IconGridLines(self);
		DisplayIcon(self);  # display the blank icon
		ToggleMainView(self);  # set the view to be the icon
		# reset the states array and take a snapshot - from some of the actions above there would be multiple states added
		self:-states := Array([]):
		self:-curState := 0:
		State_Add(self);  # take a state snapshot

		return;
	end proc:


#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
#
# Retrieving info form the objects
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

	#------------------------------------------------------------------------------------------------
	export
	Graphics::static := proc(self ::IconCreator, $)
	#------------------------------------------------------------------------------------------------
		description "Return the graphics variable.";

		return copy(self:-graphics, 'deep');
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	SelID::static := proc(self ::IconCreator, $)
	#------------------------------------------------------------------------------------------------
		description "Return the selID variable.";

		return self:-selID;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Extent::static := proc(self ::IconCreator, $)
	#------------------------------------------------------------------------------------------------
		description "Return the extent variable.";

		return self:-extent;
	end proc:


end module;

protect('IconCreator');