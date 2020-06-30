--[[
	Perma SWEP system by Zak STEAM_0:1:50714411
]]--

local providerIDs = {
	"ply",
	"grp",
	"eds"
}

local providerNames = {
	["ply"] = "Player",
	["grp"] = "Group",
	["eds"] = "EDS"
}

local currentPerson, currentGroup, currentEDS
local currentInventory = {}
local perm = {}

local OtherSweps = PermSWEPs.HiddenSWEPs or {}
local swepsList = false
local thingToThing = {
	["Player"] = "steam id",
	["Group"] = "rank",
	["EDS"] = "power(number)"
}
local currentMode = false

local function getValidSWEPs()
	if !swepsList then
		swepsList = table.Add(weapons.GetList(), OtherSweps)
	end
	return swepsList
end

local function weaponList()
	local new = {}
	for k, v in ipairs(getValidSWEPs()) do
--		PrintTable(v)
		if istable(v) and v.PrintName and #v.PrintName >= 1 and v.ClassName and !table.HasValue(currentInventory, v.ClassName) and !string.find(v.ClassName, "base") then
			table.insert(new, {PrintName = v.PrintName, ClassName = v.ClassName})
		end
	end
	return new
end

local function SendUpdatedSWEPsToProvider(provider, target, sweps)
	net.Start("PermSweps_SendInventoryToServer")
		net.WriteString(provider)
		net.WriteString(target)
		net.WriteString(util.TableToJSON(sweps))
	net.SendToServer()
end

local function InventoryChanged(id, t)
	if id then
		SendUpdatedSWEPsToProvider("ply", id, t)
	end
end

local function GroupInventoryChanged(rank, t)
	if rank then
		SendUpdatedSWEPsToProvider("grp", rank, t)
	end
end

local function EDSInventoryChanged(num, t)
	if num and tonumber(num) == num then
		SendUpdatedSWEPsToProvider("eds", num, t)
	end
end

local function FetchUpdatedSWEPsFromProvider(provider, target)
	net.Start("PermSweps_GetInventoryFromServer")
		net.WriteString(provider)
		net.WriteString(target)
	net.SendToServer()
end

local function IsValidUserGroup(val)
	for k, v in pairs(CAMI.GetUsergroups()) do
		if k == val then return true end
	end
	return false
end

