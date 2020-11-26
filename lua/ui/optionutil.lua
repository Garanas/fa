
-- INFORMATION ABOUT CHOICES -- 

-- Some code may feel hacky because there are a lot of previous unusual choices to the design. I'll
-- try to formulate some of them here.

-- ABOUT THE OPTION FORMAT -- 

-- There are two option formats present. They are both supported by the game and both in use
-- at the time of writing. Hence, we need to keep them both going.

-- format 1: The extensive format
-- {
--     default 	= 1,
--     label 		= "Commanders",
--     help 		= "Defines how many commanders must survive the onslaught.",
--     key 		= 'RainmakersCommanders',
--     pref	 	= 'RainmakersCommanders',
--     values 		= {
--         { text 	= "All must survive", help = "We leave no man behind.", key = 1, },		
--         { text 	= "One must survive", help = "The mission is all what matters, at any cost.", key = 2, },	
--     },	
-- },

-- format 2: The simple format
-- {
--     default = 1,
--     label = "<LOC zombies_0004>Vampire",
--     help = "<LOC zombies_0005>Recieve Mass and Energy cost of whatever you kill",
--     key = 'VampirePercentage1',
--     value_text = "%s",
--     value_help = "<LOC zombies_0006>%s times mass & energy vampire",
--     values = {
--         '0','0.25','0.5','0.75','1.0','1.25','1.5','1.75','2.0'
--     }
-- },

-- ABOUT THE GAME OPTIONS --

-- The game options that are set do not represent the index of the option, but the actual value. This is a bit
-- odd since we need the index for the tooltips and we can easily retrieve the value, given the index, but 
-- the reverse is not as easily accomplished.

-- We cannot change this into the corresponding indices because the game options values are _also_ used throughout
-- various files, including the lobby.lua file. E.g., it would require a hefty refactoring and that is a tad too much
-- work right now.

local GlobalOpts = import('/lua/ui/lobby/lobbyOptions.lua').globalOpts
local TeamOpts = import('/lua/ui/lobby/lobbyOptions.lua').teamOptions
local AIOpts = import('/lua/ui/lobby/lobbyOptions.lua').AIOpts

--- Creates an (combibox) option as expected in the map select manu.
-- @parm option
-- @parm gameOptions
-- @parm depth The depth of the element, analoge to <h1>, <h2>, etc html tags. A value of 1 is section, 2 is a sub section, 3 is a sub sub section, etc.
function MakeMapSelectOption(option, depth)
    option.type = 'option'
    option.depth = depth
    return option
end

--- Creates an (chosen) option as expected in the lobby.
-- @parm option
-- @parm gameOptions
-- @parm depth The depth of the element, analoge to <h1>, <h2>, etc html tags. A value of 1 is section, 2 is a sub section, 3 is a sub sub section, etc.
function MakeLobbyOption(option, gameOptions, depth)

    -- At the top of this file the format is laid out
    local function FindOptionInformationFormat1(gameOptions, option, information)
        local gameOption = gameOptions[option.key]
        if gameOption then 
            information.valueKey = gameOption
            -- game option is set, find the corresponding index
            for k, value in option.values do
                if value.key  == gameOption then 
                    information.text = value.text 
                    information.help = value.help 
                    information.index = k
                    break
                end
            end
        else
            -- game option is not set, use the default value
            information.index = option.default
            information.default = true 
            information.text = option.values[option.default].text
            information.help = option.values[option.default].help
            information.valueKey = option.values[option.default].key
        end
    end

    -- At the top of this file the format is laid out
    local function FindOptionInformationFormat2(gameOptions, option, information)
        local gameOption = gameOptions[option.key]
        if gameOption then 
            information.valueKey = gameOption
            -- game option is set, find the corresponding index
            for k, value in option.values do
                if value.key  == gameOption then 
                    information.index = k 
                    information.text  = LOCF(option.value_text, gameOption)
                    information.help  = LOCF(option.value_help, gameOption)
                    break
                end
            end
        else 
            -- game option is not set, use the default value
            information.index = option.default
            information.text  = LOCF(option.value_text, option.values[option.default])
            information.help  = LOCF(option.value_help, option.values[option.default])
            information.valueKey = option.values[option.default]
        end
    end

    local function FindOptionInformation(gameOptions, option, information )
        if option.value_help ~= nil then 
            FindOptionInformationFormat2(gameOptions, options, information)
        else 
            FindOptionInformationFormat1(gameOptions, options, information)
        end
    end

    local information = { }

    information.type      = 'option'
    information.depth     = depth
    information.label     = option.label
    information.optionKey = option.key

    FindOptionInformation(gameOptions, option, information)

    return information
