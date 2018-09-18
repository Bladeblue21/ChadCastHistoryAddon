-- TODO:
	-- Spell fucntionality
		-- Show interrupted casts
			-- The failed trigger if firing before the interrupt.
			-- Need to find a way to show the X instead of the Red box
				-- Maybe actually do both?
		-- Have the recent cast frame only pull from the players spells	
			-- Currently its showing for all characters spells around the player.
		-- Make a new function that handles if a cast is done
			-- Completed will show green.
			-- Red X for kicked.
			-- Pass a
		-- Enum for casted states.
			-- Unknown, Succeed, Kicked, Interrupted.
			-- Start toggling show for the textures once they are set
			-- Figure out how to access the textures by name. Instead of for one of the frames.
			-- Terrible solution is to add the texture to the table for each frame. This might cause a bunch of table entries that it will be hard to keep track of.
				-- But might be able to only insert the needed texture this way.
	-- Tournament Support
		-- Make a bar for each of the arena nameplates
		-- Track spells for each player
		
	-- Move xml stuff into one template.
	-- Create a table in a table to handle spellicon and successOverlay
		-- Something like this	
			-- table.insert(playerSpellList, { spellIcon = spellIcon, success = success })
		

local playerSpellList = {}
local castStatusList = {}


function PlayerCombatLogEventUnfiltered(_, eventtype, hideCaster,                                                                      
      sourceGUID, sourceName, _, _, _, _, _, _, id, spellName, spellSchool, amount, school)
	  
	  print(eventtype)
	  
	if eventtype == "SPELL_CAST_SUCCESS" then
		if sourceGUID == playerGUID then
			if midChannel == 0 and midCast == 0 then
				PlayerUnitSpellcastInstant(sourceName, id)
				print(sourceName, id)
			end
			
			if midCast == 1 then
				PlayerUnitSpellcastSucceeded()
			end
		end
	end
	
	if eventtype == "SPELL_CAST_FAILED" then
		-- Insert Red Fail Border here
		PlayerUnitSpellcastInterrupted(sourceName, id)
		UpdatePlayerSpell(3)
		print("Cast Failed")
	end
		
	if eventtype == "SPELL_INTERRUPT" then
		-- Insert Red X over spell Icon here
		PlayerUnitSpellcastInterrupted(sourceName, id)
		UpdatePlayerSpell(4)
		print("Cast Interrupted with ", spellName, " by ", sourceName)
	end
	

end

function PlayerUnitSpellcastInstant(Name, spellid)
		spellName, rank, spellIcon, castTime, minRange, maxRange = GetSpellInfo(spellid)
		AddPlayerSpell(spellName, spellIcon, 2)
		UpdatePlayerSpell(2)

		-- AddSpellBorder(goodCastTexture)
end

function PlayerUnitSpellcastStart(unitTarget, castGUID, spellID)
	if unitTarget == "player" then
		spellName, rank, spellIcon, castTime, minRange, maxRange = GetSpellInfo(spellID)
		AddPlayerSpell(spellName,spellIcon, 1)
		UpdatePlayerSpell(1)
	end
end



function PlayerUnitSpellcastSucceeded()
	midCast = 0
	UpdatePlayerSpell(2)
end



function PlayerUnitSpellcastInterrupted()
	--unitName, spellName, spellRank, spellCounter, id = ...
	print("Interrupted function")
	if midCast == 1 or midChannel == 1 then
		midCast = 0
		midChannel = 0
		print("Set to Zero", midCast, midChannel)
	end
end

function PlayerUnitSpellcastChannelStart(unitTarget,castGUID, spellID)
	if unitTarget == "player" then
		spellName, rank, spellIcon, castTime, minRange, maxRange = GetSpellInfo(spellID)
		AddPlayerSpell(spellName,spellIcon, 1)
	end
end

function PlayerUnitSpellcastChannelStop(unitTarget, castGUID, spellID)
	if unitTarget == "player" then
		midChannel = 0
	end
	UpdatePlayerSpell(2)
	print(midChannel)
	print("Channel finished")
end


