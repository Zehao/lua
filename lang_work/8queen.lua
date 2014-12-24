#!/usr/bin/env lua

local N=8
local totalSolutions=0

local function isplaceok(arr,row,col)
	for i = 1 , row-1 do
		if (arr[i] == col) or (col - arr[i] == row - i) or (arr[i] - col == row - i ) then
			return false
		end
	end
	return true
end


local function print_sol(arr)
	for i = 1,N do
		for j = 1,N do
			io.write(arr[i] == j and 'x' or '.')
		end
		io.write('\n')
	end
	io.write('\n')
end


local function sol(arr,row)
	if row >  N then
		print_sol(arr)	
		totalSolutions  = totalSolutions + 1
		return
	end

	for i = 1,N do
		if isplaceok(arr,row,i) then 
			arr[row] = i
			sol(arr,row +1 )
		end
	end
end


--run
sol({},1)
print("total solutions: " .. totalSolutions)

