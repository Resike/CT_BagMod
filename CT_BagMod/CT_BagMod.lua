local _G = _G
local pairs = pairs
local string = string
local type = type

local ContainerIDToInventoryID = ContainerIDToInventoryID
local GameTooltip = GameTooltip
local GetBagName = GetBagName
local GetBindingKey = GetBindingKey
local PickupBagFromSlot = PickupBagFromSlot
local PutItemInBackpack = PutItemInBackpack
local PutItemInBag = PutItemInBag
local ToggleBackpack = ToggleBackpack
local ToggleBag = ToggleBag

local EQUIP_CONTAINER = EQUIP_CONTAINER
local FONT_COLOR_CODE_CLOSE = FONT_COLOR_CODE_CLOSE
local NORMAL_FONT_COLOR_CODE = NORMAL_FONT_COLOR_CODE
local NUM_CONTAINER_FRAMES = NUM_CONTAINER_FRAMES

local defaultSettings = { }

local function CopySettings(src, dst)
	if type(src) ~= "table" then
		return { }
	end
	if type(dst) then
		dst = { }
	end
	for k, v in pairs(src) do
		if type(v) == "table" then
			dst[k] = CopySettings(v, dst[k])
		elseif type(v) ~= type(dst[k]) then
			dst[k] = v
		end
	end
	return dst
end

CT_BagModOptions = CopySettings(defaultSettings, CT_BagModOptions)

function CT_GetNextCID()
	for i = 1, 5, 1 do
		if not _G["ContainerFrame"..i]:IsVisible() then
			return i
		end
	end
	return 5
end

function CT_GetBagID(container)
	if not container then
		return nil
	end
	return _G["ContainerFrame"..container]:GetID()
end

function CT_CCFrame_ToggleEditBox(self)
	if _G[self:GetParent():GetName().."EBFrame"]:IsVisible() ~= 1 then
		_G[self:GetParent():GetName().."EBFrame"]:Show()
	else
		CT_SaveEditBox(_G[self:GetParent():GetName().."EBFrameEditBox"], self:GetParent():GetID() + 1)
		_G[self:GetParent():GetName().."EBFrame"]:Hide()
	end
end

function CT_SaveEditBox(box, id)
	local text = box:GetText()
	if not text or string.len(text) == 0 then 
		text = ""
	end
	box:SetText("")
	CT_BagModOptions[CT_GetBagID(id)] = text
	if text == "" then
		_G["ContainerFrame"..id.."Name"]:SetText(GetBagName(CT_GetBagID(id)))
	else
		_G["ContainerFrame"..id.."Name"]:SetText(text)
	end
end

function CT_CCEditBox_OnEnterPressed(self)
	CT_SaveEditBox(self, self:GetParent():GetParent():GetID() + 1)
end

function CT_CCEditBox_OnEscapePressed(self)
	if CT_BagModOptions[CT_GetBagID(self:GetParent():GetParent():GetID() + 1)] and string.len(CT_BagModOptions[CT_GetBagID(self:GetParent():GetParent():GetID() + 1)]) > 0 and CT_BagModOptions[CT_GetBagID(self:GetParent():GetParent():GetID() + 1)] ~= GetBagName(CT_GetBagID(self:GetParent():GetParent():GetID() + 1)) then
		_G["ContainerFrame"..self:GetParent():GetParent():GetID() + 1 .."Name"]:SetText(CT_BagModOptions[CT_GetBagID(self:GetParent():GetParent():GetID() + 1)])
	else
		_G["ContainerFrame"..self:GetParent():GetParent():GetID() + 1 .."Name"]:SetText(GetBagName(CT_GetBagID(self:GetParent():GetParent():GetID() + 1)))
	end
	self:SetText("")
	if self:GetParent():IsVisible() == 1 then
		self:GetParent():Hide()
	end
end

function CT_CCFrame_OnShow(self)
	if CT_BagModOptions[CT_GetBagID(self:GetParent():GetID( ) +1)] and string.len(CT_BagModOptions[CT_GetBagID(self:GetParent():GetID() + 1)]) > 0 then
		_G["ContainerFrame"..self:GetParent():GetID() + 1 .."Name"]:SetText(CT_BagModOptions[CT_GetBagID(self:GetParent():GetID() + 1)])
	else
		_G["ContainerFrame"..self:GetParent():GetID() + 1 .."Name"]:SetText(GetBagName(CT_GetBagID(self:GetParent():GetID() + 1)))
	end
end

function CT_CCItemSlotButton_OnLoad(self)
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	self:RegisterEvent("ITEM_LOCK_CHANGED")
	self:RegisterEvent("CURSOR_UPDATE")
	self:RegisterEvent("BAG_UPDATE_COOLDOWN")
	self:RegisterEvent("SHOW_COMPARE_TOOLTIP")
	self:RegisterForDrag("LeftButton")
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
end

