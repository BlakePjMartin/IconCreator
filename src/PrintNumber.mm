#---------------------------------------------------------------------------------------------------
local
PrintNumber::static := proc(num, {forceFloat::boolean := false, digits::integer := 1}, $)
#---------------------------------------------------------------------------------------------------
	description "Returns a string of the number with formatting applied.";

	# check if we force a float to be returned
	if forceFloat then
		return sprintf(cat("%.", convert(digits, 'string'), "f"), num);
	end if;

	# if not forcing a float then first see if an integer can printed
	local retStr;
	try
		retStr := sprintf("%d", convert(num, 'integer'));
	catch:
		retStr := sprintf(cat("%.", convert(digits, 'string'), "f"), num);
	end try:

	return retStr;
end proc:
