unprotect('Ellipse');

module Ellipse()

	# inherit the FilledShape object (which in turn inherits the GraphicItem object)
	option object(FilledShape);

#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
#
# Object variables
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
	local
		# these variables are specified in the Modelica standard
		  extent	# this is the extent value for the Modelica code
		, startAngle := 0.0
		, endAngle := 360.0

		# this is the calculated location of the corners of the ellipse based on the extent, rotation, and origin values
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
# Maple visualization of the ellipse
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
$include <src/GraphicalElements/RectangularBoundary/DisplaySelected.mm>
$include <src/GraphicalElements/RectangularBoundary/CalculateVizPts.mm>

	#------------------------------------------------------------------------------------------------
	export
	Display::static := proc(self ::Ellipse, $)
	#------------------------------------------------------------------------------------------------
		description "Generates a Maple plot of the Ellipse object.";

		# check if the ellipse is visible
		if not(self:-visible) then
			return PLOT();
		end if:

		# create the lines for the outline of the rectangle, if not set to "None"
		local lineDisp;
		if self:-pattern = "None" then
			lineDisp := NULL;
		else
			lineDisp := POLYGONS(
							  op(plottools:-ellipse(self:-origin + 0.5*(self:-extent[1] + self:-extent[2]), (self:-extent[2][1] - self:-extent[1][1])/2., (self:-extent[2][2] - self:-extent[1][2])/2.))
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
							  op(plottools:-ellipse(self:-origin + 0.5*(self:-extent[1] + self:-extent[2]), (self:-extent[2][1] - self:-extent[1][1])/2., (self:-extent[2][2] - self:-extent[1][2])/2.))
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
	GraphicModelica::static := proc(self ::Ellipse, $)
	#------------------------------------------------------------------------------------------------
		description "Generates Modelica code for the Ellipse.";

		local
			  mo := cat("\t\t\tEllipse(\n")
			, defGraphic := Ellipse([-1, -1], [1, 1])
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

		# Start Angle
		curVal := Get_startAngle(self);
		if curVal <> Get_startAngle(defGraphic) then
			mo := sprintf("%s\t\t\t\tstartAngle = %s,\n", mo, PrintNumber(curVal));
		end if:

		# End Angle
		curVal := Get_endAngle(self);
		if curVal <> Get_endAngle(defGraphic) then
			mo := sprintf("%s\t\t\t\tendAngle = %s,\n", mo, PrintNumber(curVal));
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
$include <src/GraphicalElements/RectangularBoundary/ClickedBoundary.mm>
$include <src/GraphicalElements/RectangularBoundary/Dragged.mm>

	#------------------------------------------------------------------------------------------------
	export
	Clicked::static := proc(self ::Ellipse, x ::numeric, y ::numeric, $)
	#------------------------------------------------------------------------------------------------
		description "Returns true or false to indicate if the Ellipse has been clicked based on the given [x,y]."
					"Internally updates drag[\"type\"] to indicate what kind of drag action would be performed if [x,y] was the starting click.";

		# reset the drag info
		self:-drag["type"] := false;
		self:-drag["num"] := 0;

		# checks if the point [x,y] lies inside the Ellipse
		# check for type "inside"
		local
			  Ox, Oy
			, Rx := (self:-extent[2][1] - self:-extent[1][1])/2.
			, Ry := (self:-extent[2][2] - self:-extent[1][2])/2.
			;

		Ox, Oy := op(self:-origin + 0.5*(self:-extent[1] + self:-extent[2]));	# origin

		if (x - Ox)^2/Rx^2 + (y - Oy)^2/Ry^2 <= 1 then  # point is inside the ellipse
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
		description "Defines what happens when calling Ellipse(pt1, pt2)";

		return Object(Ellipse, _passed);
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	ModuleCopy::static := proc(	  self ::Ellipse
									, proto ::Ellipse
									, pt1 ::[numeric, numeric]
									, pt2 ::[numeric, numeric]
									, $)
	#------------------------------------------------------------------------------------------------
		description "Defines what happens when calling Object(Ellipse, pt1, pt2)";

		self:-extent := [pt1, pt2];
		self:-objType := "Ellipse";
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
	Set_extent::static := proc(	  self ::Ellipse
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
	Get_extent::static := proc(self ::Ellipse, $)
	#------------------------------------------------------------------------------------------------
		description "Returns the extent variable.";

		return self:-extent;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Set_startAngle::static := proc(self ::Ellipse, startAngle ::numeric, $)
	#------------------------------------------------------------------------------------------------
		description "Updates the startAngle variable.";

		self:-startAngle := startAngle;

		return;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Get_startAngle::static := proc(self ::Ellipse, $)
	#------------------------------------------------------------------------------------------------
		description "Returns the startAngle variable.";

		return self:-startAngle;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Set_endAngle::static := proc(self ::Ellipse, endAngle ::numeric, $)
	#------------------------------------------------------------------------------------------------
		description "Updates the endAngle variable.";

		self:-endAngle := endAngle;

		return;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Get_endAngle::static := proc(self ::Ellipse, $)
	#------------------------------------------------------------------------------------------------
		description "Returns the endAngle variable.";

		return self:-endAngle;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Get_vizPts::static := proc(self ::Ellipse, $)
	#------------------------------------------------------------------------------------------------
		description "Returns the vizPts variable.";

		return self:-vizPts;
	end proc:

	#------------------------------------------------------------------------------------------------
	Set_origin::static := proc(self ::Ellipse, pt ::[numeric, numeric], $)
	#------------------------------------------------------------------------------------------------
		description "Updates the origin variable.";

		self:-origin := pt;
		CalculateVizPts(self);

		return;
	end proc:


end module:

protect('Ellipse');