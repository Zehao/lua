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
	将utf8格式的unicode字符转换为原始2字节的unicode表示

	例如： "金泽豪test123" 转换为 "\x91\xd1\x6c\xfd\x8c\x6atest123"

]]
function utf8_to_unicode( str )

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

		-- 0000 0000-0000 007F | 0xxxxxxx , 1bit
		if  cur_byte < 0x80 then 
			res_str[#res_str +1] = string.sub(str,i,i)
			i = i + 1

		-- 0000 0080-0000 07FF | 110xxxxx 10xxxxxx , 2bits
		elseif cur_byte < 0xe0 then
			res_str[#res_str + 1] = concat_val(cur_byte,string.byte(str,i+1))
			i = i+2
		-- 0000 0800-0000 FFFF | 1110xxxx 10xxxxxx 10xxxxxx , 3bits
		elseif cur_byte < 0xf0 then
			res_str[#res_str + 1] =concat_val(cur_byte,string.byte(str,i+1),string.byte(str,i+2))
			i = i+3
		end
	end
	return table.concat(res_str)
end

g_res_tb = {}

function marshal(json_str)
	if(left_pos >= right_pos ) then
		return
	end

	if json_str[left_pos] == "{" then
	end
end


function Marshal(json_str)
	if json_str == nil or json_str == "" then
		return nil,"null input"
	end

	res = marshal(json_str)

	-- 
end




function Unmarshal(lua_val)
	if type(lua_val) ~= "table" then
		return nil,"table input expected"
	end

	return "json_str" 
end









return M

