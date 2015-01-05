local lua_path = lualib:IO_GetLuaPath()
local package_path = package.path
package.path = string.format("%s;%s?.lua;%s?", package_path, lua_path, lua_path)
require("system/�лᷱ�ٶ�")

local all_items = {
        --������              ��ʼ����    �һ���Ҫ���׶�
        {"����",                99,           10 },
        {"����֮��",            99,           20},
        {"�ؼ���ҳ",            99,           20 },
        {"��ʯ��",              99,           10 },
        {"��ħ״",              20,           100},
        {"������",              99,           20 },
        {"������",                10,           200},
        {"����ӡ",              10,           500},
        {"�������",              10,           100},
}

local guid = ""
local level = 35	--�����ȼ�
local goldnum = 1000	--1000���=1�㹱�׵�
local gold_t = {1000000, 2000000, 3000000}		--ˢ��1-2-3�ο����Ҫ�Ľ��

function main(npc, player, number)
	if npc ~= nil then
		guid = npc
	end
	if lualib:GuildGuid(player) == "" then
		return "��Ǹ����û���лᣬ���ܴ��л�ر���"
	end
	if lualib:Level(player) < level then
		return "�ر���ֻΪǿ�߿��ţ�������35��֮���������ҡ�"
	end
	local x, y
	local msg = "#OFFSET<X:10,Y:10>#��Ŀǰ���лṱ�׵�Ϊ��#COLORCOLOR_GREENG#"..lualib:Player_GetGuildCtrb(player).."#COLOREND#����ÿ�����#COLORCOLOR_PURPLE#�����һ�#COLOREND#���µ��ߣ�\n"
	msg = msg.."#OFFSET<X:10>##COLORCOLOR_ORANGE#---------------------------------------------------------------------------#COLOREND#\n\n"
	local form_str = "<form default_parent=NpcTalk,Container>"
	for i = 1, #all_items do
		local nums = all_items[i][2] - lualib:GetDayInt(player, all_items[i][1]..i)
		if i % 3 == 1 and i ~= 1 then
			x = 10
		elseif i % 3 == 2 then
			x = 170
			y = y - 40
		elseif i % 3 == 0 then
			x = 320
			y = y - 40
		else
			x = 10
			y = 60
		end
		form_str = form_str .. "<itemctrl id=���"..i.." x="..x.." y=".. y-10 .." w=35 h=35 init_item="..all_items[i][1].." count="..nums.."/>"

		msg = msg.."#POS<X:"..x + 35 ..",Y:".. y ..">#".."<@item_exchange#"..i.." *01*"..lualib:KeyName2Name(all_items[i][1], 4).."["..all_items[i][3].."��]>"
		y = y + 40
		x = 0
	end
	msg = msg.."\n\n#OFFSET<X:10>##COLORCOLOR_ORANGE#---------------------------------------------------------------------------#COLOREND#\n"
	msg = msg.."#OFFSET<X:22,Y:10>##IMAGE1902700030#<@introduce *01* �л�ر������>             #IMAGE1902700037#<@givegold *01* ���׽��>             #IMAGE1902700042#<@refresh *01* ˢ�¹������>\n"
	msg = form_str .. "<text><![CDATA["..msg.."]]></text></form>"
	lualib:NPCTalkDetail(player, msg, 518, 260)
	return ""
end

function givegold(player)
	lualib:SysMsg_SendInputDlg(player, 10, "��������Ҫ���׵Ľ����", 30, 12, "givegold_ex", "")
	return main(guid, player)
end

function givegold_ex(id, player, silver)
	local silver = tonumber(silver)
	if silver == nil then
		lualib:MsgBox(player, "�����봿���֣�")
		return
	end
	if silver <= 0 then
		lualib:MsgBox(player, "���������0����������")
		return
	end
	if silver % goldnum ~= 0 then
		lualib:MsgBox(player, "������1000�ı�����")
		return
	end

	if not lualib:Player_IsGoldEnough(player, silver, false) then
		lualib:MsgBox(player, "��Ҳ��㣡")
		return
	end

	local ctrb = silver / goldnum

	lualib:Player_SubGold(player, silver,false, "�۽�ң����׽��", guid)

	AddFamilyProsperity(player, ctrb, "���׽��")

	return main(guid, player)
end

