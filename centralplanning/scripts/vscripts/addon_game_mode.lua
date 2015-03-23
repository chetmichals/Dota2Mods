--[[
Dota PvP game mode
]]

print( "Dota PvP game mode loaded." )

if DotaPvP == nil then
	DotaPvP = class({})
end

--------------------------------------------------------------------------------
-- ACTIVATE
--------------------------------------------------------------------------------
function Activate()
    GameRules.DotaPvP = DotaPvP()
    GameRules.DotaPvP:InitGameMode()
end

--------------------------------------------------------------------------------
-- INIT
--------------------------------------------------------------------------------
function DotaPvP:InitGameMode()
	local GameMode = GameRules:GetGameModeEntity()

	-- Enable the standard Dota PvP game rules
	GameRules:GetGameModeEntity():SetTowerBackdoorProtectionEnabled( true )
	--GameRules:GetGameModeEntity():SetBotThinkingEnabled( true ) 

	--Intilize a bunch of varables
	local nDifficulty = GameRules:GetCustomGameDifficulty()
	GoodTeamRGold = 0
	GoodTeamUGold = 0
	BadTeamRGold = 0
	BadTeamUGold = 0
	goodCount = 0
	badCount = 0
	GoodTeamRGoldLastTick = 0
	GoodTeamRGoldAccumulation = 0
	GoodTeamUGoldLastTick = 0
	GoodTeamUGoldAccumulation = 0
	BadTeamRGoldLastTick = 0
	BadTeamRGoldAccumulation = 0
	BadTeamUGoldLastTick = 0
	BadTeamUGoldAccumulation = 0
	
	
	--GameRules:SetPreGameTime( 20.0 )
	
	
	-- If normal mode, delay roshan till 30 seconds after spawn
	if nDifficulty == 0 then
		--Removes default roshan spawn without needing map edit
		for _, roshan in pairs( Entities:FindAllByClassname( "npc_dota_roshan_spawner" ) ) do
			roshan:RemoveSelf()
			print ("Rosh Spawn Deleted")
		end
		
		for _, roshan in pairs( Entities:FindAllByClassname( "npc_dota_roshan" ) ) do
			roshan:RemoveSelf()
			print ("Rosh Deleted")
		end
		
		iRoshTimerStartedValue = 0
		self._SpawnRoshanTime = 0
		GameRules:GetGameModeEntity():SetThink( "RoshanThink", self, "RoshanThinker", 1 )
	end
	
	-- If difficulty is set to "Insane"
	if nDifficulty == 2 then
		GameRules:GetGameModeEntity():SetThink( "GiveRoshCheese", self, "RoshanThinker", 1 )
	end
	
	-- Register Think
	--GameMode:SetContextThink( "DotaPvP:GameThink", function() return self:GameThink() end, 0.25 )
	GameRules:GetGameModeEntity():SetThink( "OnThink", self, "MainThinker", 0.01 ) 
	
	-- Register Game Events
	
end

--------------------------------------------------------------------------------
function DotaPvP:GameThink()
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		PlayerResource:SetGold( nPlayerID, 1, false)
	end
	
	return 0.01
end

function DotaPvP:GiveRoshCheese()
	for _, roshan in pairs( Entities:FindAllByClassname( "npc_dota_roshan" ) ) do
		if roshan:HasItemInInventory("item_cheese") == false then
			local item = CreateItem("item_cheese", roshan, roshan)
			if item ~= nil then
				roshan:AddItem(item)
				print ("We have given Roshan Cheese")
			else
				print ("No cheese!?!re")
			end
		end
	end
	return 1
end

function DotaPvP:Debugger()
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		 print ("Loop 1")
		local hero = PlayerResource:GetSelectedHeroEntity( nPlayerID )
		for itemSlot = 0, 5, 1 do
			 print ("Loop 2")
			if hero ~= nil then
				local Item = hero:GetItemInSlot( itemSlot )
				if Item ~= nil then
					
					print( string.format( "Item Name: %s", Item:GetName() ) )
					print( string.format( "Item Owner: %s", Item:GetPurchaser() ) )
					print( string.format( "Item Owner Class: %s", Item:GetPurchaser():GetClassname() ) )
					Item:SetPurchaser ( hero )
				end
			end
		end
	end
	return 1
end

