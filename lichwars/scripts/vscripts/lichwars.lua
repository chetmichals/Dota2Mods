print ('[LichWars] lichwars.lua' )

USE_LOBBY = true
THINK_TIME = 0.1
MAX_KILLS = 50

GameMode = nil

if LichWars == nil then
  print ( '[LichWars] creating LichWars game mode' )
  LichWars = {}
  LichWars.szEntityClassName = "LichWars"
  LichWars.szNativeClassName = "dota_base_game_mode"
  LichWars.__index = LichWars
end

function LichWars:new( o )
  print ( '[LichWars] LichWars:new' )
  o = o or {}
  setmetatable( o, LichWars )
  return o
end

function Precache(context)

--Spell Effects
PrecacheResource("particle_folder", "particles/units/heroes/hero_lich", context)
PrecacheResource("particle_folder", "particles/units/heroes/hero_crystalmaiden", context)
PrecacheResource("particle_folder", "particles/units/heroes/hero_siren", context)
PrecacheResource("particle_folder", "particles/units/heroes/hero_ancient_apparition", context)
PrecacheResource("particle_folder", "particles/units/heroes/hero_jakiro", context)

--Tower Projectiles
PrecacheResource("particle_folder", "particles/base_attacks", context)

--Sound Effects
PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_crystalmaiden.vsndevts", context)
--PrecacheResource("soundfile", "soundevents/game_sounds_custom.vsndevts", context)
PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_lich.vsndevts", context)
PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_naga_siren.vsndevts", context)
PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_ancient_apparition.vsndevts", context)
PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_jakiro.vsndevts", context)


end

function LichWars:InitGameMode()
  print('[LichWars] Starting to load LichWars gamemode...')

  -- Setup rules
  GameRules:SetHeroRespawnEnabled( false )
  --GameRules:SetUseUniversalShopMode( true )
  GameRules:SetSameHeroSelectionEnabled( true )
  GameRules:SetHeroSelectionTime( 30.0 )
  GameRules:SetPreGameTime( 30.0)
  GameRules:SetPostGameTime( 60.0 )
  GameRules:SetTreeRegrowTime( 60.0 )
  --GameRules:SetGoldPerTick( 1000.0 )
  print('[LichWars] Rules set')

  --InitLogFile( "log/LichWars.txt","")

  -- Hooks
  ListenToGameEvent( "game_rules_state_change", Dynamic_Wrap( LichWars, "OnGameRulesStateChange" ), self )
  ListenToGameEvent('entity_killed', Dynamic_Wrap(LichWars, 'OnEntityKilled'), self)
  ListenToGameEvent('player_connect_full', Dynamic_Wrap(LichWars, 'AutoAssignPlayer'), self)
  ListenToGameEvent('player_disconnect', Dynamic_Wrap(LichWars, 'CleanupPlayer'), self)
  ListenToGameEvent('dota_item_purchased', Dynamic_Wrap(LichWars, 'ShopReplacement'), self)
  ListenToGameEvent('player_say', Dynamic_Wrap(LichWars, 'PlayerSay'), self)
  ListenToGameEvent('player_connect', Dynamic_Wrap(LichWars, 'PlayerConnect'), self)
  --ListenToGameEvent('player_info', Dynamic_Wrap(LichWars, 'PlayerInfo'), self)
  ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(LichWars, 'AbilityUsed'), self)
  ListenToGameEvent('npc_spawned', Dynamic_Wrap( LichWars, 'OnNPCSpawned' ), self )

  -- Change random seed
  local timeTxt = string.gsub(string.gsub(GetSystemTime(), ':', ''), '0','')
  math.randomseed(tonumber(timeTxt))

  -- Timers
  self.timers = {}

  -- userID map
  self.vUserNames = {}
  self.vUserIds = {}
  self.vSteamIds = {}
  self.vBots = {}
  self.vBroadcasters = {}

  self.vPlayers = {}
  self.vRadiant = {}
  self.vDire = {}
  self.scoreRadiant = 0
  self.scoreDire = 0

  -- Active Hero Map
  self.vPlayerHeroData = {}
  print('[LichWars] values set')

  print('[LichWars] Precaching stuff...')
  --PrecacheUnitByName('npc_precache_everything')
  print('[LichWars] Done precaching!') 

  print('[LichWars] Done loading LichWars gamemode!\n\n')
end

