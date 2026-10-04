# AdditionalStorageSlotsLua (RuneScape: Dragonwilds)

Aumenta os espacos dos baus, caixotes, barris, estoque de madeira, suportes e do inventario
do jogador. Versao em Lua - Windows e Linux - do efeito do
[AdditionalStorageSlots](https://www.nexusmods.com/runescapedragonwilds/mods/37), de
**Mathayuss** (mod C++ so de Windows). Codigo proprio; a ideia e a config sao dele.

## Onde instalar

- **Servidor: obrigatorio.** Quem manda no inventario e o servidor
  (`UInventoryComponent::SetMaxSlotCount` so roda com autoridade). Sem o mod nele, os espacos
  extras nao existem.
- **Jogadores: provavelmente tambem.** O servidor manda os espacos extras pela rede (o array
  `ItemSlots`), mas nao o numero `MaxSlotCount`: a tela do jogador pode continuar no valor de
  fabrica. Use este mod ou o original, **com os mesmos valores**.

## Config

`Config/Config.txt`, uma classe por linha: `BP_BaseBuilding_Chest_C = 100` (1 a 1000). So
aumenta: um valor menor que o de fabrica e ignorado, porque encolher jogaria item fora.

## Medido no servidor dedicado (UE 5.6.1, fork Linux do UE4SS)

- Valores de fabrica: estoque de madeira 48, inventario do jogador 20.
- Com o mod, os modelos (os `*_GEN_VARIABLE` das classes Blueprint) e o padrao do inventario
  pessoal passam a 100; o servidor segue de pe, com o heartbeat do EOS.
- Ainda NAO testado com jogador: construir um bau, ver os 100 espacos e guardar alem do 48.
- Tirar o mod nao apaga item: o jogo guarda no save o que ficou fora do limite
  (`TryRestoreSavedOutOfBoundsItems`) e devolve quando a capacidade volta.
