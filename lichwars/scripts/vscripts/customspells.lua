function ability_duoduansheji( keys ) 
	local shifazhe=keys.unit
	local angles=shifazhe:GetAngles()
	local angle=angles.y - 30
	local vt=shifazhe:GetAbsOrigin()
	--shifazhe:HeroLevelUp(true)
	--shifazhe:HeroLevelUp(true)
	--shifazhe:HeroLevelUp(true)
    vt.x,vt.y=jizuobiao(vt,angle+30,30)  
	for i=1,10 do 
		local cast_x,cast_y=jizuobiao(vt,angle,200)
		local majia,jineng=majia_and_jineng(shifazhe,vt,"ability_majia_duoduansheji_qiangliji",1,vector(cast_x,cast_y))
		local majia_2,jineng_2=majia_and_jineng(shifazhe,vt,"ability_duoduansheji_jitui",1,vector(cast_x,cast_y))
		angle=angle+6
		wr_gamemode.timer["duoduansheji_majia".. majia:entindex()]={endtime=GameRules:GetGameTime()+0.11,fun = function() majia:CastAbilityOnPosition(vector(cast_x,cast_y),jineng,0) end}
		wr_gamemode.timer["duoduansheji_majia_2".. majia_2:entindex()]={endtime=GameRules:GetGameTime()+0.11,fun = function() majia_2:CastAbilityOnPosition(vector(cast_x,cast_y),jineng_2,0) end}
		wr_gamemode.timer["duoduansheji_majia_death".. majia:entindex()]={endtime=GameRules:GetGameTime()+1.5,fun = function() UTIL_RemoveImmediate(majia) end}
		wr_gamemode.timer["duoduansheji_majia_2_death".. majia_2:entindex()]={endtime=GameRules:GetGameTime()+1.5,fun = function() UTIL_RemoveImmediate(majia_2) end}
	end
end 

function lich_suicide( keys )
	PrintTable( keys )
	local caster = keys.caster
	local currentMana = caster:GetMana()
	local spellLevel = keys.ability:GetLevel()
	local kotlGiffMana = currentMana * (0.15 * spellLevel) -- Sets the amount of mana to give to 15% * level * Caster's Mana
	for _, heroes in pairs( keys.target_entities) do
		heroes:GiveMana(kotlGiffMana)
	end
	
	caster:Kill(keys.ability,keys.attacker)
	local reviveTime = caster:GetRespawnTime()
	reviveTime = reviveTime * .50 --Makes respawn 50% faster
	caster:SetTimeUntilRespawn(reviveTime)
end

function slowDownAnimation( keys)
	keys.ability:SetPlaybackRate(.1)
end

