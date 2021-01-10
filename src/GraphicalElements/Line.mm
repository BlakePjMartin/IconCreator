unprotect('Line');

module Line()

	# inherit the GraphicItem object
	option object(GraphicItem);

#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
#
# Object variables
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
	local
		# these variables are specified in the Modelica standard
		  points	# list of points in the line
		, color := [0, 0, 0]
		, pattern := "Solid"
		, thickness := 0.25
		, arrow := ["None", "None"]
		, arrowSize := 3.0
		, smooth := "None"

		# this is the calculated location of the corners of the ellipse based on the extent, rotation, and origin values
		, boxSize := 3  # size of boxes when the object is selected

		# record of information for a during a drag action
		, drag := Record(	  "type" = false	# [false, point]
							, "num" = 0			# integer indicate the number of the point selected
							, "start" = [0, 0]
							, "origin" = [0, 0]
							, "points" = []
							)
		;

#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
#
# Helper functions
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
$include <src/PrintNumber.mm>

#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
#
# Maple visualization of the line
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

	#------------------------------------------------------------------------------------------------
	export
	DisplaySelected::static := proc(self ::Line, $)
	#------------------------------------------------------------------------------------------------
		description "Creates a visualization that should be shown when the Line is displayed.";

		# disp will contain all the information for the plotting
		local
			  i
			, disp := NULL
			, tempPt
			;

		# add box for each of the points
		for i to numelems(self:-points) do
			tempPt := self:-origin + self:-points[i];
			disp := disp, POLYGONS([	  [tempPt[1]-self:-boxSize, tempPt[2]-self:-boxSize]
										, [tempPt[1]+self:-boxSize, tempPt[2]-self:-boxSize]
										, [tempPt[1]+self:-boxSize, tempPt[2]+self:-boxSize]
										, [tempPt[1]-self:-boxSize, tempPt[2]+self:-boxSize]
									], STYLE(LINE), THICKNESS(0));

		end do:

		# add a light blue border
		disp := disp, seq(
						  CURVES(
							  op(
								  plottools:-line(
									  self:-origin + self:-points[i]
									, self:-origin + self:-points[i+1]
									, 'transparency'= 0.75
									)
								)
							, THICKNESS(10)
							, COLOR(RGB, 0, 0,  0.80392157)
							)
						, i = 1..numelems(self:-points)-1
						);

		return disp;
	end proc;

	#------------------------------------------------------------------------------------------------
	export
	Display::static := proc(self ::Line)
	#------------------------------------------------------------------------------------------------
		description "Generates a Maple plot of the Line object.";

		# check if the line is visible
		if not(self:-visible) then
			return PLOT();
		end if:

		# create the lines for the outline of the rectangle, if not set to "None"
		local lineDisp;
		if self:-pattern = "None" then
			lineDisp := NULL;
		else

			lineDisp := POLYGONS(
							  [self:-origin$numelems(self:-points)] + self:-points
							, COLOR(RGB, op(self:-color/~255.0))
							, STYLE(LINE)
							, LINESTYLE(ifelse(self:-pattern = "Solid", SOLID, ifelse(self:-pattern = "Dash", DASH, ifelse(self:-pattern = "Dot", DOT, DASHDOT))))
							, THICKNESS(self:-thickness/0.25)
						);

(*
			lineDisp := seq(POLYGONS([self:-origin + self:-points[i], self:-origin + self:-points[i+1]]
								, COLOR(RGB, op(self:-color/~255.0))
								, STYLE(LINE)
								, LINESTYLE(ifelse(self:-pattern = "Solid", SOLID, ifelse(self:-pattern = "Dash", DASH, ifelse(self:-pattern = "Dot", DOT, DASHDOT))))
								, THICKNESS(self:-thickness/0.25)
								)
							, i = 1..numelems(self:-points)-1);
*)
		end if:

		return lineDisp;
	end proc:

#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
#
# Modelica code output
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

	#------------------------------------------------------------------------------------------------
	export
	GraphicModelica::static := proc(self ::Line, $)
	#------------------------------------------------------------------------------------------------
		description "Generates Modelica code for the Line.";

		local
			  mo := cat("\t\t\tLine(\n")
			, defGraphic := Line([[-1, -1], [1, 1]])
			, curVal
			, x
			;

		# Origin
		curVal := Get_origin(self);
		if curVal <> Get_origin(defGraphic) then
			mo := sprintf("%s\t\t\t\torigin = {%s, %s},\n", mo, op(PrintNumber~(curVal)));
		end if:

		# Points
		mo := sprintf("%s\t\t\t\tpoints = {%s},\n", mo, StringTools:-Join(map(x -> sprintf("{%s, %s}", op(PrintNumber~(x))), Get_points(self)), ", "));

		# Visible
		curVal := Get_visible(self);
		if curVal <> Get_visible(defGraphic) then
			mo := sprintf("%s\t\t\t\tvisible = %s,\n", mo, convert(curVal, 'string'));
		end if:

		# Rotation
		curVal := Get_rotation(self);
		if curVal <> Get_rotation(defGraphic) then
			mo := sprintf("%s\t\t\t\trotation = %s,\n", mo, PrintNumber(curVal));
		end if:

		# Line Pattern
		curVal := Get_pattern(self);
		if curVal <> Get_pattern(defGraphic) then
			mo := sprintf("%s\t\t\t\tpattern = LinePattern.%s,\n", mo, StringTools:-DeleteSpace(curVal));
		end if:

		# Colour
		curVal := Get_color(self);
		if curVal <> Get_color(defGraphic) then
			mo := sprintf("%s\t\t\t\tcolor = {%s, %s, %s},\n", mo, op(PrintNumber~(curVal)));
		end if:

		# Line Thickness
		curVal := Get_thickness(self);
		if curVal <> Get_thickness(defGraphic) then
			mo := sprintf("%s\t\t\t\tthickness = %s,\n", mo, PrintNumber(curVal));
		end if:

		# Smooth
		curVal := Get_smooth(self);
		if curVal <> Get_smooth(defGraphic) then
			mo := sprintf("%s\t\t\t\tsmooth = Smooth.%s,\n", mo, curVal);
		end if:

		# Arrow
		curVal := Get_arrow(self);
		if curVal <> Get_arrow(defGraphic) then
			mo := sprintf("%s\t\t\t\tarrow = {%s, %s},\n", mo, op(curVal));
		end if:

		# Arrow Size
		curVal := Get_arrowSize(self);
		if curVal <> Get_arrowSize(defGraphic) then
			mo := sprintf("%s\t\t\t\tarrowSize = %s,\n", mo, PrintNumber(curVal));
		end if:

		# trim the string to remove extra characters
		mo := sprintf("%s),\n",  mo[1..-3]);

		return mo;
	end proc;

#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
#
# Click actions
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

	#------------------------------------------------------------------------------------------------
	export
	Clicked::static := proc(self ::Line, x ::numeric, y ::numeric, $)
	#------------------------------------------------------------------------------------------------
		description "Returns true or false to indicate if the Line has been clicked based on the given [x,y]."
					"Internally updates drag[\"type\"] to indicate what kind of drag action would be performed if [x,y] was the starting click.";

		# reset the drag info
		self:-drag["type"] := false;
		self:-drag["num"] := 0;

		# checks if the point [x,y] lies close enough to the Line
		# check for type "inside"
		local thisType := false, origPt1, origPt2, vecPts, vecPerp, ptsRect, pt1, pt2, A, B, C, curCheck, eps := 5.;

		for i to numelems(self:-points) - 1 do
			origPt1 := self:-origin + self:-points[i];
			origPt2 := self:-origin + self:-points[i+1];

			# get a vector perpendicular to the line from origPt1 to origPt2
			# get the vector from origPt1 to origPt2 and then rotate by 90 deg
			vecPts := (origPt2 - origPt1)/sqrt(add((origPt2 - origPt1)^~2.));
			vecPerp := [-vecPts[2], vecPts[1]];  # vecPts with a rotation of 90 deg applied

			# calculate the points for the rectangle surrounding the line - do it in counter-clockwise order
			ptsRect := [origPt1 + eps * vecPerp, origPt1 - eps * vecPerp, origPt2 - eps * vecPerp, origPt2 + eps * vecPerp];

			# check the current rectangle
			curCheck := [];
			for local k to 4 do
				pt1 := ptsRect[k];
				pt2 := ptsRect[modp(k, 4) + 1];

				A := -(pt2[2] - pt1[2]);
				B := pt2[1] - pt1[1];
				C := -(A*pt1[1] + B*pt1[2]);

				curCheck := [op(curCheck), ifelse(A*x + B*y + C <= 0, false, true)];
			end do:

			# only inside the rectangle if all the entries are true
			if not(member(false, curCheck)) then
				thisType := true;
				break;
			end if;
		end do:

		if thisType then
			self:-drag["type"] := "inside";
			return true;
		end if:

		return false;
	end proc;

	#------------------------------------------------------------------------------------------------
	export
	ClickedBoundary::static := proc(self ::Line, x ::numeric, y ::numeric, $)
	#------------------------------------------------------------------------------------------------
		description "Returns true or false to indicate if the Line has been clicked based on the given [x,y]."
					"Internally updates drag[\"type\"] to indicate what kind of drag action would be performed if [x,y] was the starting click.";

		# reset the drag info
		self:-drag["type"] := false;
		self:-drag["num"] := 0;

		# check if the point [x,y] is inside one of the boxes on the points when the line is selected
		# check for type "point" and sets the number of the point
		local i, tempPt;

		for i to numelems(self:-points) do
			tempPt := self:-origin + self:-points[i];
			if abs(x - tempPt[1]) <= self:-boxSize and abs(y - tempPt[2]) <= self:-boxSize then
				self:-drag["type"] := "point";
				self:-drag["num"] := i;
				return true;
			end if:
		end do:

		return false;
	end proc;

	#------------------------------------------------------------------------------------------------
	export
	Dragged::static := proc(	  self ::Line
								, ptStart ::[numeric, numeric]
								, ptEnd ::[numeric, numeric]
								, gridSize ::numeric
								, $)
	#------------------------------------------------------------------------------------------------
		description "Handles what happens when the Line is being draggged from [xStart, yStart] to [xEnd, yEnd]."
					"The drag action can either be on the inside or a point of the Line."
					"Sets and uses internal variables to help determine what action to perform."
					"This procedure should only be called after a Clicked has been done";

		# check if the dragStart has changed and if so then update variables
		if self:-drag["start"] <> ptStart then
			self:-drag["start"] := ptStart;
			self:-drag["origin"] := Get_origin(self);
			self:-drag["points"] := Get_points(self);
		end if:

		local tempPts;

		if self:-drag["type"] = false then
			return;

		elif self:-drag["type"] = "inside" then
			# based on the drag origin and current position update the origin
			Set_origin(self, round~((self:-drag["origin"] + ptEnd - self:-drag["start"])/~gridSize)*gridSize);

		elif self:-drag["type"] = "point" then
			# based on the drag origin and current position update the point
			tempPts := self:-drag["points"];
			tempPts[self:-drag["num"]] := tempPts[self:-drag["num"]] + ptEnd - self:-drag["start"];
			Set_points(self, map(x -> round~(x/~gridSize)*gridSize, tempPts));

		end if:

		return;
	end proc;

