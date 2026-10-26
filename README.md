# Mantella - Horde Followers

A small Skyrim Special Edition patch that connects **[Mantella](https://www.nexusmods.com/skyrimspecialedition/mods/98631)** (AI conversations with NPCs) to **[Horde - A Light-Weight SKSE Follower Management System](https://www.nexusmods.com/skyrimspecialedition/mods/175589)**.

It adds two new Mantella actions, so an NPC you talk to through Mantella can join or leave your Horde party:

| Action name | LLM key | What it does |
|---|---|---|
| `JoinPartyHorde` | `JoinParty` | Recruits the NPC the same way the vanilla "Follow me" line does, so Horde adopts them as a party member. |
| `LeavePartyHorde` | `LeaveParty` | Dismisses the NPC from your Horde party. |

Both actions take the list of NPC names Mantella sends, so in a group conversation several NPCs can join or leave at once. If no name matches, the NPC who spoke is used, the same fallback Mantella uses for its own actions.

Mantella's own Follow and Unfollow actions are not changed. In Mantella's action settings, turn on either Mantella's Follow/Unfollow or the two Horde actions, not both.

Download: [Nexus Mods](https://www.nexusmods.com/skyrimspecialedition/mods/196589) or the [GitHub releases](https://github.com/Abhisek571/Mantella-Horde-Followers/releases).

## Future development

While building this I found Horde too limited for what I want to do: other mods can't tell its followers to wait, follow or stay passive. Further work will continue in a separate mod built on Nether's Follower Framework. This mod stays available and works as described here.

## Requirements

- [Mantella - Bring NPCs to Life with AI](https://www.nexusmods.com/skyrimspecialedition/mods/98631) 0.14
- [Horde - A Light-Weight SKSE Follower Management System](https://www.nexusmods.com/skyrimspecialedition/mods/175589)
- Skyrim Special Edition / Anniversary Edition with SKSE (both mods above need it)

## Installation

1. Install with your mod manager. The plugin `Mantella - Horde Followers.esp` is ESL-flagged and loads after `Horde.esp`.
2. Open the Mantella UI, go to the actions settings, enable **JoinPartyHorde** and **LeavePartyHorde**, and disable Mantella's **Follow** and **Unfollow**.
3. Start a new Mantella conversation and ask an NPC to join your party.

Safe to add mid-playthrough. To uninstall, dismiss Horde followers recruited this way if you like (Horde keeps them otherwise), then disable the mod.

## Notes and limits

- NPCs who already follow you through another follower system are refused, because Horde only manages followers recruited through the vanilla follower quest.
- NPCs who follow you through Mantella's own follower system are moved over to Horde.
- No wait, follow me or passive/aggressive actions. Horde has no way for other mods to send it those commands, so use Horde's own menu, hotkeys and powers for them.
- Action names have no spaces or brackets: Mantella sends them to the AI as tool names, and some AI services reject names with spaces.
- Tested in game with Horde 3.0.1 and Mantella 0.14: in a live conversation the AI picked both actions on its own (leave, then rejoin), and Horde released and re-adopted the follower each time. Moving an NPC from Mantella's own follower system to Horde was tested with simulated action events.

## Source layout

- `Source/Scripts/MantellaHorde_Main.psc`: the only script. It listens for the two Mantella action events and handles recruiting and dismissing.
- `SKSE/Plugins/MantellaSoftware/data/actions/*.json`: the two action definitions Mantella reads.
- `esp/`: the plugin as [Spriggit](https://github.com/Mutagen-Modding/Spriggit) YAML (one quest that runs the script).

To compile, use the Creation Kit's Papyrus compiler with the vanilla, SKSE and Mantella script sources on the import path.

## License

MIT. See [LICENSE](LICENSE). Mantella and Horde belong to their authors and are not included.

## Credits

- [Mantella](https://www.nexusmods.com/skyrimspecialedition/mods/98631) by Art from the Machine and contributors
- [Horde](https://www.nexusmods.com/skyrimspecialedition/mods/175589) by ColdSun
