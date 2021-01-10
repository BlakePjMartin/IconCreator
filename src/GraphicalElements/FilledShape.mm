unprotect('FilledShape');

module FilledShape()

	# inherit the GraphicItem object
	option object(GraphicItem);

#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
#
# Object variables
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
	local
		  lineColor := [0, 0, 0]
		, fillColor := [255, 255, 255]
		, pattern := "Solid"
		, fillPattern := "None"
		, lineThickness := 0.25
		;

#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
#
# get/set lineColor
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
	#------------------------------------------------------------------------------------------------
	export
	Get_lineColor::static := proc(self ::FilledShape, $)
	#------------------------------------------------------------------------------------------------
		description "Returns the lineColor variable.";

		return self:-lineColor;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Set_lineColor::static := proc(self ::FilledShape, R ::integer, G ::integer, B ::integer, $)
	#------------------------------------------------------------------------------------------------
		description "Updates the lineColor variable.";

		# check that the values are all valid (between 0 and 255, inclusively)
		if select(x -> x < 0 or x > 255, [R, G, B]) <> [] then
			error "The [R, G, B] values must all be between 0 and 255, inclusively";
		end if:

		self:-lineColor := [R, G, B];

		return;
	end proc:

#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
#
# get/set fillColor
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
	#------------------------------------------------------------------------------------------------
	export
	Get_fillColor::static := proc(self ::FilledShape, $)
	#------------------------------------------------------------------------------------------------
		description "Returns the fillColor variable.";

		return self:-fillColor;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Set_fillColor::static := proc(self ::FilledShape, R ::integer, G ::integer, B ::integer, $)
	#------------------------------------------------------------------------------------------------
		description "Updates the fillColor variable.";

		# check that the values are all valid (between 0 and 255, inclusively)
		if select(x -> x < 0 or x > 255, [R, G, B]) <> [] then
			error "The [R, G, B] values must all be between 0 and 255, inclusively";
		end if:

		self:-fillColor := [R, G, B];

		return;
	end proc:

#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
#
# get/set pattern
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
	#------------------------------------------------------------------------------------------------
	export
	Get_pattern::static := proc(self ::FilledShape, $)
	#------------------------------------------------------------------------------------------------
		description "Returns the pattern variable.";

		return self:-pattern;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Set_pattern::static := proc(	  self ::FilledShape
									, pattern ::{"None", "Solid", "Dash", "Dot", "DashDot",
											"DashDotDot"}
									, $)
	#------------------------------------------------------------------------------------------------
		description "Updates the pattern variable.";

		self:-pattern := pattern;

		return;
	end proc:

#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
#
# get/set fillPattern
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
	#------------------------------------------------------------------------------------------------
	export
	Get_fillPattern::static := proc(self ::FilledShape, $)
	#------------------------------------------------------------------------------------------------
		description "Returns the fillPattern variable.";

		return self:-fillPattern;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Set_fillPattern::static := proc(	  self ::FilledShape
										, fillPattern ::{"None", "Solid", "Horizontal", "Vertical",
												"Cross", "Forward", "Backward", "CrossDiag",
												"HorizontalCylinder", "VerticalCylinder", "Sphere"}
										, $)
	#---------------------------------------------------------------------------------------------------
		description "Updates the fillPattern variable.";

		self:-fillPattern := fillPattern;

		return;
	end proc:

#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
#
# get/set lineThickness
#
#<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
	#------------------------------------------------------------------------------------------------
	export
	Get_lineThickness::static := proc(self ::FilledShape, $)
	#------------------------------------------------------------------------------------------------
		description "Returns the lineThickness variable.";

		return self:-lineThickness;
	end proc:

	#------------------------------------------------------------------------------------------------
	export
	Set_lineThickness::static := proc(self ::FilledShape, lineThickness ::positive, $)
	#------------------------------------------------------------------------------------------------
		description "Updates the lineThickness variable.";

		self:-lineThickness := lineThickness;

		return;
	end proc:

end module:

protect('FilledShape');