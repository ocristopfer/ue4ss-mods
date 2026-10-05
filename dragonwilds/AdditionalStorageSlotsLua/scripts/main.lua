--[[
AdditionalStorageSlotsLua - more slots in chests and in the player inventory of RuneScape: Dragonwilds.

Lua version (runs on the Windows UE4SS AND on the Linux build of the ocristopfer/RE-UE4SS fork,
`linux` branch) of the same effect as Mathayuss' AdditionalStorageSlots (C++ mod on Nexus,
Windows only). Original code, written from what the game does - not from the original mod's
code. Config/Config.txt uses the SAME format, so the server and the players use the same values.

What was measured on the server (UE 5.6.1):
- The capacity is the MaxSlotCount property of UInventoryComponent (a C++ game class). Each
  chest's stock value comes from the class's TEMPLATE component in the Blueprint class (the
  "<Component>_GEN_VARIABLE" inside BP_BaseBuilding_*_C); the player inventory's comes from the
  template inside BP_PlayerController (class BP_Components_PersonalInventory_C).
- UInventoryComponent::SetMaxSlotCount (native, not reachable from Lua) only runs with authority -
  the SERVER is in charge - and, when growing, extends the ItemSlots array with empty slots
  (zeros) and marks it for replication. The extra slots reach the players over the network; the
  MaxSlotCount number does not. That is why the mod must be on the server, and probably on the
  players too (so their UI accepts slots beyond the stock value).
- The game keeps in the save the items left beyond the limit and gives them back when the
  capacity grows again (TryRestoreSavedOutOfBoundsItems): removing the mod does not delete items.

How it works:
1. on startup, a scan fixes the TEMPLATES (the *_GEN_VARIABLE and the class default);
2. NotifyOnNewObject catches each class loaded later, and each newly created component whose
   ItemSlots is still empty;
3. it only GROWS, never shrinks.

What it deliberately does NOT do: touch a component whose ItemSlots is already built (a chest
from the save that was already in the world). Growing the array from Lua crashed the real server
(SIGFPE inside UE4SS's TArray, reproduced with the real save), and would skip replication to the
players and TryRestoreSavedOutOfBoundsItems; changing only the number would leave MaxSlotCount
100 with an array of 48, which the game would index past the end. Consequence: when UE4SS starts
before the world (Windows, and the Linux build loaded with LD_PRELOAD) it applies to everything;
on a build that only finishes starting with the save already loaded, the chests that ALREADY
existed keep the old capacity - the ones built afterwards, and the inventory of whoever joins,
are born with the new value.
]]

local MOD = "AdditionalStorageSlotsLua"
-- Mod version (semver), in a single place: the log shows it, tools/package.py reads it for the
-- zip name, and CHANGELOG.md says what changed in each one. Behavior changed: bump the version.
local VERSION = "1.3.1"
local INVENTORY_CLASS = "/Script/Dominion.InventoryComponent"
-- Bounds for the config value: zero or negative makes no sense, and a huge array weighs on the
-- network (the whole ItemSlots goes to every player that opens the chest).
local MIN_SLOTS, MAX_SLOTS = 1, 1000
-- How many levels of owner (outer) to climb to find the chest's class: the inherited template
-- lives in InheritableComponentHandler, one level below the class.
local MAX_OUTER_DEPTH = 4
-- A freshly constructed object does not have its properties loaded from the package yet: wait a bit.
local PATCH_DELAY_MS = 250

local function log(msg) print(("[%s] %s\n"):format(MOD, msg)) end

local function mod_dir()
  local source = debug.getinfo(1, "S").source:gsub("^@", ""):gsub("\\", "/")
  return source:match("^(.*)/scripts/[^/]+$") or "."
end

local function read_config(path)
  local config, count = {}, 0
  local file = io.open(path, "r")
  if not file then
    log("no " .. path .. ": nothing will be changed")
    return config, 0
  end
  for raw in file:lines() do
    -- A BOM at the start of the file (Windows editor) would stick to the first name.
    local line = raw:gsub("^\239\187\191", ""):gsub("[#;].*$", "")
    local name, value = line:match("^%s*([%w_]+)%s*=%s*(%-?%d+)%s*$")
    if name then
      local slots = tonumber(value)
      if slots < MIN_SLOTS or slots > MAX_SLOTS then
        log(("%s = %d outside %d-%d: ignored"):format(name, slots, MIN_SLOTS, MAX_SLOTS))
      else
        config[name] = slots
        count = count + 1
      end
    end
  end
  file:close()
  return config, count
