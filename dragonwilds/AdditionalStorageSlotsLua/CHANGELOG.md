# Changelog - AdditionalStorageSlotsLua

Versao em `scripts/main.lua` (`VERSION`), semver: correcao sobe o ultimo numero, classe ou
recurso novo sobe o do meio, mudanca que exige mexer na config sobe o primeiro.

## 1.3.0
- Quando o primeiro componente de uma classe nasce, o MODELO dela e acertado na hora (o jogo
  copia o modelo por cima do componente logo depois de construi-lo, entao acertar so o componente
  nao bastava), e o componente tambem. Com o fork do UE4SS `dragonwilds-v2`, que inicia antes do
  mundo, isso faz os baus do SAVE nascerem com a capacidade nova.
- Medido com o save real (87 baus): 85 com a capacidade da config, e a contagem de espacos
  ocupados de cada bau IGUAL a de uma rodada sem o mod (1382) - nenhum item perdido.

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
