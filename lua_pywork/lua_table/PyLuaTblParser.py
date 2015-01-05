# -*- coding: utf-8 -*-
__author__ = 'Zehao'

var_start = '_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'

var_digits = '0123456789'

var_num_exp = "-+.abcdefABCDEFxX"

const_type = {"nil":None,"true":True,"false":False}

const_type_res = {None:"nil",True:"true",False:"false"}


def get_string_with_bracket(raw_string,pos):
    '''
    获取'[['开头的字符串
    '''
    res = raw_string.find("]]",pos)
    if res == -1 :
        raise Exception("invalid string")
    return raw_string[pos:res+2],res+2

def get_string_with_quote(raw_string,pos):
    '''
    获取引号开头的字符串
    '''
    _pos = pos
    ch = raw_string[pos]
    pos += 1
    while pos < len(raw_string):
        if raw_string[pos]=="\\":
            pos += 2
        elif raw_string[pos] == ch :
            break
        else:
            pos += 1
    return  raw_string[_pos+1:pos],pos+1

def get_variable(raw_string,pos):
    '''
    获取合法变量： 字符或下划线开头
    :param raw_string:
    :param pos:
    :return:
    '''
    _pos = pos
    if raw_string[pos] not in var_start:
        raise Exception("invalid variable name"),raw_string[pos]
    pos += 1
    valid_chars = var_start + var_digits
    while raw_string[pos] in valid_chars:
        pos += 1

    return raw_string[_pos:pos],pos

def get_number(raw_string,pos):
    '''
    获取数字表示形式：合法的有 123 , -1.23e-3 , 0x11 , 0xa.bp-1 ,
    '''
    _pos = pos
    valid_str = var_num_exp + var_digits

    while raw_string[pos] in valid_str:
        pos += 1
    val = raw_string[_pos:pos]

    try:
        ans =   tonumber(val),pos
    except :
        raise Exception(raw_string[_pos:_pos +20])
    return  ans

def tonumber(num_str):
    return eval(num_str)

def deepcopy(dic):
    if isinstance(dic,list):
        l = []
        for v in dic:
            if isinstance(v,dict) or isinstance(v,list):
                l.append(deepcopy(v))
            else:
                l.append(v)
        return l
    d = {}
    for k,v in dic.items():
        if isinstance(v,dict) or isinstance(v,list):
            d[k] = deepcopy(v)
        else:
            d[k]=v
    return d


def escapeWhite(s,pos):
    while (pos < len(s)) and s[pos] in " \r\n\t":
        pos += 1
    return pos

def is_valid_sep(s,pos):
    pos = escapeWhite(s,pos)
    pos = checkAndEscapeComment(s,pos)
    pos = escapeWhite(s,pos)
    if s[pos] in ",}":
        return True
    return False

def encode_str(s,iskey):
    i=0
    target="'"
    while i < len(s):
        if s[i]=="\\":
            i+=2
            continue
        elif s[i]=="'":
            target='"'
            break
        i+=1
    if iskey:
        return "[" + target + s + target +"]"
    else:
        return  target + s + target

def checkAndEscapeComment(s,pos):
    '''
    判断是否为注释并过滤，可以为行注释和块注释
    '''
    isBlockCmt = False
    if ( s[pos] != '-' ) or (s[pos] != s[pos+1]):
        return pos
    pos += 2
    #s以--结束
    if pos >= len(s):
        return pos

    if s[pos] =='[' :
        equals_cnt = 0
        pos += 1
        while pos <len(s):
            if s[pos] == '=':
                equals_cnt += 1
                pos += 1
            elif s[pos]=='[':
                isBlockCmt = True
                break;
            elif s[pos]=='\n':
                return pos+1
            else:
                isBlockCmt = False
                break

    if isBlockCmt:
        sub = "]" + "=" * equals_cnt  + "]"
        res = s.find(sub,pos)
        if res == -1 :
            raise Exception("invalid block comments")
        return res + len(sub)
    else:
        while  (pos < len(s)) and s[pos] !='\n' :
            pos += 1
        return pos+1


