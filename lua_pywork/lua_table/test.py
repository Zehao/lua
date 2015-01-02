__author__ = 'Zehao'

'''
lua table:

{  a=1 , b   ="2" , ['truevalue'] = true    , [  "1" ]='"abc"' , }

{ [1]=2,[2]=4,[4]='ab"c'    ,  text=nil , value = 3 , }

{ 'a' , 'e' , 'i ' , 'p ' , " 1  " , true , nil , -- comment1
--comment2
false

--[==[

comments[][]===

]==]

 }

'''

def test(d) :
    d.strip()
    return d


d = dict()
d["1"]=2
d[2]=3
d['abc'] = dict()
d['abc']["test"] = '''
 lua table:'''

a = test(d)
print a,d