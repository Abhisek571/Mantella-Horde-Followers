Scriptname MantellaHorde_Main extends Quest
{Adds two Mantella actions, Join Party (Horde) and Leave Party (Horde).
Horde adopts followers recruited through the vanilla DialogueFollower quest,
so recruiting goes through DialogueFollowerScript.SetFollower, the same call
vanilla hire dialogue makes. Mantella's own Follow and Unfollow actions are
left untouched; the player picks which ones to enable in Mantella.}

Actor Property PlayerRef Auto
Quest Property DialogueFollower Auto
Faction Property CurrentFollowerFaction Auto
Faction Property DismissedFollowerFaction Auto
Faction Property CurrentHireling Auto
Faction Property HordeFollowerFaction Auto

string Property ACTION_PREFIX = "MantellaConversation_Action_" AutoReadOnly
string Property ADVANCED_ACTION_PREFIX = "MantellaConversation_Advanced_Action_" AutoReadOnly
string Property ACTION_FOLLOW = "mantella_horde_follow" AutoReadOnly
string Property ACTION_DISMISS = "mantella_horde_dismiss" AutoReadOnly

; Horde scans for new followers every 5 seconds.
float Property ADOPT_TIMEOUT = 12.0 AutoReadOnly

bool busy = false

Event OnInit()
	Register()
EndEvent

Function Register()
	RegisterForModEvent(ADVANCED_ACTION_PREFIX + ACTION_FOLLOW, "OnFollowAdvanced")
	RegisterForModEvent(ACTION_PREFIX + ACTION_FOLLOW, "OnFollowLegacy")
	RegisterForModEvent(ADVANCED_ACTION_PREFIX + ACTION_DISMISS, "OnDismissAdvanced")
	RegisterForModEvent(ACTION_PREFIX + ACTION_DISMISS, "OnDismissLegacy")
	RegisterForModEvent("MantellaConversation_Started", "OnConversationStarted")
EndFunction

Event OnConversationStarted()
	Register()
EndEvent

; ---------------------------------------------------------------------------
; Mantella actions. Advanced events name the NPCs in "source"; legacy events
; (the LLM left out the arguments) carry only the speaker.
; ---------------------------------------------------------------------------

Event OnFollowAdvanced(Form akSpeaker, Form akConversation, int aiArguments)
	Actor[] npcs = ResolveSources(akSpeaker, akConversation, aiArguments)
	int i = 0
	While i < npcs.Length
		If npcs[i]
			Follow(npcs[i])
		EndIf
		i += 1
	EndWhile
EndEvent

Event OnFollowLegacy(Form akSpeaker)
	Follow(akSpeaker as Actor)
EndEvent

Event OnDismissAdvanced(Form akSpeaker, Form akConversation, int aiArguments)
	Actor[] npcs = ResolveSources(akSpeaker, akConversation, aiArguments)
	int i = 0
	While i < npcs.Length
		If npcs[i]
			Dismiss(npcs[i])
		EndIf
		i += 1
	EndWhile
EndEvent

Event OnDismissLegacy(Form akSpeaker)
	Dismiss(akSpeaker as Actor)
EndEvent

; Turns the "source" names into actors. Falls back to the speaker when no
; name resolves, the same fallback Mantella uses for its legacy actions.
Actor[] Function ResolveSources(Form akSpeaker, Form akConversation, int aiArguments)
	Actor[] result = new Actor[10]
	int found = 0
	MantellaConversation conversation = akConversation as MantellaConversation
	string[] names = SKSE_HTTP.getStringArray(aiArguments, "source")
	int i = 0
	While conversation && i < names.Length && found < result.Length
		Actor npc = conversation.GetActorByName(names[i])
		If npc
			result[found] = npc
			found += 1
		EndIf
		i += 1
	EndWhile
	If found == 0
		result[0] = akSpeaker as Actor
	EndIf
	Return result
EndFunction

; ---------------------------------------------------------------------------
; Orders
; ---------------------------------------------------------------------------

Function Follow(Actor akActor)
	If !akActor || akActor.IsDead() || akActor == PlayerRef
		Return
	EndIf
	Lock()
	If IsHordeFollower(akActor)
		Debug.Notification(akActor.GetDisplayName() + " is already in your party.")
	ElseIf akActor.IsPlayerTeammate() && !IsMantellaFollower(akActor)
		; Already following through its own follower system; Horde skips these.
		Tell(akActor.GetDisplayName() + " is already following you.", akActor.GetDisplayName() + " already follows the player through another follower system and cannot join the Horde party.")
	Else
		ReleaseFromMantella(akActor)
		Recruit(akActor)
	EndIf
	Unlock()
