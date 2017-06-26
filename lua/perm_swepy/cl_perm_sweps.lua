/*
	Perma SWEP system by Hackcraft STEAM_0:1:50714411
*/

local currentPerson
local currentInventory = {}
local perm = {}

local function weaponList()
	local new = {}
	for k, v in ipairs(weapons.GetList()) do
//		PrintTable(v)
		if istable(v) and v.PrintName and #v.PrintName >= 1 and v.ClassName and !table.HasValue(currentInventory, v.ClassName) and !string.find(v.ClassName, "base") then
			table.insert(new, {PrintName = v.PrintName, ClassName = v.ClassName})
		end
	end
	return new
end

local function InventoryChanged(id, t)
	if id then
		net.Start("PermSweps_SendInventoryToServer")
			net.WriteString(id)
			net.WriteString(util.TableToJSON(t))
		net.SendToServer()
	end
end

local function PermMenu()

	currentPerson = false

	local Frame = vgui.Create( "DFrame" )
	Frame:SetSize( 1000, 725 )
	Frame:Center()
	Frame:SetTitle( "Perm SWEPS" )
	Frame:SetVisible( true )
	Frame:SetDraggable( false )
	Frame:ShowCloseButton( true )
	Frame:MakePopup()

	local DComboBox = vgui.Create( "DComboBox", Frame )
	DComboBox:SetPos( 5, 30 )
	DComboBox:SetSize( 800, 20 )
	DComboBox:SetValue( "Player" )
	for k, v in ipairs(player.GetHumans()) do
		DComboBox:AddChoice( v:Nick() )
	end
	DComboBox.OnSelect = function( panel, index, value )
		local did = false
		for k, v in ipairs(player.GetHumans()) do
			if value == v:Nick() then
				did = true
				currentPerson = v:SteamID()
				currentInventory = {}
				DComboBox:SetValue( v:Nick() )
				net.Start("PermSweps_GetInventoryFromServer")
					net.WriteString(currentPerson)
				net.SendToServer()
			end
		end
		if !did then
			DComboBox:Clear()
			DComboBox:SetValue( "Player" )
			for k, v in ipairs(player.GetHumans()) do
				DComboBox:AddChoice( v:Nick() )
			end
		end
	end

	local steamid = vgui.Create( "DTextEntry", Frame ) 
	steamid:SetPos( 805, 30 )
	steamid:SetSize( 190, 20 )
	steamid:SetText( "steam id" )
	steamid.OnEnter = function( self )
		local val = self:GetValue()
		if val != "steam id" and string.Left(val, 5) == "STEAM" then
			currentPerson = val
			currentInventory = {}
			DComboBox:SetValue( val )
			net.Start("PermSweps_GetInventoryFromServer")
				net.WriteString(currentPerson)
			net.SendToServer()
		else
			surface.PlaySound("buttons/button2.wav")
		end
	end

	perm.available = vgui.Create( "DListView", Frame )
	perm.available:SetPos( 5, 55 )
	perm.available:SetSize( 990, 300 )
	perm.available:SetMultiSelect( true )
	perm.available:AddColumn( "PrintName" )
	perm.available:AddColumn( "ClassName" )

	for k, v in ipairs(weaponList()) do
		perm.available:AddLine( v.PrintName, v.ClassName )
	end

	local TextEntry = vgui.Create( "DTextEntry", Frame ) 
	TextEntry:SetPos( 5, 360 )
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
	perm.inventory:SetPos( 5, 420 )
	perm.inventory:SetSize( 990, 300 )
	perm.inventory:SetMultiSelect( true )
	perm.inventory:AddColumn( "PrintName" )
	perm.inventory:AddColumn( "ClassName" )

	local add = vgui.Create( "DButton", Frame )
	add:SetText( "Add" )				
	add:SetPos( 5, 385 )			
	add:SetSize( 60, 30 )				
	add.DoClick = function()	
		if !currentPerson then surface.PlaySound("buttons/button2.wav") return end			
		for k, line in pairs(perm.available:GetSelected()) do
			local class = line:GetValue(2)
			local name = line:GetValue(1)
			if !table.HasValue(currentInventory, class) then
				table.insert(currentInventory, class)
				perm.inventory:AddLine( name, class )
				perm.available:RemoveLine( line:GetID() )
			end
	    end	
	    InventoryChanged(currentPerson, currentInventory)
	end

	local remove = vgui.Create( "DButton", Frame )
	remove:SetText( "Remove" )				
	remove:SetPos( 65, 385 )			
	remove:SetSize( 60, 30 )				
	remove.DoClick = function()	
		if !currentPerson then surface.PlaySound("buttons/button2.wav") return end		
		for k, line in pairs(perm.inventory:GetSelected()) do
			local class = line:GetValue(2)
			local name = line:GetValue(1)
			if table.HasValue(currentInventory, class) then
				table.RemoveByValue(currentInventory, class)
				perm.inventory:RemoveLine( line:GetID() )
				perm.available:AddLine( name, class )
			end
	    end		
	    InventoryChanged(currentPerson, currentInventory)	
	end

end

concommand.Add("perm_swep_menu", function(ply)
	if ply:IsSuperAdmin() then
		PermMenu()
	else
		ply:ChatPrint("No access!")
	end
end)

net.Receive("PermSweps_SendInventoryToClient", function(len)
	local data = net.ReadString()

	currentInventory = util.JSONToTable(data)

//	print("t")
//	PrintTable(currentInventory)
//	print("t")

	perm.available:Clear()
	for k, v in ipairs(weaponList()) do
		perm.available:AddLine( v.PrintName, v.ClassName )
	end

	perm.inventory:Clear()
	for k, v in ipairs(weapons.GetList()) do
		if table.HasValue(currentInventory, v.ClassName) then
			perm.inventory:AddLine(v.PrintName, v.ClassName)
		end
	end
end)