end

function MakeSectionOption(option, depth)
    return {
        type = 'option',
        depth = 'depth',
        information = option
    }
end

function MakeSectionOptions(options, depth)
    local adjusted = { }
    for _, option in options do 
        table.insert(adjusted, MakeSectionOption(option, depth))
    end
    return adjusted
end

--- Creates a title element that can be used to relay a section
-- @parm text The text of the element.
-- @parm depth The depth of the element, analoge to <h1>, <h2>, etc html tags. A value of 1 is section, 2 is a sub section, 3 is a sub sub section, etc.
function MakeSectionTitle(text, depth)
    return {
        type = 'title',
        depth = depth,
        text = text
    }
end

--- Creates a text element that can be used to relay information
-- @parm text The text of the element.
-- @parm depth The depth of the element, analoge to <h1>, <h2>, etc html tags. A value of 1 is section, 2 is a sub section, 3 is a sub sub section, etc.
function MakeSectionText(text, depth)
    return { 
        type = 'text',
        text = text ,
        depth = depth
    }
end

--- Creates a bit of empty space.
function MakeSpacer()
    return {
        type = 'spacer'
    }
end

--- Creates a section that is can be used to check for validity
-- @parm title The title of the section
-- @parm options The options of the section
-- @parm depth the depth of the element, analoge to <h1>, <h2>, etc html tags. A value of 1 is section, 2 is a sub section, 3 is a sub sub section, etc.
function MakeSection(title, elements, subsections)
    return { 
        title = title,
        elements = elements, 
        subsections = subsections
    }
end

--- Cached team options, to prevent the constantly recomputation of them
local cachedTeamOptions = nil 

--- Retrieves the team options stored in a section
function TeamOptions(refresh)

    -- check if we computed these already
    if not refresh and cachedTeamOptions then 
        return cachedTeamOptions
    end

    -- construct the section, cache it and return it
    local title = 'Team options'
    local options = MakeSectionOptions(TeamOpts)
    local subsections = { }

    cachedTeamOptions = MakeSection(
        title, 
        options,
        subsections
    )

    return table.deepcopy(cachedTeamOptions)
end

--- Cached game options, to prevent the constantly recomputation of them
local cachedGameOptions = nil 

--- Retrieves the game options stored in a section
function GameOptions(refresh)

    -- check if we computed these already
    if not refresh and cachedGameOptions then 
        return table.deepcopy(cachedGameOptions)
    end
    
    -- construct the section, cache it and return it
    local title = 'Game options'  
    local options = MakeSectionOptions(GlobalOpts)
    local subsections = { }

    cachedGameOptions = MakeSection(
        title,
        options,
        subsections
    )

    return table.deepcopy(cachedGameOptions)
end

--- Cached AI options, to prevent the constantly recomputation of them
local cachedAIOptions = nil 

--- Retrieves the AI options stored in a section
function AIOptions(refresh) 

    -- check if we computed these already
    if not refresh and cachedAIOptions then 
        return table.deepcopy(cachedAIOptions)
    end

    -- construct the section, cache it and return it
    local title = 'AI options'
    local options = MakeSectionOptions(AIOpts)
    local subsections = { }

    cachedAIOptions = MakeSection(
        title,
        options,
        subsections
    )

    return table.deepcopy(cachedAIOptions)
end

--- Cached map options, to prevent the constantly recomputation of them
local cachedMapName = ""
local cachedMapOptions = nil 

