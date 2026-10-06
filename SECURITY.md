# Security policy

The mods are Lua scripts loaded by UE4SS inside the game or dedicated server
process, with the same access to the machine as that process. Please treat
security issues accordingly.

## Reporting a vulnerability

Do **not** open a public issue. Use GitHub's private vulnerability reporting
(the "Report a vulnerability" button on the repository's **Security** tab) and include:

- the game, the mod and its version (logged on startup, and in `scripts/main.lua`);
- the platform (Windows client/server or Linux dedicated server) and the UE4SS build;
- steps to reproduce, or a proof of concept.

You should get an answer within a few days. Fixes are released as a new version
of the affected mod (tag `<game>/<Mod>/v<version>`); the advisory is published
once a fixed release is available.

## Supported versions

Only the latest version of each mod receives fixes.

## Scope

In scope: the mods and `tools/package.py` in this repository — for example a
mod reading or writing files outside its own folder, a config value that can
execute code, or a way for a **player connected to a server** to abuse a mod's
behaviour (crash the server, corrupt saves, gain items or access they shouldn't).

Out of scope:

- UE4SS itself: report to [UE4SS-RE/RE-UE4SS](https://github.com/UE4SS-RE/RE-UE4SS),
  or to [ocristopfer/RE-UE4SS](https://github.com/ocristopfer/RE-UE4SS) for the
  Linux branch;
- the games and their anti-cheat;
- third-party copies of these mods: only download them from this repository's
  releases.
