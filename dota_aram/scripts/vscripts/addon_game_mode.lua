local function loadModule(name)
    local status, err = pcall(function()
        -- Load the module
        require(name)
    end)

    if not status then
        -- Tell the user about it
        print('WARNING: '..name..' failed to load!')
        print(err)
    end
end

print( "Dota ARAM loaded." )

if DotaARAM == nil then
	DotaARAM = class({})
end

--------------------------------------------------------------------------------
-- ACTIVATE
--------------------------------------------------------------------------------
function Activate()
    GameRules.DotaARAM = DotaARAM()
    GameRules.DotaARAM:InitGameMode()
end

--------------------------------------------------------------------------------
-- INIT
--------------------------------------------------------------------------------
function DotaARAM:InitGameMode()
	loadModule ( 'util' )
	loadModule ( 'timers' )
	require("unstuck")
	local GameMode = GameRules:GetGameModeEntity()
	SetupGlimpse()	

	-- Enable the standard Dota PvP game rules
	GameRules:GetGameModeEntity():SetTowerBackdoorProtectionEnabled( true )

	-- Register Think
	GameMode:SetContextThink( "DotaARAM:GameThink", function() return self:GameThink() end, 0.25 )

	-- Register Game Events
	ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(DotaARAM, "OnStateChanged"), self)
	ListenToGameEvent('npc_spawned', Dynamic_Wrap( DotaARAM, 'OnNPCSpawned' ), self )
	
	-- Set Rules
	GameRules:SetGoldPerTick(3)
	GameRules:SetGoldTickTime(1)
	GameRules:SetPreGameTime(30)
end

--------------------------------------------------------------------------------
function DotaARAM:GameThink()
	return 0.25
end

function DotaARAM:OnStateChanged()	--if GameRules:State_Get() == DOTA_GAMERULES_STATE_INIT then	
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_PRE_GAME then
		print ("Pre Game")
		for _, roshan in pairs( Entities:FindAllByClassname( "ent_dota_fountain" ) ) do 
				roshan:RemoveModifierByName("modifier_fountain_aura")
				print ("Removed Fountain Aura")
		end
	end
	
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_HERO_SELECTION then
		for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
				local playerHandle = PlayerResource:GetPlayer(nPlayerID)
				PlayerResource:SetHasRandomed(nPlayerID)
				PlayerResource:SetHasRepicked(nPlayerID)
				playerHandle:MakeRandomHeroSelection()
		end
	end
end

function DotaARAM:OnNPCSpawned( keys )
  local spawnedUnit = EntIndexToHScript( keys.entindex )
  if not spawnedUnit:IsIllusion() and spawnedUnit:IsHero() then
    local level = spawnedUnit:GetLevel()
      while level < 3 do
        spawnedUnit:AddExperience (500,false)
		spawnedUnit:SetGold( 1500, false)
        level = spawnedUnit:GetLevel()
      end
	ARAM_Buff = CreateItem("item_modifier_aram", nil, nil)
	ARAM_Buff:ApplyDataDrivenModifier(spawnedUnit,spawnedUnit,"ARAM_BUFF",nil)
  end
end

function DotaARAM:OnPlayerLoaded(keys)

  -- Get player id
  local playerEnt = EntIndexToHScript(keys.index+1)

  -- Force the player to random a hero
  playerEnt:MakeRandomHeroSelection()

end