class PyLuaTblParser:

    def __init__(self):

        self.dic =None
        self.str = None



    def load(self,s):
        assert(len(s) != 0 )
        self.dic,p = self.parseTable(s,0)


    def parseTable(self,s,pos):

        cur_isList = True
        keys= list()
        values=list()
        if pos >= len(s):
            raise Exception("error format")
        pos = escapeWhite(s,pos)
        if s[pos] != "{":
            raise Exception("error table")
        pos += 1
        key = None
        pos = escapeWhite(s,pos)
        pos = checkAndEscapeComment(s,pos)
        pos = escapeWhite(s,pos)
        while (pos < len(s) and s[pos]!="}"):
            #get key
            pos = escapeWhite(s,pos)
            pos = checkAndEscapeComment(s,pos)
            pos = escapeWhite(s,pos)
            if s[pos] == "'" or s[pos] == '"':  #quoted string
                key,pos = get_string_with_quote(s,pos)
            elif s[pos] == "[":
                pos = escapeWhite(s,pos+1)
                pos = checkAndEscapeComment(s,pos)
                pos = escapeWhite(s,pos)
                if s[pos] == "'" or s[pos] == '"' :
                    key,pos = get_string_with_quote(s,pos)
                else:
                    key,pos = get_number(s,pos)
                pos = escapeWhite(s,pos)
                pos = checkAndEscapeComment(s,pos)
                pos = escapeWhite(s,pos)
                if s[pos] !="]":
                    raise Exception("error format")
                pos += 1

            elif s[pos] == "{":
                key,pos = self.parseTable(s,pos)
            elif s[pos] in var_start:
                key,pos = get_variable(s,pos)
                if key == "true" or key == "false" or key == "nil":
                    key = const_type[key]
            elif s[pos] in (var_digits+"-"):
                key,pos = get_number(s,pos)
            else:
                raise Exception("error key format")

            keys.append(key)

            #get separater, ",", or "="
            pos = escapeWhite(s,pos)
            pos = checkAndEscapeComment(s,pos)
            pos = escapeWhite(s,pos)
            value = None

            if s[pos]=="=":
                cur_isList = False
                pos = escapeWhite(s,pos+1)
                pos = checkAndEscapeComment(s,pos)
                pos = escapeWhite(s,pos)
                if s[pos]=="'" or s[pos]=='"':
                    value,pos = get_string_with_quote(s,pos)
                elif s[pos]=="[" and s[pos+1]==s[pos]:
                    value,pos = get_string_with_bracket(s,pos)
                elif s[pos:pos+3]=="nil" and is_valid_sep(s,pos+3):
                    value,pos = None,pos+3
                elif s[pos:pos+4]=="true" and is_valid_sep(s,pos+4):
                    value,pos = True,pos+4
                elif s[pos:pos+5]=="false" and is_valid_sep(s,pos+5):
                    value,pos = False,pos+5
                elif s[pos]=="{":
                    value,pos = self.parseTable(s,pos)
                else:
                    value,pos = get_number(s,pos)
                pos = escapeWhite(s,pos)
                pos = checkAndEscapeComment(s,pos)
                pos = escapeWhite(s,pos)
            if s[pos] == ",":
                pos += 1
                pos = escapeWhite(s,pos)
                pos = checkAndEscapeComment(s,pos)
                pos = escapeWhite(s,pos)
            values.append(value)
            #print(key,value)

        if len(keys) == 0:
            return {},pos+1
        if cur_isList:
            return keys,pos+1
        else:
            tmp_tb = {}
            for i in range(len(keys)):
                if values[i] :
                    tmp_tb[keys[i]] = values[i]
            return tmp_tb,pos+1

    def encodeTable(self,tb):
        tmp_str="{"
        if isinstance(tb,dict):
            for k,v in tb.items():
                if isinstance(k,str):
                    tmp_str += encode_str(k,True)
                else:
                    tmp_str += "[" + str(k) +"]"
                tmp_str +="="
                if isinstance(v,dict) or isinstance(v,list):
                    tmp_str += self.encodeTable(v)
                elif isinstance(v,bool) or v==None:
                        tmp_str += const_type_res[v]
                elif isinstance(v,str):
                    tmp_str += encode_str(v,False)
                else:
                    tmp_str += str(v)
                tmp_str +=","
        elif isinstance(tb,list):
            for v in tb:
                if isinstance(v,dict) or isinstance(v,list):
                    tmp_str += self.encodeTable(v)
                elif isinstance(v,bool) or  v==None:
                    tmp_str += const_type_res[v]
                elif isinstance(v,str):
                    tmp_str += encode_str(v,False)
                else:
                    tmp_str += str(v)
                tmp_str +=","

        tmp_str +="}"
        return tmp_str


    def dump(self):
        return self.str


    def loadLuaTable(self,f):
        _file = open(f,"r")
        input_str = _file.read()
        _file.close()
        self.dic,p = self.parseTable(input_str,0)

####################

    def dumpLuaTable(self,f):
        _file = open(f,"w")
        _file.write(self.encodeTable(self.output_dict))
        _file.close()
        pass

    def loadDict(self,d):
        assert (isinstance(d,dict))
        self.input_dict = self.loadDict2(d)
        self.output_str = self.encodeTable(self.input_dict)


    def loadDict2(self,d):
        tmp_dic={}
        for k,v in d.items():
            if k== None or isinstance(k,bool) or isinstance(v,list) or isinstance(k,dict):
                continue
            if isinstance(v,dict):
                tmp_dic[k]=self.loadDict2(v)
            elif isinstance(v,list):
                tmp_dic[k]=v[:]
            else:
                tmp_dic[k]=v
        return tmp_dic


    def dumpDict(self):



if __name__ == '__main__':
    f = open("read.txt")
    print(f.read())



