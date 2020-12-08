WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

SIDEBAR = WINDOW_WIDTH * 2 / 3 + 30

CARD_WIDTH = 80
CARD_HEIGHT = 120

BUTTON_WIDTH = 100
BUTTON_HEIGHT = 30

-- Area below deck where card is drawn
CARD_START_X = 730
CARD_START_Y = 450

DECK_SIZE = 6
DECK_X = 730
DECK_Y = 300

DISCARD_X = 600
DISCARD_Y = 570

HAND_LIMIT = 4

REPUTATION = 0
POPULATION = 500

Class = require 'class'
require 'Button'
require 'Card'
require 'Keywords'
require 'Util'
require 'Mat'

-- Card database
deck = {}
hand = {}
discard = {}
drawn = 0
keys = {}
cardSprites = {}
cardZones = {}

-- Phase counters
unitsplaced = 0

-- Interaction variables
local challenger = {}
local defender = {}

-- Display strings
local outString = "Nothing to display\n"
local testString = ""

function love.load()
    -- Establish window settings
    love.window.setTitle('Card Game')
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        vsync = 1,
        resizable = true})

    -- Set Random Seed
    love.math.setRandomSeed(os.time())
    
    -- Create background canvas
    gameMat = love.graphics.newCanvas(WINDOW_WIDTH, WINDOW_HEIGHT)
    love.graphics.setCanvas(gameMat)
        love.graphics.clear()
        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(1, 0, 0, 0.2)
        -- opponent side bottom (L-R)
        love.graphics.rectangle('line', 200, 30, CARD_WIDTH, CARD_HEIGHT)
        love.graphics.rectangle('line', 300, 30, CARD_WIDTH, CARD_HEIGHT)
        love.graphics.rectangle('line', 400, 30, CARD_WIDTH, CARD_HEIGHT)
        love.graphics.rectangle('line', 500, 30, CARD_WIDTH, CARD_HEIGHT)
        love.graphics.rectangle('line', 600, 30, CARD_WIDTH, CARD_HEIGHT)
        -- opponent side top row (L-R)
        love.graphics.rectangle('line', 200, 180, CARD_WIDTH, CARD_HEIGHT)
        love.graphics.rectangle('line', 300, 180, CARD_WIDTH, CARD_HEIGHT)
        love.graphics.rectangle('line', 400, 180, CARD_WIDTH, CARD_HEIGHT)
        love.graphics.rectangle('line', 500, 180, CARD_WIDTH, CARD_HEIGHT)
        love.graphics.rectangle('line', 600, 180, CARD_WIDTH, CARD_HEIGHT)
    
        -- player side top row (L-R)
        --love.graphics.rectangle('fill', 200, 420, CARD_WIDTH, CARD_HEIGHT)
        --love.graphics.rectangle('fill', 300, 420, CARD_WIDTH, CARD_HEIGHT)
        --love.graphics.rectangle('fill', 400, 420, CARD_WIDTH, CARD_HEIGHT)
        --love.graphics.rectangle('fill', 500, 420, CARD_WIDTH, CARD_HEIGHT)
        love.graphics.rectangle('line', 600, 420, CARD_WIDTH, CARD_HEIGHT)
        
        -- player side bottom row (L-R)
        love.graphics.rectangle('line', 200, 570, CARD_WIDTH, CARD_HEIGHT)
        --love.graphics.rectangle('fill', 300, 570, CARD_WIDTH, CARD_HEIGHT)
        --love.graphics.rectangle('fill', 400, 570, CARD_WIDTH, CARD_HEIGHT)
        love.graphics.rectangle('line', 500, 570, CARD_WIDTH, CARD_HEIGHT)
        --love.graphics.rectangle('fill', 600, 570, CARD_WIDTH, CARD_HEIGHT)

        -- Deck Zone
        love.graphics.setColor(1, 0, 1, 0.5)
        love.graphics.rectangle('line', DECK_X, DECK_Y, CARD_WIDTH, CARD_HEIGHT)
        love.graphics.setColor(0, 0, 0, 1)

    love.graphics.setCanvas()

    -- Create buttons
    playButton = Button(WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2, 100, 30, 'PLAY', 'play')
    mainButton = Button(10, 10, 'Main Menu', 'main')
    resetButton = Button(10, 40, 'Reset', 'reset')
    drawButton = Button(10, 70, 'Draw', 'draw')
    setButton = Button(10, 100, 'Set', 'set')
    shuffleButton = Button(10, 130, 'Shuffle', 'shuffle')
    challengeButton = Button(10, 160, 'Challenge', 'challenge')
    endButton = Button(10, 190, 'End', 'end')
    actionButton = Button(10, 220, 'Action', 'actionWindow')
    effectsButton = Button(10, 250, 'Effects', 'effects')

    -- Create cardZones
    cardZones[1] = Mat("unit1", 300, 420, "Unit")
    cardZones[2] = Mat("unit2", 400, 420, "Unit")
    cardZones[3] = Mat("unit3", 500, 420, "Unit")
    cardZones[4] = Mat("building1", 300, 570, "Backrow")
    cardZones[5] = Mat("building2", 400, 570, "Backrow")
    cardZones[6] = Mat("building3", 500, 570, "Backrow")
    cardZones[7] = Mat("leader", 200, 420, "Leader")
    cardZones[8] = Mat("discard", DISCARD_X, DISCARD_Y, "Discard")

    -- use load function in read card database  
    load(deck, "cardsdb.txt")
    if deck == nil then
        testString = "Error loading deck"
    end

    -- draw a sprite for Deck and Discard
    deckSprite = Card(DECK_X, DECK_Y, CARD_WIDTH, CARD_HEIGHT)
    discardSprite = Card(DISCARD_X, DISCARD_Y, CARD_WIDTH, CARD_HEIGHT)

    -- shuffle cards
    shuffle(deck)

    -- initialize game state
    gameState = 'play'

    -- initialize game phase
    gamePhase = 'draw'

    -- initialize action
    gameAction = ''