local function PermMenu()

	currentPerson, currentGroup, currentEDS = false, false, false
	local boxes = {}

	local Frame = vgui.Create( "DFrame" )
	Frame:SetSize( 1000, 750 )
	Frame:Center()
	Frame:SetTitle( "Perm SWEPS" )
	Frame:SetVisible( true )
	Frame:SetDraggable( false )
	Frame:ShowCloseButton( true )
	Frame:MakePopup()

	-- Multipurpose
	local steamid = vgui.Create( "DTextEntry", Frame ) 
	steamid:SetPos( 805, 55 )
	steamid:SetSize( 190, 20 )
	steamid:SetText( "" )
	steamid:SetVisible(false)
	steamid.OnEnter = function( self )
		local val = self:GetValue()
		if boxes.Player:IsVisible() then
	    	if val != "steam id" and string.Left(val, 5) == "STEAM" then
				currentPerson = val
				currentInventory = {}
				boxes.Player:SetValue( val )

				FetchUpdatedSWEPsFromProvider("ply", currentPerson)
			else
				surface.PlaySound("buttons/button2.wav")
			end
		elseif boxes.Group:IsVisible() then
			if !IsValidUserGroup(val) then
				surface.PlaySound("buttons/button2.wav")
			else
				currentGroup = val
				currentInventory = {}
				boxes.Group:SetValue( val )

				FetchUpdatedSWEPsFromProvider("grp", currentGroup)
			end
		elseif boxes.EDS:IsVisible() then
			val = tonumber(val)
			if val > 100 or val < 1 then
				surface.PlaySound("buttons/button2.wav")
			else
				currentEDS = val
				currentInventory = {}
				boxes.EDS:SetValue( val )

				FetchUpdatedSWEPsFromProvider("eds", val)
			end
		end
	end

	-- Pick from Players, Groups, EDS power
	boxes.Pick = vgui.Create( "DComboBox", Frame )
	boxes.Pick:SetPos( 5, 30 )
	boxes.Pick:SetSize( 990, 20 )
	boxes.Pick:SetValue( "Select" )

	boxes.Pick:AddChoice( "Player" )
	boxes.Pick:AddChoice( "Group" )

	-- Hide Easy Dontation System when not installed (probably no one uses it)
	if EDSCFG then
		boxes.Pick:AddChoice( "EDS" )
	end

	boxes.Pick.OnSelect = function( panel, index, value )
		currentPerson, currentGroup, currentEDS = false, false, false
		for k, v in pairs(boxes) do
			if k == "Pick" then continue end
			if k == value then
				boxes[k]:SetVisible(true)
				steamid:SetVisible(true)
				steamid:SetText(thingToThing[k])
				currentMode = k
				if value == "EDS" then
					steamid:SetNumeric( true )
				else
					steamid:SetNumeric( false )
				end
			else
				boxes[k]:SetVisible(false)
			end
		end
	end

	-- Players
	boxes.Player = vgui.Create( "DComboBox", Frame )
	boxes.Player:SetPos( 5, 55 )
	boxes.Player:SetSize( 800, 20 )
	boxes.Player:SetValue( "Player" )
	boxes.Player:SetVisible(false)
	for k, v in ipairs(player.GetHumans()) do
		boxes.Player:AddChoice( v:Nick() )
	end
	boxes.Player.OnSelect = function( panel, index, value )
		local did = false
		for k, v in ipairs(player.GetHumans()) do
			if value == v:Nick() then
				did = true
				currentPerson = v:SteamID()
				currentInventory = {}
				boxes.Player:SetValue( v:Nick() )

				FetchUpdatedSWEPsFromProvider("ply", currentPerson)
			end
		end
		if !did then
			boxes.Player:Clear()
			boxes.Player:SetValue( "Player" )
			for k, v in ipairs(player.GetHumans()) do
				boxes.Player:AddChoice( v:Nick() )
			end
		end
	end

	-- Groups
	boxes.Group = vgui.Create( "DComboBox", Frame )
	boxes.Group:SetPos( 5, 55 )
	boxes.Group:SetSize( 800, 20 )
	boxes.Group:SetValue( "Group" )
	boxes.Group:SetVisible(false)
	for k, v in pairs(CAMI.GetUsergroups()) do
		boxes.Group:AddChoice( k )
	end
	boxes.Group.OnSelect = function( panel, index, value )
		-- do stuff here
		currentGroup = value
		currentInventory = {}
		boxes.Group:SetValue( value )

		FetchUpdatedSWEPsFromProvider("grp", currentGroup)
	end

	-- EDS Power
	boxes.EDS = vgui.Create( "DComboBox", Frame )
	boxes.EDS:SetPos( 5, 55 )
	boxes.EDS:SetSize( 800, 20 )
	boxes.EDS:SetValue( "EDS" )
	boxes.EDS:SetVisible(false)
	for i=1, 100 do
		boxes.EDS:AddChoice( i )
	end
	boxes.EDS.OnSelect = function( panel, index, value )
		-- do stuff here
		currentEDS = value
		currentInventory = {}
		boxes.EDS:SetValue( value )

		FetchUpdatedSWEPsFromProvider("eds", value)
	end

	perm.available = vgui.Create( "DListView", Frame )
	perm.available:SetPos( 5, 80 )
	perm.available:SetSize( 990, 300 )
	perm.available:SetMultiSelect( true )
	perm.available:AddColumn( "PrintName" )
	perm.available:AddColumn( "ClassName" )

	for k, v in ipairs(weaponList()) do
		perm.available:AddLine( v.PrintName, v.ClassName )
	end

	local TextEntry = vgui.Create( "DTextEntry", Frame ) 
	TextEntry:SetPos( 5, 385 )
	TextEntry:SetSize( 990, 20 )
	TextEntry:SetText( "" )
	TextEntry.OnTextChanged = function( self )
		perm.available:Clear()
		local val = string.lower(self:GetValue())

		for k, v in ipairs(weaponList()) do
			if string.find(string.lower(v.PrintName), val) or string.find(string.lower(v.ClassName), val) then
				perm.available:AddLine( v.PrintName, v.ClassName )
			end
		end
	end

	perm.inventory = vgui.Create( "DListView", Frame )
	perm.inventory:SetPos( 5, 445 )
	perm.inventory:SetSize( 990, 300 )
	perm.inventory:SetMultiSelect( true )
	perm.inventory:AddColumn( "PrintName" )
	perm.inventory:AddColumn( "ClassName" )

	local add = vgui.Create( "DButton", Frame )
	add:SetText( "Add" )				
	add:SetPos( 5, 410 )			
	add:SetSize( 60, 30 )				
	add.DoClick = function()
		if !currentPerson and !currentGroup and !currentEDS then surface.PlaySound("buttons/button2.wav") return end

		for k, line in pairs(perm.available:GetSelected()) do
			local class = line:GetValue(2)
			local name = line:GetValue(1)
			if !table.HasValue(currentInventory, class) then
				table.insert(currentInventory, class)
				perm.inventory:AddLine( name, class )
				perm.available:RemoveLine( line:GetID() )
			end
	    end	
	    if boxes.Player:IsVisible() then
	    	InventoryChanged(currentPerson, currentInventory)
		elseif boxes.Group:IsVisible() then
			GroupInventoryChanged(currentGroup, currentInventory)
		elseif boxes.EDS:IsVisible() then 
			EDSInventoryChanged(currentEDS, currentInventory)
		end
	end

	local remove = vgui.Create( "DButton", Frame )
	remove:SetText( "Remove" )				
	remove:SetPos( 65, 410 )			
	remove:SetSize( 60, 30 )				
	remove.DoClick = function()	
		if !currentPerson and !currentGroup and !currentEDS then surface.PlaySound("buttons/button2.wav") return end

		for k, line in pairs(perm.inventory:GetSelected()) do
			local class = line:GetValue(2)
			local name = line:GetValue(1)
			if table.HasValue(currentInventory, class) then
				table.RemoveByValue(currentInventory, class)
				perm.inventory:RemoveLine( line:GetID() )
				perm.available:AddLine( name, class )
			end
	    end		
	   	if boxes.Player:IsVisible() then
	    	InventoryChanged(currentPerson, currentInventory)
		elseif boxes.Group:IsVisible() then
			GroupInventoryChanged(currentGroup, currentInventory)
		elseif boxes.EDS:IsVisible() then 
			EDSInventoryChanged(currentEDS, currentInventory)
		end
	end

end

concommand.Add("perm_swep_menu", function(ply)
	if ply:IsSuperAdmin() then
		PermMenu()
	else
		ply:ChatPrint("No access!")
	end
end)

-- Update menu
net.Receive("PermSweps_SendInventoryToClient", function(len)
	local providerID = net.ReadString()
	local target = net.ReadString()
	local data = net.ReadString()
	currentInventory = util.JSONToTable(data) // sweps

	perm.available:Clear()
	for k, v in ipairs(weaponList()) do
		perm.available:AddLine( v.PrintName, v.ClassName )
	end

	perm.inventory:Clear()
	for k, v in ipairs(getValidSWEPs()) do
		if table.HasValue(currentInventory, v.ClassName) then
			perm.inventory:AddLine(v.PrintName, v.ClassName)
		end
	end
end)