--- Retrieves the map options stored in a section
function MapOptions(scenario, refresh)

    -- check if we computed these already
    local cacheID = scenario.name .. repr(scenario.map_version)
    if not refresh and (cacheID == cachedMapName) then
        return table.deepcopy(cachedMapOptions)
    end

    local title = 'Map options'
    local options = { }
    local subsections = { }

    -- no scenario (map) can be chosen
    if scenario then 
        options = MakeSectionOptions(scenario.options or { })
    else
        WARN("Option util: No scenario defined")
    end
    
    cachedMapName = cacheID
    cachedMapOptions = MakeSection(
        title,
        options,
        subsections
    )

    return table.deepcopy(cachedMapOptions)
end

function ModOptions(mods)

    local title = 'Mod options'
    local options = { }
    local subsections = { }

    local function FindOptionsOfMod(name, path)
        -- load in the options file
        local data = {}
        doscript(path, data)

        -- retrieve the options, make it backwards compatible with AI options file
        local title = name
        local options = MakeSectionOptions(data.options or data.AIOpts)
        local subsections = { }

        return MakeSection(title, options, subsections)
    end

    -- load in the options file of each mod
    for k, mod in mods do 

        local directory = mod.location

        -- determine the path to the options file
        local file = 'mod_options.lua'
        local path = directory .. '/' .. file 

        if DiskGetFileInfo(path) then
            table.insert(subsections, FindOptionsOfMod(mod.name, path))
        end

        -- determine the path to the backwards compatible AI options file
        local file = 'lua/ai/lobbyoptions/lobbyoptions.lua'
        local path = directory .. '/' .. file_old

        if DiskGetFileInfo(path) then
            table.insert(subsections, FindOptionsOfMod(mod.name, path))
        end
    end

    return table.deepcopy(MakeSection(
        title,
        options,
        subsections
    ))
end

function AllSections(scenario, mods, refresh)
    sections = { }
    table.insert(sections, TeamOptions(refresh))
    table.insert(sections, GameOptions(refresh))
    table.insert(sections, AIOptions  (refresh))
    table.insert(sections, MapOptions (scenario, refresh))
    table.insert(sections, ModOptions (mods, refresh))
    return sections
end

-- checks whether there are conflicting options
function CheckSections(sections)

    -- checks whether or not there are duplicate keys and if not reports them
    local function CheckDuplicateKeys(sections, keys)
        -- find duplicate options
        for _, section in sections do 
            -- for each option, add in the key
            for _, element in section.elements do 
                if element.type == 'option' then 
                    option = element.information
                    if keys[option.key] then
                        WARN ("Option util: Found a duplicate key " .. option.key .. " in section " .. section.title ". This may cause unexpected behavior.")
                    end
                    keys[option.key] = true  
                    
                end
            end

            -- for each section, add in their subsections keys
            CheckDuplicateKeys(section.subsections, keys)
        end
    end

    -- checks whether or not all default values are sane and if not reports them
    local function CheckDefaultValues(sections)
        for _, section in sections do 
            for k, element in section.elements do
                if element.type == 'option' then 
                    option = element.information

                    -- check if we have a default value
                    if not option.default then 
                        option.default = 1 
                        WARN("Option " .. option.key .. " does not have a default index defined.")
                    end 
            
                    -- check if we have a number
                    local notANumber = type(option.default) ~= "number"
                    if notANumber then 
                        WARN("Option " .. option.key .. " has a default index which is not a number: " .. to_string(option.default))
                    end
            
                    -- check if the number is in range
                    local outOfRange = option.default <= 0 or option.default > table.getn(option.values)
                    if outOfRange then
                        WARN("Option " .. option.key .. " has a default index which is out of bounds: " .. to_string(option.default))
                    end
            
                    -- check if we have an integral number
                    local notIntegral = math.floor(option.default) ~= option.default 
                    if notIntegral then 
                        WARN("Option " .. option.key .. " has a default index which is not an integral number " .. to_string(option.default))
                    end
            
                    -- check if we have a valid default value
                    local valid = not (notANumber or outOfRange or notIntegral)
                    if not valid then 
            
                        -- developer may have seen the default value as the value, instead of the index that holds the value. Try to fix it!
                        local replacementValue = 1
                        for k, v in option.values do
                            if v.key == option.default then
                                -- Huzzah, we found it!
                                replacementValue = k
                                break
                            end
                        end
            
                        option.default = replacementValue
                    end
                end
            end

            -- recurse into children
            CheckDefaultValues(section.subsections)
        end
    end

    local keys = { }
    CheckDuplicateKeys(sections, keys)
    CheckDefaultValues(sections)

    return sections
