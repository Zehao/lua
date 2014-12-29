#!/usr/bin/env lua

tb1={ [1] = 'abc' , 'a' , 'b' }

tb2={ 'a' , [1] = 'abc' , 'b' }

tb3={ 'a' , 'b' , [1] = 'abc' }

tb4={ 'a' , 'b', ["c"] = 1 , [2]='bcd'}