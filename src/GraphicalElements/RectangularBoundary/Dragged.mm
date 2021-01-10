#------------------------------------------------------------------------------------------------
export
Dragged::static := proc(	  self::{Ellipse, Rectangle}
							, ptStart::[numeric, numeric]
							, ptEnd::[numeric, numeric]
							, gridSize::numeric
							, $)
#------------------------------------------------------------------------------------------------
	description "Handles what happens when the object is being draggged from [xStart, yStart] to [xEnd, yEnd]."
				"The drag action can either be on the inside, corner, or side of the object."
				"Sets and uses internal variables to help determine what action to perform."
				"This procedure should only be called after a Clicked has been done";

	# check if the dragStart has changed and if so then update variables
	if self:-drag["start"] <> ptStart then
		self:-drag["start"] := ptStart;
		self:-drag["origin"] := Get_origin(self);
		self:-drag["extent"] := Get_extent(self);
	end if:

	if self:-drag["type"] = false then
		return;

	elif self:-drag["type"] = "inside" then
		# based on the drag origin and current position update the origin
		Set_origin(self, round~((self:-drag["origin"] + ptEnd - self:-drag["start"])/~gridSize)*gridSize);

	elif self:-drag["type"] = "corner" then
		# based on the drag origin and current position update the extent and origin
		# get the current ratio to keep this the same
		local
			  ratio := (self:-drag["extent"][2][1] - self:-drag["extent"][1][1])/(self:-drag["extent"][2][2] - self:-drag["extent"][1][2])  # diffX/diffY
			, dragDeltaX := ptEnd[1] - self:-drag["start"][1]
			, dragDeltaY := ptEnd[2] - self:-drag["start"][2]
			, gridChangeInX
			, gridChangeInY
			, cVec  # vector from the bottom left point to the (new) centre of the rectangle
			;

		if self:-drag["num"] = 1 then		# bottom-left corner of unrotated rectangle
			# check where the cursor has moved to, based on the ratio determine if the cursor position determines the new x or y
			if dragDeltaY < dragDeltaX/ratio then # use y to determine the new size
				#gridChangeInY := round(dragDeltaY/gridSize)*gridSize;
				gridChangeInY := dragDeltaY;
				gridChangeInX := sign(dragDeltaY)*ratio*abs(gridChangeInY);

			else
				#gridChangeInX := round(dragDeltaX/gridSize)*gridSize;
				gridChangeInX := dragDeltaX;
				gridChangeInY := sign(dragDeltaX)/ratio*abs(gridChangeInX);

			end if:

			# create the cVec
			cVec := 0.5*self:-drag["extent"][2] - 0.5*self:-drag["extent"][1] + 0.5*[-gridChangeInX, -gridChangeInY];

		elif self:-drag["num"] = 2 then	# bottom-right corner of unrotated rectangle
			# check where the cursor has moved to, based on the ratio determine if the cursor position determines the new x or y
			if dragDeltaY < -dragDeltaX/ratio then # use y to determine the new size
				#gridChangeInY := round(dragDeltaY/gridSize)*gridSize;
				gridChangeInY := dragDeltaY;
				gridChangeInX := -sign(dragDeltaY)*ratio*abs(gridChangeInY);

			else
				#gridChangeInX := round(dragDeltaX/gridSize)*gridSize;
				gridChangeInX := dragDeltaX;
				gridChangeInY := -sign(dragDeltaX)/ratio*abs(gridChangeInX);

			end if:

			# create the cVec
			cVec := 0.5*self:-drag["extent"][2] - 0.5*self:-drag["extent"][1] + 0.5*[gridChangeInX, -gridChangeInY];

		elif self:-drag["num"] = 3 then	# top-right corner of unrotated rectangle
			# check where the cursor has moved to, based on the ratio determine if the cursor position determines the new x or y
			if dragDeltaY > dragDeltaX/ratio then # use y to determine the new size
				#gridChangeInY := round(dragDeltaY/gridSize)*gridSize;
				gridChangeInY := dragDeltaY;
				gridChangeInX := sign(dragDeltaY)*ratio*abs(gridChangeInY);

			else
				#gridChangeInX := round(dragDeltaX/gridSize)*gridSize;
				gridChangeInX := dragDeltaX;
				gridChangeInY := sign(dragDeltaX)/ratio*abs(gridChangeInX);

			end if:

			# create the cVec
			cVec := 0.5*self:-drag["extent"][2] - 0.5*self:-drag["extent"][1] + 0.5*[gridChangeInX, gridChangeInY];

		elif self:-drag["num"] = 4 then	# top-left corner of unrotated rectangle
			# check where the cursor has moved to, based on the ratio determine if the cursor position determines the new x or y
			if dragDeltaY > -dragDeltaX/ratio then # use y to determine the new size
				#gridChangeInY := round(dragDeltaY/gridSize)*gridSize;
				gridChangeInY := dragDeltaY;
				gridChangeInX := -sign(dragDeltaY)*ratio*abs(gridChangeInY);

			else
				#gridChangeInX := round(dragDeltaX/gridSize)*gridSize;
				gridChangeInX := dragDeltaX;
				gridChangeInY := -sign(dragDeltaX)/ratio*abs(gridChangeInX);

			end if:

			# create the cVec
			cVec := 0.5*self:-drag["extent"][2] - 0.5*self:-drag["extent"][1] + 0.5*[-gridChangeInX, gridChangeInY];

		end if:

		# update the origin and extent
		Set_origin(self, self:-drag["origin"] + 0.5*self:-drag["extent"][1] + 0.5*self:-drag["extent"][2] + 0.5*[gridChangeInX, gridChangeInY]);
		Set_extent(self, -cVec, cVec);

	elif self:-drag["type"] = "edge" then
		# based on the drag origin and current position update the extent
		if self:-drag["num"] = 1 then		# bottom edge of unrotated ellipse
			Set_origin(self, round~((self:-drag["origin"] + [0, (ptEnd[2] - self:-drag["start"][2])/2])/~gridSize)*gridSize);
			Set_extent(self
				, round~(([self:-drag["extent"][1][1], self:-drag["extent"][1][2] + (ptEnd[2] - self:-drag["start"][2])/2])/~gridSize)*gridSize
				, round~(([self:-drag["extent"][2][1], self:-drag["extent"][2][2] - (ptEnd[2] - self:-drag["start"][2])/2])/~gridSize)*gridSize
				);

		elif self:-drag["num"] = 2 then	# right edge of unrotated ellipse
			Set_origin(self, round~((self:-drag["origin"] + [(ptEnd[1] - self:-drag["start"][1])/2, 0])/~gridSize)*gridSize);
			Set_extent(self
				, round~(([self:-drag["extent"][1][1] - (ptEnd[1] - self:-drag["start"][1])/2, self:-drag["extent"][1][2]])/~gridSize)*gridSize
				, round~(([self:-drag["extent"][2][1] + (ptEnd[1] - self:-drag["start"][1])/2, self:-drag["extent"][2][2]])/~gridSize)*gridSize
				);

		elif self:-drag["num"] = 3 then	# top edge of unrotated ellipse
			Set_origin(self, round~((self:-drag["origin"] + [0, (ptEnd[2] - self:-drag["start"][2])/2])/~gridSize)*gridSize);
			Set_extent(self
				, round~(([self:-drag["extent"][1][1], self:-drag["extent"][1][2] - (ptEnd[2] - self:-drag["start"][2])/2])/~gridSize)*gridSize
				, round~(([self:-drag["extent"][2][1], self:-drag["extent"][2][2] + (ptEnd[2] - self:-drag["start"][2])/2])/~gridSize)*gridSize
				);

		elif self:-drag["num"] = 4 then	# left edge of unrotated ellipse
			Set_origin(self, round~((self:-drag["origin"] + [(ptEnd[1] - self:-drag["start"][1])/2, 0])/~gridSize)*gridSize);
			Set_extent(self
				, round~(([self:-drag["extent"][1][1] + (ptEnd[1] - self:-drag["start"][1])/2, self:-drag["extent"][1][2]])/~gridSize)*gridSize
				, round~(([self:-drag["extent"][2][1] - (ptEnd[1] - self:-drag["start"][1])/2, self:-drag["extent"][2][2]])/~gridSize)*gridSize
				);

		end if:

	end if:

	# update the visualization
	CalculateVizPts(self);

	return;
end proc;