end

function love.mousepressed(x, y, button)
    
    --[[
            LEFT CLICKING
    ]]
    if button == 1 then
        --[[ DECK ZONE]]
        if x >= DECK_X and x <= DECK_X + CARD_WIDTH and
            y >= DECK_Y and y <= DECK_Y + CARD_HEIGHT then
            --[[ DRAW PHASE ]]
            if gamePhase == 'draw' then
                if drawn < #deck then
                    outString = "Drawing..."
                else
                    love.window.showMessageBox('Deck Error','No more cards to draw','error')
                end
            end
        end

        --[[ DISCARD ZONE ]]
        if x >= DISCARD_X and x <= DISCARD_X + CARD_WIDTH and 
            y >= DISCARD_Y and y <= DISCARD_Y + CARD_HEIGHT then
            outString = "Cards in discard: " .. #discard
        end
        
        --[[ CARD ZONE ]]
        for i = #cardSprites, 1, -1 do
            if card_click(x, y, cardSprites[i]) and cardSprites[i].id ~= nil then
                --[[ DRAW PHASE -- left-clicking a card during the Draw Phase simply reads it]]
                if gamePhase == 'draw' then
                    outString = "Reading..."
                    cardSprites[i]:display_info()
                --[[ SET PHASE -- left-clicing a card that is NOT set and NOT discarded starts dragging it]]
                elseif gamePhase == 'set' then
                    if cardSprites[i].set == false and cardSprites[i].discard == false then
                        outString = "Dragging..."
                        gameAction = 'dragging'
                        cardSprites[i].dragging.active = true
                        cardSprites[i].dragging.diffX = x - cardSprites[i].x 
                        cardSprites[i].dragging.diffY = y - cardSprites[i].y
                    end
                    cardSprites[i]:display_info()
                --[[ CHALLENGE PHASE -- left-clicking a card during the challenges phase begins challenge?]]
                elseif gamePhase == 'challenge' then
                    outString = "Beginning challenge..."
                end
            end
        end

    end

    --[[
            RIGHT CLICKING
    ]]
    if button == 2 then
        -- [[ DECK ZONE ]]
        if x >= DECK_X and x <= DECK_X + CARD_WIDTH and
            y >= DECK_Y and y <= DECK_Y + CARD_HEIGHT then
            --[[ DRAW PHASE -- right-clicking Deck during Draw Phase begins Searching]]
            if gamePhase == 'draw' then
                outString = "Searching deck..."
            end
        end
        -- [[ DISCARD ZONE - Right-clicking Discard pile during any Phase begins Searching ]]
        if x >= DISCARD_X and x <= DISCARD_X + CARD_WIDTH and 
            y >= DISCARD_Y and y <= DISCARD_Y + CARD_HEIGHT then
                outString = "Searching discard..."
        end

        -- [[ CARD ZONE ]]
        for i = #cardSprites, 1, -1 do
            if card_click(x, y, cardSprites[i]) and cardSprites[i].id ~= nil then
                --[[ DRAW PHASE OR SET PHASE]]
                if gamePhase == 'draw' or gamePhase == 'set' then
                    cardSprites[i]:display_info()
                --[[ CHALLENGE PHASE - right-clicking a card during the challenges phase enables action ]]
                elseif gamePhase == 'challenge' then
                    outString = "Begin card action..."
                end
            end
        end
    end
