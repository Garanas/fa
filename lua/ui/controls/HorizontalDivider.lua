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

local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Bitmap = import("/lua/maui/bitmap.lua").Bitmap

---@class UIHorizontalDivider : Bitmap
HorizontalDivider = ClassUI(Bitmap) {

    ---@param self UIHorizontalDivider
    ---@param parent Control
    ---@param inset number
    ---@param color Color
    __init = function(self, parent, inset, color)
        Bitmap.__init(self, parent)
    end,

    ---@param self UIHorizontalDivider
    ---@param parent Control
    ---@param inset number
    ---@param color Color
    __post_init = function(self, parent, inset, color)
        LayoutHelpers.LayoutFor(self)
            :AtLeftIn(parent, inset)
            :AtRightIn(parent, inset)
            :Height(2)
            :ResetWidth()
            :Color(color)
            :End()
    end,
}

---@param parent Control
---@param inset number
---@param color Color
---@return UIHorizontalDivider
CreateHorizontalDivider = function(parent, inset, color)
    return HorizontalDivider(parent, inset, color)
end
