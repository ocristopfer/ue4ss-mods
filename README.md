# ue4ss-mods

Unreal game mods written in **Lua for UE4SS**, running the same way on **Windows** (official
[RE-UE4SS](https://github.com/UE4SS-RE/RE-UE4SS)) and on **Linux** (dedicated servers, with the
`linux` branch of the fork [ocristopfer/RE-UE4SS](https://github.com/ocristopfer/RE-UE4SS/tree/linux)).

The goal is to bring here mods that only exist as Windows `.dll` files (UE4SS C++ mods), which a
Linux server cannot load: instead of converting the DLL, we find out what it does in the game and
write the same effect in Lua, with our own code.

## Mods

| game | mod | what it does | idea from |
|---|---|---|---|
| RuneScape: Dragonwilds | [AdditionalStorageSlotsLua](dragonwilds/AdditionalStorageSlotsLua) | more slots in chests (iron chest included), racks and the player inventory | AdditionalStorageSlots, by Mathayuss (Nexus, Windows-only C++ mod) |

## Installing

Each release has three zips per mod (built by `tools/package.py`, see [Packaging](#packaging)):

| zip | contents | how to install |
|---|---|---|
| `<game>-<Mod>-<version>-windows.zip` | `Binaries/Win64/ue4ss/Mods/<Mod>/...` | extract into the game folder that contains `Binaries/` |
| `<game>-<Mod>-<version>-linux.zip` | `Binaries/Linux/ue4ss/Mods/<Mod>/...` | extract into the game folder that contains `Binaries/` |
| `<game>-<Mod>-<version>.zip` | `<Mod>/...` | extract into the `Mods/` folder by hand |

The `-windows`/`-linux` zips are **drop-in**: they mirror the game's folder, so extracting them
(overwriting) puts the mod in place and replaces an older version of it. They only write inside
the mod's own folder - `mods.txt` and other mods are left alone; the mod's `enabled.txt` turns it
on. Updating overwrites `Config/Config.txt` too: keep a copy of yours if you changed it.

```bash
# Linux server: the folder that contains Binaries/ (e.g. <Server>/<Project>/)
unzip -o dragonwilds-AdditionalStorageSlotsLua-1.3.1-linux.zip -d <Server>/<Project>/
```

**UE4SS itself** has to be installed first:

- **Windows (client or server):** install [RE-UE4SS](https://github.com/UE4SS-RE/RE-UE4SS/releases)
  in the game. Mods go in `<Game>/Binaries/Win64/ue4ss/Mods/`.
- **Linux (dedicated server):** install a `linux-*` release of
  [ocristopfer/RE-UE4SS](https://github.com/ocristopfer/RE-UE4SS/releases) as described in its
  [docs/linux.md](https://github.com/ocristopfer/RE-UE4SS/blob/linux/docs/linux.md):
  `libUE4SS.so`, `UE4SS-settings.ini` and `Mods/shared` in `<Game>/Binaries/Linux/ue4ss/`, and the
  server started with `LD_PRELOAD=<...>/ue4ss/libUE4SS.so`. Mods go in
  `<Game>/Binaries/Linux/ue4ss/Mods/`. Games with a modified engine (Dragonwilds) also need the
  `VTableLayout.ini`/`UE4SS_Signatures/` generated from the server's `.sym` (see the same doc).

## Layout

```
<game>/<Mod>/            exactly the folder that goes into .../ue4ss/Mods/
  scripts/main.lua        the mod
  Config/                 what the server owner tunes
  enabled.txt             turns the mod on without touching mods.txt
  CHANGELOG.md            what changed in each version
<game>/.testbed/          checkers used in tests (not packaged)
tools/package.py          builds the zips of every mod in dist/
```

## Rules

- **Lua only.** That is what makes the same file run on both platforms. No `.dll` or `.so`
  here: a native mod would have to be built twice, against two different UE4SS builds.
- **Original code.** The original mod tells us WHAT to do (by measuring the game); the code here
  is not a copy of it, and the mod's README credits the idea. Same config format as the original,
  when there is one, so the server and the players use the same values.
- **Works with UE4SS starting before OR after the world.** On Windows, and on Linux with
  `LD_PRELOAD`, UE4SS starts before the map; a build that starts late finds the save already
  loaded. A mod that only acts "when the object is born" misses everything that already existed:
  scan what exists AND listen for what is born.
- **Touch game objects on the game thread** (`ExecuteInGameThread`): `ExecuteWithDelay` and the
  `NotifyOnNewObject` of a background load run outside it.
- **Version in `scripts/main.lua`** (`local VERSION = "x.y.z"`, semver), shown in the log on
  startup. Behavior changed: bump the version, write it in the mod's `CHANGELOG.md` and tag the
  commit `<game>/<Mod>/v<version>`. Server and players on the SAME version.
- Everything in English: comments (explaining WHY - what was measured in the game), log
  messages, docs, identifiers and file names.

## Testing

The mods are tested on the real dedicated server, in Docker, with the Linux build of
[ocristopfer/RE-UE4SS](https://github.com/ocristopfer/RE-UE4SS/tree/linux). Each game's checker
lives in `<game>/.testbed/`: a Lua script dropped in as an extra mod that logs what the mod
changed.

## Packaging

```bash
python tools/package.py
# dist/dragonwilds-AdditionalStorageSlotsLua-1.3.1.zip
# dist/dragonwilds-AdditionalStorageSlotsLua-1.3.1-windows.zip
# dist/dragonwilds-AdditionalStorageSlotsLua-1.3.1-linux.zip
```
