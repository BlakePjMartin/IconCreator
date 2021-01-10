#------------------------------------------------------------------------------------------------
export
DisplaySelected::static := proc(self ::{Ellipse, Rectangle}, $)
#------------------------------------------------------------------------------------------------
	description "Creates an visualization that should be shown when the object is displayed.";

	# disp will contain all the information for the plotting
	local
		  disp := NULL
		;

	# add the border to show currently selected item
	local tempPts, i;


	# add boxes for the corners
	for i to 4 do
		tempPts := self:-vizPts[i];
		disp := disp, POLYGONS([	  [tempPts[1]-self:-boxSize, tempPts[2]-self:-boxSize]
									, [tempPts[1]+self:-boxSize, tempPts[2]-self:-boxSize]
									, [tempPts[1]+self:-boxSize, tempPts[2]+self:-boxSize]
									, [tempPts[1]-self:-boxSize, tempPts[2]+self:-boxSize]
								], STYLE(LINE), THICKNESS(0));
	end do:

	# add boxes for the midpoints
	for i to 4 do
		tempPts := (self:-vizPts[modp(i, 4) + 1] + self:-vizPts[i])/2;
		disp := disp, POLYGONS([	  [tempPts[1]-self:-boxSize, tempPts[2]-self:-boxSize]
									, [tempPts[1]+self:-boxSize, tempPts[2]-self:-boxSize]
									, [tempPts[1]+self:-boxSize, tempPts[2]+self:-boxSize]
									, [tempPts[1]-self:-boxSize, tempPts[2]+self:-boxSize]
								], STYLE(LINE), THICKNESS(0));
	end do:

	# add a light blue border
	disp := disp, POLYGONS(self:-vizPts, COLOUR(RGB, 0, 0, 0.80392157), STYLE(LINE), THICKNESS(10), TRANSPARENCY(0.75));

	return disp;
end proc;