end

function love.mousereleased(x, y, button)
    
    --[[
            LEFT-CLICKING
    ]]
    if button == 1 then
        --[[ DECK ZONE ]]
        if x >= DECK_X and x <= DECK_X + CARD_WIDTH and
            y >= DECK_Y and y <= DECK_Y + CARD_HEIGHT then
            --[[ DRAW PHASE ]]
            if gamePhase == 'draw' then  
                if drawn < #deck then
                    -- draw a card from the top of the deck
                    local index = #deck - drawn
                    outString = move(deck[index], 'deck', 'hand')
                    
                    -- Proceed to next phase
                    --gamePhase = 'set'
                end
            else
                love.window.showMessageBox('Phase Error','Cannot draw outside of Draw Phase','error')
            end
        end

        --[[ DISCARD ZONE ]]
        if x >= DISCARD_X and x <= DISCARD_X + CARD_WIDTH and 
            y >= DISCARD_Y and y <= DISCARD_Y + CARD_HEIGHT then
            --[[ Left-clicking the Discard zone during any phase lists discarded cards ]]
            outString = "Cards in discard: " .. #discard .. "\n"
            for i = 1, #discard do
                outString = outString .. discard[i].name .. "\n"        
            end
        end

        --[[ CARD ZONE ]]
        for i = #cardSprites, 1, -1 do
            if card_click(x, y, cardSprites[i]) and cardSprites[i].id ~= nil then
                --[[ DRAW PHASE -- left-clicking a card during the Draw Phase simply reads it]]
                if gamePhase == 'draw' then
                    cardSprites[i]:display_info()
                --[[ SET PHASE -- setting is dragging]]
                elseif gamePhase == 'set' then
                    cardSprites[i]:display_info()
                    -- Card should be draggable and not in discard pile
                    if cardSprites[i].dragging.active and cardSprites[i].discard == false then
                        -- 'Snap' carSprite to nearest cardZone    
                        if cardSprites[i].y >= 0 and cardSprites[i].y <= WINDOW_HEIGHT then
                            -- Card height can only be 30, 180, 420, 570
                            if cardSprites[i].y <= 90 then
                                cardSprites[i].x = math.floor(x / 100) * 100
                                cardSprites[i].y = 30
                            elseif cardSprites[i].y > 90 and cardSprites[i].y <= 340 then
                                cardSprites[i].x = math.floor(x / 100) * 100
                                cardSprites[i].y = 180
                            elseif cardSprites[i].y > 340 and cardSprites[i].y <= 500 then
                                cardSprites[i].x = math.floor(x / 100) * 100
                                cardSprites[i].y = 420
                            elseif cardSprites[i].y > 500 and cardSprites[i].y <= 660 then
                                cardSprites[i].x = math.floor(x / 100) * 100
                                cardSprites[i].y = 570
                            else
                                refresh_hand()
                            end
                        end


                        -- Compare cardSprite and cardZone
                        for j = #cardZones, 1, -1 do
                            if cardSprites[i].x == cardZones[j].x and cardSprites[i].y == cardZones[j].y then
                                -- cardZones must be empty
                                if cardZones[j].empty == false then
                                    love.window.showMessageBox('Card Place Error', 'There is already a card there','error')
                                -- cardZones must match type
                                elseif unitsplaced < 1 or cardSprites[i].type ~= 'Unit' then
                                    -- Implement costs if applicable
                                    if cardSprites[i].cost == '0' or cost(cardSprites[i]) then
                                        -- Place card
                                        if cardSprites[i].type == cardZones[j].type then
                                            cardZones[j].empty = false
                                            cardSprites[i].set = true

                                            -- Take note of limits
                                            if cardSprites[i].type == 'Unit' then
                                                unitsplaced = 1
                                            end

                                            refresh_hand()
                                        else
                                            love.window.showMessageBox('Card Place Error', 'Must place card in correct zone', 'error')
                                        end
                                    end
                                else
                                    love.window.showMessageBox('Card Place Error', 'Can only establish one Unit per turn', 'error')
                                end       
                            end
                        end

                        -- Finish dragging
                        cardSprites[i].dragging.active = false

                        -- Refresh hand
                        refresh_hand()

                        --[[ ACTIVATE PASSIVE CARD EFFECTS 
                        if cardSprites[i].type == 'Backrow' then
                            love.window.showMessageBox('Card Effect','Activating Card Effect','info')
                            parseKeywords(cardSprites[i])
                            run(cardSprites[i].actionkey, cardSprites[i].args)
                        end]]
                        
                    end
                --[[ CHALLENGES PHASE -- left-clicking a card during the Challenges Phase Selects it]]
                elseif gamePhase == 'challenge' then
                    cardSprites[i]:display_info()
                    -- Selecting a card that is ALREADY ACTIVE 
                    if cardSprites[i].active and cardSprites[i].set then
                        --[[ 
                                If a Defender has been assigned...
                        ]]
                        if defender.id ~= nil then
                            -- Selecting Active Defender /initiates/ the Challenge
                            if cardSprites[i].name == defender.name then
                                
                                outString = challenge(challenger,defender)
                                -- Reset values
                                challenger.active = false
                                challenger = {}
                                defender.active = false
                                defender = {}

                                refresh_hand()
                                gamePhase = 'actionWindow'

                            -- Selecting Challenger /cancels/ Challenge altogether
                            elseif cardSprites[i].name == challenger.name then
                                cardSprites[i].active = false
                                challenger.active = false
                                challenger = {}
                                defender.active = false
                                defender = {}
                                outString = "Challenge cancelled."
                            -- Selecting any another card /reassigns/ the Defender
                            else
                                defender = cardSprites[i]
                                outString = "Defender re-assigned to: " .. defender.name
                            end
                        --[[
                                If a Challenger has been assigned... 
                        ]]
                        elseif challenger.id ~= nil then
                            -- Selecting Challenger (again) /cancels/ the Challenge
                            if cardSprites[i].name == challenger.name then
                                cardSprites[i].active = false
                                challenger = {}
                                outString = "Challenge cancelled."
                            end
                        end
                    -- Selecting a card that is NOT ACTIVE
                    elseif cardSprites[i].active == false and cardSprites[i].set then
                        --[[
                                If a Challenger has NOT been assigned, card Selected is assigned as Challenger
                        ]]
                        if challenger.id == nil then
                            challenger = cardSprites[i]
                            outString = "Challenger selected: " .. challenger.name
                        --[[
                                If a Challenger has been assigned, card Selected is assigned as Defender
                        ]]
                        else
                            defender = cardSprites[i]
                            outString = "Defender selected: " .. defender.name
                        end
                        -- Activate card
                        cardSprites[i].active = true
                    end
                end
            end
        end

    end

    --[[
            RIGHT-CLICKING
    ]]
    if button == 2 then
        --[[ DECK ZONE ]]
        if x >= DECK_X and x <= DECK_X + CARD_WIDTH and
            y >= DECK_Y and y <= DECK_Y + CARD_HEIGHT then
            --[[ DRAW PHASE -- Right-clicking the Deck during Draw Phase allows Searching]]
            if gamePhase == 'draw' then

                search(deck)
                --gamePhase = 'set'
            else
                -- Right-clicking the Deck any other time displays how many cards are left
                outString = "Cards left: " .. #deck - drawn
            end
        end
        --[[ DISCARD ZONE ]]
        if x >= 600 and x <= 600 + CARD_WIDTH and 
            y >= 570 and y <= 570 + CARD_HEIGHT then
            --[[ Right-clicking Discard Zone during any Phase allows you to Return cards]]

                search(discard)
                gamePhase = 'actionWindow'

        end
        --[[ CARD ZONE ]]
        for i = #cardSprites, 1, -1 do
            if card_click(x, y, cardSprites[i]) and cardSprites[i].id ~= nil then
                --[[ DRAW PHASE - right-clicking a card during the Draw phase simply reads it ]]
                if gamePhase == 'draw' then
                    cardSprites[i]:display_info()
                --[[ SET PHASE - right-clicking a card during the set phase opens up actions ]]
                elseif gamePhase == 'set' then

                    cardSprites[i]:display_info()

                    local title = 'Card Action'
                    local message = 'Select action'
                    local buttons = {}

                    -- If card is set then it is already in play
                    if cardSprites[i].set == true then
                        buttons = {"Return to Hand","Return to Deck","Activate Effect", "Cancel", escapebutton = 4}

                        local buttonpressed = love.window.showMessageBox(title, message, buttons)

                        if buttonpressed == 1 then
                            move(cardSprites[i], 'play', 'hand')  
                        elseif buttonpressed == 2 then
                            move(cardSprites[i], 'play', 'deck')
                        end

                        -- Change gamePhase immediately to stop prompt 
                        gamePhase = 'actionWindow'
                        
                    -- Otherwise, it is still in the hand or in the discard pile
                    elseif cardSprites[i].set == false then
                        buttons = {"Return to Deck", "Activate Effect", "Cancel", escapebutton = 3}

                        local buttonpressed = love.window.showMessageBox(title, message, buttons)

                        if buttonpressed == 1 then
                            move(cardSprites[i], 'hand', 'deck')  
                        end
                        gamePhase = 'actionWindow'
                    end

                --[[ CHALLENGE PHASE -- Right-clicking cards in play initiates card actions ]]
                elseif gamePhase == 'challenge' then
                    -- Display card actions
                    if cardSprites[i].discard == false then
                        local title = 'Card Action'
                        local message = 'Choose an action for ' .. cardSprites[i].name
                        buttons = {"Activate effect", "Battle", "Discard", "Cancel", escapebutton = 4}

                        buttonpressed = love.window.showMessageBox(title,message,buttons)

                        if buttonpressed == 1 then
                            outString = "Effect activated!"
                            --TODO
                        elseif buttonpressed == 3 then
                            move(cardSprites[i], 'play', 'discard')
                        end
                    end
                    cardSprites[i]:display_info()
                end
            end
            -- Refresh hand
            refresh_hand()
        end
    end 