function LichWars:CaptureGameMode()
  if GameMode == nil then
    -- Set GameMode parameters
    GameMode = GameRules:GetGameModeEntity()    
    -- Disables recommended items...though I don't think it works
    GameMode:SetRecommendedItemsDisabled( false )
    -- Override the normal camera distance.  Usual is 1134
    GameMode:SetCameraDistanceOverride( 1504.0 )
    -- Set Buyback options
    GameMode:SetCustomBuybackCostEnabled( true )
    GameMode:SetCustomBuybackCooldownEnabled( true )
    GameMode:SetBuybackEnabled( false )
    -- Override the top bar values to show your own settings instead of total deaths
    GameMode:SetTopBarTeamValuesOverride ( true )
    -- Chage the minimap icon size
    GameRules:SetHeroMinimapIconSize( 500 )

    print( '[LichWars] Beginning Think' ) 
    GameMode:SetContextThink("LichWarsThink", Dynamic_Wrap( LichWars, 'Think' ), 0.1 )
  end 
end

-- WELCOME MESSAGE
function LichWars:OnGameRulesStateChange()
  local nNewState = GameRules:State_Get()
  if nNewState == DOTA_GAMERULES_STATE_PRE_GAME then
    ShowGenericPopup( "#lichwars_instructions_title", "#lichwars_instructions_body", "", "", DOTA_SHOWGENERICPOPUP_TINT_SCREEN )
  end
end

function LichWars:AbilityUsed(keys)
  print('[LichWars] AbilityUsed')
  PrintTable(keys)
end

-- Cleanup a player when they leave
function LichWars:CleanupPlayer(keys)
  print('[LichWars] Player Disconnected ' .. tostring(keys.userid))
end

function LichWars:CloseServer()
  -- Just exit
  SendToServerConsole('exit')
end

function LichWars:PlayerConnect(keys)
  print('[LichWars] PlayerConnect')
  PrintTable(keys)
  
  -- Fill in the usernames for this userID
  self.vUserNames[keys.userid] = keys.name
  if keys.bot == 1 then
    -- This user is a Bot, so add it to the bots table
    self.vBots[keys.userid] = 1
  end
end

local hook = nil
local attach = 0
local controlPoints = {}
local particleEffect = ""

function LichWars:PlayerSay(keys)
  print ('[LichWars] PlayerSay')
  PrintTable(keys)
  
  -- Get the player entity for the user speaking
  local ply = self.vUserIds[keys.userid]
  if ply == nil then
    return
  end
  
  -- Get the player ID for the user speaking
  local plyID = ply:GetPlayerID()
  if not PlayerResource:IsValidPlayer(plyID) then
    return
  end
  
  -- Should have a valid, in-game player saying something at this point
  -- The text the person said
  local text = keys.text
  
  -- Match the text against something
  local matchA, matchB = string.match(text, "^-swap%s+(%d)%s+(%d)")
  if matchA ~= nil and matchB ~= nil then
    -- Act on the match
  end
  
end

function LichWars:AutoAssignPlayer(keys)
  print ('[LichWars] AutoAssignPlayer')
  PrintTable(keys)
  LichWars:CaptureGameMode()
  
  local entIndex = keys.index+1
  -- The Player entity of the joining user
  local ply = EntIndexToHScript(entIndex)
  
  -- The Player ID of the joining player
  local playerID = ply:GetPlayerID()
  
  -- Update the user ID table with this user
  self.vUserIds[keys.userid] = ply
  -- Update the Steam ID table
  self.vSteamIds[PlayerResource:GetSteamAccountID(playerID)] = ply
  
  -- If the player is a broadcaster flag it in the Broadcasters table
  if PlayerResource:IsBroadcaster(playerID) then
    self.vBroadcasters[keys.userid] = 1
    return
  end
  
  -- If this player is a bot (spectator) flag it and continue on
  if self.vBots[keys.userid] ~= nil then
    return
  end

  
  playerID = ply:GetPlayerID()
  -- Figure out if this player is just reconnecting after a disconnect
  if self.vPlayers[playerID] ~= nil then
    self.vUserIds[keys.userid] = ply
    return
  end
  
  -- If we're not using a lobby, assign players round robin to teams
  if not USE_LOBBY and playerID == -1 then
    if #self.vRadiant > #self.vDire then
      ply:SetTeam(DOTA_TEAM_BADGUYS)
      ply:__KeyValueFromInt('teamnumber', DOTA_TEAM_BADGUYS)
      table.insert (self.vDire, ply)
    else
      ply:SetTeam(DOTA_TEAM_GOODGUYS)
      ply:__KeyValueFromInt('teamnumber', DOTA_TEAM_GOODGUYS)
      table.insert (self.vRadiant, ply)
    end
    playerID = ply:GetPlayerID()
  end

  --Autoassign player
  self:CreateTimer('assign_player_'..entIndex, {
  endTime = Time(),
  callback = function(LichWars, args)
    -- Make sure the game has started
    print ('ASSIGNED')
    if GameRules:State_Get() >= DOTA_GAMERULES_STATE_PRE_GAME then
      -- Assign a hero to a fake client
      local heroEntity = ply:GetAssignedHero()
      if PlayerResource:IsFakeClient(playerID) then
        if heroEntity == nil then
          CreateHeroForPlayer('npc_dota_hero_axe', ply)
        else
          PlayerResource:ReplaceHeroWith(playerID, 'npc_dota_hero_axe', 0, 0)
        end
      end
      heroEntity = ply:GetAssignedHero()
      -- Check if we have a reference for this player's hero
      if heroEntity ~= nil and IsValidEntity(heroEntity) then
        -- Set up a heroTable containing the state for each player to be tracked
        local heroTable = {
          hero = heroEntity,
          nTeam = ply:GetTeam(),
          bRoundInit = false,
          name = self.vUserNames[keys.userid],
        }
        self.vPlayers[playerID] = heroTable

        if GameRules:State_Get() > DOTA_GAMERULES_STATE_PRE_GAME then
            -- This section runs if the player picks a hero after the round starts
        end

        return
      end
    end

    return Time() + 1.0
  end
})
end

