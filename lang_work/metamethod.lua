#!/bin/env lua


local mt={}
local Set={}

function Set.new(s)
	local set = {} 
	setmetatable(set,mt)
	for key in pairs(s) do
		set[key] = true
	end
	return set
end


function Set.union(s1,s2)
	local res = {}
	for key in pairs(s1) do
		res[key]=true
	end
	for key in pairs(s2) do
		res[key]=true
	end
	return res
end


function Set.toString(s)
	local res = {}
	for v in pairs(s) do
		res[#res+1]=v
	end

	return table.concat(res,",")
end

local function union(s1,s2)
	local res = {}
	for key in pairs(s1) do
		res[key]=true
	end
	for key in pairs(s2) do
		res[key]=true
	end
	return res
end

mt.__add = Set.union      --metamethod for table
-- mt.__add = union      --metamethod for table
--print(getmetatable(S1))


S1=Set.new{1,2,3,4,5}
S2=Set.new{3,4,5,6,7}

S3 = S1+S2


print( Set.toString(S3))

--[[
for key in pairs(S3) do
	io.write(key,",")
end
io.write("\n")

--]]
