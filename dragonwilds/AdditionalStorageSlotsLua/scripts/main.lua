--[[
AdditionalStorageSlotsLua - mais espacos nos baus e no inventario do RuneScape: Dragonwilds.

Versao em Lua (roda no UE4SS de Windows E no fork Linux ocristopfer/ue4ss-linux) do mesmo
efeito do AdditionalStorageSlots de Mathayuss (mod C++ do Nexus, so Windows). Codigo proprio,
escrito a partir do que o jogo faz - nao do codigo do mod original. A Config/Config.txt tem o
MESMO formato, para o servidor e os jogadores usarem os mesmos valores.

O que foi medido no servidor (UE 5.6.1):
- A capacidade e a propriedade MaxSlotCount do UInventoryComponent (classe C++ do jogo). O
  valor de fabrica de cada bau vem do componente-MODELO da classe Blueprint (o
  "<Componente>_GEN_VARIABLE" dentro do BP_BaseBuilding_*_C); o do inventario do jogador, do
  modelo dentro do BP_PlayerController (classe BP_Components_PersonalInventory_C).
- UInventoryComponent::SetMaxSlotCount (nativo, sem acesso pelo Lua) so roda com autoridade -
  quem manda e o SERVIDOR - e, ao aumentar, cresce o array ItemSlots com espacos vazios
  (zeros) e o marca para replicar. Os espacos extras chegam aos jogadores pela rede; o numero
  MaxSlotCount nao. Por isso o mod precisa estar no servidor, e provavelmente tambem nos
  jogadores (para a tela deles aceitar os espacos alem do valor de fabrica).
- O jogo guarda no save os itens que ficaram fora do limite e os devolve quando a capacidade
  volta a crescer (TryRestoreSavedOutOfBoundsItems): tirar o mod nao apaga item.

Tres momentos, porque o UE4SS pode subir ANTES do mundo (Windows) ou DEPOIS dele (o fork
Linux so termina de iniciar com o save ja carregado):
1. ao iniciar, uma varredura acerta os modelos e os componentes que ja existem;
2. NotifyOnNewObject pega cada componente novo (classe carregada depois, bau construido);
3. so CRESCE, nunca encolhe: encolher o array jogaria item fora.
]]

local MOD = "AdditionalStorageSlotsLua"
local INVENTORY_CLASS = "/Script/Dominion.InventoryComponent"
-- Limites do valor da config: zero ou negativo nao faz sentido, e um array gigante pesa na
-- rede (todo o ItemSlots vai para cada jogador que abre o bau).
local MIN_SLOTS, MAX_SLOTS = 1, 1000
-- Quantos niveis de "dono" (outer) se sobe para achar a classe do bau: o modelo herdado mora
-- em InheritableComponentHandler, um nivel abaixo da classe.
local MAX_OUTER_DEPTH = 4
-- O objeto recem-construido ainda nao tem as propriedades carregadas do pacote: espera um pouco.
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
    log("sem " .. path .. ": nada sera alterado")
    return config, 0
  end
  for raw in file:lines() do
    -- BOM no comeco do arquivo (editor do Windows) grudaria no primeiro nome.
    local line = raw:gsub("^\239\187\191", ""):gsub("[#;].*$", "")
    local name, value = line:match("^%s*([%w_]+)%s*=%s*(%-?%d+)%s*$")
    if name then
      local slots = tonumber(value)
      if slots < MIN_SLOTS or slots > MAX_SLOTS then
        log(("%s = %d fora de %d-%d: ignorado"):format(name, slots, MIN_SLOTS, MAX_SLOTS))
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

-- O valor configurado para este componente, ou nil. Casa pela classe do proprio componente (o
-- inventario do jogador) ou pela classe do dono: o modelo mora DENTRO da classe Blueprint (o
-- outer e o BP_BaseBuilding_*_C), e o componente vivo dentro do ator dessa classe.
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

local function patch(component)
  if not component or not component:IsValid() then return false end
  local target = target_for(component)
  if not target then return false end
  local ok, current = pcall(function() return component:GetPropertyValue("MaxSlotCount") end)
  if not ok or type(current) ~= "number" or current >= target then return false end
  component:SetPropertyValue("MaxSlotCount", target)
  -- Componente VIVO ja tem o ItemSlots do tamanho antigo: cresce com espacos vazios, como o
  -- SetMaxSlotCount do jogo faz (ler um indice alem do fim faz o UE4SS acrescentar zeros). O
  -- modelo nao tem itens (array vazio): mexer nele faria cada bau novo nascer com lixo.
  if not is_template(component) then
    local slots = component:GetPropertyValue("ItemSlots")
    if slots and slots:GetArrayNum() > 0 and slots:GetArrayNum() < target then
      local _ = slots[target]
    end
  end
  return true
end

local function scan()
  local inventory = StaticFindObject(INVENTORY_CLASS)
  if not inventory or not inventory:IsValid() then
    log("classe " .. INVENTORY_CLASS .. " nao encontrada: o jogo mudou?")
    return
  end
  local patched = 0
  ForEachUObject(function(obj)
    local ok, is_inventory = pcall(function() return obj:IsA(inventory) end)
    if ok and is_inventory and patch(obj) then patched = patched + 1 end
  end)
  log(("varredura: %d componente(s) ajustado(s)"):format(patched))
end

if CONFIGURED == 0 then
  log("nenhuma classe configurada")
  return
end
log(("%d classe(s) configurada(s)"):format(CONFIGURED))

ExecuteInGameThread(scan)

NotifyOnNewObject(INVENTORY_CLASS, function(component)
  ExecuteWithDelay(PATCH_DELAY_MS, function()
    ExecuteInGameThread(function()
      if patch(component) then
        log(("%s -> %d espacos"):format(component:GetFullName(), target_for(component)))
      end
    end)
  end)
end)
