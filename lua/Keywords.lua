--[[
    KEYWORD FUNCTIONS
]]


--[[ 
    Parses 'keyword' attribute of cardSprite; 
    keywords are in the format: keyword(attribute1; attribute2; ...)
]]
function parseKeywords(cardSprite)
    local args = {}
    local keywordString = tostring(cardSprite.keyword)

    local index = string.find(keywordString, '%(') -- word before the first '(' is the keyword 
    local subkeyword = string.sub(keywordString, 1, index - 1)
    cardSprite.actionkey = subkeyword
    

    local arguments = string.sub(keywordString, index + 1, #keywordString - 1) -- disregards parentheses

    for word in arguments:gmatch('[^;]+') do 
        args[#args + 1] = word -- create an attribute called 'args' that contains a variable number of arguments
    end

    cardSprite.args = args
end

--[[
    Runs the function 'actionkey' with arguments 'arg' belonging to 'cardSprite'
        Needs to contain all keywords
]]

function run(actionkey, args, cardSprite)
    
    -- Usage: increase(object, attribute, amount) [3 arguments]
    if actionkey == 'increase' then
        increase(args[1], args[2], args[3], cardSprite)
    end

end

-- Looks for cards that match [subtype] and increase its [attribute] by [amount], card effect sourced from [effectCard]
function increase(subtype, attribute, amount, effectCard)
    local keysIndex = 0
    -- Find attribute key
    for i = 1, #keys do
        if string.lower(keys[i]) == string.lower(attribute) then
            keysIndex = tostring(keys[i])
        end
    end
    
    -- For each cardSprite on the field
    for i = 1, #cardSprites do
        if cardSprites[i].subtype == subtype and cardSprites[i].set == true then

            -- Check if cardSprite is in effectCard's targets
            local targets = effectCard.targets
            if #targets == 0  then
                -- Add the first target
                effectCard.targets[1] = cardSprites[i].id
                -- Activate effect
                cardSprites[i][keysIndex] = cardSprites[i][keysIndex] + amount
                love.window.showMessageBox('Info','Added first target and increased ' .. keysIndex .. ' of ' .. cardSprites[i].name,'info')
            else
                love.window.showMessageBox('Info','Checking list of targets... (' .. #targets .. ')','info')
                -- Iterate through targets to check for a match
                local j = 1
                local skip = false
                while j < #targets + 1 do
                    love.window.showMessageBox('Info','Comparing ' .. effectCard.targets[j] .. ' with ' .. cardSprites[i].id,'info')
                    if effectCard.targets[j] == cardSprites[i].id then
                        -- Already in targets
                        love.window.showMessageBox('Info',cardSprites[i].name .. ' has already been affected','info')
                        skip = true
                    end
                    j = j + 1
                end

                if skip == false then
                    -- Add to targets
                    effectCard.targets[j] = cardSprites[i].id
                    love.window.showMessageBox('Info','Added ' .. cardSprites[i].name .. ' to targets','info')

                    -- Activate effect
                    cardSprites[i][keysIndex] = cardSprites[i][keysIndex] + amount
                    love.window.showMessageBox('Info','Increased ' .. keysIndex .. ' of ' .. cardSprites[i].name .. ' by ' .. amount,'info')
                end
            end
        end         
    end
end