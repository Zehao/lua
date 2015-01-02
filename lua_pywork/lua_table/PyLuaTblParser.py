# -*- coding: utf-8 -*-
__author__ = 'Zehao'

var_start = '_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'

var_digits = '0123456789'

var_num_exp = "-+.abcdefABCDEFPpxX"


def get_string_with_bracket(raw_string,pos):
    '''
    获取'[['开头的字符串
    :param raw_string:
    :param pos:
    :return:
    '''
    res = raw_string.find("]]",pos)
    if res == -1 :
        raise Exception("invalid string")
    return raw_string[pos:res+2],res+2

def get_string_with_quote(raw_string,pos):
    '''
    获取引号开头的字符串
    :param raw_string:
    :param pos:
    :return:
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
    #结束
    if raw_string[pos] not in " =":
        raise Exception("invalid character"),raw_string[pos]

    return raw_string[_pos:pos],pos

def get_number(raw_string,pos):
    '''
    获取数字表示形式：合法的有 123 , -1.23e-3 , 0x11 , 0xa.bp-1 ,
    :param raw_string:
    :param pos:
    :return:
    '''
    _pos = pos
    valid_str = var_num_exp + var_digits

    while raw_string[pos] in valid_str:
        pos += 1
    val = raw_string[_pos:pos]

    return  tonumber(val),pos

def tonumber(num_str):
    pass


def escapeWhite(s,pos):
    while (pos < len(s)) and s[pos] in " \r\n\t":
        pos += 1
    return pos

class PyLuaTblParser:

    def __init__(self):
        self.raw_str = None


    def load(self,s):
        '''
        :param s:
        :return:
        '''
        assert(len(s) != 0 )
        self.raw_str = str(s)


    def checkAndEscapeComment(self,s,pos):
        '''
        判断是否为注释并过滤，可以为行注释和块注释
        :param s:
        :param pos:
        :return:
        '''
        isCmt = None
        isBlockCmt = None

        if ( s[pos] == '-' ) and (s[pos] == s[pos+1]):
            isCmt = True
        else:
            return pos
        pos += 2
        #s以--结束
        if pos >= len(s):
            return pos

        if s[pos] !='[' :
            isBlockCmt = False
        equals_cnt = 0
        pos += 1
        while pos <len(s):
            if s[pos] == '=':
                equals_cnt += 1
                pos += 1
            elif s[pos]=='[':
                isBlockCmt = True
                break;
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

    def parseTable(self,s,pos):
        cur_tb = dict()
        cur_isList = False
        pos = self.escapeWhite(s,pos)
        if pos >= len(s):
            raise Exception("error format")

        while (pos < len(s) and s[pos]!="}"):
            if s[pos] == '"' or s[pos] == '"':  #quoted string
                key,_pos = get_string_with_quote(s,pos)
            if s[pos] == "["
                if s[pos] == s[pos+1]:
                    key,_pos = get_string_with_quote(s,pos)
                else:
                    
            if s[pos] == "-":







    def get_variable(self,s,pos):
        pos_end = pos + 1
        if s[pos] == '"':  #quoted string


        elif s[pos] == "'":



        elif s[pos]=="[":                   #string or number key

        elif s[pos] in var_start:   # variable

        elif s[pos] == "-": # numbers or comment

        else:
            raise Exception("error format")








    def parseStr(self,s,pos):
        #table的构造只能以'{'开头或注释开头'--'
        if s[pos] !='{' or s[pos] != '-':
            raise Exception("error format")


        if s[pos]=='-':
            pos = self.checkAndEscapeComment(s,pos)




    def dump(self):
        '''

        :return:
        '''
        pass

    def loadLuaTable(self,f):
        '''
        :param f:
        :return:
        '''
        pass

    def dumpLuaTable(self,f):
        '''
        :param f:
        :return:
        '''
        pass

    def loadDict(self,d):
        '''
        :param d:
        :return:
        '''
        pass

    def dumpDict(self):
        '''
        :return:
        '''
        pass


if __name__ == '__main__':
    parser = PyLuaTblParser()

    s ='''--[=[

    ]=]abc
    '''
    res = parser.checkAndEscapeComment(s,0)
    print(str(s[res]))

