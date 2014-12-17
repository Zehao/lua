#!/bin/env lua

Account = {
	balance = 0,
	withdraw = function(self,v) self.balance = self.balance - v end,
	deposit = function(self,v) self.balance = self.balance + v end,
	new  = function(self,t)
		t = t or {}
		setmetatable(t,self)
		-- self.__index = self 
		self.__index = function(t,v) print("__index") return self[v] end 
		--  self.__newindex = function(t,k,v) print("__newindex") t[k]=v end   --stack overflow
		return t
	end
}


a = Account:new{mytype = "1 star"}
b = Account:new{}



