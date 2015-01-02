#!/usr/bin/env lua

tb1={   a=123, 'b' }

tb1=--{   a=123, 'b' }
{

}

 tb={-3.1e-0, 0x88, 040, "a",['a']=[[[ab]c]]}

tb2={ 'a' , -1,  _c= 'abc@#$\'%^&*()' , 'b' }

tb3={ 'a' , 'b' , [1] = 'abc' } --[[test ]]

tb4={ 'a' , 'b',---
 ["c"] = 1 , [2]='bcd'}


tb5={ 'a' , 'e' , 'i ' , 'p ' , " 1  " , true , nil , -- comment1
--comment2
false

--[==[
--===
comments[][]===
}
]==]
,1,
}
