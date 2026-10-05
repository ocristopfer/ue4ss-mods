# Changelog - AdditionalStorageSlotsLua

Version in `scripts/main.lua` (`VERSION`), semver: a fix bumps the last number, a new class or
feature bumps the middle one, a change that requires editing the config bumps the first.

## 1.3.1
- Log messages, comments and docs in English. No behavior change.
- Linux: targets the `linux` branch of [ocristopfer/RE-UE4SS](https://github.com/ocristopfer/RE-UE4SS)
  (loaded with `LD_PRELOAD`, mods in `Binaries/Linux/ue4ss/Mods/`), replacing the old
  `ue4ss-linux` fork.
- Drop-in zips: `-windows.zip` and `-linux.zip` mirror the game folder; extract them into the
  folder that contains `Binaries/`.

## 1.3.0
- When the first component of a class is born, that class's TEMPLATE is fixed right away (the
  game copies the template over the component right after constructing it, so fixing only the
  component was not enough), and the component too. With a UE4SS that starts before the world
  (the old `dragonwilds-v2` Linux build), this makes the chests from the SAVE be born with the
  new capacity.
- Measured with the real save (87 chests): 85 with the configured capacity, and the count of
  filled slots of each chest EQUAL to a run without the mod (1382) - no item lost.

## 1.2.0
- Iron chest (`BP_BaseBuilding_Chest_Iron_C`, 64 stock slots) in the config.
- Version in the log on startup.

## 1.1.0
- No longer touches a chest already built in the world, only the templates and newly created
  components. 1.0.0 grew the array of the save's chests from Lua and CRASHED the server (SIGFPE
  inside UE4SS's TArray), reproduced with the real save. Do not use 1.0.0.

## 1.0.0
- First version: changes `MaxSlotCount` of chests, racks and the player inventory, with the same
  `Config.txt` as AdditionalStorageSlots (Mathayuss).
