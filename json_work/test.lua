
--[[

总结：
	1.以为json字符串必须是{或[开头的，错误多次
	2.写unicode到utf8的互相转换，之后发现其实没必要，bit32库也不能使用
	3.字符串连接".."操作比table.concat慢很多，TLE几次
	4.test case输入的json字符串有 "\xAA" 其实是不合法的输入,反斜杠后面只能是b,f,n,r,t,u,",/,\  (见ECMA-404)
	5.多次打error看case的输入了- -

]]



json = require("json")

json_str1 = [[
	{
		"te\"st":1 ,
		"test2":2   ,
		"金泽豪":"呵呵",
		"又一个\ttable" : { "tb1":-1e-3, "tb2":2E2}   ,  

		"array": [true,true,false]}
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
	{"key1":"[null, 12, null, 13], {\"/\":\"5.6778888\"}"}
]]


json_str8 = [[
	 {"key1":"value1", "key2":"value2:\"!@#$%^&*(\"", "key3":[{"key1":250}, {"key2":25.5}] }

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

json_str11 = [[

{"1":-8,"2":8,"3":8,"4":{},"5":{},"6":[{}],"7":{"1":-100,"2":101,"-1.2":88,"3.4":99},"a":"\"\t\"\"\"\"\"\\\"\"\"\""}

]]

json_str12=[[
{"/\"\xCA\xFE\xBA\xBE\xAB\x98\xFC\xDE\xBC\xDA\xEFJ`1~!@#$%^&*()_+-=[]{}|;:',./<>?":"A key can be any string"}
]]

json_str13 = [[
	"\u6211\u662funicode\u7f16\u7801"
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


tb={[1]=-12.2e10,nil,"\n\\\t\v"}


tb1={}
tb2={1,3,5}
tb3={a=1,b=2,c=3,d=true,e=false,[1]={}}
tb4={[-1.2]=88,[3.4]=99,-100,101}
tb5={-8,a=[[""""""\""""]],8,8,{},tb1,{tb1},tb4}


tab,message = json.Marshal([["\n"]])

-- if type(tab) ~="table" then print(type(tab) , "|" .. tostring(tab) .. "|") 
-- else
--  print_table(tab)
-- end
print( "|" .. tab .. "|")
res_str = json.Unmarshal(tab)
print(res_str)
