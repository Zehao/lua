local item_tb1 =
{
{"荣誉勋章11号",  1000},
{"荣誉勋章12号",  900},
{"荣誉勋章13号",  800},
{"荣誉勋章14号",  700},
{"荣誉勋章15号",  600},
}

local max, pr_y = 0, 0

for i = 1, #item_tb1 do
	max = max + item_tb1[i][2]		
end
							

for _, v in pairs(item_tb1) do
	print(v[1],v[2])
end
