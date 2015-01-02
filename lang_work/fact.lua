--defines a factorial function
--[[

---
------
=====
==[=]==]]

str=[===[abcdefghdsjgiowejfiopsnaod;cmweh192rbsdnaNCD	Q[ QWEFHE023-1HD
	FOCNSDONVC WOCHQ2IRF3H2[F
	FOWHFOWEJQIPFCNSACN Z,X VowFO	HEFENAodhioqfhqewo
	fjwogihePJFEIHGHGEPJepfjweion
	]hi302fjsohfsvnsof[fewjfjw]fdsonvdsf[[fdsofnwieoghofw]==]==]===]


function fact(n)
	if n == 0 then
		return 1
	end
	return n * fact(n-1)
end
print ("input a num:")
a = io.read("*n") --read a number
print(fact(a))
print(str)

