# ue4ss-mods

Mods de jogos Unreal escritos em **Lua para o UE4SS**, para rodar do mesmo jeito no
**Windows** (UE4SS oficial, RE-UE4SS) e no **Linux** (servidor dedicado, com o fork
[ocristopfer/ue4ss-linux](https://github.com/ocristopfer/ue4ss-linux)).

A ideia e migrar para ca mods que so existem como `.dll` de Windows (mod C++ do UE4SS), que
um servidor Linux nao carrega: em vez de converter a DLL, descobre-se o que ela faz no jogo e
escreve-se o mesmo efeito em Lua, com codigo proprio.

## Mods

| jogo | mod | o que faz | origem da ideia |
|---|---|---|---|
| RuneScape: Dragonwilds | [AdditionalStorageSlotsLua](dragonwilds/AdditionalStorageSlotsLua) | aumenta os espacos dos baus, suportes e do inventario do jogador | AdditionalStorageSlots, de Mathayuss (Nexus, mod C++ so de Windows) |

## Estrutura

```
<jogo>/<Mod>/            exatamente a pasta que vai em .../Binaries/<plataforma>/Mods/
  scripts/main.lua        o mod
  Config/                 o que o dono do servidor ajusta
  enabled.txt             liga o mod sem mexer no mods.txt
<jogo>/.testbed/          verificadores usados nos testes (nao vao no pacote)
tools/package.py          gera dist/<jogo>-<Mod>.zip de cada mod
```

## Regras

- **So Lua.** E o que faz o mesmo arquivo rodar nas duas plataformas. Nada de `.dll` nem `.so`
  aqui: mod nativo teria de ser compilado duas vezes, contra dois UE4SS diferentes.
- **Codigo proprio.** O mod original serve para saber O QUE fazer (medindo o jogo); o codigo
  daqui nao e copia dele, e o README do mod da o credito da ideia. Config no mesmo formato do
  original, quando existe, para servidor e jogadores usarem os mesmos valores.
- **Funciona com o UE4SS iniciando antes OU depois do mundo.** No Windows o UE4SS sobe antes
  do mapa; no fork Linux ele so termina de iniciar com o save ja carregado. Mod que so age
  "quando o objeto nasce" perde tudo o que ja existia: varra o que existe E escute o que nasce.
- **Mexa nos objetos do jogo no game thread** (`ExecuteInGameThread`): `ExecuteWithDelay` e o
  `NotifyOnNewObject` de um carregamento em segundo plano rodam fora dele.
- Comentarios em portugues, explicando POR QUE (o que foi medido no jogo); identificadores e
  nomes de arquivo em ingles.

## Instalar

**Windows (cliente ou servidor):** instale o [RE-UE4SS](https://github.com/UE4SS-RE/RE-UE4SS/releases)
no jogo e copie a pasta do mod para `<Jogo>/Binaries/Win64/ue4ss/Mods/` (ou `.../Win64/Mods/`,
conforme a versao do UE4SS).

**Linux (servidor dedicado):** instale o UE4SS pelo fork (no painel gamepanel: tela Mods,
"Instalar UE4SS") e copie a pasta do mod para `<Jogo>/Binaries/Linux/Mods/`.

## Testar

O fork tem um testbed que sobe o servidor de verdade em Docker (`testbed/` do
ocristopfer/ue4ss-linux). O verificador de cada jogo fica em `<jogo>/.testbed/`.

```bash
python tools/package.py          # dist/dragonwilds-AdditionalStorageSlotsLua.zip
```
