json = require("json")

json_str1 = [[

	{
		"test":1 ,
		"test2":2   ,
		"金泽豪":"呵呵",
		"又一个table" : { "tb1":1, "tb2":2}   ,  

		"array": [true,true,false]
	}


]]

json_str2 = [[

	{     }

]]

json_str3 = [[

	{}

]]

json_str4 = [[

	[    ]

]]

json_str5 = [[

	[]

]]

json_str6 = [[

	[true,  1  ,"abc","嘿嘿", false , null ,true]

]]


-- not valid
json_str7 = [[

	[true,  1  ,"abc","嘿嘿", false , null ,true,"tb":{}]

]]


json_str8 = [[

	 [null,1,null,1]

]]




-- 按不同缩进递归打印table
local function print_table( tb ,level)
	if  tb == nil then return end

	level = level or 0
	for k,v in pairs(tb) do
		io.write(string.rep("\t",level))
		io.write("key:" .. k .. "\t")
		if type(v) == "table" then
			io.write("\n")
			print_table(v,level + 1)
		else 
			io.write("value:" .. tostring(v) .. "\n")
		end
	end
end



tb1={}
tb2={1,3,5,7}
tb3={a=1,b=2,c=3,d=true,e=false,[1]={}}
tb4={[1.2]=88,[3.4]=99,100,101}
tb5={8,8,8,8,{},tb1,{tb1},tb4}

 -- tab,message = json.Marshal(json_str7)

 -- if message then print(message) ;return; end

 -- print_table(tab)

res_str = json.Unmarshal(json.Marshal(json_str8))
print(res_str)
