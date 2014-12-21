
--[[
	make string support subscription,ie, ('abc')[2] == 'b'

assert( getmetatable('').__index == string )

]] 
local string_mt = getmetatable('')
local old_index  = string_mt.__index
string_mt.__index = function ( t,... )
	local  k = ...
	if type(...) == 'number' then
		if k > #t then
			error('index out of range.')
		end
		return old_index.sub(t,k,k)
	else
		return old_index[k]
	end
end