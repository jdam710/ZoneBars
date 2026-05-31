# ZoneBars

ZoneBars is a World of Warcraft Retail addon that hides or shows selected action
bars based on the dungeon or raid you are currently in.

It is designed for Retail WoW and targets the current client interface listed in
`ZoneBars/ZoneBars.toc`.

The entire addon is fully vibe coded, and i made it entirely for myself, so don't count on it being perfect and use it at your own risk.
Feel free to comment bugs, or fork it entirely to make it properly if you want.

## Features

- Add multiple dungeon or raid rules.
- Choose `Hide` or `Show` behavior per rule.
- Select one or more difficulties from a compact multi-select dropdown.
- Select one or more bars from 1-5.
- Edit or delete existing rules.
- Automatically loads dungeons and raids from the in-game Encounter Journal.
- Detects unknown dungeons/raids you enter and saves them under `Unknown`.
- Filters pseudo Encounter Journal entries that are not real zones.
- Supports Blizzard default action bars, Bartender4, and common ElvUI bar frame names.

## Install

Copy the `ZoneBars` folder into:

```text
World of Warcraft/_retail_/Interface/AddOns/ZoneBars
```

The installed folder should contain:

```text
ZoneBars.toc
ZoneBars.lua
README.md
```

Then restart WoW or run:

```text
/reload
```

## Usage

Open the options UI in game:

```text
/zonebars
```

To add a rule:

1. Choose expansion, content type, rule mode, instance, difficulties, and bars.
2. Click `Add Rule`.
3. Use `Edit` or `Delete` in the current rules list to manage saved rules.

Rule modes:

- `Hide`: hide selected bars only when the rule matches.
- `Show`: show selected bars only when the rule matches, hiding them elsewhere.

## Notes

ZoneBars builds its dungeon and raid list dynamically from Blizzard's Encounter
Journal APIs. Future instances should appear automatically when Blizzard exposes
them through the client.

When an unknown dungeon or raid is detected, ZoneBars stores it in saved
variables under the `Unknown` expansion so it can still be used in rules.
