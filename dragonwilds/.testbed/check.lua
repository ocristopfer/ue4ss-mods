-- Verificador do teste: le o MaxSlotCount de todo InventoryComponent dos baus e do jogador.
local function say(m) print("[storage-check] " .. m .. "\n") end
ExecuteWithDelay(40000, function()
  ExecuteInGameThread(function()
    local inv = StaticFindObject("/Script/Dominion.InventoryComponent")
    ForEachUObject(function(o)
      local ok, isinv = pcall(function() return o:IsA(inv) end)
      if ok and isinv then
        local full = o:GetFullName()
        if full:find("BaseBuilding", 1, true) or full:find("PersonalInventory", 1, true) then
          local slots = o:GetPropertyValue("ItemSlots")
          say(tostring(o:GetPropertyValue("MaxSlotCount")) .. " slots=" .. tostring(slots and slots:GetArrayNum()) .. " | " .. full)
        end
      end
    end)
  end)
end)
