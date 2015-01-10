# -*- coding: utf-8 -*-
__author__ = 'Zehao'

#变量的合法开头
var_start = '_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'

var_digits = '0123456789'
#lua中number类型可出现的字符
var_num_exp = "-+.abcdefABCDEFxX"

escape_from = { 'a':'\a' , 'b': '\b',  'f': '\f',
                'n': '\n','r': '\r','t': '\t',
                'v': '\v','"': '\"',"'": '\'','\\': '\\'}

escape_to = { '\a': r'\a' , '\b': r'\b',  '\f': r'\f',
              '\n': r'\n' , '\r': r'\r','\t': r'\t',
              '\v': r'\v' , '"': r'\"', "'": r'\'','\\': r'\\'}

const_type = {"nil":None,"true":True,"false":False}
const_type_res = {None:"nil",True:"true",False:"false"}


def get_string_with_bracket(raw_string,pos):
    '''
    获取'[['开头的字符串,此类字符串不需要转义
    '''
    res = raw_string.find("]]",pos+2)
    if res == -1 :
        raise Exception("invalid string")
    return raw_string[pos+2:res],res+2

def get_string_with_quote(raw_string,pos):
    '''
    获取引号开头的字符串,需要转义
    '''
    _pos = pos
    ch = raw_string[pos]
    pos += 1
    tmp_str = ""
    while pos < len(raw_string):
        if raw_string[pos]=="\\":
            tmp_str += escape_from.get(raw_string[pos+1],raw_string[pos+1])
            pos += 2
        elif raw_string[pos] == ch :
            break
        else:
            tmp_str += raw_string[pos]
            pos += 1
    return  tmp_str,pos+1

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
    获取数字表示形式：合法的有 123 , -1.23e-3 , 0x11 ,0XABCD
    '''
    _pos = pos
    valid_str = var_num_exp + var_digits

    while raw_string[pos] in valid_str:
        if raw_string[pos] == "-" and raw_string[pos+1] == raw_string[pos]:
            break
        pos += 1
    val = raw_string[_pos:pos]

    try:
        ans =eval(val),pos
    except :
        raise Exception(raw_string[_pos:_pos +20])
    return  ans

def deepcopy(dic):
    '''
    深度拷贝,如果是dict，忽略掉key不是字符串和数字的kv对
    '''
    if isinstance(dic,list):
        l = []
        for v in dic:
            if isinstance(v,(dict,list)):
                l.append(deepcopy(v))
            else:
                l.append(v)
        return l
    d = {}

    for k,v in dic.items():
        if k== None or isinstance(k,(bool,list,dict)):
            continue
        if isinstance(v,(dict,list)):
            d[k] = deepcopy(v)
        else:
            d[k]=v
    return d

def encode_str(s,iskey):
    '''
    将python字符串编码输出，需要反转义
    '''
    i=0
    target=""
    while i < len(s):
        target += escape_to.get(s[i],s[i])
        i+=1
    if iskey:
        target = "['" + target +"']"
    else:
        target = "'" + target +"'"
    return target

def escapeWhiteAndComment(s,pos):
    '''
    去掉空白字符和注释
    注释可以为行注释和块注释 例如 -- , --[[ xxx ]] , --[===[ xxx ]===]
    '''
    while (pos < len(s)) and s[pos] in " \r\n\t":
        pos += 1
    if ( s[pos] != '-' ) or (s[pos] != s[pos+1]):
        return pos
    isBlockCmt = False
    pos += 2
    equals_cnt = 0
    if s[pos] =='[' :
        pos += 1
        while pos <len(s):
            if s[pos] == '=':
                equals_cnt += 1
                pos += 1
            elif s[pos]=='[':
                isBlockCmt = True
                break
            else:
                isBlockCmt = False
                break
    if isBlockCmt:
        sub = "]" + "=" * equals_cnt  + "]"
    else:
        sub = "\n"
    res = s.find(sub,pos)
    if res == -1 :
        raise Exception("invalid block comments")
    pos =  res + len(sub)
    while (pos < len(s)) and s[pos] in " \r\n\t":
        pos += 1
    return pos


class PyLuaTblParser:

    def __init__(self):

        self._dic =None

    def load(self,s):
        assert(len(s) != 0 )
        self._dic,p = self.parseTable(s,0)


    def parseTable(self,s,pos):
        cur_isList = True
        cur_dict = {}
        if pos >= len(s):
            raise Exception("error format")
        pos = escapeWhiteAndComment(s,pos)
        if s[pos] != "{":
            raise Exception("error table")
        cur_key = 1
        pos = escapeWhiteAndComment(s,pos+1)
        while (pos < len(s) and s[pos]!="}"):
            #get key
            key = None
            if s[pos] == "'" or s[pos] == '"':  #quoted string
                key,pos = get_string_with_quote(s,pos)
            elif s[pos] == "[":
                pos = escapeWhiteAndComment(s,pos+1)
                if s[pos] == "'" or s[pos] == '"' :
                    key,pos = get_string_with_quote(s,pos)
                else:
                    key,pos = get_number(s,pos)
                pos = escapeWhiteAndComment(s,pos)
                if s[pos] !="]":
                    raise Exception("error format" + s[pos:pos+10])
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

            #get separater, ",", or "="
            pos = escapeWhiteAndComment(s,pos)
            value = None
            if s[pos]=="=":
                cur_isList = False
                pos = escapeWhiteAndComment(s,pos+1)
                if s[pos]=="'" or s[pos]=='"':
                    value,pos = get_string_with_quote(s,pos)
                elif s[pos]=="[" and s[pos+1]==s[pos]:
                    value,pos = get_string_with_bracket(s,pos)
                    #print("value:%s") % value
                elif s[pos] in var_start:
                    value,pos = get_variable(s,pos)
                    value = const_type[value]
                elif s[pos]=="{":
                    value,pos = self.parseTable(s,pos)
                else:
                    value,pos = get_number(s,pos)
                if value != None:
                    cur_dict[key] = value
                pos = escapeWhiteAndComment(s,pos)
            else:
                cur_dict[cur_key] = key
                cur_key += 1
            if s[pos] == ",":
                pos = escapeWhiteAndComment(s,pos+1)
        if len(cur_dict) == 0:
            return cur_dict,pos+1
        if cur_isList:
            return cur_dict.values(),pos+1
        else:
            return cur_dict,pos+1

    def encodeTable(self,tb):
        tmp_str="{"
        if isinstance(tb,dict):
            for k,v in tb.items():
                if isinstance(k,str):
                    tmp_str += encode_str(k,True)
                else:
                    tmp_str += "[" + str(k) +"]"
                tmp_str +="="
                if isinstance(v,(list,dict)):
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
                if isinstance(v,(list,dict)):
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
        return self.encodeTable(self._dic)

    def loadLuaTable(self,f):
        _file = open(f,"r")
        input_str = _file.read()
        _file.close()
        self._dic,p = self.parseTable(input_str,0)


    def dumpLuaTable(self,f):
        _file = open(f,"w")
        _file.write(self.encodeTable(self._dic))
        _file.close()

    def loadDict(self,d):
        assert (isinstance(d,(dict,list)) )
        self._dic = deepcopy(d)

    def dumpDict(self):
        return deepcopy(self._dic)

    def __getitem__(self, item):
        return self._dic[item]

    def __setitem__(self, key, value):
        self._dic.update({key:value})

    def update(self, E=None, **F):
        '''
            完全等同于dict的update. Update D from dict/iterable E and F
        '''
        self._dic.update(E,F)


if __name__ == '__main__':
    a1 = PyLuaTblParser();
    a1.loadLuaTable("read2.txt")
    a1.dumpLuaTable("read_out.txt")

