#!/bin/env lua

print(debug.getinfo(2, "S").what)


function test()
	print(debug.getinfo(2, "S").what)
end


test()
