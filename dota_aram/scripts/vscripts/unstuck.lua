GlipseGlobalID = 
{
	CasterHandle,
	SpellHandle
}

vecMyVector = Vector(10,10,10)

function SetupGlimpse()
	
	hawk = CreateUnitByName("flying_dummy_unit", vecMyVector, false, nil, nil, DOTA_TEAM_NEUTRALS)
	GlipseGlobalID.CasterHandle = hawk
	--print (hawk)
	local dummy = hawk:FindAbilityByName("flying_dummy_unit_passive")
	dummy:SetLevel(1) --Makes unit invisible and unselectiable 
	local dummy = hawk:FindAbilityByName("dummy_glimpse")
	dummy:SetLevel(1) --Gives the unit the ability to use Glimpse
	hawk:SetDayTimeVisionRange(0)
	hawk:SetNightTimeVisionRange(0)
	GlipseGlobalID.SpellHandle = dummy
	print("Dummy Glimpse Set Up")
	PrintTable (GlipseGlobalID)
	print(GlipseGlobalID.CasterHandle:GetName())
end

function OnStartTouch( skip_zone )
	if GlipseGlobalID.CasterHandle == nil then
		findGlimpse()
	end
	DummyUnit = GlipseGlobalID.CasterHandle
	print(DummyUnit)
	GlipseGlobal = GlipseGlobalID.SpellHandle
	DummyUnit:CastAbilityOnTarget(skip_zone.activator,GlipseGlobal,-1)
end

function findGlimpse()
	print ("looking for Glimpse")
	for _, unit in pairs( Entities:FindAllByClassname("npc_dota_base_additive")) do
		if unit:HasAbility("dummy_glimpse") == true then
			GlipseGlobalID.CasterHandle = unit
			GlipseGlobalID.SpellHandle = unit:FindAbilityByName("dummy_glimpse")
			print ("Found Glimpse Unit")
		end
	end
end