-- Used to store the targets for the headbutt ability
HeadButtTargetHolder = {} 

function movetest(args)
local caster = args.caster
caster:ApplyAbsVelocityImpulse(caster:GetForwardVector()*500)
end

function TestGravityFunc(args)
	finishTime = args.Duration + GameRules:GetGameTime()
	print (finishTime)
	Timers:CreateTimer(1/64, function() return headbuttDash(args,finishTime) end)
end

function saveTarget(args)
	print("Top of the function")
	local caster = args.caster
	local target = args.target
	casterID = caster:GetEntityIndex()
	--HeadButtTargetHolder
	HeadButtTargetHolder[casterID] = target
	print (target)
	contextTest(caster)
end

function headbuttDash(args)
	--PrintTable(args)
	target = HeadButtTargetHolder[args.caster:GetEntityIndex()]
    local targetPos = target:GetAbsOrigin()
    local casterPos = args.caster:GetAbsOrigin()

    local direction = targetPos - casterPos
    local vec = direction:Normalized() * 40
	--print (vec)
	if direction:Length() < 50 then 
		args.caster:InterruptMotionControllers(true)
	end

    args.caster:SetAbsOrigin(casterPos + vec)
end

function contextTest(caster)
local target = HeadButtTargetHolder[caster:GetEntityIndex()]
print (target)
end