
local globalOptions = import('/lua/ui/lobby/lobbyOptions.lua').globalOpts
local teamOptions = import('/lua/ui/lobby/lobbyOptions.lua').teamOptions
local AIOptions = import('/lua/ui/lobby/lobbyOptions.lua').AIOpts

function MakeHeader(title, content, tooltipTitle, tooltipValue)
    return {
        type = 'header',
        title = title,
        content = content,
        tooltipTitle = tooltipTitle,
        tooltipValue = tooltipValue
    }
end

-- makes a title component
function MakeTitle(text)
    return {
        type = 'title',
        text = text
    }
end

-- makes a sub title component
function MakeSubTitle(text)
    return { 
        type = 'subtitle',
        text = text 
    }
end

-- makes a sub title component
function MakeText(text)
    return { 
        type = 'text',
        text = text 
    }
end

-- makes a spacer component
function MakeSpacer()
    return {
        type = 'spacer'
    }
end

-- makes an option component
function MakeOption(text, data, default)
    return {
        type = 'option',
        text = text,
        data = data,
        default = default
    }
end

function MakeOptions (unformatted)
    local formatted = { }
    for k, option in unformatted do 
        local text = option.label
        local data = option
        local default = option.default
        table.insert(formatted, MakeOption(text, data, default))
    end
    return formatted
end

-- returns a table of type:
-- {
--     {
--         type = title
--         text = string
--     }
--     {
--         type = option
--         option = {
--             ...
--         }
--     }
--     {
--         type = option
--         option = {
--             ...
--         }
--     }
--     ...
-- }
function TeamOptionsFormatted()
    local title = { MakeTitle('Team options') }
    local options = MakeOptions(teamOptions)
    return table.cat(title, options)
end

function GameOptionsFormatted()
    local title = { MakeTitle('Game options') }
    local options = MakeOptions(globalOptions)
    return table.cat(title, options)
end

function AIOptionsFormatted() 
    local title = { MakeTitle('AI options') }
    local options = MakeOptions(AIOptions)
    return table.cat(title, options)
end

function MapOptionsFormatted(scenario)
    local title = { MakeTitle('Map options') }
    local options = { }

    -- no scenario (map) can be chosen
    if scenario then 
        -- no _options.lua file can be defined for the scenario
        if scenario.options then 
            options = MakeOptions(scenario.options)
        else
            SPEW("Option Util: No options defined by scenario.")
        end
    else
        SPEW("Option Util: No scenario defined.")
    end
    return table.cat(title, options)
end

function ModOptionsFormatted(mods)

    -- returns a function that given an option, checks if the key matches.
    local function CheckForClash(option, key)
        return option.key == key
    end

    -- load in the options file for each mod
    local options = { }
    for k, mod in mods do 

        -- add in the subtitle
        table.insert(options, MakeSubTitle(mod.name .. " Options"))

        -- determine the path to the options file
        local directory = mod.location
        local file = 'mod_options.lua'
        local path = directory .. '/' .. file 

        -- does such a file exist?
        if DiskGetFileInfo(path) then
            -- try to retrieve the options
            local data = {}
            doscript(path, data)

            if data.options ~= nil then 

                -- go over the options, find out if there is a name clash with the team / game options
                for k, option in data.options do 

                    local key = option.key
                    local clashed = false 

                    -- if we haven't clashed already, check these options too
                    if not clashed then 
                        if table.predicate(teamOptions, CheckForClash, key) then
                            WARN("A mod option key clashes with a key from the team options: " .. key .. ". The option is not shown and not taken into account.")
                            clashed = true
                        end
                    end

                    -- if we haven't clashed already, check these options too
                    if not clashed then 
                        if table.predicate(globalOptions, CheckForClash, key) then
                            WARN("A mod option key clashes with a key from the global options: " .. key .. ". The option is not shown and not taken into account.")
                            clashed = true
                        end
                    end

                    -- if we haven't clashed already, check these options too
                    if not clashed then 
                        if table.predicate(AIOptions, CheckForClash, key) then
                            WARN("A mod option key clashes with a key from the AI options: " .. key .. ". The option is not shown and not taken into account.")
                            clashed = true
                        end
                    end

                    -- if we haven't clashed, consider it a valid option!
                    if not clashed then 
                        local text = option.label
                        local data = option
                        local default = option.default
                        table.insert(options, MakeOption(text, data, default))
                    end
                end
            end
        end
    end

    -- add in the title of the section
    local title = { MakeTitle('Mod options') }
    return table.cat(title, options)
end

function OptionsFormatted(scenario, mods)
    local teamOptionsFormatted = TeamOptionsFormatted()
    local gameOptionsFormatted = GameOptionsFormatted()
    local aIOptionsFormatted = AIOptionsFormatted()
    local mapOptionsFormatted = MapOptionsFormatted(scenario)
    local modOptionsFormatted = ModOptionsFormatted(mods)

    return table.concatenate(
        teamOptionsFormatted,
        gameOptionsFormatted,
        aIOptionsFormatted,
        mapOptionsFormatted,
        modOptionsFormatted
    )
end

function OptionsCorrected(entries, noContentMessage)
    local corrected = { }
    for k, entry in entries do 
        -- add in the entry itself
        table.insert(corrected, entry)

        -- check if a title has content, otherwise add in a message
        if entry.type == 'title' then 
            if not TitleHasContent(entries, k) then 
                table.insert(corrected, MakeText(noContentMessage))
            end
        end

        -- check if a subtitle has content, otherwise add in a message
        if entry.type == 'subtitle' then 
            if not SubtitleHasContent(entries, k) then 
                table.insert(corrected, MakeText(noContentMessage))
            end
        end
    end
    return corrected
end

function TitleHasContent(entries, index)
    local next = index + 1
    while entries[next] do  
        -- we count subtitles as content
        if entries[next].type == 'subtitle' then 
            return true
        end

        -- we count options as content
        if entries[next].type == 'option' then 
            return true
        end

        -- we 'count' headers as content?
        if entries[next].type == 'header' then
            WARN("UI: Headers should be at the top.")
            return true
        end

        -- we do not count titles as content
        if entries[next].type == 'title' then 
            return false 
        end

        -- look further
        if entries[next].type == 'spacer' then 
            next = next + 1
        end
    end

    -- end of the table, this entry has no content under it     
    return false
end

function SubtitleHasContent(entries, index)
    local next = index + 1
    while entries[next] do  
        -- we count options as content
        if entries[next].type == 'option' then 
            return true
        end

        -- we do not count subtitles as content
        if entries[next].type == 'subtitle' then 
            return false
        end

        -- we do not count titles as content
        if entries[next].type == 'title' then 
            return false 
        end

        -- look further
        if entries[next].type == 'spacer' then 
            next = next + 1
        end
    end

    -- end of the table, this entry has no content under it  
    return false
end