--[[
    Stores utility functions used by HISTORIA CARD GAME.
]]

require 'Card'


-- Loads a database into an existing table
function load(table, pathtofile)
    local i = 0
    local endsearch = false
    for line in love.filesystem.lines(pathtofile) do
        -- Read first line as 'keys'
        if not endsearch then
            for word in line:gmatch('[^,]+') do
                keys[#keys + 1] = word
            end
            endsearch = true  
        -- Read the rest of the lines as cardinfo
        else
            local cardinfo = {}
            for word in line:gmatch('[^,]+') do
                cardinfo[#cardinfo + 1] = word 
            end

            -- Combine key and card info
            table[i] = {}
            for j = 1, #keys do
                table[i][keys[j]] = cardinfo[j]
                -- also include that it has not been drawn
            end
            table[i].drawn = false
            
        end
        i = i + 1
    end
    return table, keys
end

--[[ Calculates and implements cost
        Costs are always in the form digit-character, e.g. '500p'
        where p = population, r = reputation, etc.
]]
function cost(cardSprite)
    local cost = string.match(cardSprite.cost, "%d+")
    local key = string.match(cardSprite.cost, "%a+")

    if key == 'p' then
        buttons = {"OK", "Cancel", escapebutton = 2}
        local buttonpressed = love.window.showMessageBox('Info','You are about to pay ' .. cost .. ' population points. Proceed?', buttons)
        if buttonpressed == 1 then
            POPULATION = POPULATION - cost
            return true
        else
            return false
        end
    end
end

-- Employ the Fisher-Yates shuffle to shuffle cards in table
function shuffle(cards)
    
    for i = 1, #cards - 1 do
        local r = love.math.random(i, #cards)
        -- Make sure only cards that have not been drawn are shuffled
        if cards[i].drawn == false and cards[r].drawn == false then
            cards[i], cards[r] = cards[r], cards[i]
        end
    end

end

-- Checks if x, y is within cardSprite
function card_click(x, y, cardSprite)
    if x >= cardSprite.x and x <= cardSprite.x + CARD_WIDTH and
        y >= cardSprite.y and y <= cardSprite.y + CARD_HEIGHT then
            return true
    else
        return false
    end
end

-- Searches a table of cards and lists all of its contents
function search(table)

    local location = ''
    local buttons = {"Cancel", escapebutton = 1}
    local index = 0 
    -- Create buttons out of cards in table
    for i = 1, #table do
        -- Make sure the card is not in your hand (for deck) or is discarded (for discard)
        if table[i].drawn == false then
            buttons[#buttons + 1] = table[i].name
            location = 'deck'
        elseif table[i].discard == true then
            buttons[#buttons + 1] = table[i].name
            location = 'discard'
        end 
    end
    

    local buttonpressed = love.window.showMessageBox('Search', 'Select a card', buttons)

    -- Iterate through the buttons
    for i = #buttons, 1, -1 do

        -- If a certain button is pressed
        if buttonpressed == i and buttonpressed ~= 1 then

            for j = 1, #table do 
                if table[j].name == buttons[i] then
                    index = j
                end
            end

            -- If it comes from the deck
            if location == 'deck' then
                buttons2 = {"Hand", "Cancel", escapebutton = 2}

                local buttonpressed2 = love.window.showMessageBox('Return to', 'Select location to move ' .. table[index].name, buttons2)

                if buttonpressed2 == 1 then
                    move(table[index], 'deck', 'hand')
                end

            -- If it comes from the discard pile
            elseif location == 'discard' then
                buttons2 = {"Hand", "Deck", "Cancel", escapebutton = 3}

                local buttonpressed2 = love.window.showMessageBox('Return to', 'Select location to move ', buttons2)
            
                if buttonpressed2 == 1 then
                    move(table[index], location, 'hand')
                elseif buttonpressed2 == 2 then
                    move(table[index], location, 'deck')
                    
                end
            else
                love.window.showMessageBox('Info','location: ','info')
            end


            -- Search the source table
            for j = 1, #table do
                -- to find a match for the button and send it
                if buttons[i] == table[j].name then
                    -- either to the Hand
                    if buttonpressed2 == 1 then
                        move(table[j], table, hand)
                    -- or to the Deck
                    elseif buttonpressed2 == 2 then
                        move(table[j], table, deck)
                    end
                end
            end

        end
    end
end


-- Handles moving cards from deck, discard, cardzone
function move(cardSprite, fromLocation, toLocation)

    -- Get comparable deck index
    local index = 0
    for i = 1, #deck do
        if cardSprite.id == deck[i].id then
            index = i
        end
    end
    -- Get comparable cardSprites index
    local spriteIndex = 0
    for i = 1, #cardSprites do
        if cardSprite.id == cardSprites[i].id then
            spriteIndex = i
        end
    end
    -- Get comparable hand index
    local handIndex = 0
    for i = #hand, 1, -1 do
        if hand[i].id == cardSprite.id then
            handIndex = i
        end
    end


    -- We can make assumptions about whether a cardSprite is drawn, set, or discarded

    -- [[ FROM HAND ]]
    if fromLocation == 'hand' then

        cardSprite.drawn = true
        cardSprite.set = false
        cardSprite.discard = false
        
        -- Remove cardSprite from hand array
        table.remove(hand, handIndex)

    --[[ FROM DECK ]]
    elseif fromLocation == 'deck' then

        deck[index].drawn = true
        deck[index].set = false
        deck[index].discard = false
        
    --[[ FROM DISCARD ]]
    elseif fromLocation == 'discard' then
        cardSprite.drawn = true
        cardSprite.set = false
        cardSprite.discard = false

        -- Remove card from the discard array
        
        for i = #discard, 1, -1 do 
            if discard[i].id == cardSprite.id then
                table.remove(discard, i)
            end
        end

    --[[ FROM PLAY ]]
    elseif fromLocation == 'play' then
        cardSprite.drawn = true
        cardSprite.set = false
        cardSprite.discard = false
        -- Search cardZone where cardSprite is and free it
        for i = #cardZones, 1, -1 do
            if cardZones[i].x == cardSprite.x then
                cardZones[i].empty = true
            end
        end
    end

    --[[ TO HAND ]]
    if toLocation == 'hand' then
        -- If card is moved from the deck, it does not yet have a cardSprite
        if fromLocation == 'deck' then
            -- create cardSprite in arbitrary start location
            cardSprites[#cardSprites + 1] = Card(CARD_START_X, CARD_START_Y, CARD_WIDTH, CARD_HEIGHT)

            -- load information onto generated cardSprite
            local info = deck[index]
            cardSprites[#cardSprites]:load_info(keys, info)
            cardSprites[#cardSprites]:display_info()

            -- record that card has been drawn and not discarded
            deck[index].drawn = true
            cardSprites[#cardSprites].drawn = true
            cardSprites[#cardSprites].discard = false
            
            -- Add card to hand
            hand[#hand + 1] = cardSprites[#cardSprites]

            -- but do not set
            cardSprites[#cardSprites].set = false
        else
            cardSprite.drawn = true
            cardSprite.set = false

            -- Add to hand array
            hand[#hand + 1] = cardSprite
        end

    --[[ TO DECK ]]
    elseif toLocation == 'deck' then

        deck[index].drawn = false
        deck[index].set = false

        -- Un-draw cardSprite
        table.remove(cardSprites, spriteIndex)

    
    --[[ TO DISCARD ]]
    elseif toLocation == 'discard' then
        cardSprite.drawn = true
        cardSprite.set = false
        cardSprite.discard = true
        discard[#discard + 1] = cardSprite

        -- Move cardSprite
        cardSprite.x = DISCARD_X
        cardSprite.y = DISCARD_Y

    --[[ TO PLAY ]]
    elseif toLocation == 'play' then
        local type = cardSprite.type
        for i = 1, #cardZones do
            if type == cardZones[i].type and cardZones[i].empty == true then
                cardSprite.x = cardZones[i].x
                outString = "Established " .. cardSprite.name .. " in " .. cardZones[i].type .. " zone."
            end
        end
    end

    refresh_hand()
    outString = "Moved " .. cardSprite.name .. " from " .. fromLocation .. " to " .. toLocation

    return outString

end

-- Refreshes hand
function refresh_hand()

    -- Clear hand
    for i = #hand, 1, -1 do
        table.remove(hand, i)
    end

    -- Re-populate hand array with cards drawn from the deck but not in play or discarded
    for i = #cardSprites, 1, -1 do
        if cardSprites[i].drawn == true and cardSprites[i].set == false and cardSprites[i].discard == false then
            hand[#hand + 1] = cardSprites[i]
        elseif cardSprites[i].discard == true then
            -- Render discard pile
            cardSprites[i].x = DISCARD_X
            cardSprites[i].y = DISCARD_Y
        end
    end

    -- Re-render hand in correct position
    for i = #hand, 1, -1 do
        if i < 4 then
            hand[i].x = 800 + i * 90
            hand[i].y = 430
        elseif i >= 4 then
            hand[i].x = 800 + (i - 3) * 90
            hand[i].y = 560
        end
    end 

    -- Refesh drawn counter
    drawn = 0
    for i = #deck, 1, -1 do
        if deck[i].drawn == true then
            drawn = drawn + 1
        end
    end

    -- Refresh discard pile
    for i = #deck, 1, -1 do
        if deck.discard == true then
            discard[#discard + 1] = deck
        end
    end

end

-- Resets the game
function reset()

    -- Remove all cardSprites
    for i = #cardSprites, 1, -1 do
        table.remove(cardSprites, i)
    end

    -- Empty all cardZones
    for i = 1, #cardZones do
        cardZones[i].empty = true
    end

    -- Empty hand
    for i = #hand, 1, -1 do
        table.remove(hand, i)
    end

    -- Empty discard
    for i = #discard, 1, -1 do
        table.remove(discard, i)
    end


    -- Mark all cards as 'not drawn' 'not set'
    for i = #deck, 1, -1 do
        deck[i].drawn = false
        deck[i].set = false
    end

    -- Shuffle deck
    shuffle(deck)

    -- reset drawn counter
    drawn = 0

    -- reset points
    POPULATION = 500
    REPUTATION = 0

end

-- Handles all the Challenge functions
function challenge(challenger, defender)
    local winner = {}
    local loser = {}
    local outString = ''

    if challenger.type ~= defender.type then
        love.window.showMessageBox('Challenge Error','Cannot initiate challenge between cards of dissimilar type','error')
    else
        local diff = tonumber(challenger.strength) - tonumber(defender.strength)
        if diff > 0 then
            winner = challenger
            loser = defender
            REPUTATION = REPUTATION + diff
        elseif diff == 0 then
            winner = challenger
            loser = defender
        else
            winner = defender
            loser = challenger
            POPULATION = POPULATION + diff
        end

        -- clear loser's cardZone
        for i = 1, #cardZones do
            if loser.x == cardZones[i].x then
                cardZones[i].empty = true
            end
        end

        -- Discard loser's cardSprite
        for i = 1, #cardSprites do
            if loser.id == cardSprites[i].id then
                move(cardSprites[i], 'play', 'discard')
                cardSprites[i].active = false
            end
        end

        -- Deactivate winner
        for i = 1, #cardSprites do
            if winner.id == cardSprites[i].id then
                cardSprites[i].active = false
            end
        end

        outString = challenger.name .. "(" .. challenger.strength .. ") vs " .. defender.name .. "(" .. defender.strength .. ") Winner: " .. winner.name

        refresh_hand()

    end
    
    return outString
end