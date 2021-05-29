-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Ruleset action types

function onInit()
	ActionsManager.registerModHandler("cast", modCast);
end

function modCast(rSource, rTarget, rRoll)
	local aAddDesc = {};
	local nAddMod = 0;
	local rConcRoll = {};
	local nodeActor = DB.findNode(rSource.sCreatureNode);
	local bDefCast = ModifierStack.getModifierKey("SPELL_DCAST");
	local nCCmod = 0;
	
	if not bDefCast then
		return;
	elseif rSource then
		table.insert(aAddDesc, "[CAST DEFENSIVELY]");
		local aCastString, aCastStringStats = StringManager.split(rRoll.sDesc,"]",false);
		local nodeSpell, nodeLevel, nodeSpellClass = getSpellNode(rSource, StringManager.trim(aCastString[2]));
		if not nodeSpell then
			return;
		else
			nCCmod = DB.getValue(nodeSpellClass, "cc.misc", 0);
			if ActorManager.isPC(nodeActor) then
				for _,nodeFeats in pairs(DB.getChildren(nodeActor, "featlist")) do
					if DB.getValue(nodeFeats, "name", "") == "Combat Casting" then
						nAddMod = nAddMod + 4;
					end
				end
			else
				local sFeats = DB.getValue(nodeActor, "feats", {});
				if sFeats then
					aCastString, aCastStringStats = StringManager.split(sFeats,",",true);
					for i = 1, #aCastString do
						if aCastString[i] == "Combat Casting" then
							nAddMod = nAddMod + 4;
						end
					end
				end
			end
		end
		if nAddMod ~= 0 then
			nCCmod = nCCmod + nAddMod;
			DB.setValue(nodeSpellClass, "cc.misc", "number", nCCmod);
			GameSystem.performConcentrationCheck(nil, rSource, nodeSpellClass);
			nCCmod = nCCmod - nAddMod;
			DB.setValue(nodeSpellClass, "cc.misc", "number", nCCmod);
		else
			GameSystem.performConcentrationCheck(nil, rSource, nodeSpellClass);
		end
	end
end	

function getSpellNode(sActor, sSpellName)
	local nodeActor = DB.findNode(sActor.sCreatureNode);
	local nodeTransferSpell = nil;
	local nodeTransferLevel = nil;
	local nodeTransferSpellClass = nil;
	
	for _,nodeSpellClass in pairs(DB.getChildren(nodeActor, "spellset")) do
		for _,nodeLevel in pairs(DB.getChildren(nodeSpellClass, "levels")) do
			for _,nodeSpell in pairs(DB.getChildren(nodeLevel, "spells")) do
				if DB.getValue(nodeSpell, "name", "") == sSpellName then
					nodeTransferSpell = nodeSpell;
					nodeTransferLevel = nodeLevel;
					nodeTransferSpellClass = nodeSpellClass;
				end
			end
		end
	end
	return nodeTransferSpell, nodeTransferLevel, nodeTransferSpellClass;
end