EndFunction

Function Dismiss(Actor akActor)
	If !akActor
		Return
	EndIf
	Lock()
	DialogueFollowerScript dfs = DialogueFollower as DialogueFollowerScript
	If IsHordeFollower(akActor)
		DismissFromHorde(akActor)
	ElseIf dfs && dfs.pFollowerAlias.GetActorRef() == akActor
		dfs.DismissFollower(0, 0)
	Else
		Debug.Notification(akActor.GetDisplayName() + " is not in your party.")
	EndIf
	Unlock()
EndFunction

; ---------------------------------------------------------------------------
; Helpers
; ---------------------------------------------------------------------------

bool Function IsHordeFollower(Actor akActor)
	Return HordeFollowerFaction && akActor.IsInFaction(HordeFollowerFaction)
EndFunction

bool Function IsMantellaFollower(Actor akActor)
	Faction following = Game.GetFormFromFile(0x003806, "Mantella.esp") as Faction
	Return following && akActor.IsInFaction(following)
EndFunction

; Takes an NPC out of Mantella's own follower quest, if it put them there.
Function ReleaseFromMantella(Actor akActor)
	If !IsMantellaFollower(akActor)
		Return
	EndIf
	Faction following = Game.GetFormFromFile(0x003806, "Mantella.esp") as Faction
	Quest followerQuest = Game.GetFormFromFile(0x021211, "Mantella.esp") as Quest
	akActor.RemoveFromFaction(following)
	akActor.SetPlayerTeammate(false)
	If followerQuest
		followerQuest.Reset()
		followerQuest.Stop()
		Utility.Wait(0.5)
		followerQuest.Start()
	EndIf
	akActor.EvaluatePackage()
EndFunction

; Recruits like vanilla hire dialogue, then waits for Horde to adopt the
; follower. The next recruit must wait: SetFollower moves the vanilla follower
; alias, and Horde only adopts an actor while it holds that alias.
Function Recruit(Actor akActor)
	DialogueFollowerScript dfs = DialogueFollower as DialogueFollowerScript
	If !dfs
		Return
	EndIf
	akActor.SetActorValue("WaitingForPlayer", 0)
	dfs.SetFollower(akActor)
	akActor.EvaluatePackage()
	float waited = 0.0
	While waited < ADOPT_TIMEOUT && !IsHordeFollower(akActor)
		Utility.Wait(0.5)
		waited += 0.5
	EndWhile
	If IsHordeFollower(akActor)
		Debug.Notification(akActor.GetDisplayName() + " joins your party.")
	Else
		Debug.Notification(akActor.GetDisplayName() + " is following you, but Horde has not added them yet.")
	EndIf
EndFunction

; Mirrors vanilla DismissFollower. Horde sees the follower leave the follower
; faction and the player's team on its next scan and releases them.
Function DismissFromHorde(Actor akActor)
	DialogueFollowerScript dfs = DialogueFollower as DialogueFollowerScript
	int attempt = 0
	While attempt < 2 && IsHordeFollower(akActor)
		akActor.StopCombatAlarm()
		akActor.AddToFaction(DismissedFollowerFaction)
		akActor.RemoveFromFaction(CurrentHireling)
		akActor.RemoveFromFaction(CurrentFollowerFaction)
		akActor.SetPlayerTeammate(false)
		akActor.SetActorValue("WaitingForPlayer", 0)
		If dfs && dfs.pFollowerAlias.GetActorRef() == akActor
			dfs.pFollowerAlias.Clear()
		EndIf
		akActor.EvaluatePackage()
		; Horde keeps a follower it re-checks in the same scan that adopts a
		; new recruit, so try once more if it is still tracked afterwards.
		float waited = 0.0
		While waited < ADOPT_TIMEOUT && IsHordeFollower(akActor)
			Utility.Wait(0.5)
			waited += 0.5
		EndWhile
		attempt += 1
	EndWhile
	If IsHordeFollower(akActor)
		Debug.Notification(akActor.GetDisplayName() + " could not be dismissed. Use Horde to dismiss them.")
	Else
		Debug.Notification(akActor.GetDisplayName() + " leaves your party.")
	EndIf
EndFunction

; Shows a notification and tells the NPCs in the conversation why.
Function Tell(string asNotification, string asEvent)
	Debug.Notification(asNotification)
	int handle = ModEvent.Create("MantellaAddEvent")
	If handle
		ModEvent.PushString(handle, asEvent)
		ModEvent.Send(handle)
	EndIf
EndFunction

Function Lock()
	While busy
		Utility.WaitMenuMode(0.25)
	EndWhile
	busy = true
EndFunction

Function Unlock()
	busy = false
EndFunction
