local labColoring = {}

labColoring.colorMath = require("utils.colorMath")

local set_color = rendering.set_color
local get_visible = rendering.get_visible
local set_visible = rendering.set_visible

local working = defines.entity_status.working
local low_power = defines.entity_status.low_power

local max = math.max
local random = math.random
local floor = math.floor

-- constants

local stride = 6

-- state

labColoring.state = nil

labColoring.colorForLab = nil

labColoring.init = function (state)
    labColoring.state = state
    if labColoring.state then
        local colorFunctions = labColoring.colorMath.colorFunctions
        labColoring.colorForLab = colorFunctions[labColoring.state.lastColorFunc % #colorFunctions + 1]
    end
    return state
end

labColoring.initialState = {
    lastColorFunc = 1,
    direction = 1,
    meanderingTick = 0,
}

labColoring.chooseNewFunction = function()
    local colorFunctions = labColoring.colorMath.colorFunctions
    if #colorFunctions > 1 then
        local newColorFunc = random(1, #colorFunctions - 1)
        if newColorFunc >= labColoring.state.lastColorFunc then
            newColorFunc = newColorFunc + 1
        end
        labColoring.colorForLab = colorFunctions[newColorFunc]
        labColoring.state.lastColorFunc = newColorFunc
    end
end

labColoring.chooseNewDirection = function()
    if labColoring.state.meanderingTick > 0 then
        labColoring.state.direction = floor(random()*1.999)*2 - 1
    else
        labColoring.state.direction = 1
    end
end

labColoring.switchPattern = function ()
    chooseNewFunction()
    chooseNewDirection()
end

labColoring.updateRenderers = function (event, labRenderers, researchColor)
    labColoring.state.meanderingTick = max(0, labColoring.state.meanderingTick + labColoring.state.direction)
    local offset = event.tick % stride
    local fcolor = {r=0, g=0, b=0, a=0}
    for name, force in pairs(game.forces) do
        local labsForForce = labRenderers.labsForForce(force.index)
        if labsForForce then
            local colors = researchColor.getColorsForResearch(force.current_research)
            local playerPosition = {x = 0, y = 0}
            if force.players[1] then
                playerPosition = force.players[1].position
            end
            for index, lab in pairs(labsForForce) do
                if index % stride == offset then
                    if not lab.valid then
                        softErrorReporting.showModError("errors.registered-lab-deleted")
                        labRenderers.reloadLabs()
                        return
                    end
                    local animation, light = labRenderers.getRenderObjects(lab)
                    if lab.status == working or lab.status == low_power then
                        if not get_visible(animation) then
                            set_visible(animation, true)
                            set_visible(light, true)
                        end
                        labColoring.colorForLab(labColoring.state.meanderingTick, colors, playerPosition, lab.position, fcolor)
                        set_color(animation, fcolor)
                        set_color(light, fcolor)
                    else
                        if get_visible(animation) then
                            set_visible(animation, false)
                            set_visible(light, false)
                        end
                    end
                end
            end
        end
    end
end

return labColoring