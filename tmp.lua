bit32x={
tobin= function(dec)
	local bits = {}
	for i = 1,32 do
		bits[#bits+1] = dec%2
		dec = math.floor(dec/2)
	end
	return bits
end
,
todec=function( bin )
	--print(bin)
	local res = bin[1]
	for i = 2,32 do
		res = res + bin[i]*(2^(i-1))
	end
	return res
end
,
band = function (left,right)
	local bin_left,bin_right = bit32x.tobin(left), bit32x.tobin(right)
	local res_bin={}
	for i = 1,32 do
		if (bin_left[i] == 1) and (bin_right[i] == 1) then  
			res_bin[i] = 1
		else  
			res_bin[i] = 0
		end
	end
	return bit32x.todec(res_bin)
end
,
bor=function ( left,right )
	local bin_left,bin_right = bit32x.tobin(left), bit32x.tobin(right)
	local res_bin={}
	for i = 1,32 do 
		if bin_left[i] == 0 and bin_right[i] == 0 then
			res_bin[i] = 0
		else 
			res_bin[i] = 1
		end
	end
	return bit32x.todec(res_bin)
end
,
lshift=function ( value, count)
	local bin_val = bit32x.tobin(value)
	for i = 32,count+1,-1 do
		bin_val[i] = bin_val[i-count]
	end
	for i = count,1 do
		bin_val[i] = 0 
	end
	return bit32x.todec(bin_val)
end
,
rshift = function (value,count )
	local bin_val = bit32x.tobin(value)
	for i = 1,32-count do
		bin_val[i] = bin_val[i+count]
	end
	for i = 32-count+1,32 do
		bin_val[i] = 0 
	end
	return bit32x.todec(bin_val)
end

}


-- a = bit32.tobin(34)
-- for _,v in pairs(a) do
-- 	io.write(v)
-- end
-- print()
-- a=bit32.todec(bit32.tobin(34))

-- a = bit32.band(5,7)
-- b= bit32.bor ( 199,322)

-- c = bit32.lshift(182,4)

-- -- d = bit32.rshift(3333,3)

res = 25159
		local b1 = bit32.bor(bit32.band(0x3f,res),0x80)
		local b2 = bit32.bor(bit32.band(0x3f,bit32.rshift(res,6)),0x80)
		local b3 = bit32.bor(bit32.band(0x0f,bit32.rshift(res,12)),0xe0)

print(b1,b2,b3)
		local c1 = bit32x.bor(bit32x.band(0x3f,res),0x80)
		local c2 = bit32x.bor(bit32x.band(0x3f,bit32x.rshift(res,6)),0x80)
		local c3 = bit32x.bor(bit32x.band(0x0f,bit32x.rshift(res,12)),0xe0)
print(c1,c2,c3)
