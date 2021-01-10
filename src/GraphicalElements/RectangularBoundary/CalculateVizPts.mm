#------------------------------------------------------------------------------------------------
local
CalculateVizPts::static := proc(self ::{Ellipse, Rectangle}, $)
#------------------------------------------------------------------------------------------------
	description "Calculates the actual location of the points of the object corners.";

	# create the points for the corners of the ellipse
	local pts := [NULL
				, [self:-extent[1][1], self:-extent[1][2]]
				, [self:-extent[2][1], self:-extent[1][2]]
				, [self:-extent[2][1], self:-extent[2][2]]
				, [self:-extent[1][1], self:-extent[2][2]]
			];

	# rotate the points
	local rot := self:-rotation*Pi/180.;
	pts := map(x -> [x[1]*cos(rot)-x[2]*sin(rot), x[1]*sin(rot)+x[2]*cos(rot)], pts);

	# place about the origin
	local orig := self:-origin;
	self:-vizPts := map(x -> [x[1]+orig[1], x[2]+orig[2]], pts);

	return;
end proc: