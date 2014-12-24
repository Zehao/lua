
基于lua 5.2.3 封装实现一个可供其他lua脚本使用的功能模块，具体要求为:
    1、实现一个标准的lua功能模块
    2、封装json格式的数据与lua value间的互相转换功能
    3、遵循json格式定义确保相同的数据源彼此转换后数据仍然一致
    4、只允许使用lua内建基础库，不允许使用任何第三方开发库
    5、有合理的注释和单元测试代码
    6、独立完成此作业，对任何代码抄袭现象零容忍

基本要求：
提交lua代码文件名为json.lua，测试代码和文档（如果有）可以打一个包作为第二个附件提交
json.lua中需要实现以下接口：
	function Marshal(json_str) return lua_val end
	function Unmarshal(lua_val) return "json_str" end

对基本要求的说明：
	1、lua版本要求5.2.3	
	2、lua的空table统一转化成json的空object，而不是空array
	3、test case中的json_str符合ECMA-404 json格式标准
	4、Unmarshal传入的lua_val如果是table的话，不会有循环嵌套
	5、table如果是以array方式使用，转换如下：{[2]=1,[4]=1} == {nil,1,nil,1} <-> [null,1,null,1]
	6、table中有string key时，统一处理成hash table的格式，如：{1,2;a=3} -> {"1":1,"2":2","a":3}
	7、不会出现类似 {1,2;["2"]="same key 2 in json"} 造成转换有歧义的table
	8、Unicode转成lua字符串时，按lua的字符串格式 \xXX\xYY...
	9、能成功转换的话，只需要return单个值

进阶要求：
对test case的错误进行检查，返回相应错误
	function Marshal(json_str) return nil, "error_type" end

基本测试方法：
local json = require 'json'

local test_result1 = json.Marshal('{"a":1}')
local test_result2 = json.Unmarshal{ b="cd" }

-- validate test_result1 & test_result2
