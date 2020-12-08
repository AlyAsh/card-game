Button = Class{}

function Button:init(x, y, text, phase)
    self.x = x
    self.y = y
    self.width = BUTTON_WIDTH
    self.height = BUTTON_HEIGHT
    self.text = text
    self.phase = phase

end

function Button:update(dt)
    if love.mouse.isDown(1) == true and
        love.mouse.getX() >= self.x and love.mouse.getX() <= self.x + self.width and
        love.mouse.getY() >= self.y and love.mouse.getY() <= self.y + self.height then

            -- mouse pressed
            gamePhase = self.phase
    end
end

function Button:render(dt)
    love.graphics.rectangle('line', self.x, self.y, self.width, self.height)
    love.graphics.print(self.text, self.x + 20, self.y + 10)
end
