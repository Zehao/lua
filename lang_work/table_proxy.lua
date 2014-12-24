#!/bin/env lua


--[[ a proxy for table 

]]

function proxy(t)
	local _t = t
	local tt = {}
	local mt = {
		__index= function(t,i) 
			print( "accessing " .. tostring(i))
			return _t[i]
		end,

		__newindex=function(t,k,v)
			print( "updating " .. tostring(k) .. " of new value " .. tostring(v))
			_t[k] = v
		end,
		
		__pairs=function()
			return function(_,k) return next(_t,k) end
		end
	}
	setmetatable(tt,mt)
	return tt
end


t1 = {'a','b','c',1,2,3,a=123,b=456}

t1_proxy = proxy(t1)