end

--- Deep-copies the sections into a separate instance.
-- @param sections The sections to be deep-copied.
function CopySections(sections)
    return table.deepcopy(sections)
end

--- Trims out sections that are empty, e.g., for maps or mods with no options.
-- @param sections Sections to trim.
function TrimEmptySections(sections)
    local adjusted = { }

    for _, section in sections do
        local hasElements = not table.empty(section.elements)
        local hasSubsections = not table.empty(section.subsections)
        if hasElements or hasSubsections then 
            section.subsections = TrimEmptySections(section.subsections)
            table.insert(adjusted, section)
        end
    end

    return adjusted
end

--- Notifies that sections are empty, e.g., for maps or mods with no options.
-- @param sections Sections to trim.
function MarkEmptySections(sections)
    for _, section in sections do
        if table.empty(section.subsections) then 
            section.subsections = { }
            table.insert(section.subsections, MakeSectionText("No (default) options", section.depth))
        else 
            section.subsections = MarkEmptySections(section.subsections)
        end
    end

    return sections
end

--- Trims out options that have their default value set in the lobby. Requires you to run the function
-- MarkDefaultSections(sections, gameOptions) prior.
-- @param sections Sections to trim.
function TrimDefaultOptions(sections)
    for _, section in sections do
        -- keep the options that are not default
        local adjusted = { }
        for _, element in section.elements do
            if element.type == 'option' then
                if not element.isDefaultInLobby then 
                    table.insert(adjusted, element)
                end
            else
                table.insert(adjusted, element)
            end
        end

        section.elements = adjusted 

        section.subsections = TrimDefaultOptions(section.subsections)
    end

    return sections
end

--- Marks options that have their default value set.
-- @param sections Sections to check for default options.
-- @param gameOptions The current game options set in the lobby.
function MarkDefaultSections(sections, gameOptions)
    local function IsDefaultOption(option, gameOptions) 
        -- retrieve the default value, compare it with the one in the game options
        local defValue = option.values[option.default].key or option.values[option.default]
        return defValue == gameOptions[option.key]
    end

    for _, section in sections do 
        -- adjust the options accordingly
        for _, element in section.elements do
            if element.type == 'option' then 
                element.isDefaultInLobby = IsDefaultOption(element.information, gameOptions)
            end
        end

        -- apply recursively
        MarkDefaultSections (section.subsections, gameOptions)
    end

    return sections
end

function PrepareTooltipsSections(sections, gameOptions)

end

--- Flattens the sections into a list of elements that can be used as information boxes and / or combi boxes.
-- @param sections Sections generated from a set of options.
-- @param hideEmptySections Whether or not empty sections will have a message stating there are no (changed) options.
-- @param dept The depth of the current section - can be ignored in the initial call.
function FormatSections(sections, depth)

    depth = depth or 1

    local formatted = { }
    for _, section in sections do 

        local countElements = table.getn(section.element)
        local countSubsections = table.getn(section.subsections)

        -- add in the title if we have options, subsections or if we want to show everything
        if (not hideEmptySections) or countElements > 0 or countSubsections > 0 then 
            table.insert(formatted, MakeSectionTitle(section.title, depth))
        end

        -- add in a bit of text saying that there are no options
        if (not hideEmptySections) and countElements == 0 and countSubsections == 0  then 
            table.insert(formatted, MakeSectionText("There are no (changed) options", depth))
        end

        -- add in all potential options
        for k, option in section.elements do 
            table.insert(formatted, MakeLobbyOption(option, depth + 1))
        end

        -- process subsections
        local subFormatted = FormatSections(section.subsections, hideEmptySections)
        for _, formattee in subFormatted do 
            table.insert(formatted, formattee)
        end
    end

    return formatted;
