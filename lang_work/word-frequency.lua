#!/bin/env lua


local function allwords()
	local words = function()
		for line in io.lines() do
			for word in string.gmatch(line,"%w+") do
				coroutine.yield(word)
			end
		end
	end

	return coroutine.wrap(words)
end



local counter = {}

for w in allwords() do
	counter[w] = (counter[w] or 0) + 1
end

-- table.sort(counter,function(a,b) return counter[a] > counter[b] end)



local words = {}
for w in pairs(counter) do
	words[#words + 1] = w
end
table.sort(words,function(a,b) return counter[a] > counter[b] end)


for i,v in pairs(words)  do
	print(v, counter[v])
end