end

local CONFIG, CONFIGURED = read_config(mod_dir() .. "/Config/Config.txt")

local function name_of(obj)
  local ok, name = pcall(function() return obj:GetFName():ToString() end)
  return ok and name or nil
end

local function class_name_of(obj)
  local ok, name = pcall(function() return obj:GetClass():GetFName():ToString() end)
  return ok and name or nil
end

-- The configured value for this component, or nil. Matches by the component's own class (the
-- player inventory) or by the owner's class: the template lives INSIDE the Blueprint class (its
-- outer is BP_BaseBuilding_*_C), and the live component inside an actor of that class.
local function target_for(component)
  local value = CONFIG[class_name_of(component) or ""]
  if value then return value end
  local outer = component
  for _ = 1, MAX_OUTER_DEPTH do
    local ok, next_outer = pcall(function() return outer:GetOuter() end)
    if not ok or not next_outer or not next_outer:IsValid() then return nil end
    outer = next_outer
    value = CONFIG[name_of(outer) or ""] or CONFIG[class_name_of(outer) or ""]
    if value then return value end
  end
  return nil
end

local function is_template(component)
  local name = name_of(component) or ""
  return name:find("_GEN_VARIABLE", 1, true) ~= nil or name:find("^Default__") ~= nil
end

-- A live component the game already built (slot array with a size) is not touched: see the top.
local function already_built(component)
  if is_template(component) then return false end
  local ok, num = pcall(function() return component:GetPropertyValue("ItemSlots"):GetArrayNum() end)
  return not ok or num > 0
end

local function patch(component)
  if not component or not component:IsValid() then return false end
  local target = target_for(component)
  if not target or already_built(component) then return false end
  local ok, current = pcall(function() return component:GetPropertyValue("MaxSlotCount") end)
  if not ok or type(current) ~= "number" or current >= target then return false end
  component:SetPropertyValue("MaxSlotCount", target)
  return true
end

-- The live component's template: "<owner's Blueprint class>:<component name>_GEN_VARIABLE".
-- When the component is born the template is already loaded (the game copies from it), so it is
-- the right time to fix it - once per class, because the lookup walks every object.
local templates_done = {}
local function patch_template_of(component)
  local ok, actor_class = pcall(function() return component:GetOuter():GetClass() end)
  if not ok or not actor_class or not actor_class:IsValid() then return end
  local class_path = actor_class:GetFullName():gsub("^%S+%s+", "")
  local path = class_path .. ":" .. (name_of(component) or "") .. "_GEN_VARIABLE"
  if templates_done[path] then return end
  templates_done[path] = true
  local template = StaticFindObject(path)
  if template and template:IsValid() and patch(template) then
    log(("%s -> %d slots (template)"):format(path, target_for(template)))
  end
end

local function scan()
  local inventory = StaticFindObject(INVENTORY_CLASS)
  if not inventory or not inventory:IsValid() then
    log("class " .. INVENTORY_CLASS .. " not found: did the game change?")
    return
  end
  local patched = 0
  ForEachUObject(function(obj)
    local ok, is_inventory = pcall(function() return obj:IsA(inventory) end)
    if ok and is_inventory and patch(obj) then patched = patched + 1 end
  end)
  log(("scan: %d template(s)/component(s) adjusted"):format(patched))
end

if CONFIGURED == 0 then
  log("no class configured")
  return
end
log(("v%s - %d class(es) configured"):format(VERSION, CONFIGURED))

ExecuteInGameThread(scan)

NotifyOnNewObject(INVENTORY_CLASS, function(component)
  -- LIVE component: right away, still inside construction - ItemSlots is empty and the game only
  -- builds it afterwards, already with the new limit. Waiting missed the chests from the save:
  -- with UE4SS starting early, they are born from the old template inside the wait window
  -- (measured with the real save).
  if not is_template(component) then
    patch_template_of(component)
    if patch(component) then
      log(("%s -> %d slots"):format(component:GetFullName(), target_for(component)))
    end
    return
  end
  -- Template: construction comes before the properties are read from disk; changing it now
  -- would be undone.
  ExecuteWithDelay(PATCH_DELAY_MS, function()
    ExecuteInGameThread(function()
      if patch(component) then
        log(("%s -> %d slots"):format(component:GetFullName(), target_for(component)))
      end
    end)
  end)
end)