end

function FormatToLobbyOptions(sections, gameOptions, hideEmptySections, depth)

    -- we do not expect this value to be set in the first iteration
    depth = depth or 1

    local formatted = { }
    for _, section in sections do 

        local countElements = table.getn(section.options)
        local countSubsections = table.getn(section.subsections)

        -- add in the title if we have elements, subsections or if we want to show everything
        if (not hideEmptySections) or countElements > 0 or countSubsections > 0 then 
            table.insert(formatted, MakeSectionTitle(section.title, depth))
        end

        -- add in a bit of text saying that there are no options
        if (not hideEmptySections) and countElements == 0 and countSubsections == 0  then 
            table.insert(formatted, MakeSectionText("There are no (changed) options", depth))
        end

        -- add in all potential options
        for k, option in section.options do 
            table.insert(formatted, MakeOption(option, depth))
        end

        -- process subsections
        local subFormatted = FormatSections(section.subsections, gameOptions, hideEmptySections, depth + 1)
        for _, formattee in subFormatted do 
            table.insert(formatted, formattee)
        end
    end

    return formatted;
end

function AddTooltipsToFormatted(formatted, gameOptions) 

    for _, formattee in formatted do 
        if formattee.type == 'option' then 
        end
    end

end

-- function ModOptionsFormatted(mods)

--     local options = { }

--     -- returns a function that given an option, checks if the key matches.
--     local function CheckForClash(option, key)
--         return option.key == key
--     end

--     local function FindOptionsOfMod(path)

--         -- does such a file exist?
--         if DiskGetFileInfo(path) then

--             -- try to retrieve the options
--             local data = {}
--             doscript(path, data)

--             -- find the options, keep backwards compatibility in mind
--             local unformattedOptions = data.options or data.AIOpts
--             if unformattedOptions ~= nil then 

--                 -- go over the options, find out if there is a name clash with the team / game options
--                 for k, option in unformattedOptions do 

--                     local key = option.key
--                     local clashed = false 

--                     -- if we haven't clashed already, check these options too
--                     if not clashed then 
--                         if table.predicate(teamOptions, CheckForClash, key) then
--                             WARN("A mod option key clashes with a key from the team options: " .. key .. ". The option is not shown and not taken into account.")
--                             clashed = true
--                         end
--                     end

--                     -- if we haven't clashed already, check these options too
--                     if not clashed then 
--                         if table.predicate(globalOptions, CheckForClash, key) then
--                             WARN("A mod option key clashes with a key from the global options: " .. key .. ". The option is not shown and not taken into account.")
--                             clashed = true
--                         end
--                     end

--                     -- if we haven't clashed already, check these options too
--                     if not clashed then 
--                         if table.predicate(AIOptions, CheckForClash, key) then
--                             WARN("A mod option key clashes with a key from the AI options: " .. key .. ". The option is not shown and not taken into account.")
--                             clashed = true
--                         end
--                     end

--                     -- if we haven't clashed, consider it a valid option!
--                     if not clashed then 
--                         local text = option.label
--                         local data = option
--                         local default = option.default
--                         table.insert(options, MakeOption(text, data, default))
--                     end
--                 end
--             end
--         end
--     end

--     -- load in the options file for each mod
--     for k, mod in mods do 
--         -- add in the subtitle
--         table.insert(options, MakeSubTitle(mod.name))

--         -- determine the path to the options file
--         local directory = mod.location
--         local file = 'mod_options.lua'
--         local path = directory .. '/' .. file 
--         FindOptionsOfMod(path)

--         -- determine the path to the backwards compatible AI options file
--         local file_old = 'lua/ai/lobbyoptions/lobbyoptions.lua'
--         local path = directory .. '/' .. file_old
--         FindOptionsOfMod(path)
--     end