#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
#
# Module apply and copy
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

	#------------------------------------------------------------------------------------------------
	export
	ModuleApply::static := proc()
	#------------------------------------------------------------------------------------------------
		description "Defines what happens when calling Line([pt1, pt2, ...])";

		return Object(Line, _passed);
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	ModuleCopy::static := proc(self ::Line, proto ::Line, points ::list([numeric, numeric]), $)
	#------------------------------------------------------------------------------------------------
		description "Defines what happens when calling Object(Line, [pt1, pt2, ...])";

		self:-points := points;
		self:-objType := "Line";
		# all the other variables get set to the default values

		return;
	end proc:

#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
#
# get/set for object variables
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

	#------------------------------------------------------------------------------------------------
	export
	Set_points::static := proc(self ::Line, points ::list([numeric, numeric]), $)
	#------------------------------------------------------------------------------------------------
		description "Updates the points variable.";

		self:-points := points;

		return;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Get_points::static := proc(self ::Line, $)
	#------------------------------------------------------------------------------------------------
		description "Returns the points variable.";

		return self:-points;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Set_color::static := proc(self ::Line, R ::integer, G ::integer, B ::integer, $)
	#------------------------------------------------------------------------------------------------
		description "Updates the color variable.";

		self:-color := [R, G, B];

		return;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Get_color::static := proc(self ::Line, $)
	#------------------------------------------------------------------------------------------------
		description "Returns the color variable.";

		return self:-color;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Set_pattern::static := proc(	  self ::Line
									, pattern ::{"None", "Solid", "Dash", "Dot",
											"DashDot", "DashDotDot"}
									, $)
	#---------------------------------------------------------------------------------------------------
		description "Updates the pattern variable.";

		self:-pattern := pattern;

		return;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Get_pattern::static := proc(self ::Line, $)
	#------------------------------------------------------------------------------------------------
		description "Returns the pattern variable.";

		return self:-pattern;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Set_thickness::static := proc(self ::Line, thickness ::positive, $)
	#------------------------------------------------------------------------------------------------
		description "Updates the thickness variable.";

		self:-thickness := thickness;

		return;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Get_thickness::static := proc(self ::Line, $)
	#------------------------------------------------------------------------------------------------
		description "Returns the thickness variable.";

		return self:-thickness;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Set_arrow::static := proc(	  self ::Line
								, arrow1 ::{"None", "Open", "Filled", "Half"}
								, arrow2::{"None", "Open", "Filled", "Half"}
								, $)
	#------------------------------------------------------------------------------------------------
		description "Updates the arrow variable.";

		self:-arrow := [arrow1, arrow2];

		return;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Get_arrow::static := proc(self ::Line, $)
	#------------------------------------------------------------------------------------------------
		description "Returns the arrow variable.";

		return self:-arrow;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Set_arrowSize::static := proc(self ::Line, arrowSize ::positive, $)
	#------------------------------------------------------------------------------------------------
		description "Updates the arrowSize variable.";

		self:-arrowSize := arrowSize;

		return;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Get_arrowSize::static := proc(self ::Line, $)
	#------------------------------------------------------------------------------------------------
		description "Returns the arrowSize variable.";

		return self:-arrowSize;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Set_smooth::static := proc(self ::Line, smooth ::{"None", "Bezier"}, $)
	#------------------------------------------------------------------------------------------------
		description "Updates the smooth variable.";

		self:-smooth := smooth;

		return;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Get_smooth::static := proc(self ::Line, $)
	#------------------------------------------------------------------------------------------------
		description "Returns the smooth variable.";

		return self:-smooth;
	end proc:


end module:

protect('Line');