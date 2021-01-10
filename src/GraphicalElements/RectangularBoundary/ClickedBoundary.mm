#------------------------------------------------------------------------------------------------
export
ClickedBoundary::static := proc(	  self ::{Ellipse, Rectangle}
									, x ::numeric
									, y ::numeric
									, $)
#------------------------------------------------------------------------------------------------
	description "Returns true or false to indicate if the object has been clicked based on the given [x,y]."
				"Internally updates drag[\"type\"] to indicate what kind of drag action would be performed if [x,y] was the starting click.";

	# reset the drag info
	self:-drag["type"] := false;
	self:-drag["num"] := 0;

	# check if the point [x,y] is inside one of the corner boxes when the object is selected
	# check for type "corner" and sets the number of the corner
	local cornerX, cornerY;

	for i to 4 do
		cornerX, cornerY := op(self:-vizPts[i]);
		if abs(x - cornerX) <= self:-boxSize and abs(y - cornerY) <= self:-boxSize then
			self:-drag["type"] := "corner";
			self:-drag["num"] := i;
			return true;
		end if:
	end do:

	# check if the point [x,y] is inside one of the corner boxes when the object is selected
	# check for type "corner" and sets the number of the corner
	local edgeX, edgeY;

	for i to 4 do
		edgeX, edgeY := op(self:-vizPts[i]/2 + self:-vizPts[modp(i, 4) + 1]/2);
		if abs(x - edgeX) <= self:-boxSize and abs(y - edgeY) <= self:-boxSize then
			self:-drag["type"] := "edge";
			self:-drag["num"] := i;
			return true;
		end if:
	end do:

	return false;
end proc;