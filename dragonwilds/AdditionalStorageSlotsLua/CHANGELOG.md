# Changelog - AdditionalStorageSlotsLua

Versao em `scripts/main.lua` (`VERSION`), semver: correcao sobe o ultimo numero, classe ou
recurso novo sobe o do meio, mudanca que exige mexer na config sobe o primeiro.

## 1.2.0
- Bau de ferro (`BP_BaseBuilding_Chest_Iron_C`, 64 espacos de fabrica) na config.
- Versao no log ao iniciar.

## 1.1.0
- Nao mexe mais em bau que ja esta montado no mundo, so nos modelos e em componente recem-criado.
  A 1.0.0 crescia o array dos baus do save pelo Lua e DERRUBAVA o servidor (SIGFPE dentro do
  TArray do UE4SS), reproduzido com o save real. Nao use a 1.0.0.

## 1.0.0
- Primeira versao: troca o `MaxSlotCount` dos baus, suportes e do inventario do jogador, com a
  mesma `Config.txt` do AdditionalStorageSlots (Mathayuss).
