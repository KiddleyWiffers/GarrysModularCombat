include("shared.lua")

function ENT:Draw()
    self:DrawModel()
end

-- Code for the net.Receive in gmc_weselector

local propMenu = nil

function OpenPropGUI()
    if not IsValid(propMenu) then
        local PropOrEnt = entity:GetNWString("PropOrEnt")
        local entry = entity:GetNWString("Entry")
        
        -- Create the propMenu
        local propMenu = vgui.Create("DFrame")
        propMenu:SetSize(300, 130)
        propMenu:SetTitle("Prop/Entity/Vehicle Placer")
        propMenu:Center()
        propMenu:MakePopup()

        -- Create the first checkbox for "Prop"
        local propCheckbox = vgui.Create("DCheckBoxLabel", propMenu)
        propCheckbox:SetPos(20, 35)
        propCheckbox:SetText("Prop")
        propCheckbox:SetValue(0) -- Default to unchecked
        propCheckbox:SizeToContents()

        -- Create the second checkbox for "Entity"
        local entityCheckbox = vgui.Create("DCheckBoxLabel", propMenu)
        entityCheckbox:SetPos(120, 35)
        entityCheckbox:SetText("Entity")
        entityCheckbox:SetValue(0) -- Default to unchecked
        entityCheckbox:SizeToContents()

        -- Create the third checkbox for "Vehicle"
        local vehicleCheckbox = vgui.Create("DCheckBoxLabel", propMenu)
        vehicleCheckbox:SetPos(220, 35)
        vehicleCheckbox:SetText("Vehicle")
        vehicleCheckbox:SetValue(0) -- Default to unchecked
        vehicleCheckbox:SizeToContents()
        
		local invalidEntityWarning = vgui.Create("DLabel", propMenu)
		invalidEntityWarning:SetPos(20, 60)
		invalidEntityWarning:SetTextColor(Color(255,0,0))
		invalidEntityWarning:SetText("Warning! The model, entity, or vehicle listed is invalid!")
		invalidEntityWarning:SizeToContents()
		invalidEntityWarning:Hide()
		
        -- Create a text entry box
        local textEntry = vgui.Create("DTextEntry", propMenu)
        textEntry:SetPos(20, 80)
        textEntry:SetSize(260, 25)
        textEntry:SetText(entry)
        
        -- Set initial checkbox based on PropOrEnt
        if PropOrEnt == "Prop" then
            propCheckbox:SetValue(true)
        elseif PropOrEnt == "Ent" then
            entityCheckbox:SetValue(true)
        elseif PropOrEnt == "Vehicle" then
            vehicleCheckbox:SetValue(true)
        end

        -- Ensure mutual exclusivity between checkboxes
        local function ResetOtherCheckboxes(selectedCheckbox)
            if selectedCheckbox ~= propCheckbox then propCheckbox:SetValue(false) end
            if selectedCheckbox ~= entityCheckbox then entityCheckbox:SetValue(false) end
            if selectedCheckbox ~= vehicleCheckbox then vehicleCheckbox:SetValue(false) end
        end

        -- Update logic for "Prop"
        function propCheckbox:OnChange(val)
            if val then
                ResetOtherCheckboxes(self)
                PropOrEnt = "Prop"
                textEntry:SetValue("models/props_junk/wood_crate001a.mdl")
            end
        end

        -- Update logic for "Entity"
        function entityCheckbox:OnChange(val)
            if val then
                ResetOtherCheckboxes(self)
                PropOrEnt = "Ent"
				textEntry:SetValue("item_healthcharger")
            end
        end

        -- Update logic for "Vehicle"
        function vehicleCheckbox:OnChange(val)
            if val then
                ResetOtherCheckboxes(self)
                PropOrEnt = "Vehicle"
				textEntry:SetValue("Jeep")
            end
        end

        -- Update logic for text entry
        function textEntry:OnValueChange(val)
			local ValidEntry = false
			if PropOrEnt == "Prop" then
				if not util.IsModelLoaded(val) then
					net.Start("PrecacheModelServerside")
						net.WriteString(val)
					net.SendToServer()
				end
				if util.IsValidModel(val) then
					ValidEntry = true
				end
			elseif PropOrEnt == "Ent" then
				local entities = list.Get("SpawnableEntities")
				if entities[val] then
					ValidEntry = true
				end
			elseif PropOrEnt == "Vehicle" then
				local vechs = list.Get("Vehicles")
				if vechs[val] then
					ValidEntry = true
				end
			end
			if ValidEntry then
				invalidEntityWarning:Hide()
				net.Start("SendUserInputToPropSpawner")
					net.WriteString(PropOrEnt)
					net.WriteString(val)
					net.WriteEntity(entity)
				net.SendToServer()
			else
				invalidEntityWarning:Show()
			end
        end
		
		textEntry.Think = function()
			local val = textEntry:GetValue()
			if PropOrEnt == "Prop" and util.IsValidModel(val) and entity:GetModel() != val then
				invalidEntityWarning:Hide()
				net.Start("SendUserInputToPropSpawner")
					net.WriteString(PropOrEnt)
					net.WriteString(val)
					net.WriteEntity(entity)
				net.SendToServer()
			end
		end
    end
end