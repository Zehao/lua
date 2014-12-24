-- #!/usr/bin/env lua

local M = {}
local  type,pairs,ipairs,table,bit32,string,tonumber,tostring,select,next,error,setmetatable,math=
	   type,pairs,ipairs,table,bit32,string,tonumber,tostring,select,next,error,setmetatable,math


setmetatable(M, {__index = _G})

_ENV = M

local count_tc = 0

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
	local res = bin[1]
	for i = 2,32 do
		res = res + bin[i]*2^(i-1)
	end
	return res
end
,
band = function (left,right)
	local bin_left,bin_right = bit32.tobin(left), bit32.tobin(right)
	local res_bin={}
	for i = 1,32 do
		if bin_left[i] == 1 and bin_right[i] == 1 then  
			res_bin[i] = 1
		else  
			res_bin[i] = 0
		end
	end
	return bit32.todec(res_bin)
end
,
bor=function ( left,right )
	local bin_left,bin_right = bit32.tobin(left), bit32.tobin(right)
	local res_bin={}
	for i = 1,32 do 
		if bin_left[i] == 0 and bin_right[i] == 0 then
			res_bin[i] = 0
		else 
			res_bin[i] = 1
		end
	end
	return bit32.todec(res_bin)
end
,
lshift=function ( value, count)
	return value*(2^count)
end
,
rshift = function (value,count )
	return math.floor(value/(2^count))
end

}

function unicode_to_utf8(byte_str)
	local res=0
	for i =1,4 do
		local ch = tonumber(string.sub(byte_str,i,i),16)
		res = res + bit32.lshift(ch,16-4*i)
	end
	--print(res)
	if res < 0x80 then
		return string.char(bit32.band(0x7f,res))
	elseif res < 0x800 then
		local b1 = bit32.bor(bit32.band(0x3f,res),0x80)
		local b2 = bit32.bor(bit32.band(0x1f,bit32.rshift(res,6)),0xc0)
		return string.char(b2) .. string.char(b1)
	else
		local b1 = bit32.bor(bit32.band(0x3f,res),0x80)
		local b2 = bit32.bor(bit32.band(0x3f,bit32.rshift(res,6)),0x80)
		local b3 = bit32.bor(bit32.band(0x0f,bit32.rshift(res,12)),0xe0)
		--print(b1,b2,b3)
		return string.char(b3) .. string.char(b2) .. string.char(b1)
	end
end


function unicode_to_utf8_2(byte_str)
	local ch1  = tonumber(string.sub(byte_str,1,2),16)
	local ch2  = tonumber(string.sub(byte_str,3,4),16)
	return string.char(ch1) .. string.char(ch2)
end

local parse_array
local parse_object
local find_right
local find_string
local find_string2

tb_consts = {["true"]=true, ["false"] = false}

local escape_from={

	["a"] = "\a", ["b"] = "\b" , ["f"] = "\f", 
	["n"] = "\n", ["r"] = "\r" , ["t"] = "\t",
	["v"] = "\v", ["\\"] = "\\" ,
	 __index=function(t,k) 
	 	if k == "u" then
	 		return "unicode"
	 	end
	 	return k 
	 end

 }

