#!/usr/bin/env lua

local M = {}
local  type,pairs,ipairs,table,bit32,string,tonumber,tostring,select,next,error,setmetatable,math=
	   type,pairs,ipairs,table,bit32,string,tonumber,tostring,select,next,error,setmetatable,math


setmetatable(M, {__index = _G})

_ENV = M

local parse_array
local parse_object
local find_right
local find_string

tb_consts = {["true"]=true, ["false"] = false}

local escape_from={

	["b"] = "\b" , ["f"] = "\f", ["n"] = "\n", ["r"] = "\r" , ["t"] = "\t",
	["\\"] = "\\" ,['"'] = '"' , ["/"] = "/"
 }

local escape_to = {
	["\b"] = [[\b]] , ["\f"] = [[\f]],["\n"] = [[\n]] , ["\r"] = [[\r]] , ["\t"] = [[\t]],
	["\\"] = [[\\]] , ['"'] = [[\"]],
}

function unicode_to_u(byte_str)
	local ch1  = tonumber(string.sub(byte_str,1,2),16)
	local ch2  = tonumber(string.sub(byte_str,3,4),16)
	return string.char(ch1) .. string.char(ch2)
end

 --[[
	获取一个字符串，转义成escape_from中的字符
	返回  字符串左边下标，右边下标，字符串
	错误返回-1
 ]]
find_string = function(str,start)

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
			if next_char == "u" then
				res_str[#res_str+1] = unicode_to_u(string.sub(str,i+2,i+5))
				i = i + 6
			else
				local es = escape_from[next_char]
				if es then
					res_str[#res_str+1] = es
				else
					res_str[#res_str+1] = string.sub(str,i,i+1)
				end
				i = i + 2
			end
		else 
			res_str[#res_str+1] = ch
			i = i+1
		end
	end
	return -1
end

--去掉空格
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
		return tb_res,message   --返回nil和错误信息
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

	local encoded_str = {}
	encoded_str[#encoded_str + 1] = "["
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
		encoded_str[#encoded_str + 1] = tmp_str

		encoded_str[#encoded_str + 1] = ","
	end
	encoded_str[#encoded_str] = "]"
	return table.concat(encoded_str)
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

	local encoded_str={}

	encoded_str[#encoded_str + 1] = "{"

	for k,v in pairs(tb) do
		local value_type = type(v)

		-- if value_type == "function"

		if type(k) == "number" then
			encoded_str[#encoded_str + 1]  = [["]] .. tostring(k) .. [["]]
		else
			encoded_str[#encoded_str + 1]  = encode_str(k)
		end

		encoded_str[#encoded_str + 1] = ":"

		if value_type == "number" or value_type == "boolean" then
			encoded_str[#encoded_str + 1] =  tostring(v)
		elseif value_type == "string" then
			encoded_str[#encoded_str + 1] =  encode_str(v)
		elseif value_type == "table" then
			encoded_str[#encoded_str + 1] =  encode_table(v)
		end
		encoded_str[#encoded_str + 1] = ","
	end
	encoded_str[#encoded_str] = "}"

	return table.concat( encoded_str)

end

--对lua字符串编码，将控制字符转义
encode_str = function(str )
	local res_str = {}
	res_str[#res_str+1] = [["]]
	for i = 1,#str do
		local ch = string.sub(str,i,i)

		if escape_to[ch] then
			res_str[#res_str+1]= escape_to[ch]
		else
			res_str[#res_str+1]= ch
		end
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

