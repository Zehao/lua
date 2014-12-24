-- #!/usr/bin/env lua

local M = {}
local  type,pairs,ipairs,table,bit32,string,tonumber,tostring,select,next,error,setmetatable,math=
	   type,pairs,ipairs,table,bit32,string,tonumber,tostring,select,next,error,setmetatable,math


setmetatable(M, {__index = _G})

_ENV = M

bit32={
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
--[[
	将utf8编码的unicode字符转换为原始2字节的unicode表示

	例如： "金泽豪test123" 转换为 "\x91\xD1\x6C\xFD\x8C\x6Atest123"

]]
function utf8_to_unicode( str )

	--error(tostring(bit32.band))

	-- 将多个字节的utf8值组合成2字节
	local  concat_val = function ( ... )
		-- local  bit32 = bit32
		local args = table.pack(...)
		local res = 0
		if args.n == 2 then
			args[1] = bit32.band(args[1],0x1f)
			args[2] = bit32.band(args[2],0x3f)
			res = bit32.bor(bit32.lshift(args[1],6),args[2])
		elseif args.n == 3 then
			-- error(tostring(bit32.band) .." str:" ..str .. "." .. args[1] .. "," .. args[2] .."," ..args[3] .. "type:" .. type(args[1]) .. "," .. type(args[2]) .. "," .. type(args[3])) 
			args[1] = bit32.band(args[1],0x0f)
			args[2] = bit32.band(args[2],0x3f)
			args[3] = bit32.band(args[3],0x3f)
			res = bit32.bor(bit32.lshift(args[1],12),bit32.lshift(args[2],6),args[3])
		end
		return string.format("\\u%04x",res)
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

--[[
\u6211\u662f
]]
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

local parse_array
local parse_object
local find_right
local find_string

tb_consts = {["true"]=true, ["false"] = false, ["null"] = nil}

--[[
	找到对应的右括号，包括嵌套的情况
	输入当前字符，起始位置
	返回下标或-1
]]
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
				-- error("|" .. str .. "|")
				-- local ch1 = [[\x]] .. string.upper(string.sub(str,i+2,i+3))

				-- local ch2 = [[\x]] .. string.upper(string.sub(str,i+4,i+5))
				-- res_str[#res_str+1]   = ch1 .. ch2
				res_str[#res_str+1] = unicode_to_utf8(string.sub(str,i+2,i+5))
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
--[[

	递归解析以'{'开头，'}'结尾的json字符串
]]
parse_object =  function ( raw_json_str,tb_res )
	--print("parse object,json_str:" .. raw_json_str)
	if #raw_json_str == 0 then return tb_res end

	-- 提取{}内部分
	local json_str= string.match(raw_json_str, "^%s*{%s*(.*)%s*}%s*$" )
	if not json_str then 
		return nil , "bracket '{','}' not match "
	end

	if  json_str=="" then return tb_res end

    local pos_left = 1
    local key
    local value

    -- 查找每一项k,v并判断类型
	while pos_left <= #json_str do
		--print("POSITION:" .. pos_left .. " OF " .. #json_str)
		--local key_left,key_right,key = string.find(json_str,"\"(.-)\"%s*:%s*",pos_left)
		local key_left,key_right,key = find_string(json_str,pos_left)
		if key_left == -1 then return nil,'wrong json string,expected "key": ' end
		--print("KEY:" .. key)
		--unicode-- 
		-- key = utf8_to_unicode(key)

		
		key_left,key_right = string.find(json_str,"^%s*:%s*",key_right+1)

		if not key_left then
			return nil," ':' expected "
		end

		local value_left_pos  = key_right + 1
		local value_left_char = string.sub(json_str,value_left_pos,value_left_pos)
		local value_right_pos
		--print("VALUE_LEFT_CHAR:" .. value_left_char)
		--true,false,null
		if value_left_char == "t" or value_left_char == "f" or value_left_char == "n" then  
			value_left_pos,value_right_pos,value = string.find(json_str,"(%a*)",value_left_pos)
			if value ~= "true" and value ~="false" and value ~= "null" then
				return nil,"only true,false or null is valid for key:" .. key
			end
			tb_res[key] = tb_consts[value]

		-- {}
		elseif value_left_char=="{" then 
			value_right_pos = find_right(json_str,value_left_char,value_left_pos)
			if value_right_pos == -1 then
				return nil,"bracket '{', '}' not match"
			end
			local value,message = parse_object(string.sub(json_str,value_left_pos,value_right_pos),{})  --recursively
			if message then return nil,message end
			tb_res[key] = value

		-- []
		elseif value_left_char =="[" then
			value_right_pos = find_right(json_str,value_left_char,value_left_pos)
			if value_right_pos == -1 then
				return nil,"bracket '[', ']' not match"
			end
			local value ,message = parse_array(string.sub(json_str,value_left_pos,value_right_pos),{})  --for array
			if message then return nil,message end
			tb_res[key] = value

		-- string
		elseif value_left_char == '"' then
			value_left_pos,value_right_pos,value = find_string(json_str,value_left_pos)
			if value_left_pos == -1 then
				return nil,"expected double quoted string for key:" .. key
			end
			--unicode--  
			-- value = utf8_to_unicode (value)

			tb_res[key] = value

		-- numbers
		else
			value_left_pos,value_right_pos,value = string.find(json_str,"([^,%s]+)",value_left_pos)
			if not value_left_pos then
				return nil,"expected numbers for key:" .. key
			end
			value = tonumber(value)
			if not value then
				return nil,"not a valid value for key:" .. key
			end
			tb_res[key] = tonumber(value)
		end

		pos_left = value_right_pos + 1
		if pos_left > #json_str then break end
		--print("pos_left:" .. pos_left .. "now:" .. string.sub(json_str,pos_left))
		pos_left = select(2,string.find(json_str,"[%s,]*",pos_left))
		pos_left = pos_left + 1
	end

	return tb_res
end 


--[[
	解析json数组格式字符串

	注意有nil的情况，不能使用table.insert。如 [null,1,null,1]插入后变为{[1]=1,[2]=1},应为{[2]=1,[4]=1}

]]
parse_array = function( raw_json_str,tb_res )
	--print("parse array,json_str:" .. raw_json_str)
	if #raw_json_str == 0 then return tb_res end
	local json_str= string.match(raw_json_str, "^%s*%[%s*(.*)%s*%]%s*$" ) 
	if not json_str then 
		return nil,"bracket'[',']' not match"
	end

	if json_str == "" then 
		return tb_res 
	end

	local  value_left = 1
	local value_right
	local pos_tmp
	local value
	local tb_index = 1
	while value_left <= #json_str do
		cur_char = string.sub(json_str,value_left,value_left)

		--json object
		if cur_char=="{" then
			value_right = find_right(json_str,cur_char,value_left)
			if value_right == -1 then
				return nil,"bracket '{', '}' not match"
			end
			tb_res[tb_index] = parse_object(string.sub(json_str,value_left,value_right) , {} ) -- for object

		-- json array
		elseif cur_char=="[" then
			value_right = find_right(json_str,cur_char,value_left)
			if value_right == -1 then
				return nil,"bracket '[', ']' not match"
			end
			--recursively
			tb_res[tb_index] = parse_array(string.sub(json_str,value_left,value_right), {} ) 

		-- strings
		elseif cur_char=='"' then
			value_left,value_right,value = find_string(json_str,value_left)
			if -1 == value_left then
				return nil,"expected double quoted string near " .. string.sub(json_str,value_left,value_left+3)
			end
			--unicode--   
			-- value = utf8_to_unicode(value)
			tb_res[tb_index] = value

		-- true,false,null
		elseif cur_char=="t" or cur_char=="f" or cur_char=="n" then
			value_left,value_right,value = string.find(json_str,"(%a*)",value_left)
			if (value ~= "true") and (value ~="false") and (value ~= "null") then
				return nil, value .. " is not a valid value"
			end
			tb_res[tb_index] = tb_consts[value]
		-- numbers
		else
			value_left,value_right,value = string.find(json_str,"([^,%s]+)",value_left)
			if not value_left then
				return nil, "expected numbers near " .. string.sub(json_str,value_left,value_left+3)
			end
			value = tonumber(value)
			if not value then
				return nil,"not a valid string/number near " .. string.sub(json_str,value_left,value_left+2)
			end
			tb_res[tb_index] =  value
		end

		--print("value_right:" .. json_str:sub(value_right))
		value_right = value_right + 1
		if value_right > #json_str then break end
		pos_tmp,value_right = string.find(json_str,"[%s,]*",value_right)

		value_left = value_right + 1
		tb_index = tb_index + 1
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

	--判断是{还是[开头
	str_type = string.match(json_str,"^%s*([\\[{])")

	local tb_res ={}
	local message
	if str_type == "{" then
		tb_res,message = parse_object(json_str,tb_res)

	elseif str_type == "[" then
		tb_res,message = parse_array(json_str,tb_res)


	-- true,false,null,number,string
	else 
		local val = string.match(json_str,"^%s*(.-)%s*$")  --去掉首尾空格
		if val == "true" then
			return true
		elseif val == "false" then 
			return false
		elseif val == "null" then
			return nil
		elseif tonumber(val) then
			return tonumber(val)
		elseif string.sub(val,1,1) == [["]] then
		    local tmp_l,tmp_r,value = find_string(val,1)
		    --value = val
		    return value
		else
			return nil,"error json format"
		end
	end

	return tb_res,message
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
	-- error(tostring(bit32.band))
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

