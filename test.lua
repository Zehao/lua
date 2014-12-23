json = require("json")

json_str1 = [[

	{
		"te\"st":1 ,
		"test2":2   ,
		"金泽豪":"呵呵",
		"又一个\ttable" : { "tb1":-1e-3, "tb2":2E2}   ,  

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

	[  true  ]

]]

json_str5 = [[

	[]

]]

json_str6 = [[

	[true,  1  ,"abc","嘿嘿", false , null ,true,
		{
			"test":1 ,
			"test2":2   ,
			"array":[1,2,3,true,null,1],
			"又一个table" : { "tb1":1, "tb2":2}  
		}
	]

]]



json_str7 = [[

	{"key1":"[null, 12, null, 13], {\"/\":\"div\"}"}

]]


json_str8 = [[

	 {"key1":"value1", "key2":"value2:\"orz\"", "key3":[{"key1":250}, {"key2":25.5}] }

]]

json_str9 = [[
[
    {
        "n\t\"ame": "Michael",
        "a\nge": 20,
        "ad\tdress": {
            "Long_name": "4long",
            "short_\"\"name": "4short"
        }
    },
    {
        "name": "Mike",
        "age": 21,
        "address": {
            "Long_name": "1lo,}]ng",
            "short_name": "1short"
        }
    }
]

]]


json_str10 = [[

    {
        "name":    "Mi}chael",
        "age": 20
    }


]]


json_str11=[[
{
	"log":"info", "pc":"0x77c16e5a", "type":"T_MOV_M2R_PROPAG", "addr":"0x031ed430", 
"size":4, "value":1198595772, "thread":250, "ins":"mov ecx, dword ptr [edx]",
 "sym":{"img":"msvcrt.dll", "func":"memchr", "off":"0x5a"},
  "tags":[
  {"byte":0, "tags":["1-4"] },
  {"byte":1, "tags":["1-3"] },
  {"byte":2, "tags":["1-2", "1-3"] },
  {"byte":3, "tags":["1-1"] }
  ]
}

]]


json_str12 = [[

{"1":-8,"2":8,"3":8,"4":{},"5":{},"6":[{}],"7":{"1":-100,"2":101,"-1.2":88,"3.4":99},"a":"\"\t\"\"\"\"\"\\\"\"\"\""}

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
tb2={1,3,5}
tb3={a=1,b=2,c=3,d=true,e=false,[1]={}}
tb4={[-1.2]=88,[3.4]=99,-100,101}
tb5={-8,a=[[""""""\""""]],8,8,{},tb1,{tb1},tb4}




 tab,message = json.Marshal(json_str12)

--print(tab,message)

if type(tab) ~="table" then print(type(tab) , "|" .. tostring(tab) .. "|") 
else
 print_table(tab)
end

res_str = json.Unmarshal(tab)
print(res_str)
