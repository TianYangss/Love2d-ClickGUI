
local KillAura = {
    range = 4.2,
    onlyPlayers = true,
    rotation = false,
    mode = "Switch",

    -- TargetHUD
    attackCooldown = 1.0,
    attackTimer = 0,
    damage = 3
}

UI.RegisterSlider("killaura", "Range", "range", 3.0, 6.0, 0.1)
UI.RegisterCheckbox("killaura", "Only Players", "onlyPlayers")
UI.RegisterCheckbox("killaura", "Rotation", "rotation")
UI.RegisterMode("killaura", "Mode", "mode", {"Single", "Switch", "Multi"})
UI.RegisterSlider("killaura", "Attack Cooldown", "attackCooldown", 0.1, 3.0, 0.1)
UI.RegisterSlider("killaura", "Damage", "damage", 1, 20, 1)

function KillAura:SendAttackEvent()
    if ty.AttackEventReceivers then
        for _, receiver in ipairs(ty.AttackEventReceivers) do
            if receiver.OnAttack then
                pcall(receiver.OnAttack, receiver, self.damage)
            end
        end
    end
end

function KillAura:OnUpdate(dt)
    if ty.ModuleStates["combat"] and ty.ModuleStates["combat"]["killaura"] then
        self.attackTimer = self.attackTimer - dt

        if self.attackTimer <= 0 then
            self:PerformAttack()
            self.attackTimer = self.attackCooldown
        end
    end
end

function KillAura:PerformAttack()
    self:SendAttackEvent()
end

function KillAura:OnEnabled()
    ty.log("[KillAura] Module enabled - Mode: " .. self.mode)
    self.attackTimer = 0
end

function KillAura:OnDisabled()
    ty.log("[KillAura] Module disabled")
end

return KillAura