--******************************************************************************************************
--** Copyright (c) 2025 Willem 'Jip' Wijnia
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

local Prefs = import("/lua/user/prefs.lua")
local LazyVarCreate = import("/lua/lazyvar.lua").Create

---@class ChatConfigurationPreferenceData
---@field font_size number
---@field fade_time number
---@field win_alpha number
---@field feed_background boolean
---@field feed_persists boolean
---@field notify_color number
---@field link_color number
---@field priv_color number
---@field allies_color number

local ChatColors = {
    'ffffffff',
    'ffff4242',
    'ffefff42',
    'ff4fff42',
    'ff42fff8',
    'ff424fff',
    'ffff42eb',
    'ffff9f42'
}

--- Size in pixels, requires separate UI scaling
ChatFontSize = LazyVarCreate(14)

--- Time in seconds
ChatFadeTime = LazyVarCreate(15)

--- Controls transparency of the window
ChatWindowAlpha = LazyVarCreate(1)

--- Controls whether the feed background is visible
ChatFeedBackground = LazyVarCreate(false)

--- Controls whether the feed remains persistent
ChatFeedPersists = LazyVarCreate(true)

--- Color of notify messages. It is an index-based color from the ChatColors table.
ChatNotifyColor = LazyVarCreate(8)

--- Color of messages that are clickable, such as messages with linked camera positions. It is an index-based color from the ChatColors table.
ChatLinkColor = LazyVarCreate(3)

--- Color of messages that are sent privately to you, like a whisper. It is an index-based color from the ChatColors table.
ChatPrivateColor = LazyVarCreate(2)

--- Color of messages that are sent by allies. It is an index-based color from the ChatColors table.
ChatAlliesColor = LazyVarCreate(2)

--- Responsible for loading from the preference file.
LoadFromPreferenceFile = function()
    ---@type ChatConfigurationPreferenceData?
    local options = Prefs.GetFromCurrentProfile("chatoptions")

    if not options then
        return
    end

    local fontSize = tonumber(options.font_size)
    if fontSize then
        ChatFontSize:Set(fontSize)
    end

    local fadeTime = tonumber(options.fade_time)
    if fadeTime then
        ChatFadeTime:Set(fadeTime)
    end

    local windowAlpha = tonumber(options.win_alpha)
    if windowAlpha then
        ChatWindowAlpha:Set(windowAlpha)
    end

    if options.feed_background == true then
        ChatFeedBackground:Set(true)
    else
        ChatFeedBackground:Set(false)
    end

    if options.feed_persist == true then
        ChatFeedPersists:Set(true)
    else
        ChatFeedPersists:Set(false)
    end

    local notifyColor = tonumber(options.notify_color)
    if notifyColor and ChatColors[notifyColor] then
        ChatNotifyColor:Set(notifyColor)
    end

    local linkColor = tonumber(options.link_color)
    if linkColor and ChatColors[linkColor] then
        ChatLinkColor:Set(linkColor)
    end

    local privColor = tonumber(options.priv_color)
    if privColor and ChatColors[privColor] then
        ChatPrivateColor:Set(privColor)
    end

    local alliesColor = tonumber(options.allies_color)
    if alliesColor and ChatColors[alliesColor] then
        ChatAlliesColor:Set(alliesColor)
    end
end

--- Responsible for saving to the preference file.
SaveToPreferenceFile = function()
    Prefs.SetToCurrentProfile("chatoptions", {
        font_size = ChatFontSize(),
        fade_time = ChatFadeTime(),
        win_alpha = ChatWindowAlpha(),
        feed_background = ChatFeedBackground(),
        feed_persist = ChatFeedPersists(),
        notify_color = ChatNotifyColor(),
        link_color = ChatLinkColor(),
        priv_color = ChatPrivateColor(),
        allies_color = ChatAlliesColor()
    })
end