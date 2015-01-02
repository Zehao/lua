#!/usr/bin/env lua

function iter(a,i)
	i = i + 1
	if a[i] then
		return i,a[i]
	end
end


function ipairs (a)
	return iter,a,0
end