function item_exchange(player, id)
	lualib:SysMsg_SendInputDlg(player, 10, "��������Ҫ���������", 30, 12, "item_exchange_ex", id)
	return main(guid, player)
end

function item_exchange_ex(dlgid, player, silver, id)
    local id = tonumber(id)
	local silver = tonumber(silver)
	if silver == nil then
		lualib:MsgBox(player, "�����봿���֣�")
		return
	end
	if silver <= 0 then
		lualib:MsgBox(player, "���������0����������")
		return
	end
	local nums = lualib:GetDayInt(player, all_items[id][1]..id)
	if all_items[id][2] - nums < silver then
		lualib:MsgBox(player, "�һ�ʧ�ܣ���زر�����Ʒ��治�㡣")
		return
	end
	local ctrb = all_items[id][3] * silver
	if lualib:Player_GetGuildCtrb(player) < ctrb then
		lualib:MsgBox(player, "�һ�ʧ�ܣ������лṱ�׶Ȳ��㡾".. ctrb .."����")
		return
	end
	if lualib:GetBagFree(player) < 1 then
		lualib:MsgBox(player, "�һ�ʧ�ܣ������ٱ���һ�������ռ䡣")
		return
	end
	if lualib:Player_ReCalGuildCtrb(player, -ctrb) then
		lualib:GiveItem(player, all_items[id][1], silver, "����Ʒ�����׶ȶһ�", player)
		lualib:SetDayInt(player, all_items[id][1]..id, nums + silver)
		lualib:MsgBox(player, "��ϲ���ɹ��һ���"..all_items[id][1].."��"..silver.."����")
		return main(guid, player)
	else
		lualib:MsgBox(player, "�������׶�ʧ�ܣ�")
		return
	end
end

function introduce(player)
	local msg = [[
�лṱ�׵����ͨ�����#COLORCOLOR_PURPLE#�л����񡢲����л�#COLOREND#��#COLORCOLOR_GREENG#���׽��#COLOREND#���

�ر��󲿷���Ʒ#COLORCOLOR_PURPLE#ÿ������#COLOREND#��Ӧ������ͨ��ˢ�²ر�������ö���Ĺ��������ÿ������ˢ�����Σ�

#COLORCOLOR_GREENG#���׽�ҹ���#COLOREND#1000��� = 1���лṱ�׵�

]]
	lualib:NPCTalkDetail(player, msg, 518, 200)
	return ""
end

function refresh(player)
	local nums = lualib:GetDayInt(player, "refreshnums") + 1
	local gold = gold_t[nums]
	if gold == nil then
		lualib:MsgBox(player, "��Ǹ��ÿ��ֻ����ˢ�¡�"..#gold_t.."���Σ�������������")
	else
		local str = "#COLORCOLOR_RED#              ˢ�¿��ȷ�ϣ�#COLOREND#\n\n"
		str = str.."#COLORCOLOR_YELLOW#��"..nums.."��ˢ�²ر�����Ҫ����"..gold.."��ң��Ƿ�ȷ��ˢ�£�#COLOREND#"
		str = str.."#BUTTON0#ȷ��#BUTTONEND##BUTTON1#ȡ��#BUTTONEND#"
		lualib:SysMsg_SendMsgDlg(player, 1000, str, 100, "refresh_ex", "")
	end
	return main(guid, player)
end

function refresh_ex(dlg_id, player, BUTTON_ID, param)
	if BUTTON_ID == 1 then
		return ""
	end
	local nums = lualib:GetDayInt(player, "refreshnums") + 1
	if gold_t[nums] == nil then
		lualib:MsgBox(player, "#COLORCOLOR_YELLOW#ÿ��ֻ����ˢ�¡�"..#gold_t.."���Σ�������������#COLOREND#")
		return
	end
	if not lualib:SubGold(player, gold_t[nums], "�۽�ң�ˢ�²ر�����", guid) then
		lualib:MsgBox(player, "#COLORCOLOR_YELLOW#���Ľ�Ҳ��㡾"..gold_t[nums].."��������ˢ�£�#COLOREND#")
		return
	end
	for k, v in ipairs(all_items) do
		lualib:SetDayInt(player, v[1]..k, 0)
	end
	lualib:SetDayInt(player, "refreshnums", nums)
	lualib:MsgBox(player, "#COLORCOLOR_YELLOW#ˢ�³ɹ������ֿ��Կ�ʼ������ˣ�#COLOREND#")
	return main(guid, player)
end