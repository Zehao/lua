json = require("json")

--a="金泽豪test123"

--print(json.utf8_to_unicode(a))

json_str1 = [[

	{
		"test":1 ,
		"test2":2   ,
		"金泽豪":"呵呵",

		"又一个table" : { "tb1":1, "tb2":2}
	}


]]
	


-- 按不同缩进递归打印table
local function print_table( tb ,level)
	level = level or 0
	for k,v in pairs(tb) do
		io.write(string.rep("\t",level))
		io.write("key:" .. k .. ",")
		if type(v) == "table" then
			io.write("\n")
			print_table(v,level + 1)
		else 
			io.write("value:" .. v .. "\n")
		end
	end
end



tb = json.Marshal(json_str1)

print_table(tb)


--[[



     {  "bindings" :  [ 
				{"ircEvent": "PRIVMSG", "method": "newURI", "regex": "^http://.*"}, 
				{"ircEvent": "PRIVMSG", "method": "deleteURI", "regex": "^delete.*"}, 
				{"ircEvent": "PRIVMSG", "method": "randomURI", "regex": "^random.*"} 
		]	
	}    



]]