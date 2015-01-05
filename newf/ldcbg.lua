local lua_path = lualib:IO_GetLuaPath()
local package_path = package.path
package.path = string.format("%s;%s?.lua;%s?", package_path, lua_path, lua_path)
require("system/行会繁荣度")

local all_items = {
        --索引名              初始数量    兑换需要贡献度
        {"神羽",                99,           10 },
        {"神兽之魂",            99,           20},
        {"秘籍残页",            99,           20 },
        {"宝石矿",              99,           10 },
        {"伏魔状",              20,           100},
        {"任务令",              99,           20 },
        {"修炼丹",                10,           200},
        {"开光印",              10,           500},
        {"天机密引",              10,           100},
}

local guid = ""
local level = 35	--开启等级
local goldnum = 1000	--1000金币=1点贡献点
local gold_t = {1000000, 2000000, 3000000}		--刷新1-2-3次库存需要的金币

function main(npc, player, number)
	if npc ~= nil then
		guid = npc
	end
	if lualib:GuildGuid(player) == "" then
		return "抱歉，您没有行会，不能打开行会藏宝阁！"
	end
	if lualib:Level(player) < level then
		return "藏宝阁只为强者开放，请升到35级之后再来找我。"
	end
	local x, y
	local msg = "#OFFSET<X:10,Y:10>#你目前的行会贡献点为【#COLORCOLOR_GREENG#"..lualib:Player_GetGuildCtrb(player).."#COLOREND#】，每天可以#COLORCOLOR_PURPLE#限量兑换#COLOREND#以下道具：\n"
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
		form_str = form_str .. "<itemctrl id=翅膀"..i.." x="..x.." y=".. y-10 .." w=35 h=35 init_item="..all_items[i][1].." count="..nums.."/>"

		msg = msg.."#POS<X:"..x + 35 ..",Y:".. y ..">#".."<@item_exchange#"..i.." *01*"..lualib:KeyName2Name(all_items[i][1], 4).."["..all_items[i][3].."点]>"
		y = y + 40
		x = 0
	end
	msg = msg.."\n\n#OFFSET<X:10>##COLORCOLOR_ORANGE#---------------------------------------------------------------------------#COLOREND#\n"
	msg = msg.."#OFFSET<X:22,Y:10>##IMAGE1902700030#<@introduce *01* 行会藏宝阁介绍>             #IMAGE1902700037#<@givegold *01* 捐献金币>             #IMAGE1902700042#<@refresh *01* 刷新购买次数>\n"
	msg = form_str .. "<text><![CDATA["..msg.."]]></text></form>"
	lualib:NPCTalkDetail(player, msg, 518, 260)
	return ""
end

function givegold(player)
	lualib:SysMsg_SendInputDlg(player, 10, "请输入您要捐献的金币数", 30, 12, "givegold_ex", "")
	return main(guid, player)
end

function givegold_ex(id, player, silver)
	local silver = tonumber(silver)
	if silver == nil then
		lualib:MsgBox(player, "请输入纯数字！")
		return
	end
	if silver <= 0 then
		lualib:MsgBox(player, "请输入大于0的正整数！")
		return
	end
	if silver % goldnum ~= 0 then
		lualib:MsgBox(player, "请输入1000的倍数！")
		return
	end

	if not lualib:Player_IsGoldEnough(player, silver, false) then
		lualib:MsgBox(player, "金币不足！")
		return
	end

	local ctrb = silver / goldnum

	lualib:Player_SubGold(player, silver,false, "扣金币：捐献金币", guid)

	AddFamilyProsperity(player, ctrb, "捐献金币")

	return main(guid, player)
end

function item_exchange(player, id)
	lualib:SysMsg_SendInputDlg(player, 10, "请输入您要购买的数量", 30, 12, "item_exchange_ex", id)
	return main(guid, player)
end

function item_exchange_ex(dlgid, player, silver, id)
    local id = tonumber(id)
	local silver = tonumber(silver)
	if silver == nil then
		lualib:MsgBox(player, "请输入纯数字！")
		return
	end
	if silver <= 0 then
		lualib:MsgBox(player, "请输入大于0的正整数！")
		return
	end
	local nums = lualib:GetDayInt(player, all_items[id][1]..id)
	if all_items[id][2] - nums < silver then
		lualib:MsgBox(player, "兑换失败，领地藏宝阁物品库存不足。")
		return
	end
	local ctrb = all_items[id][3] * silver
	if lualib:Player_GetGuildCtrb(player) < ctrb then
		lualib:MsgBox(player, "兑换失败，您的行会贡献度不足【".. ctrb .."】。")
		return
	end
	if lualib:GetBagFree(player) < 1 then
		lualib:MsgBox(player, "兑换失败，请至少保留一个背包空间。")
		return
	end
	if lualib:Player_ReCalGuildCtrb(player, -ctrb) then
		lualib:GiveItem(player, all_items[id][1], silver, "给物品：贡献度兑换", player)
		lualib:SetDayInt(player, all_items[id][1]..id, nums + silver)
		lualib:MsgBox(player, "恭喜您成功兑换【"..all_items[id][1].."】"..silver.."个！")
		return main(guid, player)
	else
		lualib:MsgBox(player, "调整贡献度失败！")
		return
	end
end

function introduce(player)
	local msg = [[
行会贡献点可以通过完成#COLORCOLOR_PURPLE#行会任务、参与行会活动#COLOREND#和#COLORCOLOR_GREENG#捐献金币#COLOREND#获得

藏宝阁部分物品#COLORCOLOR_PURPLE#每日限量#COLOREND#供应，可以通过刷新藏宝阁来获得额外的购买次数，每日最多可刷新三次！

#COLORCOLOR_GREENG#捐献金币规则：#COLOREND#1000金币 = 1点行会贡献点

]]
	lualib:NPCTalkDetail(player, msg, 518, 200)
	return ""
end

function refresh(player)
	local nums = lualib:GetDayInt(player, "refreshnums") + 1
	local gold = gold_t[nums]
	if gold == nil then
		lualib:MsgBox(player, "抱歉，每天只允许刷新【"..#gold_t.."】次，请明天再来！")
	else
		local str = "#COLORCOLOR_RED#              刷新库存确认！#COLOREND#\n\n"
		str = str.."#COLORCOLOR_YELLOW#第"..nums.."次刷新藏宝阁需要消耗"..gold.."金币，是否确定刷新？#COLOREND#"
		str = str.."#BUTTON0#确定#BUTTONEND##BUTTON1#取消#BUTTONEND#"
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
		lualib:MsgBox(player, "#COLORCOLOR_YELLOW#每天只允许刷新【"..#gold_t.."】次，请明天再来！#COLOREND#")
		return
	end
	if not lualib:SubGold(player, gold_t[nums], "扣金币：刷新藏宝阁库存", guid) then
		lualib:MsgBox(player, "#COLORCOLOR_YELLOW#您的金币不足【"..gold_t[nums].."】，不能刷新！#COLOREND#")
		return
	end
	for k, v in ipairs(all_items) do
		lualib:SetDayInt(player, v[1]..k, 0)
	end
	lualib:SetDayInt(player, "refreshnums", nums)
	lualib:MsgBox(player, "#COLORCOLOR_YELLOW#刷新成功，您又可以开始疯狂购物了！#COLOREND#")
	return main(guid, player)
end