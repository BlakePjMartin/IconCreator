unprotect('Polygon');

module Polygon()

	# inherit the FilledShape object (which in turn inherits the GraphicItem object)
	option object(FilledShape);

#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
#
# Object variables
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
	local
		# these variables are specified in the Modelica standard
		  points
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
# Maple visualization of the polygon
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

	#------------------------------------------------------------------------------------------------
	export
	DisplaySelected::static := proc(self ::Polygon, $)
	#------------------------------------------------------------------------------------------------
		description "Creates a visualization that should be shown when the Polygon is displayed.";

		# disp will contain all the information for the plotting
		local
			  i
			, disp := NULL
			, tempPt
			;

		# add box for each of the points
		for i to numelems(self:-points) do
			tempPt := self:-origin + 	[	  cos(Get_rotation(self)*Pi/180.)*self:-points[i][1] - sin(Get_rotation(self)*Pi/180.)*self:-points[i][2]
											, sin(Get_rotation(self)*Pi/180.)*self:-points[i][1] + cos(Get_rotation(self)*Pi/180.)*self:-points[i][2]
										];

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
									  self:-origin +	[	  cos(Get_rotation(self)*Pi/180.)*self:-points[i][1] - sin(Get_rotation(self)*Pi/180.)*self:-points[i][2]
															, sin(Get_rotation(self)*Pi/180.)*self:-points[i][1] + cos(Get_rotation(self)*Pi/180.)*self:-points[i][2]
														]
									, self:-origin +	[	  cos(Get_rotation(self)*Pi/180.)*self:-points[modp(i, numelems(self:-points)) + 1][1] - sin(Get_rotation(self)*Pi/180.)*self:-points[modp(i, numelems(self:-points)) + 1][2]
															, sin(Get_rotation(self)*Pi/180.)*self:-points[modp(i, numelems(self:-points)) + 1][1] + cos(Get_rotation(self)*Pi/180.)*self:-points[modp(i, numelems(self:-points)) + 1][2]
														]
									, 'transparency'= 0.75
									)
								)
							, THICKNESS(10)
							, COLOR(RGB, 0, 0,  0.80392157)
							)
						, i = 1..numelems(self:-points)
						);

		return disp;
	end proc;

	#------------------------------------------------------------------------------------------------
	export
	Display::static := proc(self ::Polygon)
	#------------------------------------------------------------------------------------------------
		description "Generates a Maple plot of the Polygon object.";

		# check if the polygon is visible
		if not(self:-visible) then
			return PLOT();
		end if:

		# create the lines for the outline of the rectangle, if not set to "None"
		local lineDisp;
		if self:-pattern = "None" then
			lineDisp := NULL;
		else
			lineDisp := POLYGONS(
							  [self:-origin$numelems(self:-points)]
									+ map(x -> 	[	  cos(Get_rotation(self)*Pi/180.)*x[1] - sin(Get_rotation(self)*Pi/180.)*x[2]
														, sin(Get_rotation(self)*Pi/180.)*x[1] + cos(Get_rotation(self)*Pi/180.)*x[2]
													], self:-points)
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
							  [self:-origin$numelems(self:-points)]
									+ map(x -> 	[	  cos(Get_rotation(self)*Pi/180.)*x[1] - sin(Get_rotation(self)*Pi/180.)*x[2]
														, sin(Get_rotation(self)*Pi/180.)*x[1] + cos(Get_rotation(self)*Pi/180.)*x[2]
													], self:-points)
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
	GraphicModelica::static := proc(self ::Polygon, $)
	#------------------------------------------------------------------------------------------------
		description "Generates Modelica code for the Polygon.";

		local
			  mo := cat("\t\t\tPolygon(\n")
			, defGraphic := Polygon([[-1, -1], [1, 1]])
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

		# Smooth
		curVal := Get_smooth(self);
		if curVal <> Get_smooth(defGraphic) then
			mo := sprintf("%s\t\t\t\tsmooth = Smooth.%s,\n", mo, curVal);
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
	Clicked::static := proc(self ::Polygon, x ::numeric, y ::numeric, $)
	#------------------------------------------------------------------------------------------------
		description "Returns true or false to indicate if the Polygon has been clicked based on the given [x,y]."
					"Internally updates drag[\"type\"] to indicate what kind of drag action would be performed if [x,y] was the starting click.";

		# reset the drag info
		self:-drag["type"] := false;
		self:-drag["num"] := 0;

		# first do a simple check if the point is in a bounding box
		local
			  xMin := 1000
			, xMax := -1000
			, yMin := 1000
			, yMax := -1000
			, numPts := numelems(self:-points)
			;

		# create a list of the rotated points and also find the bounding box
		local rotPoints, rot := evalf(Get_rotation(self))*Pi/180.0;
		for local i to numPts do
			rotPoints[i] := [	  self:-origin[1] + evalf(cos(rot))*self:-points[i][1] - evalf(sin(rot))*self:-points[i][2]
								, self:-origin[2] + evalf(sin(rot))*self:-points[i][1] + evalf(cos(rot))*self:-points[i][2]
							];

			xMin := min(xMin, rotPoints[i][1]);
			xMax := max(xMax, rotPoints[i][1]);
			yMin := min(yMin, rotPoints[i][2]);
			yMax := max(yMax, rotPoints[i][2]);
		end do:

		if x < xMin or x > xMax or y < yMin or y > yMax then
			return false;
		end if:

		# check if the click was near one of the points of the polygon, if so then return true
		for local i to numPts do
			if sqrt((x - rotPoints[i][1])^2 + (y - rotPoints[i][2])^2) < 1 then
				return true;
			end if:
		end do:

		# create a ray from just outside the bounding box to the point [x,y]
		# iterative test points to ensure that the ray from the starting point to the click point does not intersect points on the polygon
		local t := 0.0, p1, p2, Arc, Brc, Crc;
		local validStart := false;

		while not(validStart) do
			p1 := (xMin - 20) + 15 * evalf(cos(t));
			p2 := 15 * evalf(sin(t));
			Arc := (p2 - y);
			Brc := (x - p1);
			Crc := p2*x - p1*y;

			# set to true, and if one of the conditions fails it will be reset to false
			validStart := true:

			for local i to numPts do
				if abs(Arc*rotPoints[i][1] + Brc*rotPoints[i][2] - Crc) < 5 then
					validStart := false:
					break;  # force to end the for loop
				end if:
			end do:

			# update the value for t
			t += 2.0*Pi/10;
			if t > 2.0*Pi then
				error "This isn't good";
			end if:

		end do:

		# check how many times the ray intersects lines formed between points of the polygon
		local
			  numCrosses := 0
			, Ap, Bp, Cp
			, det
			, xSoln
			, ySoln
			, r1, r2, s1, s2
			, eps := 1e-3
			;

		for local i to numPts do
			r1, r2 := op(rotPoints[i]);
			s1, s2 := op(rotPoints[modp(i, numPts) + 1]);

			Ap := (r2 - s2);
			Bp := (s1 - r1);

			det := Arc*Bp - Ap*Brc;

			if abs(det) > eps then  # solution exists
				Cp := r2*s1 - r1*s2;

				xSoln := (Bp*Crc - Brc*Cp)/det;
				ySoln := (-Ap*Crc + Arc*Cp)/det;

				if 	xSoln >= (min(r1, s1) - eps) and
					xSoln <= (max(r1, s1) + eps) and
					ySoln >= (min(r2, s2) - eps) and
					ySoln <= (max(r2, s2) + eps) and
					xSoln >= (min(p1, x) - eps) and
					xSoln <= (max(p1, x) + eps) and
					ySoln >= (min(p2, y) - eps) and
					ySoln <= (max(p2, y) + eps)
				  then
					numCrosses++;
				end if:
			end if:

		end do:

		# the number of crossings determines if the point is inside or outside
		if modp(numCrosses, 2) = 1 then
			self:-drag["type"] := "inside";
			return true;
		end if:

		return false;
	end proc;

	#------------------------------------------------------------------------------------------------
	export
	ClickedBoundary::static := proc(self ::Polygon, x ::numeric, y ::numeric, $)
	#------------------------------------------------------------------------------------------------
		description "Returns true or false to indicate if the Polygon has been clicked based on the given [x,y]."
					"Internally updates drag[\"type\"] to indicate what kind of drag action would be performed if [x,y] was the starting click.";

		# reset the drag info
		self:-drag["type"] := false;
		self:-drag["num"] := 0;

		# check if the point [x,y] is inside one of the boxes on the points when the polygon is selected
		# check for type "point" and sets the number of the point
		local rot := evalf(Get_rotation(self))*Pi/180.0, tempPt;

		for local i to numelems(self:-points) do

			tempPt := [	  self:-origin[1] + evalf(cos(rot))*self:-points[i][1] - evalf(sin(rot))*self:-points[i][2]
							, self:-origin[2] + evalf(sin(rot))*self:-points[i][1] + evalf(cos(rot))*self:-points[i][2]
						];

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
	Dragged::static := proc(	  self ::Polygon
								, ptStart ::[numeric, numeric]
								, ptEnd ::[numeric, numeric]
								, gridSize ::numeric
								, $)
	#------------------------------------------------------------------------------------------------
		description "Handles what happens when the Polygon is being draggged from [xStart, yStart] to [xEnd, yEnd]."
					"The drag action can either be on the inside or a point of the Polygon."
					"Sets and uses internal variables to help determine what action to perform."
					"This procedure should only be called after a Clicked has been done";

		# check if the dragStart has changed and if so then update variables
		if self:-drag["start"] <> ptStart then
			self:-drag["start"] := ptStart;
			self:-drag["origin"] := Get_origin(self);
			self:-drag["points"] := Get_points(self);
		end if:

		local tempPts, tempDisp, rot := evalf(Get_rotation(self))*Pi/180.0;

		if self:-drag["type"] = false then
			return;

		elif self:-drag["type"] = "inside" then
			# based on the drag origin and current position update the origin
			Set_origin(self, round~((self:-drag["origin"] + ptEnd - self:-drag["start"])/~gridSize)*gridSize);

		elif self:-drag["type"] = "point" then
			# based on the drag origin and current position update the point
			tempPts := self:-drag["points"];
			tempDisp := ptEnd - self:-drag["start"];
			tempPts[self:-drag["num"]] := tempPts[self:-drag["num"]] + [cos(rot)*tempDisp[1] + sin(rot)*tempDisp[2], -sin(rot)*tempDisp[1] + cos(rot)*tempDisp[2]];
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
		description "Defines what happens when calling Polygon([pt1, pt2, ...])";

		return Object(Polygon, _passed);
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	ModuleCopy::static := proc(	  self ::Polygon
									, proto ::Polygon
									, points ::list([numeric, numeric])
									, $)
	#------------------------------------------------------------------------------------------------
		description "Defines what happens when calling Object(Polygon, [pt1, pt2, ...])";

		self:-points := points;
		self:-objType := "Polygon";
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
	Set_points::static := proc(self ::Polygon, points ::list([numeric, numeric]), $)
	#------------------------------------------------------------------------------------------------
		description "Updates the points variable.";

		self:-points := points;

		return;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Get_points::static := proc(self ::Polygon, $)
	#------------------------------------------------------------------------------------------------
		description "Returns the points variable.";

		return self:-points;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Set_smooth::static := proc(self ::Polygon, smooth ::{"None", "Bezier"}, $)
	#------------------------------------------------------------------------------------------------
		description "Updates the smooth variable.";

		self:-smooth := smooth;

		return;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Get_smooth::static := proc(self ::Polygon, $)
	#------------------------------------------------------------------------------------------------
		description "Returns the smooth variable.";

		return self:-smooth;
	end proc:


end module:

protect('Polygon');