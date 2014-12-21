#!/usr/bin/env lua

local M = {}

setmetatable(M, {__index = _G})

_ENV = M

--[[
	make string support subscription,ie, ('abc')[2] == 'b'

assert( getmetatable('').__index == string )

]] 
local string_mt = getmetatable('')
local old_index  = string_mt.__index
string_mt.__index = function ( t,... )
	local  k = ...
	if type(...) == 'number' then
		if k > #t then
			error('index out of range.')
		end
		return old_index.sub(t,k,k)
	else
		return old_index[k]
	end
end


-- unicode字符串的字符个数
local function char_len(str)
	return #(string.gsub(str,"[\128-\191]",""))
end 

--[[
	将utf8编码的unicode字符转换为原始2字节的unicode表示

	例如： "金泽豪test123" 转换为 "\x91\xd1\x6c\xfd\x8c\x6atest123"

]]
function utf8_to_unicode( str )

	-- 将多个字节的utf8值组合成2字节
	local  function concat_val( ... )
		local args = table.pack(...)
		local res = 0
		if args.n == 2 then
			args[1] = bit32.band(args[1],0x1f)
			args[2] = bit32.band(args[2],0x3f)
			res = bit32.bor(bit32.lshift(args[1],6),args[2])
		elseif args.n == 3 then
			args[1] = bit32.band(args[1],0x0f)
			args[2] = bit32.band(args[2],0x3f)
			args[3] = bit32.band(args[3],0x3f)
			res = bit32.bor(bit32.lshift(args[1],12),bit32.lshift(args[2],6),args[3])
		end
		return string.format("\\x%x\\x%x",bit32.rshift(bit32.band(res,0xff00),8),bit32.band(res,0x00ff))
	end

	local res_str = {}
	local i = 1
	while i <= #str do
		local cur_byte = string.byte(str,i)

		-- 0000 0000-0000 007F | 0xxxxxxx , 1字节
		if  cur_byte < 0x80 then 
			res_str[#res_str +1] = string.sub(str,i,i)
			i = i + 1

		-- 0000 0080-0000 07FF | 110xxxxx 10xxxxxx , 2字节
		elseif cur_byte < 0xe0 then
			res_str[#res_str + 1] = concat_val(cur_byte,string.byte(str,i+1))
			i = i+2
		-- 0000 0800-0000 FFFF | 1110xxxx 10xxxxxx 10xxxxxx , 3字节
		elseif cur_byte < 0xf0 then
			res_str[#res_str + 1] =concat_val(cur_byte,string.byte(str,i+1),string.byte(str,i+2))
			i = i+3
		end
	end
	return table.concat(res_str)
end
 
local  function find_right(str,char,pos)
	target = "}"
	if char == "[" then 
		target = "]"
	end
	local count = 1
	for i = pos+1,#str do
		if string.sub(str,i,i) == char then count = count +1 end
		if string.sub(str,i,i) == target then count = count-1 end
		if count == 0 then
			return i
		end
	end
	return -1
end

local  function parse_object( raw_json_str,tb_res )
	if #raw_json_str == 0 then return end
	json_str= string.match(raw_json_str, "^%s*{(.*)}%s*$" )
    local pos_left = 1
	while pos_left < #json_str do
		key_left,key_right,key = string.find(json_str,"\"(.-)\"%s*:%s*",pos_left)
		if key_left == nil then return nil,'wrong json string,expected "key": ' end

		key = utf8_to_unicode(key)
		-- print("key:" .. key)

		value_left_pos = key_right+1
		value_left_char = string.sub(json_str,value_left_pos,value_left_pos)


		-- value is true ,false ,null
		if value_left_char == "t" or value_left_char == "f" or value_left_char == "n" then  
			value_left_pos,value_right_pos = string.find(json_str,"%a*",value_left_pos)
			local tmp_tb = {["true"]=true, ["false"] = false, ["null"] = nil}
			local value = string.sub(json_str , value_left_pos,value_right_pos)
			tb_res[key] = tmp_tb[value]

		-- {}
		elseif value_left_char=="{" then 
			value_right_pos = find_right(json_str,value_left_char,value_left_pos)
			tb_res[key] = parse_object(string.sub(json_str,value_left_pos,value_right_pos),{})

		-- []
		elseif value_left_char =="[" then                             ---- []
			value_right_pos = find_right(json_str,value_left_char,value_left_pos)
			tb_res[key] = parse_array(string.sub(json_str,value_left_pos,value_right_pos),{})

		-- string
		elseif value_left_char == '"' then
			value_left_pos,value_right_pos,value = string.find(json_str,"\"(.-)\"",value_left_pos)
			-- print("string value:" , value)
			tb_res[key] = utf8_to_unicode (value)

		-- numbers
		else
			value_left_pos,value_right_pos,value = string.find(json_str,"([^,%s]+)",value_left_pos)
			tb_res[key] = tonumber(value)
		end

		pos_left = value_right_pos + 1
		pos_left = select(2,string.find(json_str,"[%s,]*",pos_left))
		pos_left = pos_left + 1
	end

	return tb_res
end 


local function parse_array( raw_json_str,tb_res )
	if #raw_json_str == 0 return end
	json_str= string.match(raw_json_str, "^%s*%[%s*(.*)%s*%]%s*$" ) 
	local  pos_left = 1
	while pos_left < #json_str do
		cur_char = string.sub(json_str,pos_left,pos_left)

		--json object
		if cur_char=="{" then
			...

		-- json array
		elseif cur_char=="[" then
			...

		-- strings
		elseif cur_char=='"' then
			...

		-- true,false,null
		elseif cur_char=="t" or cur_char=="f" or cur_char=="n" then
			...

		-- numbers
		else
			...
		end



	end
end


function Marshal(json_str)
	if json_str == nil or json_str == "" then
		return nil,"null input"
	end
	--将原始串的回车，换行全部去掉
	json_str = string.gsub(json_str,"[%c]","")

	--判断是{还是[开头
	str_type = string.match(json_str,"^%s*([\\[{])")

	local tb_res ={}
	if str_type == "{" then
		tb_res,message = parse_object(json_str,tb_res)
	elseif str_type == "[" then
		tb_res,message = parse_array(json_str,tb_res)
	else 
		return nil,"{ or [ expected"
	end

	return tb_res,message
end




function Unmarshal(lua_val)
	if type(lua_val) ~= "table" then
		return nil,"table input expected"
	end

	return "json_str" 
end









return M