function DotaPvP:RoshanThink()
	local nNewState = GameRules:State_Get()
	if nNewState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS and iRoshTimerStartedValue == 0 then
		self._SpawnRoshanTime = GameRules:GetGameTime() + 30.0
		iRoshTimerStartedValue = 1
		print ("Timer Started, Roshan Soon")
	end
	if GameRules:GetGameTime() >= self._SpawnRoshanTime and iRoshTimerStartedValue == 1 then
		roshanSpawn = Vector ( 2408, -232, 40 )
		--roshanSpawn = Vector ( 0, 0, 0 )
		CreateUnitByName( "npc_dota_roshan_spawner", roshanSpawn, true, nil, nil, DOTA_TEAM_NEUTRALS )
		iRoshTimerStartedValue = 2
		print ("Roshan has spawned")
		return 0
	end
	return 1
end

function DotaPvP:OnThink()
--Set up the values for the tick
	GoodTeamRGoldLastTick = GoodTeamRGold * goodCount
	GoodTeamRGoldAccumulation = 0
	GoodTeamUGoldLastTick = GoodTeamUGold * goodCount
	GoodTeamUGoldAccumulation = 0
	BadTeamRGoldLastTick = BadTeamRGold * badCount
	BadTeamRGoldAccumulation = 0
	BadTeamUGoldLastTick = BadTeamUGold * badCount
	BadTeamUGoldAccumulation = 0
	
	goodCount = 0
	badCount = 0
	--print( string.format( "Gold last Tick: %d", GoodTeamUGoldLastTick ) )
	
	--Counts up all the teams gold
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
			GoodTeamRGoldAccumulation = GoodTeamRGoldAccumulation + PlayerResource:GetReliableGold( nPlayerID )
			GoodTeamUGoldAccumulation = GoodTeamUGoldAccumulation + PlayerResource:GetUnreliableGold ( nPlayerID )
			goodCount = goodCount + 1
		elseif PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_BADGUYS then
			BadTeamRGoldAccumulation = BadTeamRGoldAccumulation + PlayerResource:GetReliableGold( nPlayerID )
			BadTeamUGoldAccumulation = BadTeamUGoldAccumulation + PlayerResource:GetUnreliableGold ( nPlayerID )
			badCount = badCount + 1
		end
	end
	--print( string.format( "Gold Start of Tick: %d", GoodTeamUGoldAccumulation ) )
	
	GoodTeamRGoldDiff = GoodTeamRGoldAccumulation - GoodTeamRGoldLastTick
	GoodTeamUGoldDiff = GoodTeamUGoldAccumulation - GoodTeamUGoldLastTick
	BadTeamRGoldDiff = BadTeamRGoldAccumulation - BadTeamRGoldLastTick
	BadTeamUGoldDiff = BadTeamUGoldAccumulation - BadTeamUGoldLastTick
	--print( string.format( "Gold Diff: %d", GoodTeamUGoldDiff ) )
	
	GoodTeamRGold = GoodTeamRGold + GoodTeamRGoldDiff
	GoodTeamUGold = GoodTeamUGold + GoodTeamUGoldDiff
	BadTeamRGold = BadTeamRGold + BadTeamRGoldDiff
	BadTeamUGold = BadTeamUGold + BadTeamUGoldDiff
	--print( string.format( "New Gold: %d", GoodTeamUGold ) )
	
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
			PlayerResource:SetGold( nPlayerID, GoodTeamUGold, false)
			PlayerResource:SetGold( nPlayerID, GoodTeamRGold, true)
		elseif PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_BADGUYS then
			PlayerResource:SetGold( nPlayerID, BadTeamUGold, false)
			PlayerResource:SetGold( nPlayerID, BadTeamRGold, true)
		end
	end
	--print ("End Tick")
	
	--Makes it so items are owned by the person holding them
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		-- print ("Loop 1")
		local hero = PlayerResource:GetSelectedHeroEntity( nPlayerID )
		for itemSlot = 0, 5, 1 do
			-- print ("Loop 2")
			if hero ~= nil then
				local Item = hero:GetItemInSlot( itemSlot )
				if Item ~= nil then
					
					--print( string.format( "Item Name: %s", Item:GetName() ) )
					--print( string.format( "Item Owner: %s", Item:GetPurchaser() ) )
					--print( string.format( "Item Owner Class: %s", Item:GetPurchaser():GetClassname() ) )
					Item:SetPurchaser ( hero )
				end
			end
		end
	end
	
	
	
	return .01
end