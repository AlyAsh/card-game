Card = Class{}

testString = ""

function Card:init(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.dragging = {
        active = false,
        diffX = 0,
        diffY = 0}
    self.drawn = false
    self.set = false
    self.active = false
    self.action = nil
    self.discard = false
    self.activated = false
    self.targets = {}

end

function Card:load_info(keys, info)
    for i, key in ipairs(keys) do 
        self[key] = info[key]
        i = i + 1
    end
end

function Card:display_info()
    love.graphics.setColor(0, 0, 0, 1)
    testString = ""
    -- Render card info
    for key, value in pairs(self) do
        testString = testString .. key .. ": " .. tostring(value) .. "\n"
    end

    --[[For in-game card info, only display certain keys
    if self.type == "Unit" then
        testString = "Name: " .. self.name .. "\n" ..
                    "Type: " .. self.type .. "\n" ..
                    "Sub-type: " .. self.subtype .. "\n" ..
                    "Agenda: " .. self.agenda .. "\n" ..
                    "Strength: " .. self.strength .. "\n" ..
                    "Effect card?" .. tostring(self.effect) .. "\n" ..
                    self.text .. "\n"
                    
                    
    elseif self.type == "Backrow" then
        testString = "Name: " .. self.name .. "\n" ..
                    "Type: " .. self.type .. "\n" ..
                    "Sub-type: " .. self.subtype .. "\n" ..
                    "Effect card?" .. tostring(self.effect) .. "\n" ..
                    "Keyword: " .. self.keyword .. "\n" ..
                    self.text .. "\n"
                    
    end]]

        
end


function Card:update(dt)

end

function Card:render()

    if self.active == true then
        love.graphics.setColor(0, 1, 0, 1)
    else
        love.graphics.setColor(0, 0, 0, 1)
    end

    -- Render card in hand
    if self.discard == false and self.drawn == true then
        love.graphics.rectangle('line', self.x, self.y, self.width, self.height)
        love.graphics.printf(tostring(self.name), self.x + 10, self.y + 10, CARD_WIDTH - 20, "left")
        if self.strength ~= 'nil' then
            love.graphics.printf(tostring(self.strength), self.x + 10, self.y + 30, CARD_WIDTH - 20, "left")
        end
    elseif self.discard == true and self.drawn == true then
        -- Do not Render if discarded, as the discardSprite will handle that
        self.x = DISCARD_X
        self.y = DISCARD_Y
        love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
    else
        love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
    end

    -- Render card info
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.printf(testString, SIDEBAR, 230, WINDOW_WIDTH - SIDEBAR - 20, "left")

end