end

function love.update(dt)
    playButton:update(dt)
    mainButton:update(dt)
    resetButton:update(dt)
    drawButton:update(dt)
    setButton:update(dt)
    shuffleButton:update(dt)
    challengeButton:update(dt)
    endButton:update(dt)
    actionButton:update(dt)
    effectsButton:update(dt)

    -- Update cardSprites
    for i = 1, #cardSprites do
        cardSprites[i]:update(dt)
    end

    -- Update Deck and Discard sprites
    deckSprite:update(dt)
    discardSprite:update(dt)

    -- mouse position
    mouse_x = love.mouse.getX()
    mouse_y = love.mouse.getY()
    mousepos = "Mouse position " .. mouse_x .. ", " .. mouse_y
    
    -- Card dragging
    for i = #cardSprites, 1, -1 do
        if cardSprites[i].dragging.active then
            cardSprites[i].x = mouse_x - cardSprites[i].dragging.diffX
            cardSprites[i].y = mouse_y - cardSprites[i].dragging.diffY
        end
    end

    --[[ Hand Limit
    if gameAction == 'discard' and #hand > HAND_LIMIT then
        local title = "Exceeded Hand Limit"
        local message = "You have over " .. HAND_LIMIT .. " cards in your hand. Please discard " .. #hand - HAND_LIMIT .. "."
        local buttons = {}

        for i = 1, #hand do
            buttons[i] = hand[i].name
        end

        buttonpressed = love.window.showMessageBox(title, message, buttons)

        for i = 1, #buttons do
            if buttonpressed == i then
                -- Discard card(s)
                hand[i].discard = true
                hand[i].drawn = false
                
            end
        end

    end]] 
      

    -- Shuffle deck
    if gamePhase == 'shuffle' then
        shuffle(deck)
        gamePhase = 'draw'
    end

    -- End phase reset
    if gamePhase == 'end' then
        unitsplaced = 0
    end

    -- Activate all card effects
    if gamePhase == 'effects' then
        love.window.showMessageBox('Info','Game in Effects Phase','info')
        for i = #cardSprites, 1, -1 do
            if cardSprites[i].type == 'Backrow' and cardSprites[i].set == true then
                love.window.showMessageBox('Info','Activating Card Effect ' .. cardSprites[i].name,'info')
                parseKeywords(cardSprites[i])
                run(cardSprites[i].actionkey, cardSprites[i].args, cardSprites[i])
            end
        end
        gamePhase = 'set'
    end

    -- Action window
    if gamePhase == 'actionWindow' then
        for i = #cardSprites, 1, -1 do
            if cardSprites[i].discard == false and cardSprites[i].effect == true then
                love.window.showMessageBox('Card Effect','Would you like to activate the effect of ' .. cardSprites[i].name .. '?','info')
            end
        end
       
    end

    -- Game reset
    if gamePhase == 'reset' then
        reset()
        unitsplaced = 0
        gamePhase = 'draw'
        gameState = 'play'
    end

