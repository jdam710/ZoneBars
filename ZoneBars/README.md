# ZoneBars

ZoneBars is a small World of Warcraft Retail addon that hides selected action bars
when the character is inside a configured dungeon or raid on a configured
difficulty.

Open the options with:

```text
/zonebars
```

Options:

- Expansion: loaded from the in-game Encounter Journal.
- Content type: raid or dungeon.
- Instance: loaded from the Encounter Journal, plus discovered unknowns.
- Rule mode: Hide selected bars in the selected instance, or Show selected bars only in the selected instance.
- Difficulties: use the dropdown menu to check one or more difficulties, or Any.
- Bar number: check one or more bars from 1 to 5.
- Current rules: edit or delete each saved dungeon/raid rule.

Supported frame names cover the default Blizzard action bars, Bartender4 bars
1-5, and common ElvUI action bar frame names.

When the player enters a dungeon or raid that is missing from the Encounter
Journal scan, ZoneBars remembers it under the `Unknown` expansion. If the client
later exposes that instance through the Encounter Journal, it will appear under
Blizzard's expansion/tier name automatically.