function CT_CCSlotButton_OnClick(self)
	local isVisible = 0
	local container
	local button
	if self:GetID() >= 1 then
		button = _G["CharacterBag"..self:GetID() - 1 .."Slot"]
		local id = button:GetID()
		local translatedID = id - CharacterBag0Slot:GetID() + 1
		local hadItem = PutItemInBag(id)
		if not hadItem then
			ToggleBag(translatedID)
		end
		for i = 1, NUM_CONTAINER_FRAMES, 1 do
			local frame = _G["ContainerFrame"..i]
			if frame:GetID() == translatedID then
				container = i
				if frame:IsVisible() then
					isVisible = 1
					break
				end
			end
		end
		button:SetChecked(isVisible)
	else
		if not PutItemInBackpack() then
			ToggleBackpack()
			for i = 1, NUM_CONTAINER_FRAMES, 1 do
				local frame = _G["ContainerFrame"..i]
				if frame:GetID() == 0 then
					container = i
					if frame:IsVisible() then
						isVisible = 1
						break
					end
				end
			end
			_G["MainMenuBarBackpackButton"]:SetChecked(isVisible)
		end
	end
	local newCID = container
	for z = 0, 4, 1 do
		local glb = _G["CT_CCB"..z.."Button"]
		if glb and glb.CID == newCID then
			glb.CID = self.CID
			self.CID = newCID
			_G["ContainerFrame" .. glb.CID]:SetID(glb:GetID())
		end
	end
end

function CT_CCSlotButton_OnDrag(self)
	local button
	if self:GetID() ~= 0 then
		button = _G["CharacterBag"..self:GetID() - 1 .."Slot"]
	else
		button = _G["MainMenuBarBackpackButton"]
	end
	local translatedID = button:GetID() - CharacterBag0Slot:GetID() + 1
	PickupBagFromSlot(button:GetID())
	local isVisible = 0
	for i = 1, NUM_CONTAINER_FRAMES, 1 do
		local frame = _G["ContainerFrame"..i]
		if (frame:GetID() == translatedID) and frame:IsVisible() then
			isVisible = 1
			break
		end
	end
	button:SetChecked(isVisible)
end

function CT_CCFrame_OnEnter(self)
	local bagid = CT_GetBagID(self:GetParent():GetID() + 1)
	local cid = self:GetParent():GetID() + 1
	local settext
	if not CT_BagModOptions[bagid] or CT_BagModOptions[bagid] == "" then
		settext = GetBagName(bagid)
	else
		settext = CT_BagModOptions[bagid]
	end
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	if bagid and bagid == 0 then
		GameTooltip:SetText(settext, 1.0, 1.0, 1.0)
		if GetBindingKey("TOGGLEBACKPACK") then
			GameTooltip:AppendText(" "..NORMAL_FONT_COLOR_CODE.."("..GetBindingKey("TOGGLEBACKPACK")..")"..FONT_COLOR_CODE_CLOSE)
		end

	elseif bagid and bagid > 0 and ContainerIDToInventoryID(bagid) and GameTooltip:SetInventoryItem("player", ContainerIDToInventoryID(bagid)) then
		_G["GameTooltipTextLeft1"]:SetText(settext)
		local binding = GetBindingKey("TOGGLEBAG"..(5 - bagid))
		if binding then
			GameTooltip:AppendText(" "..NORMAL_FONT_COLOR_CODE.."("..binding..")"..FONT_COLOR_CODE_CLOSE)
		end 
	end
	
end

function CT_CCButton_OnEnter(self)
	local bagid = self:GetID()
	local settext
	if not CT_BagModOptions[bagid] or CT_BagModOptions[bagid] == "" then
		settext = GetBagName(bagid)
	else
		settext = CT_BagModOptions[bagid]
	end
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	if bagid == 0 then
		GameTooltip:SetText(settext, 1.0, 1.0, 1.0)
		if GetBindingKey("TOGGLEBACKPACK") then
			GameTooltip:AppendText(" "..NORMAL_FONT_COLOR_CODE.."("..GetBindingKey("TOGGLEBACKPACK")..")"..FONT_COLOR_CODE_CLOSE)
		end
	elseif GameTooltip:SetInventoryItem("player", ContainerIDToInventoryID(bagid)) then
		_G["GameTooltipTextLeft1"]:SetText(settext)
		local binding = GetBindingKey("TOGGLEBAG"..(5 - bagid))
		if binding then
			GameTooltip:AppendText(" "..NORMAL_FONT_COLOR_CODE.."("..binding..")"..FONT_COLOR_CODE_CLOSE)
		end
	else
		GameTooltip:SetText(TEXT(EQUIP_CONTAINER), 1.0, 1.0, 1.0)
	end
end