end


function love.draw()
    -- GAME STATE MAIN
    if gameState == 'main' then
        love.graphics.clear(0, 0, 0, 1)
        love.graphics.setColor(1, 1, 1, 1)
        -- print welcome message
        love.graphics.print('CARD GAME v1.0', WINDOW_WIDTH / 2, 30)
        -- display button
        playButton:render()
        
    -- GAME STATE PLAY
    elseif gameState == 'play' or gameState == 'reset' then
        -- setup field
        love.graphics.clear(1, 1, 1, 1)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setBlendMode("alpha", "premultiplied")
        love.graphics.draw(gameMat)

        -- render mat class
        for i, cardZone in ipairs(cardZones) do 
            cardZones[i]:render()
        end
        love.graphics.setColor(0, 0, 0, 1)

        -- display buttons
        mainButton:render()
        resetButton:render()
        drawButton:render()
        setButton:render()
        shuffleButton:render()
        challengeButton:render()
        endButton:render()
        actionButton:render()
        effectsButton:render()

        -- draws a line separating the last third of the window
        love.graphics.line(WINDOW_WIDTH * 2 / 3, 0, WINDOW_WIDTH * 2 / 3, WINDOW_HEIGHT)
        
        -- render cardSprites
        for i = 1, #cardSprites do  
            cardSprites[i]:render()
        end

        -- draw deck if there are still cards
        if drawn ~= #deck then
            deckSprite:render()
        end
        -- draw discard if there are cards discarded
        if #discard ~= 0 then
            discardSprite:render()
        end

        -- mouse pos
        love.graphics.print(mousepos, SIDEBAR, 5)

        -- game state
        love.graphics.print("gameState = " .. gameState, SIDEBAR, 25)

        -- game action
        love.graphics.print("gamePhase = " .. gamePhase, SIDEBAR, 40)

        -- Player points
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print("Reputation: " .. REPUTATION, 500, 330)
        love.graphics.print("Population: " .. POPULATION, 500, 360)

        -- display messages in side-bar
        if challenger.id ~= nil then
            love.graphics.print("Challenger: " .. challenger.name, SIDEBAR + 160, 5)
        end

        love.graphics.print("#cards drawn vs cards in deck: " .. drawn .. ", " .. #deck, SIDEBAR, 65)
        love.graphics.print("#cardSprites: " .. #cardSprites, SIDEBAR + 160, 85)
        for i = 1, #cardSprites do
            love.graphics.print(cardSprites[i].name .. ", x: " .. cardSprites[i].x .. ", y: " .. cardSprites[i].y, SIDEBAR + 160, 85 + i * 20)
        end
        love.graphics.print("#cards in hand: " .. #hand, SIDEBAR, 85)
        love.graphics.print("#cards in discard: " .. #discard, SIDEBAR, 105)
        love.graphics.print(testString, SIDEBAR, 140)
        love.graphics.print(outString, SIDEBAR, 160)
    end
    
end