function LichWars:LoopOverPlayers(callback)
  for k, v in pairs(self.vPlayers) do
    -- Validate the player
    if IsValidEntity(v.hero) then
      -- Run the callback
      if callback(v, v.hero:GetPlayerID()) then
        break
      end
    end
  end
end

function LichWars:OnNPCSpawned( keys )
  print ( '[LichWars] OnNPCSpawned' )
  local spawnedUnit = EntIndexToHScript( keys.entindex )
  if not spawnedUnit:IsIllusion() and spawnedUnit:IsHero() then
    local level = spawnedUnit:GetLevel()
      while level < 6 do
        spawnedUnit:AddExperience (2000,false)
        level = spawnedUnit:GetLevel()
      end
  end
end


-- Is this even needed? 
function LichWars:ShopReplacement( keys )
  print ( '[LichWars] ShopReplacement' )
  PrintTable(keys)

  -- The playerID of the hero who is buying something
  local plyID = keys.PlayerID
  if not plyID then return end

  -- The name of the item purchased
  local itemName = keys.itemname 
  
  -- The cost of the item purchased
  local itemcost = keys.itemcost
  
end

function LichWars:getItemByName( hero, name )
  -- Find item by slot
  for i=0,11 do
    local item = hero:GetItemInSlot( i )
    if item ~= nil then
      local lname = item:GetAbilityName()
      if lname == name then
        return item
      end
    end
  end

  return nil
end

function LichWars:Think()
  -- If the game's over, it's over.
  if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
    return
  end

  -- Track game time, since the dt passed in to think is actually wall-clock time not simulation time.
  local now = GameRules:GetGameTime()
  --print("now: " .. now)
  if LichWars.t0 == nil then
    LichWars.t0 = now
  end
  local dt = now - LichWars.t0
  LichWars.t0 = now

  --LichWars:thinkState( dt )

  -- Process timers
  for k,v in pairs(LichWars.timers) do
    local bUseGameTime = false
    if v.useGameTime and v.useGameTime == true then
      bUseGameTime = true;
    end
    -- Check if the timer has finished
    if (bUseGameTime and GameRules:GetGameTime() > v.endTime) or (not bUseGameTime and Time() > v.endTime) then
      -- Remove from timers list
      LichWars.timers[k] = nil

      -- Run the callback
      local status, nextCall = pcall(v.callback, LichWars, v)

      -- Make sure it worked
      if status then
        -- Check if it needs to loop
        if nextCall then
          -- Change it's end time
          v.endTime = nextCall
          LichWars.timers[k] = v
        end

      else
        -- Nope, handle the error
        LichWars:HandleEventError('Timer', k, nextCall)
      end
    end
  end

  return THINK_TIME
end

function LichWars:HandleEventError(name, event, err)
  -- This gets fired when an event throws an error

  -- Log to console
  print(err)

  -- Ensure we have data
  name = tostring(name or 'unknown')
  event = tostring(event or 'unknown')
  err = tostring(err or 'unknown')

  -- Tell everyone there was an error
  Say(nil, name .. ' threw an error on event '..event, false)
  Say(nil, err, false)

  -- Prevent loop arounds
  if not self.errorHandled then
    -- Store that we handled an error
    self.errorHandled = true
  end
end

function LichWars:CreateTimer(name, args)
  --[[
  args: {
  endTime = Time you want this timer to end: Time() + 30 (for 30 seconds from now),
  useGameTime = use Game Time instead of Time()
  callback = function(frota, args) to run when this timer expires,
  text = text to display to clients,
  send = set this to true if you want clients to get this,
  persist = bool: Should we keep this timer even if the match ends?
  }

  If you want your timer to loop, simply return the time of the next callback inside of your callback, for example:

  callback = function()
  return Time() + 30 -- Will fire again in 30 seconds
  end
  ]]

  if not args.endTime or not args.callback then
    print("Invalid timer created: "..name)
    return
  end

  -- Store the timer
  self.timers[name] = args
end

