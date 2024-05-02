local mod = RegisterMod("Vacuum Cleaner", 1)

local item = Isaac.GetItemIdByName("Vacuum Cleaner")
local variant = Isaac.GetEntityVariantByName("VacuumCleaner")

local coneHeight = 100
local coneWidth = 100

local function areaTriangle(point1, point2, point3)
    return math.abs((point1.X * (point2.Y - point3.Y) + point2.X*(point3.Y-point1.Y) + point3.X*(point1.Y-point2.Y))/2)
end

local function isPositionInCone(position, conePointA, conePointB, conePointC)
    local coneArea = areaTriangle(conePointA, conePointB, conePointC)

    local semiAreaA = areaTriangle(position, conePointB, conePointC)
    local semiAreaB = areaTriangle(conePointA, position, conePointC)
    local semiAreaC = areaTriangle(conePointA, conePointB, position)

    return (coneArea == (semiAreaA + semiAreaB + semiAreaC))
end


local function onFamiliarUpdate(_, fam)
    fam:MoveDiagonally(1)
    local velocity = fam.Velocity
    local direction = velocity:Normalized()
    local entities = Isaac:GetRoomEntities()

    -- local famPositionScreen = Isaac.WorldToScreen(fam.Position)
    local coneBasePoint = coneHeight * direction + fam.Position
    local baseDirection = direction:Rotated(90)

    local coneBasePointA = coneBasePoint + baseDirection * coneWidth
    local coneBasePointB = coneBasePoint + baseDirection * coneWidth * -1

    local coneBasePointAScreen = Isaac.WorldToScreen(coneBasePointA)
    local coneBasePointBScreen = Isaac.WorldToScreen(coneBasePointB)

    -- Isaac.RenderText("A", coneBasePointAScreen.X, coneBasePointAScreen.Y,  1, 1, 1, 255)
    -- Isaac.RenderText("B", coneBasePointBScreen.X, coneBasePointBScreen.Y,  1, 1, 1, 255)

    for _, entity in ipairs(entities) do
        if entity.Type == EntityType.ENTITY_PROJECTILE then
            if entity:GetData().touchedByVacuumCone then
                local velocityDirection = (fam.Position - entity.Position):Normalized();
                entity:AddVelocity(velocityDirection)
            end

            if isPositionInCone(entity.Position, fam.Position, coneBasePointA, coneBasePointB) then
                local entityProjectile = entity:ToProjectile()
                entityProjectile:GetData().touchedByVacuumCone = true
                entityProjectile:AddProjectileFlags(ProjectileFlags.CANT_HIT_PLAYER)
                entityProjectile:SetColor(Color(255, 0, 239, 1, 255, 255, 255), 60, 1, false, false)
                -- entityProjectile:AddProjectileFlags(ProjectileFlags.SHIELDED)
                -- mentityProjectile:Remove()
            end


        end
    end


end

local function onEvaluateCache(_, player, cacheFlag)
    if cacheFlag == CacheFlag.CACHE_FAMILIARS then
        player:CheckFamiliar(variant, player:GetCollectibleNum(item) +
                                 player:GetEffects()
                                     :GetCollectibleEffectNum(item), RNG())
    end
end

local function onInit(_, fam)
    fam.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND

end

local function onFamiliarCollision(_, fam, entity, _)
    if entity.Type == EntityType.ENTITY_PROJECTILE then
        entity:Remove()
    end
end

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, onEvaluateCache)
mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, onInit, variant)
mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, onFamiliarUpdate, variant)
mod:AddCallback(ModCallbacks.MC_PRE_FAMILIAR_COLLISION, onFamiliarCollision)
