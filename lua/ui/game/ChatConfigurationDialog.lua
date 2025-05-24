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

local UIUtil = import("/lua/ui/uiutil.lua")
local Prefs = import("/lua/user/prefs.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local CreateHorizontalDivider = import("/lua/ui/controls/horizontalDivider.lua").CreateHorizontalDivider
local Window = import("/lua/maui/window.lua").Window
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

local ChatWindowTextures = {
    tl = UIUtil.SkinnableFile('/game/panel/panel_brd_ul.dds'),
    tr = UIUtil.SkinnableFile('/game/panel/panel_brd_ur.dds'),
    tm = UIUtil.SkinnableFile('/game/panel/panel_brd_horz_um.dds'),
    ml = UIUtil.SkinnableFile('/game/panel/panel_brd_vert_l.dds'),
    m = UIUtil.SkinnableFile('/game/panel/panel_brd_m.dds'),
    mr = UIUtil.SkinnableFile('/game/panel/panel_brd_vert_r.dds'),
    bl = UIUtil.SkinnableFile('/game/panel/panel_brd_ll.dds'),
    bm = UIUtil.SkinnableFile('/game/panel/panel_brd_lm.dds'),
    br = UIUtil.SkinnableFile('/game/panel/panel_brd_lr.dds'),
    borderColor = 'ff415055',
}

---@type UIChatConfigurationDialog | nil
local ChatConfigurationDialogInstance = nil

---@class UIChatConfigurationDialog : Window
---@field DragHandleTL Bitmap
---@field DragHandleTR Bitmap
---@field DragHandleBL Bitmap
---@field DragHandleBR Bitmap
ChatConfigurationDialog = Class(Window) {

    ---@param self UIChatConfigurationDialog
    ---@param parent Control
    __init = function(self, parent)

        -- name all fields to make it easier to understand
        local title = LOC('<LOC chat_0008>Chat Options')
        local icon = nil
        local pin = nil
        local config = nil
        local lockSize = true
        local lockPosition = false
        local prefId = 'chat_config'
        local defaultPosition = nil

        Window.__init(self, parent, title, icon, pin, config, lockSize, lockPosition, prefId, defaultPosition, ChatWindowTextures)

        -- populate drag handles
        self.DragHandleTL = Bitmap(self, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-ul_btn_up.dds'))
        self.DragHandleTR = Bitmap(self, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-ur_btn_up.dds'))
        self.DragHandleBL = Bitmap(self, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-ll_btn_up.dds'))
        self.DragHandleBR = Bitmap(self, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-lr_btn_up.dds'))

        self.Divider = CreateHorizontalDivider(self, 25, 'ff000000')
    end,

    ---@param self UIChatConfigurationDialog
    ---@param parent Control
    __post_init = function(self, parent)
        LayoutHelpers.LayoutFor(self)
            :Width(500)
            :End()

        LayoutHelpers.LayoutFor(self.DragHandleTL)
            :AtLeftTopIn(self, -24, -8)
            :Over(self, 10)
            :DisableHitTest(true)
            :End()

        LayoutHelpers.LayoutFor(self.DragHandleTR)
            :AtRightTopIn(self, -22, -8)
            :Over(self, 10)
            :DisableHitTest(true)
            :End()

        LayoutHelpers.LayoutFor(self.DragHandleBL)
            :AtLeftIn(self, -24)
            :AtBottomIn(self, -8)
            :Over(self, 10)
            :DisableHitTest(true)
            :End()

        LayoutHelpers.LayoutFor(self.DragHandleBR)
            :AtRightIn(self, -22)
            :AtBottomIn(self, -8)
            :Over(self, 10)
            :DisableHitTest(true)
            :End()

        LayoutHelpers.LayoutFor(self.Divider)
            :AtTopIn(self.ClientGroup)
            :End()
    end,

    --#region Window functionality

    ---@param self UIChatConfigurationDialog
    OnClose = function(self)
        self:Destroy()
    end,

    --#endregion

}

---@param parent Control
---@return UIChatConfigurationDialog
GetChatConfigurationDialog = function(parent)
    if not ChatConfigurationDialogInstance or IsDestroyed(ChatConfigurationDialogInstance) then
        ChatConfigurationDialogInstance = ChatConfigurationDialog(parent)
    end

    return ChatConfigurationDialogInstance
end

-------------------------------------------------------------------------------
--#region Debugging

--- Called by the module manager when this module is reloaded
---@param newModule any
function __moduleinfo.OnReload(newModule)
    print("Reloading chat configuration dialog...")

    LOG(ChatConfigurationDialogInstance)
    if ChatConfigurationDialogInstance then

        -- store reference to the parent, then destroy the instance
        local parent = ChatConfigurationDialogInstance:GetParent()
        ChatConfigurationDialogInstance:Destroy()

        -- tell new module to create a new instance
        newModule.GetChatConfigurationDialog(parent)
    end
end

--- Called by the module manager when this module becomes dirty
function __moduleinfo.OnDirty()
    print("Disk changes detected for chat configuration dialog...")

    -- force a reload
    ForkThread(
        function()
            import("/lua/ui/game/ChatConfigurationDialog.lua")
        end
    )
end

--#endregion