--     -- add in the title of the section
--     local title = { MakeSectionTitle('Mod options') }
--     return table.cat(title, options)
-- end

-- --- Retrieves all the available options stored in sections
-- -- @param scenario The current scenario, for map options
-- -- @param mods The current selected mods, for mod options
-- function AllOptions(scenario, mods)
--     local sections = { }
    
-- end

function ValidateOptions(options)

end

-- function OptionsCorrectedWithMessage(entries, noContentMessage)
--     local corrected = { }
--     for k, entry in entries do 
--         -- add in the entry itself
--         table.insert(corrected, entry)

--         -- check if a title has content, otherwise add in a message
--         if entry.type == 'title' then 
--             if not TitleHasContent(entries, k) then 
--                 table.insert(corrected, MakeSectionText(noContentMessage))
--             end
--         end

--         -- check if a subtitle has content, otherwise add in a message
--         if entry.type == 'subtitle' then 
--             if not SubtitleHasContent(entries, k) then 
--                 table.insert(corrected, MakeSectionText(noContentMessage))
--             end
--         end
--     end
--     return corrected
-- end

-- function OptionsCorrectedWithRemoval(entries)
--     local previous = entries
--     local corrected = { }

--     -- allows us to recursively remove sections and subsections
--     local removing = true 
--     while removing do 

--         -- start off clean
--         corrected = { }

--         -- assume this is the last iteration
--         removing = false
--         for k, entry in previous do 
--             -- check if a title has content, keep it
--             if entry.type == 'title' then 
--                 if TitleHasContent(previous, k) then 
--                     table.insert(corrected, entry)
--                 else
--                     -- check again, see if some title now has no elements under it
--                     removing = true
--                 end
--             end

--             -- check if a subtitle has content, keep it
--             if entry.type == 'subtitle' then 
--                 if SubtitleHasContent(previous, k) then 
--                     table.insert(corrected, entry)
--                 else
--                     -- check again, see if some title now has no elements under it
--                     removing = true
--                 end
--             end

--             -- add in everything else
--             if not (entry.type == 'title' or entry.type == 'subtitle') then
--                 table.insert(corrected, entry)
--             end
--         end

--         -- switch it up
--         previous = corrected
--     end
--     return corrected
-- end

-- function TitleHasContent(entries, index)
--     local next = index + 1
--     while entries[next] do  
--         -- we count subtitles as content
--         if entries[next].type == 'subtitle' then 
--             return true
--         end

--         -- we count options as content
--         if entries[next].type == 'option' then 
--             return true
--         end

--         -- we 'count' headers as content?
--         if entries[next].type == 'header' then
--             WARN("UI: Headers should be at the top.")
--             return true
--         end

--         -- we do not count titles as content
--         if entries[next].type == 'title' then 
--             return false 
--         end

--         -- look further
--         if entries[next].type == 'spacer' or entries[next].type == 'presets' then 
--             next = next + 1
--         end
--     end

--     -- end of the table, this entry has no content under it     
--     return false
-- end

-- function SubtitleHasContent(entries, index)
--     local next = index + 1
--     while entries[next] do  
--         -- we count options as content
--         if entries[next].type == 'option' then 
--             return true
--         end

--         -- we do not count subtitles as content
--         if entries[next].type == 'subtitle' then 
--             return false
--         end

--         -- we do not count titles as content
--         if entries[next].type == 'title' then 
--             return false 
--         end

--         -- look further
--         if entries[next].type == 'spacer' or entries[next].type == 'presets' then 
--             next = next + 1
--         end
--     end

--     -- end of the table, this entry has no content under it  
--     return false
-- end

-- -- FORMATTING --

-- -- TO BE REMOVED
-- function MakeOptions (unformatted)
--     local formatted = { }
--     for k, option in unformatted do 
--         local text = option.label
--         local data = option
--         local default = option.default
--         table.insert(formatted, MakeOption(text, data, default))
--     end
--     return formatted
-- end