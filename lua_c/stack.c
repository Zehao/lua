#include <stdio.h>
#include <stdlib.h>
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include "stackdump.h"

int main (void) 
{

	lua_State *L = luaL_newstate();

	lua_pushboolean(L, 1);
	lua_pushnumber(L, 10);
	lua_pushnil(L);
	lua_pushstring(L, "hello");

	stackDump(L);/* true 10 nil 'hello' */

	lua_pushvalue(L, -4); stackDump(L);	/* true 10 nil 'hello' true */


	lua_replace(L, 3); stackDump(L);/* true 10 true 'hello' */



	lua_settop(L, 6); stackDump(L);/* true 10 true 'hello' nil nil */



	lua_remove(L, -3); stackDump(L);/* true 10 true nil nil */


	lua_settop(L, -5); stackDump(L);/* true */

	lua_close(L);
	return 0;
}
