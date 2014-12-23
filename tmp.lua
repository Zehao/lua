find_string = function(str,start)
	print(str,start)
	local i = start
	local left
	local count = 0
	while i<#str do
		local ch = string.sub(str,i,i)
		if ch == [["]] then
			if count == 0 then 
				count = count + 1
				left=i
				i=i+1 
			elseif count == 1 then 
				return left,i
			end
		elseif ch == [[\]] then
			i = i + 2
		else 
			i = i+1
		end
	end
	return -1
end
str = [[{        "name": "Mi}chael",        "age": 20    }]]

find_right =function (str,char,pos)
	local target = "}"
	if char == "[" then 
		target = "]"
	end
	local count = 1
	local i = pos+1

	while i <= #str do
		local ch = string.sub(str,i,i)
		if ch == [["]] then
			local left,right = find_string(str,i)
			if left == -1 then return -1 end
			i = right
		elseif ch == char then
			count = count + 1
		elseif ch == target then
			count = count - 1
			if count == 0 then return i end
		end
		i = i + 1
	end

	return -1
end


print( find_right(str,"{",1) )