function LichWars:RemoveTimer(name)
  -- Remove this timer
  self.timers[name] = nil
end

function LichWars:RemoveTimers(killAll)
  local timers = {}

  -- If we shouldn't kill all timers
  if not killAll then
    -- Loop over all timers
    for k,v in pairs(self.timers) do
      -- Check if it is persistant
      if v.persist then
        -- Add it to our new timer list
        timers[k] = v
      end
    end
  end

  -- Store the new batch of timers
  self.timers = timers
end

function LichWars:ShowCenterMessage( msg, dur )
  local msg = {
    message = msg,
    duration = dur
  }
  FireGameEvent("show_center_message",msg)
end

function LichWars:OnEntityKilled( keys )
  local killedUnit = EntIndexToHScript( keys.entindex_killed )
  local killerEntity = nil
  if keys.entindex_attacker == nil then
    return
  end
  
  killerEntity = EntIndexToHScript( keys.entindex_attacker )
  local killedTeam = killedUnit:GetTeam()
  local killerTeam = killerEntity:GetTeam()

  if killedUnit:IsRealHero() == true then
    local death_count_down = 5
    killedUnit:SetTimeUntilRespawn(death_count_down)

    LichWars:CreateTimer(DoUniqueString("respawn"), {
      endTime = GameRules:GetGameTime() + 1,
      useGameTime = true,
      callback = function(reflex, args)
        death_count_down = death_count_down - 1
        if death_count_down == 0 then
          --Respawn hero after 5 seconds
          killedUnit:RespawnHero(false,false,false)
          return
        else
          killedUnit:SetTimeUntilRespawn(death_count_down)
          return GameRules:GetGameTime() + 1
        end
      end
    })

    if killedTeam == DOTA_TEAM_BADGUYS then
      if killerTeam == 2 then
        self.scoreRadiant = self.scoreRadiant + 1
      end
    elseif killedTeam == DOTA_TEAM_GOODGUYS then
      if killerTeam == 3 then
        self.scoreDire = self.scoreDire + 1
      end
    end

    if self.scoreRadiant == 40 then
      LichWars:ShowCenterMessage("Radiant are 10 kills away from winning!",10)
    end
    if self.scoreDire == 40 then
      LichWars:ShowCenterMessage("Dire are 10 kills away from winning!",10)
    end


    GameMode:SetTopBarTeamValue ( DOTA_TEAM_BADGUYS, self.scoreDire)
    GameMode:SetTopBarTeamValue ( DOTA_TEAM_GOODGUYS, self.scoreRadiant )

    if self.scoreDire >= MAX_KILLS then
      GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
      GameRules:MakeTeamLose(DOTA_TEAM_GOODGUYS)
      GameRules:Defeated()
    end
    if self.scoreRadiant >= MAX_KILLS  then
      GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
      GameRules:MakeTeamLose(DOTA_TEAM_BADGUYS)
      GameRules:Defeated()
    end
  end
end

-- A helper function for dealing damage from a source unit to a target unit.  Damage dealt is pure damage
function dealDamage(source, target, damage)
  local unit = nil
  if damage == 0 then
    return
  end
  
  if source ~= nil then
    unit = CreateUnitByName("npc_dummy_unit", target:GetAbsOrigin(), false, source, source, source:GetTeamNumber())
  else
    unit = CreateUnitByName("npc_dummy_unit", target:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_NOTEAM)
  end
  unit:AddNewModifier(unit, nil, "modifier_invulnerable", {})
  unit:AddNewModifier(unit, nil, "modifier_phased", {})
  local dummy = unit:FindAbilityByName("reflex_dummy_unit")
  dummy:SetLevel(1)
  
  local abilIndex = math.floor((damage-1) / 20) + 1
  local abilLevel = math.floor(((damage-1) % 20)) + 1
  if abilIndex > 100 then
    abilIndex = 100
    abilLevel = 20
  end
  
  local abilityName = "modifier_damage_applier" .. abilIndex
  unit:AddAbility(abilityName)
  ability = unit:FindAbilityByName( abilityName )
  ability:SetLevel(abilLevel)
  
  local diff = nil
  
  local hp = target:GetHealth()
  
  diff = target:GetAbsOrigin() - unit:GetAbsOrigin()
  diff.z = 0
  unit:SetForwardVector(diff:Normalized())
  unit:CastAbilityOnTarget(target, ability, 0 )
  
  LichWars:CreateTimer(DoUniqueString("damage"), {
    endTime = GameRules:GetGameTime() + 0.3,
    useGameTime = true,
    callback = function(LichWars, args)
      unit:Destroy()
      if target:GetHealth() == hp and hp ~= 0 and damage ~= 0 then
        print ("[LichWars] WARNING: dealDamage did no damage: " .. hp)
        dealDamage(source, target, damage)
      end
    end
  })
end