find_string = function(str,start)

	setmetatable(escape_from,escape_from)
	local res_str={}
	local i = start
	local left
	local count = 0
	while i<=#str do
		local ch = string.sub(str,i,i)
		if ch == [["]] then
			if count == 0 then 
				count = count + 1;left=i;i=i+1 
			elseif count == 1 then 
				return left,i ,table.concat(res_str)
			end
		elseif ch == [[\]] then
			local next_char = string.sub(str,i+1,i+1)
			local es = escape_from[next_char]
			if es == "unicode" then
				res_str[#res_str+1] = unicode_to_utf8_2(string.sub(str,i+2,i+5))
				i = i + 6
			else
				res_str[#res_str+1] = es
				i = i + 2
			end
		else 
			res_str[#res_str+1] = ch
			i = i+1
		end
	end
	return -1
end


local escape_white = function(str,pos )
	while true do
		local ch = string.sub(str,pos,pos)
		if ch ~=" " then
			break
		end
		pos = pos + 1
	end
	return pos
end
--[[

	递归解析以'{'开头，'}'结尾的json字符串
]]
parse_object =  function ( raw_json_str,pos )
	if #raw_json_str < pos then return nil end
	
	local tb_res = {}

	while pos <= #raw_json_str do
		-- print("POSITION:" .. pos .." str:" .. string.sub(raw_json_str,pos,pos+3))

		pos = escape_white(raw_json_str,pos)

		--find key
		local key
		local ch = string.sub(raw_json_str,pos,pos)
		local key_left,key_right
		if ch == [["]] then
			key_left,key_right,key = find_string(raw_json_str,pos)
			pos = key_right+1
		elseif ch == [[}]] then
			return tb_res,pos
		else 
			return nil,"bracket '{','}' not match near " .. string.sub(raw_json_str,pos,pos+5)
		end

		-- find ':'
		key_left,key_right = string.find(raw_json_str,"^%s*:%s*",pos)
		if key_left == -1 then return nil," ':' expected " end

		pos = key_right+1
		--print("KEY:" .. key )
		--find value
		local value_left_char , value_left_pos , value_right_pos , value ,res
		value_left_char = string.sub(raw_json_str,pos,pos)

		--true ,false ,null
		if value_left_char == "t" or value_left_char == "f" or value_left_char == "n" then  
			value_left_pos,value_right_pos,value = string.find(raw_json_str,"(%a*)",pos)
			if value ~= "true" and value ~="false" and value ~= "null" then
				return nil,"only true,false or null is valid for key:" .. key
			end
			tb_res[key] = tb_consts[value]
		-- json object
		elseif value_left_char == "{" then
		    res,value_right_pos = parse_object(raw_json_str,pos+1)
			if not res then return res,value_right_pos end
			tb_res[key] = res 
		-- json array
		elseif value_left_char == "[" then
			res,value_right_pos = parse_array(raw_json_str,pos+1)
			if not res then return res,value_right_pos end
			tb_res[key] = res 
		-- string
		elseif value_left_char == [["]] then 
			value_left_pos,value_right_pos,value = find_string(raw_json_str,pos)
			if value_left_pos == -1 then
				return nil,"expected double quoted string for key:" .. key
			end
			tb_res[key] = value
		-- numbers
		else
			value_left_pos,value_right_pos,value = string.find(raw_json_str,"([^%s,%]}]+)",pos)
			--print(value_left_pos,value_right_pos,value)
			if not value_left_pos then
				return nil,"expected numbers for key:" .. key
			end
			value = tonumber(value)
			if not value then
				return nil,"not a valid value for key:" .. key
			end
			--print("tonumber:" .. tonumber(value))
			tb_res[key] = tonumber(value)
		end
		-- expected " %s* , %s*" or " %s*}"
		pos = value_right_pos + 1
		pos = select(2,string.find(raw_json_str,"[%s,]*",pos)) + 1
	end

	return tb_res
end


--[[
	解析json数组格式字符串
	注意有nil的情况，不能使用table.insert。如 [null,1,null,1]插入后变为{[1]=1,[2]=1},应为{[2]=1,[4]=1}

]]
parse_array = function( raw_json_str,pos )

	if #raw_json_str < pos  then return nil end
	local tb_res = {}
	local tb_index = 1
	while pos <= #raw_json_str do

		pos = escape_white(raw_json_str,pos)

		local ch = string.sub(raw_json_str,pos,pos)
		local res,value_left_pos, value_right_pos,value

		if ch == "]" then 
			return tb_res,pos

		elseif ch == "{" then
			 res,value_right_pos = parse_object(raw_json_str,pos + 1)
			 if not res then return nil,value_right_pos end
			 tb_res[tb_index] = res

		elseif ch == "[" then
			res,value_right_pos = parse_array(raw_json_str,pos + 1)
			 if not res then return nil,value_right_pos end
			 tb_res[tb_index] = res

		elseif ch == [["]] then 
			value_left_pos,value_right_pos,value = find_string(raw_json_str,pos)
			if value_left_pos == -1 then
				return nil,"expected double quoted string for key:" .. key
			end
			tb_res[tb_index] = value

		elseif ch=="t" or ch=="f" or ch=="n" then
			value_left_pos,value_right_pos,value = string.find(raw_json_str,"(%a*)",pos)
			if (value ~= "true") and (value ~="false") and (value ~= "null") then
				return nil, value .. " is not a valid value"
			end
			tb_res[tb_index] = tb_consts[value]

		else 
			value_left_pos,value_right_pos,value = string.find(raw_json_str,"([^%s,%]}]+)",pos)
			if not value_left_pos or (not tonumber(value) ) then
				return nil,"not a valid string/number near " .. string.sub(raw_json_str,pos,pos+4)
			end
			tb_res[tb_index]  = tonumber(value)
		end
		tb_index = tb_index + 1
		pos = value_right_pos + 1
		pos = select(2,string.find(raw_json_str,"[%s,]*",pos))+1
	end

	return tb_res
end


function Marshal(json_str)
	if json_str == nil then
		return nil
	end
	if json_str == "" then
		return ""
	end
	--将原始串的控制字符全部去掉
	json_str = string.gsub(json_str,"[%c]","")

	if count_tc == 1 then error(json_str) end
	--判断开头字符
	local pos = escape_white(json_str,1)
	local str_type = string.sub(json_str,pos,pos)

	local tb_res
	local message
	if str_type == "{" then
		tb_res,message = parse_object(json_str,pos+1)

	elseif str_type == "[" then
		tb_res,message = parse_array(json_str,pos+1)

	elseif str_type=="t" or str_type=="f" or str_type=="n" then
		local v_l,v_r,value  = string.find(json_str,"(%a*)",pos)
			if (value ~= "true") and (value ~="false") and (value ~= "null") then
				return nil, value .. " is not a valid value"
			end
		return  tb_consts[value]

	elseif str_type==[["]] then
		local v_l,v_r,value = find_string(json_str,pos)
		if v_l == -1 then
			return nil,"expected double quoted string"
		end
		return value

	else
		local v_l,v_r,value = string.find(json_str,"([^,%s]+)",pos)
		if not v_l or (not tonumber(value) ) then
			return nil,"not a valid string/number"
		end
		return tonumber(value)
	end

	if tb_res then 
		return tb_res
	else
		return tb_res,message
	end
end

local is_array_table
local encode_table
local encode_array
local encode_str

--[[
	判断是否为array形式的table,即key都是number且为整数，且大于0

	否，返回false
	是，返回true和最大的index ( 等同于table.maxn)
]]
is_array_table = function(tb)

	local isfloat = function(value)
		return string.find(tostring(value),"%.") ~= nil 
	end

	local max_index = 0
	for k,_ in pairs(tb) do
		if type(k) ~= "number" or (k <= 0) or isfloat(k) then
			return false
		end
		if max_index < k then max_index = k end
	end
	return true,max_index
end


--[[
	对数组形式的table进行编码
	输入table和table中最大的index
	输出json字符串

]]
encode_array = function(tb,max_index)
	local encoded_str = "["
	for k = 1,max_index do
		local value_type = type(tb[k])
		local tmp_str
		if value_type =="number" or value_type == "boolean" then
			tmp_str = tostring(tb[k]) 
		elseif value_type == "string" then
			tmp_str = encode_str(tb[k])
		elseif value_type == "nil" then
			tmp_str = "null"
		elseif value_type== "table" then
			tmp_str = encode_table(tb[k])
		else  -- must be function ,just ignore it
			;
		end

		encoded_str  = encoded_str .. tmp_str

		if k <max_index then
			encoded_str = encoded_str .. ","
		end
	end
	encoded_str = encoded_str .. "]"
	return encoded_str
end



--[[

	对kv形式的table进行编码
]]

encode_table = function(tb)

	-- table is {}, not nil
	if next(tb) == nil then
		return "{}"
	end

	local res,max_index = is_array_table(tb) 
	if res then
		return encode_array(tb,max_index)
	end

	local encoded_str="{"

	for k,v in pairs(tb) do
		local value_type = type(v)

		-- if value_type == "function"

		local tmp_str
		if type(k) == "number" then
			tmp_str = [["]] .. tostring(k) .. [["]]
		else
			tmp_str = encode_str(k)
		end

		tmp_str = tmp_str .. ":"

		if value_type == "number" or value_type == "boolean" then
			tmp_str = tmp_str .. tostring(v)
		elseif value_type == "string" then
			tmp_str = tmp_str .. encode_str(v)
		elseif value_type == "table" then
			tmp_str = tmp_str .. encode_table(v)
		end
		encoded_str = encoded_str .. tmp_str .. ","
	end

	encoded_str = string.sub(encoded_str,1,#encoded_str - 1) .. "}"

	return encoded_str

end


local escape_to = {
	["\a"] = [[\a]] , ["\b"] = [[\b]] , ["\f"] = [[\f]],
	["\n"] = [[\n]] , ["\r"] = [[\r]] , ["\t"] = [[\t]],
	["\v"] = [[\v]] , ["\\"] = [[\\]] , ['"'] = [[\"]],
	__index = function(t,k)
	  	return k 
	  end 
}


encode_str = function(str )
	 -- local str =utf8_to_unicode(str)
	local res_str = {}
	setmetatable(escape_to,escape_to)
	res_str[#res_str+1] = [["]]
	for i = 1,#str do
		local ch = string.sub(str,i,i)
		res_str[#res_str+1]=escape_to[ch]
	end
	res_str[#res_str+1] = [["]]
	return table.concat(res_str)
end


function Unmarshal(lua_val)

	local value_type = type(lua_val)

	if value_type == "nil" then
		return "null"
	elseif value_type == "number" then

		return tostring(lua_val)
	elseif value_type == "boolean" then
		return tostring(lua_val)
	elseif value_type == "string" then
		
		 return encode_str(lua_val)
		--return lua_val

	elseif  value_type == "table" then
		return encode_table(lua_val)
	end
end

return M

