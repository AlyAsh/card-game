-- GAME MAT registers the card zones and allows interactions with cards

Mat = Class{}

function Mat:init(id, x, y, type)
    -- player side top-row
    self.id = id
    self.x = x
    self.y = y
    self.type = type
    self.empty = true
    
end

function Mat:update(dt)

end


function Mat:render()
    love.graphics.setColor(1, 0, 0, 1)
    -- player side top-row
    love.graphics.rectangle('fill', self.x, self.y, CARD_WIDTH, CARD_HEIGHT)
    love.graphics.print(self.type, self.x, self.y - 20)
end