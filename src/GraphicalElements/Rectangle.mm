unprotect('Rectangle');

module Rectangle()

	# inherit the FilledShape object (which in turn inherits the GraphicItem object)
	option object(FilledShape);

#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
#
# Object variables
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
	local
		# these variables are specified in the Modelica standard
		  borderPattern := "None"
		, extent	# this is the extent value for the Modelica code
		, radius := 0.0

		# this is the calculated location of the corners of the rectangle based on the extent, rotation, and origin values
		, vizPts
		, boxSize := 3  # size of boxes when the object is selected

		# record of information for a during a drag action
		, drag := Record(	  "type" = false	# [false, inside, corner, edge]
							, "num" = 0			# integer indicate the number of the corner/edge selected
							, "start" = [0, 0]
							, "origin" = [0, 0]
							, "extent" = [[0, 0], [0, 0]]
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
# Maple visualization of the rectangle
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
$include <src/GraphicalElements/RectangularBoundary/DisplaySelected.mm>
$include <src/GraphicalElements/RectangularBoundary/CalculateVizPts.mm>

	#------------------------------------------------------------------------------------------------
	export
	Display::static := proc(self ::Rectangle)
	#------------------------------------------------------------------------------------------------
		description "Generates a Maple plot of the Rectangle object.";

		# check if the rectangle is visible
		if not(self:-visible) then
			return PLOT();
		end if:

		# create the lines for the outline of the rectangle, if not set to "None"
		local lineDisp;
		if self:-pattern = "None" then
			lineDisp := NULL;
		else
			lineDisp := POLYGONS(
							  self:-vizPts
							, COLOR(RGB, op(self:-lineColor/~255.0))
							, STYLE(LINE)
							, LINESTYLE(ifelse(self:-pattern = "Solid", SOLID, ifelse(self:-pattern = "Dash", DASH, ifelse(self:-pattern = "Dot", DOT, DASHDOT))))
							, THICKNESS(self:-lineThickness/0.25)
						);
		end if:

		# create the interior of the rectangle, if not set to "None"
		local intDisp;
		if self:-fillPattern = "None" then
			intDisp := NULL;
		else
			intDisp := POLYGONS(
							  self:-vizPts
							, COLOR(RGB, op(self:-fillColor/~255.0))
							, STYLE(PATCHNOGRID)
						);
		end if:

		return lineDisp, intDisp;
	end proc:


#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
#
# Modelica code output
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

	#------------------------------------------------------------------------------------------------
	export
	GraphicModelica::static := proc(self ::Rectangle, $)
	#------------------------------------------------------------------------------------------------
		description "Generates Modelica code for the Rectangle.";

		local
			  mo := cat("\t\t\tRectangle(\n")
			, defGraphic := Rectangle([-1, -1], [1, 1])
			, curVal
			, x
			;

		# Origin
		curVal := Get_origin(self);
		if curVal <> Get_origin(defGraphic) then
			mo := sprintf("%s\t\t\t\torigin = {%s, %s},\n", mo, op(PrintNumber~(curVal)));
		end if:

		# Extent
		mo := sprintf("%s\t\t\t\textent = {{%s, %s}, {%s, %s}},\n", mo, op(PrintNumber~(ListTools:-Flatten(Get_extent(self)))));

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

		# Line Colour
		curVal := Get_lineColor(self);
		if curVal <> Get_lineColor(defGraphic) then
			mo := sprintf("%s\t\t\t\tlineColor = {%s, %s, %s},\n", mo, op(PrintNumber~(curVal)));
		end if:

		# Fill Colour
		curVal := Get_fillColor(self);
		if curVal <> Get_fillColor(defGraphic) then
			mo := sprintf("%s\t\t\t\tfillColor = {%s, %s, %s},\n", mo, op(PrintNumber~(curVal)));
		end if:

		# Fill Pattern
		curVal := Get_fillPattern(self);
		if curVal <> Get_fillPattern(defGraphic) then
			mo := sprintf("%s\t\t\t\tfillPattern = FillPattern.%s,\n", mo, StringTools:-DeleteSpace(curVal));
		end if:

		# Line Thickness
		curVal := Get_lineThickness(self);
		if curVal <> Get_lineThickness(defGraphic) then
			mo := sprintf("%s\t\t\t\tlineThickness = %s,\n", mo, PrintNumber(curVal));
		end if:

		# Border Pattern
		curVal := Get_borderPattern(self);
		if curVal <> Get_borderPattern(defGraphic) then
			mo := sprintf("%s\t\t\t\tborderPattern = BorderPattern.%s,\n", mo, curVal);
		end if:

		# Radius
		curVal := Get_radius(self);
		if curVal <> Get_radius(defGraphic) then
			mo := sprintf("%s\t\t\t\tradius = %s,\n", mo, PrintNumber(curVal));
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
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
$include <src/GraphicalElements/RectangularBoundary/ClickedBoundary.mm>
$include <src/GraphicalElements/RectangularBoundary/Dragged.mm>

	#------------------------------------------------------------------------------------------------
	export
	Clicked::static := proc(self ::Rectangle, x ::numeric, y ::numeric, $)
	#------------------------------------------------------------------------------------------------
		description "Returns true or false to indicate if the Rectangle has been clicked based on the given [x,y]."
					"Internally updates drag[\"type\"] to indicate what kind of drag action would be performed if [x,y] was the starting click.";

		# reset the drag info
		self:-drag["type"] := false;
		self:-drag["num"] := 0;

		# checks if the point [x,y] lies to the left of each of the line segments as we move counterclockwise around the Rectangle
		# check for type "inside"
		local thisType := true, A, B, C, p1, pt2;

		for i to 4 do
			pt1 := self:-vizPts[i];
			pt2 := self:-vizPts[modp(i, 4) + 1];

			A := -(pt2[2] - pt1[2]);
			B := pt2[1] - pt1[1];
			C := -(A*pt1[1] + B*pt1[2]);

			if A*x + B*y + C <= 0 then
				thisType := false;
				break;
			end if:
		end do:

		if thisType then
			self:-drag["type"] := "inside";
			return true;
		end if:

		return false;
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
		description "Defines what happens when calling Rectangle(pt1, pt2)";

		return Object(Rectangle, _passed);
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	ModuleCopy::static := proc(	  self ::Rectangle
									, proto ::Rectangle
									, pt1 ::[numeric, numeric]
									, pt2 ::[numeric, numeric]
									, $)
	#------------------------------------------------------------------------------------------------
		description "Defines what happens when calling Object(Rectangle, pt1, pt2)";

		self:-extent := [pt1, pt2];
		self:-objType := "Rectangle";
		CalculateVizPts(self);
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
	Set_borderPattern::static := proc(	  self ::Rectangle
										, borderPattern ::{"None", "Raised", "Sunken", "Engraved"}
										, $)
	#------------------------------------------------------------------------------------------------
		description "Updates the borderPattern variable.";

		self:-borderPattern := borderPattern;

		return;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Get_borderPattern::static := proc(self ::Rectangle, $)
	#------------------------------------------------------------------------------------------------
		description "Returns the borderPattern variable.";

		return self:-borderPattern;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Set_extent::static := proc(	  self ::Rectangle
									, pt1 ::[numeric, numeric]
									, pt2 ::[numeric, numeric]
									, $)
	#------------------------------------------------------------------------------------------------
		description "Updates the extent variable.";

		self:-extent := [pt1, pt2];
		CalculateVizPts(self);

		return;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Get_extent::static := proc(self ::Rectangle, $)
	#------------------------------------------------------------------------------------------------
		description "Returns the extent variable.";

		return self:-extent;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Set_radius::static := proc(self ::Rectangle, radius ::nonnegative, $)
	#------------------------------------------------------------------------------------------------
		description "Updates the radius variable.";

		self:-radius := radius;

		return;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Get_radius::static := proc(self ::Rectangle, $)
	#------------------------------------------------------------------------------------------------
		description "Returns the radius variable.";

		return self:-radius;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Get_vizPts::static := proc(self ::Rectangle, $)
	#------------------------------------------------------------------------------------------------
		description "Returns the vizPts variable.";

		return self:-vizPts;
	end proc:

	#------------------------------------------------------------------------------------------------
	Set_origin::static := proc(self ::Rectangle, pt ::[numeric, numeric], $)
	#------------------------------------------------------------------------------------------------
		description "Updates the origin variable.";

		self:-origin := pt;
		CalculateVizPts(self);

		return;
	end proc:

	#------------------------------------------------------------------------------------------------
	Set_rotation::static := proc(self ::Rectangle, rotation ::numeric, $)
	#------------------------------------------------------------------------------------------------
		description "Updates the rotation variable.";

		self:-rotation := rotation;
		CalculateVizPts(self);

		return;
	end proc:


end module:

protect('Rectangle');