#!/bin/env lua


--[[

when reach a absent key of a table , __index will be called
--]]

-- version 1
mt1 = { __index=function(t) return t.__default__ end }

function setDefault1(t,d)
	t.__default__ = d
	setmetatable(t,mt1)
end

-- version 2
function setDefault2(t,d)
	local mt2 = {__index=function() return d end}
	setmetatable(t,mt2)
end