function RemovePlayerSpell()
	table.remove(playerSpellList,1,1)
	-- table.remove(playerCastStatusList,1)
end

function AddPlayerSpell(spellName, spellIcon, castStatus)
	if (#playerSpellList > 4) then
		RemovePlayerSpell()
	end
	
	table.insert(playerSpellList, { spellIcon = spellIcon, castStatus = castStatus })
		
	for i = 1, #playerSpellList do
		ChadSpellCastHistory.RecentCastFrames[i].stexture:SetTexture(playerSpellList[i].spellIcon)
		-- ChadSpellCastHistory.RecentCastStatus[i].otexture:SetTexture(castStatusList[castStatus])
	end
end

function UpdatePlayerSpell(castStatus)
	for i = 1, #playerSpellList do
		if playerSpellList[i].castStatus == 1 then
			playerSpellList[i].castStatus = castStatus
		end
		
		--ChadSpellCastHistory.RecentCastStatus[i].otexture:SetTexture(castStatusList[playerSpellList.castStatus])
		
		local spellThing = ChadSpellCastHistory.RecentCastStatus[i]
		spellThing.goodCast:SetShown(playerSpellList[i].castStatus == 2)
		spellThing.failCast:SetShown(playerSpellList[i].castStatus == 3)
		spellThing.kickCast:SetShown(playerSpellList[i].castStatus == 4)
		
		-- if (#castStatusList ~= 4) then
			-- table.insert(castStatusList, 1)
			-- table.insert(castStatusList, ChadSpellCastHistory.RecentCastStatus[i].goodCast)
			-- table.insert(castStatusList, ChadSpellCastHistory.RecentCastStatus[i].failCast)
			-- table.insert(castStatusList, ChadSpellCastHistory.RecentCastStatus[i].kickCast)
		-- end
		
	end
end

function CastDisplayOnLoad(self)
	self:RegisterEvent("UNIT_SPELLCAST_START")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_SENT")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")

	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		
	midCast = 0
	midChannel = 0
	playerGUID = UnitGUID("player")
	print("Player GUID: ", playerGUID)
	
	
end

function CastDisplayOnEvent(self, event, ...)
	print(event)
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		PlayerCombatLogEventUnfiltered(CombatLogGetCurrentEventInfo())
	end
	
	if event == "UNIT_SPELLCAST_START" and midCast == 0 and midChannel == 0 then
		local unitTarget, castGUID, spellID = ...;
		midCast = 1
		PlayerUnitSpellcastStart(unitTarget, castGUID, spellID)
	end
	
	-- if event == "UNIT_SPELLCAST_INTERRUPTED" and midCast == 1 or midChannel == 1 then
		-- PlayerUnitSpellcastInterrupted()
		-- UpdatePlayerSpell(3)
		-- print("Cast Failed")
	-- end 

	if event == "UNIT_SPELLCAST_CHANNEL_START" and midChannel == 0 then
		local unitTarget, castGUID, spellID = ...;
		midChannel = 1
		PlayerUnitSpellcastChannelStart(unitTarget,castGUID, spellID)
	else if event == "UNIT_SPELLCAST_CHANNEL_STOP" and midChannel == 1 then
		local unitTarget, castGUID, spellID = ...;
		PlayerUnitSpellcastChannelStop(unitTarget, castGUID, spellID)
		end
	end

	
	if event == "VARIABLES_LOADED" then
		CastDisplayOnLoad(self)
	end
end
	
	-- Time function if I need it
	-- local locationTime = 5 --THIS IS THE FIVE SECONDS OR ARBITRARY
	-- local elapsedTime = 0
	-- local MF = CreateFrame("Frame","MYNewmainFrame",UIParent);
	-- MF:SetScript("OnUpdate", function(self, elapsed) self:Update(self, elapsed) end)
	-- function MF:Update(self, elapsed)
		-- elapsedTime = elapsedTime + elapsed
		-- if (elapsedTime > locationTime) then
			-- elapsedTime = 0
			-- removedFrame = table.remove(playerSpellList,1)
			-- print ("Removed", spellname, "from recent casts.")
			-- removedFrame = nil
		-- end
	-- end