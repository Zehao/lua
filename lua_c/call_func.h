#include <stdio.h>
#include <stdlib.h>
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

double f (lua_State *L, double x, double y)
{
	int isnum;
	double z;

	/* push functions and arguments */
	lua_getglobal(L, "f"); /* function to be called */

	lua_pushnumber(L, x); /* push 1st argument */
	
	lua_pushnumber(L, y); /* push 2nd argument */

	/* do the call (2 arguments, 1 result) */
	if (lua_pcall(L, 2, 1, 0) != LUA_OK)
		error(L, "error running function 'f': %s",lua_tostring(L, -1));

	/* retrieve result */
	z = lua_tonumberx(L, -1, &isnum);
	if (!isnum)
		error(L, "function 'f' must return a number");

	lua_pop(L, 1); /* pop returned value */
	return z;
}
