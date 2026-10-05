# AdditionalStorageSlotsLua (RuneScape: Dragonwilds)

Increases the slots of chests, crates, barrels, lumber storage, racks and the player inventory.
Lua version - Windows and Linux - of the effect of
[AdditionalStorageSlots](https://www.nexusmods.com/runescapedragonwilds/mods/37), by
**Mathayuss** (Windows-only C++ mod). Original code; the idea and the config are Mathayuss'.

## Where to install

- **Server: required.** The server owns the inventory
  (`UInventoryComponent::SetMaxSlotCount` only runs with authority). Without the mod there, the
  extra slots do not exist.
- **Players: probably too.** The server sends the extra slots over the network (the `ItemSlots`
  array), but not the `MaxSlotCount` number: the player's UI may stay at the stock value. Use this
  mod or the original, **with the same values**.

Drop-in zips (`-windows`/`-linux`) and the UE4SS each platform needs: see the
[repository README](../../README.md#installing).

## Config

`Config/Config.txt`, one class per line: `BP_BaseBuilding_Chest_C = 100` (1 to 1000). It only
grows: a value below the stock one is ignored, because shrinking would throw items away.

## Measured on the dedicated server (UE 5.6.1, Linux UE4SS)

- Stock values: lumber storage 48, player inventory 20.
- With the mod, the templates (the `*_GEN_VARIABLE` of the Blueprint classes) and the personal
  inventory default go to 100; the server stays up, with the EOS heartbeat.
- With the server's REAL save (dozens of chests) the server stays up. An earlier version grew
  the array of existing chests from Lua and crashed the server (SIGFPE inside UE4SS's TArray):
  today an already built chest is not touched.
- **When UE4SS starts before the world it also applies to the chests already in the save.**
  Measured with the real save (87 chests): 85 with the configured capacity and the same count of
  filled slots as a run without the mod. With a UE4SS that starts after the world (an earlier
  Linux build started 30 s late) only chests built afterwards and the inventory of whoever joins
  change.
- NOT tested with a player yet: build a chest, see the 100 slots and store beyond slot 48.
- Removing the mod does not delete items: the game keeps in the save whatever was beyond the
  limit (`TryRestoreSavedOutOfBoundsItems`) and gives it back when the capacity returns.
