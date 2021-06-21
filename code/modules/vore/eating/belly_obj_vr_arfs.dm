#define VORE_SOUND_FALLOFF 0.1
#define VORE_SOUND_RANGE 3

//
//  Belly system 2.0, now using objects instead of datums because EH at datums.
//	How many times have I rewritten bellies and vore now? -Aro
//

// If you change what variables are on this, then you need to update the copy() proc.

//
// Parent type of all the various "belly" varieties.
//
/obj/belly
	name = "belly"							// Name of this location
	desc = "It's a belly! You're in it!"	// Flavor text description of inside sight/sound/smells/feels.
	var/vore_sound = "Gulp"					// Sound when ingesting someone
	var/vore_verb = "ingest"				// Verb for eating with this in messages
	var/human_prey_swallow_time = 100		// Time in deciseconds to swallow /mob/living/carbon/human
	var/nonhuman_prey_swallow_time = 30		// Time in deciseconds to swallow anything else
	var/nutrition_percent = 100				// Nutritional percentage per tick in digestion mode
	var/digest_brute = 0.5					// Brute damage per tick in digestion mode
	var/digest_burn = 0.5					// Burn damage per tick in digestion mode
	var/immutable = FALSE					// Prevents this belly from being deleted
	var/escapable = FALSE					// Belly can be resisted out of at any time
	var/escapetime = 20 SECONDS				// Deciseconds, how long to escape this belly
	var/digestchance = 0					// % Chance of stomach beginning to digest if prey struggles
	var/absorbchance = 0					// % Chance of stomach beginning to absorb if prey struggles
	var/escapechance = 0 					// % Chance of prey beginning to escape if prey struggles.
	var/transferchance = 0 					// % Chance of prey being
	var/can_taste = FALSE					// If this belly prints the flavor of prey when it eats someone.
	var/bulge_size = 0.25					// The minimum size the prey has to be in order to show up on examine.
	var/shrink_grow_size = 1				// This horribly named variable determines the minimum/maximum size it will shrink/grow prey to.
	var/transferlocation					// Location that the prey is released if they struggle and get dropped off.
	var/release_sound = "Splatter"			// Sound for letting someone out. Replaced from True/false
	var/mode_flags = 0						// Stripping, numbing, etc.
	var/fancy_vore = FALSE					// Using the new sounds?
	var/is_wet = TRUE						// Is this belly's insides made of slimy parts?
	var/wet_loop = TRUE						// Does the belly have a fleshy loop playing?
	var/obj/item/weapon/storage/vore_egg/ownegg	// Is this belly creating an egg?
	var/egg_type = "Egg"					// Default egg type and path.
	var/egg_path = /obj/item/weapon/storage/vore_egg
	var/list/emote_lists = list()			// Idle emotes that happen on their own, depending on the bellymode. Contains lists of strings indexed by bellymode
	var/emote_time = 60						// How long between stomach emotes at prey (in seconds)
	var/emote_active = TRUE					// Are we even giving emotes out at all or not?
	var/next_emote = 0						// When we're supposed to print our next emote, as a world.time

	// ARFS EDIT
	var/vorespawn_blacklist = FALSE
	// END ARFS EDIT

	//I don't think we've ever altered these lists. making them static until someone actually overrides them somewhere.
	//Actual full digest modes
	var/tmp/static/list/digest_modes = list(DM_HOLD,DM_DIGEST,DM_ABSORB,DM_DRAIN,DM_UNABSORB,DM_HEAL,DM_SHRINK,DM_GROW,DM_SIZE_STEAL,DM_EGG)
	//Digest mode addon flags
	var/tmp/static/list/mode_flag_list = list("Numbing" = DM_FLAG_NUMBING, "Stripping" = DM_FLAG_STRIPPING, "Leave Remains" = DM_FLAG_LEAVEREMAINS, "Muffles" = DM_FLAG_THICKBELLY, "Affect Worn Items" = DM_FLAG_AFFECTWORN)
	//Item related modes
	var/tmp/static/list/item_digest_modes = list(IM_HOLD,IM_DIGEST_FOOD,IM_DIGEST)

	//List of slots that stripping handles strips
	var/tmp/static/list/slots = list(slot_back,slot_handcuffed,slot_l_store,slot_r_store,slot_wear_mask,slot_l_hand,slot_r_hand,slot_wear_id,slot_glasses,slot_gloves,slot_head,slot_shoes,slot_belt,slot_wear_suit,slot_w_uniform,slot_s_store,slot_l_ear,slot_r_ear)

	var/tmp/mob/living/owner					// The mob whose belly this is.
	var/tmp/digest_mode = DM_HOLD				// Current mode the belly is set to from digest_modes (+transform_modes if human)
	var/tmp/list/items_preserved = list()		// Stuff that wont digest so we shouldn't process it again.
	var/tmp/recent_sound = FALSE				// Prevent audio spam

	// Don't forget to watch your commas at the end of each line if you change these.
	var/list/struggle_messages_outside = list(
		"%pred's %belly wobbles with a squirming meal.",
		"%pred's %belly jostles with movement.",
		"%pred's %belly briefly swells outward as someone pushes from inside.",
		"%pred's %belly fidgets with a trapped victim.",
		"%pred's %belly jiggles with motion from inside.",
		"%pred's %belly sloshes around.",
		"%pred's %belly gushes softly.",
		"%pred's %belly lets out a wet squelch.")

	var/list/struggle_messages_inside = list(
		"Your useless squirming only causes %pred's slimy %belly to squelch over your body.",
		"Your struggles only cause %pred's %belly to gush softly around you.",
		"Your movement only causes %pred's %belly to slosh around you.",
		"Your motion causes %pred's %belly to jiggle.",
		"You fidget around inside of %pred's %belly.",
		"You shove against the walls of %pred's %belly, making it briefly swell outward.",
		"You jostle %pred's %belly with movement.",
		"You squirm inside of %pred's %belly, making it wobble around.")

	var/list/digest_messages_owner = list(
		"You feel %prey's body succumb to your digestive system, which breaks it apart into soft slurry.",
		"You hear a lewd glorp as your %belly muscles grind %prey into a warm pulp.",
		"Your %belly lets out a rumble as it melts %prey into sludge.",
		"You feel a soft gurgle as %prey's body loses form in your %belly. They're nothing but a soft mass of churning slop now.",
		"Your %belly begins gushing %prey's remains through your system, adding some extra weight to your thighs.",
		"Your %belly begins gushing %prey's remains through your system, adding some extra weight to your rump.",
		"Your %belly begins gushing %prey's remains through your system, adding some extra weight to your belly.",
		"Your %belly groans as %prey falls apart into a thick soup. You can feel their remains soon flowing deeper into your body to be absorbed.",
		"Your %belly kneads on every fiber of %prey, softening them down into mush to fuel your next hunt.",
		"Your %belly churns %prey down into a hot slush. You can feel the nutrients coursing through your digestive track with a series of long, wet glorps.")

	var/list/digest_messages_prey = list(
		"Your body succumbs to %pred's digestive system, which breaks you apart into soft slurry.",
		"%pred's %belly lets out a lewd glorp as their muscles grind you into a warm pulp.",
		"%pred's %belly lets out a rumble as it melts you into sludge.",
		"%pred feels a soft gurgle as your body loses form in their %belly. You're nothing but a soft mass of churning slop now.",
		"%pred's %belly begins gushing your remains through their system, adding some extra weight to %pred's thighs.",
		"%pred's %belly begins gushing your remains through their system, adding some extra weight to %pred's rump.",
		"%pred's %belly begins gushing your remains through their system, adding some extra weight to %pred's belly.",
		"%pred's %belly groans as you fall apart into a thick soup. Your remains soon flow deeper into %pred's body to be absorbed.",
		"%pred's %belly kneads on every fiber of your body, softening you down into mush to fuel their next hunt.",
		"%pred's %belly churns you down into a hot slush. Your nutrient-rich remains course through their digestive track with a series of long, wet glorps.")

	var/list/examine_messages = list(
		"They have something solid in their %belly!",
		"It looks like they have something in their %belly!")

	var/item_digest_mode = IM_DIGEST_FOOD	// Current item-related mode from item_digest_modes
	var/contaminates = TRUE					// Whether the belly will contaminate stuff
	var/contamination_flavor = "Generic"	// Determines descriptions of contaminated items
	var/contamination_color = "green"		// Color of contamination overlay

	// Lets you do a fullscreen overlay. Set to an icon_state string.
	var/belly_fullscreen = ""
	var/disable_hud = FALSE

//For serialization, keep this updated, required for bellies to save correctly.
/obj/belly/vars_to_save()
	return ..() + list(
		"name",
		"desc",
		"vore_sound",
		"vore_verb",
		"human_prey_swallow_time",
		"nonhuman_prey_swallow_time",
		"emote_time",
		"nutrition_percent",
		"digest_brute",
		"digest_burn",
		"immutable",
		"can_taste",
		"escapable",
		"escapetime",
		"digestchance",
		"absorbchance",
		"escapechance",
		"transferchance",
		"transferlocation",
		"bulge_size",
		"shrink_grow_size",
		"struggle_messages_outside",
		"struggle_messages_inside",
		"digest_messages_owner",
		"digest_messages_prey",
		"examine_messages",
		"emote_lists",
		"emote_time",
		"emote_active",
		"mode_flags",
		"item_digest_mode",
		"contaminates",
		"contamination_flavor",
		"contamination_color",
		"release_sound",
		"fancy_vore",
		"is_wet",
		"wet_loop",
		"belly_fullscreen",
		"disable_hud",
		"egg_type",
		// ARFS EDIT
		"vorespawn_blacklist"
		// END ARFS EDIT
		)

/obj/belly/Initialize()
	. = ..()
	//If not, we're probably just in a prefs list or something.
	if(isliving(loc))
		owner = loc
		owner.vore_organs |= src
		START_PROCESSING(SSbellies, src)

/obj/belly/Destroy()
	STOP_PROCESSING(SSbellies, src)
	owner?.vore_organs?.Remove(src)
	owner = null
	return ..()

// Called whenever an atom enters this belly
/obj/belly/Entered(atom/movable/thing, atom/OldLoc)
	if(OldLoc in contents)
		return //Someone dropping something (or being stripdigested)

	//Generic entered message
	to_chat(owner,"<span class='notice'>[thing] slides into your [lowertext(name)].</span>")

	//Sound w/ antispam flag setting
	if(vore_sound && !recent_sound)
		var/soundfile
		if(!fancy_vore)
			soundfile = classic_vore_sounds[vore_sound]
		else
			soundfile = fancy_vore_sounds[vore_sound]
		if(soundfile)
			playsound(src, soundfile, vol = 100, vary = 1, falloff = VORE_SOUND_FALLOFF, preference = /datum/client_preference/eating_noises, volume_channel = VOLUME_CHANNEL_VORE)
			recent_sound = TRUE

	//Messages if it's a mob
	if(isliving(thing))
		var/mob/living/M = thing
		if(desc)
			to_chat(M, "<span class='notice'><B>[desc]</B></span>")
		var/taste
		if(can_taste && (taste = M.get_taste_message(FALSE)))
			to_chat(owner, "<span class='notice'>[M] tastes of [taste].</span>")
		vore_fx(M)
		//Stop AI processing in bellies
		if(M.ai_holder)
			M.ai_holder.go_sleep()

// Called whenever an atom leaves this belly
/obj/belly/Exited(atom/movable/thing, atom/OldLoc)
	. = ..()
	if(isliving(thing) && !isbelly(thing.loc))
		var/mob/living/L = thing
		L.clear_fullscreen("belly")
		if(L.hud_used)
			if(!L.hud_used.hud_shown)
				L.toggle_hud_vis()
		if((L.stat != DEAD) && L.ai_holder)
			L.ai_holder.go_wake()

/obj/belly/proc/vore_fx(mob/living/L)
	if(!istype(L))
		return
	if(!L.show_vore_fx)
		L.clear_fullscreen("belly")
		return

	if(belly_fullscreen)
		var/obj/screen/fullscreen/F = L.overlay_fullscreen("belly", /obj/screen/fullscreen/belly)
		F.icon_state = belly_fullscreen
		// F.color = belly_fullscreen_color
	else
		L.clear_fullscreen("belly")

	if(disable_hud)
		if(L?.hud_used?.hud_shown)
			to_chat(L, "<span class='notice'>((Your pred has disabled huds in their belly. Turn off vore FX and hit F12 to get it back; or relax, and enjoy the serenity.))</span>")
			L.toggle_hud_vis(TRUE)

// Release all contents of this belly into the owning mob's location.
// If that location is another mob, contents are transferred into whichever of its bellies the owning mob is in.
// Returns the number of mobs so released.
/obj/belly/proc/release_all_contents(include_absorbed = FALSE, silent = FALSE)
	//Don't bother if we don't have contents
	if(!contents.len)
		return FALSE

	//Find where we should drop things into (certainly not the owner)
	var/count = 0

	//Iterate over contents and move them all
	for(var/thing in contents)
		var/atom/movable/AM = thing
		if(isliving(AM))
			var/mob/living/L = AM
			if(L.absorbed && !include_absorbed)
				continue
		count += release_specific_contents(AM, silent = TRUE)

	//Clean up our own business
	items_preserved.Cut()
	if(!ishuman(owner))
		owner.update_icons()

	//Print notifications/sound if necessary
	if(!silent)
		owner.visible_message("<font color='green'><b>[owner] expels everything from their [lowertext(name)]!</b></font>")
		var/soundfile
		if(!fancy_vore)
			soundfile = classic_release_sounds[release_sound]
		else
			soundfile = fancy_release_sounds[release_sound]
		if(soundfile)
			playsound(src, soundfile, vol = 100, vary = 1, falloff = VORE_SOUND_FALLOFF, preference = /datum/client_preference/eating_noises, volume_channel = VOLUME_CHANNEL_VORE)

	return count

// Release a specific atom from the contents of this belly into the owning mob's location.
// If that location is another mob, the atom is transferred into whichever of its bellies the owning mob is in.
// Returns the number of atoms so released.
/obj/belly/proc/release_specific_contents(atom/movable/M, silent = FALSE)
	if (!(M in contents))
		return 0 // They weren't in this belly anyway

	for(var/mob/living/L in M.contents)
		L.muffled = 0
	for(var/obj/item/weapon/holder/H in M.contents)
		H.held_mob.muffled = 0

	//Place them into our drop_location
	M.forceMove(drop_location())

	items_preserved -= M

	//Special treatment for absorbed prey
	if(isliving(M))
		var/mob/living/ML = M
		var/mob/living/OW = owner
		if(ML.client)
			ML.stop_sound_channel(CHANNEL_PREYLOOP) //Stop the internal loop, it'll restart if the isbelly check on next tick anyway
		if(ML.muffled)
			ML.muffled = 0
		if(ML.absorbed)
			ML.absorbed = FALSE
			if(ishuman(M) && ishuman(OW))
				var/mob/living/carbon/human/Prey = M
				var/mob/living/carbon/human/Pred = OW
				var/absorbed_count = 2 //Prey that we were, plus the pred gets a portion
				for(var/mob/living/P in contents)
					if(P.absorbed)
						absorbed_count++
				Pred.bloodstr.trans_to(Prey, Pred.reagents.total_volume / absorbed_count)

	//Clean up our own business
	if(!ishuman(owner))
		owner.update_icons()

	//Print notifications/sound if necessary
	if(!silent)
		owner.visible_message("<font color='green'><b>[owner] expels [M] from their [lowertext(name)]!</b></font>")
		var/soundfile
		if(!fancy_vore)
			soundfile = classic_release_sounds[release_sound]
		else
			soundfile = fancy_release_sounds[release_sound]
		if(soundfile)
			playsound(src, soundfile, vol = 100, vary = 1, falloff = VORE_SOUND_FALLOFF, preference = /datum/client_preference/eating_noises, volume_channel = VOLUME_CHANNEL_VORE)

	return 1

// Actually perform the mechanics of devouring the tasty prey.
// The purpose of this method is to avoid duplicate code, and ensure that all necessary
// steps are taken.
/obj/belly/proc/nom_mob(mob/prey, mob/user)
	if(owner.stat == DEAD)
		return
	if(prey.buckled)
		prey.buckled.unbuckle_mob()

	prey.forceMove(src)
	owner.updateVRPanel()
	if(isanimal(owner))
		owner.update_icon()

	for(var/mob/living/M in contents)
		M.updateVRPanel()

// Get the line that should show up in Examine message if the owner of this belly
// is examined.   By making this a proc, we not only take advantage of polymorphism,
// but can easily make the message vary based on how many people are inside, etc.
// Returns a string which shoul be appended to the Examine output.
/obj/belly/proc/get_examine_msg()
	if(contents.len && examine_messages.len)
		var/formatted_message
		var/raw_message = pick(examine_messages)
		var/total_bulge = 0

		var/living_count = 0
		for(var/mob/living/L in contents)
			living_count++

		formatted_message = replacetext(raw_message, "%belly", lowertext(name))
		formatted_message = replacetext(formatted_message, "%pred", owner)
		formatted_message = replacetext(formatted_message, "%prey", english_list(contents))
		formatted_message = replacetext(formatted_message, "%count", contents.len)
		formatted_message = replacetext(formatted_message, "%countprey", living_count)
		for(var/mob/living/P in contents)
			if(!P.absorbed) //This is required first, in case there's a person absorbed and not absorbed in a stomach.
				total_bulge += P.size_multiplier
		if(total_bulge >= bulge_size && bulge_size != 0)
			return("<span class='warning'>[formatted_message]</span>")
		else
			return ""

// The next function gets the messages set on the belly, in human-readable format.
// This is useful in customization boxes and such. The delimiter right now is \n\n so
// in message boxes, this looks nice and is easily delimited.
/obj/belly/proc/get_messages(type, delim = "\n\n")
	ASSERT(type == "smo" || type == "smi" || type == "dmo" || type == "dmp" || type == "em" || type == "im_digest" || type == "im_hold" || type == "im_absorb" || type == "im_heal" || type == "im_drain")

	var/list/raw_messages
	switch(type)
		if("smo")
			raw_messages = struggle_messages_outside
		if("smi")
			raw_messages = struggle_messages_inside
		if("dmo")
			raw_messages = digest_messages_owner
		if("dmp")
			raw_messages = digest_messages_prey
		if("em")
			raw_messages = examine_messages
		if("im_digest")
			raw_messages = emote_lists[DM_DIGEST]
		if("im_hold")
			raw_messages = emote_lists[DM_HOLD]
		if("im_absorb")
			raw_messages = emote_lists[DM_ABSORB]
		if("im_heal")
			raw_messages = emote_lists[DM_HEAL]
		if("im_drain")
			raw_messages = emote_lists[DM_DRAIN]

	var/messages = null
	if(raw_messages)
		messages = list2text(raw_messages, delim)
	return messages

// The next function sets the messages on the belly, from human-readable var
// replacement strings and linebreaks as delimiters (two \n\n by default).
// They also sanitize the messages.
/obj/belly/proc/set_messages(raw_text, type, delim = "\n\n")
	ASSERT(type == "smo" || type == "smi" || type == "dmo" || type == "dmp" || type == "em" || type == "im_digest" || type == "im_hold" || type == "im_absorb" || type == "im_heal" || type == "im_drain")

	var/list/raw_list = text2list(html_encode(raw_text),delim)
	if(raw_list.len > 10)
		raw_list.Cut(11)
		log_debug("[owner] tried to set [lowertext(name)] with 11+ messages")

	for(var/i = 1, i <= raw_list.len, i++)
		if((length(raw_list[i]) > 160 || length(raw_list[i]) < 10) && !(type == "im_digest" || type == "im_hold" || type == "im_absorb" || type == "im_heal" || type == "im_drain")) //160 is fudged value due to htmlencoding increasing the size
			raw_list.Cut(i,i)
			log_debug("[owner] tried to set [lowertext(name)] with >121 or <10 char message")
		else if((type == "im_digest" || type == "im_hold" || type == "im_absorb" || type == "im_heal" || type == "im_drain") && (length(raw_list[i]) > 510 || length(raw_list[i]) < 10))
			raw_list.Cut(i,i)
			log_debug("[owner] tried to set [lowertext(name)] idle message with >501 or <10 char message")
		else
			raw_list[i] = readd_quotes(raw_list[i])
			//Also fix % sign for var replacement
			raw_list[i] = replacetext(raw_list[i],"&#37;","%")

	ASSERT(raw_list.len <= 10) //Sanity

	switch(type)
		if("smo")
			struggle_messages_outside = raw_list
		if("smi")
			struggle_messages_inside = raw_list
		if("dmo")
			digest_messages_owner = raw_list
		if("dmp")
			digest_messages_prey = raw_list
		if("em")
			examine_messages = raw_list
		if("im_digest")
			emote_lists[DM_DIGEST] = raw_list
		if("im_hold")
			emote_lists[DM_HOLD] = raw_list
		if("im_absorb")
			emote_lists[DM_ABSORB] = raw_list
		if("im_heal")
			emote_lists[DM_HEAL] = raw_list
		if("im_drain")
			emote_lists[DM_DRAIN] = raw_list

	return

// Handle the death of a mob via digestion.
// Called from the process_Life() methods of bellies that digest prey.
// Default implementation calls M.death() and removes from internal contents.
// Indigestable items are removed, and M is deleted.
/obj/belly/proc/digestion_death(mob/living/M)
	add_attack_logs(owner, M, "Digested in [lowertext(name)]")

	// If digested prey is also a pred... anyone inside their bellies gets moved up.
	if(is_vore_predator(M))
		M.release_vore_contents(include_absorbed = TRUE, silent = TRUE)

	//Drop all items into the belly.
	if(config.items_survive_digestion)
		for(var/obj/item/W in M)
			if(istype(W, /obj/item/organ/internal/mmi_holder/posibrain))
				var/obj/item/organ/internal/mmi_holder/MMI = W
				var/atom/movable/brain = MMI.removed()
				if(brain)
					M.remove_from_mob(brain,owner)
					brain.forceMove(src)
					items_preserved += brain
			for(var/slot in slots)
				var/obj/item/I = M.get_equipped_item(slot = slot)
				if(I)
					M.unEquip(I,force = TRUE)
					if(contaminates || istype(I, /obj/item/weapon/card/id))
						I.gurgle_contaminate(contents, contamination_flavor, contamination_color) //We do an initial contamination pass to get stuff like IDs wet.
					if(item_digest_mode == IM_HOLD)
						items_preserved |= I
					else if(item_digest_mode == IM_DIGEST_FOOD && !(istype(I,/obj/item/weapon/reagent_containers/food) || istype(I,/obj/item/organ)))
						items_preserved |= I

	//Reagent transfer
	if(ishuman(owner))
		var/mob/living/carbon/human/Pred = owner
		if(ishuman(M))
			var/mob/living/carbon/human/Prey = M
			Prey.bloodstr.del_reagent("numbenzyme")
			Prey.bloodstr.trans_to_holder(Pred.bloodstr, Prey.bloodstr.total_volume, 0.5, TRUE) // Copy=TRUE because we're deleted anyway
			Prey.ingested.trans_to_holder(Pred.bloodstr, Prey.ingested.total_volume, 0.5, TRUE) // Therefore don't bother spending cpu
			Prey.touching.trans_to_holder(Pred.bloodstr, Prey.touching.total_volume, 0.5, TRUE) // On updating the prey's reagents
		else if(M.reagents)
			M.reagents.trans_to_holder(Pred.bloodstr, M.reagents.total_volume, 0.5, TRUE)

	//Incase they have the loop going, let's double check to stop it.
	M.stop_sound_channel(CHANNEL_PREYLOOP)
	// Delete the digested mob
	M.ghostize() // Make sure they're out, so we can copy attack logs and such.
	qdel(M)

// Handle a mob being absorbed
/obj/belly/proc/absorb_living(mob/living/M)
	M.absorbed = 1
	to_chat(M, "<span class='notice'>[owner]'s [lowertext(name)] absorbs your body, making you part of them.</span>")
	to_chat(owner, "<span class='notice'>Your [lowertext(name)] absorbs [M]'s body, making them part of you.</span>")
	if(M.noisy) //Mute drained absorbee hunger if enabled.
		M.noisy = FALSE

	if(ishuman(M) && ishuman(owner))
		var/mob/living/carbon/human/Prey = M
		var/mob/living/carbon/human/Pred = owner
		//Reagent sharing for absorbed with pred - Copy so both pred and prey have these reagents.
		Prey.bloodstr.trans_to_holder(Pred.ingested, Prey.bloodstr.total_volume, copy = TRUE)
		Prey.ingested.trans_to_holder(Pred.ingested, Prey.ingested.total_volume, copy = TRUE)
		Prey.touching.trans_to_holder(Pred.ingested, Prey.touching.total_volume, copy = TRUE)
		// TODO - Find a way to make the absorbed prey share the effects with the pred.
		// Currently this is infeasible because reagent containers are designed to have a single my_atom, and we get
		// problems when A absorbs B, and then C absorbs A,  resulting in B holding onto an invalid reagent container.

	//This is probably already the case, but for sub-prey, it won't be.
	if(M.loc != src)
		M.forceMove(src)

	//Seek out absorbed prey of the prey, absorb them too.
	//This in particular will recurse oddly because if there is absorbed prey of prey of prey...
	//it will just move them up one belly. This should never happen though since... when they were
	//absobred, they should have been absorbed as well!
	for(var/belly in M.vore_organs)
		var/obj/belly/B = belly
		for(var/mob/living/Mm in B)
			if(Mm.absorbed)
				absorb_living(Mm)

	//Update owner
	owner.updateVRPanel()
	if(isanimal(owner))
		owner.update_icon()

//Digest a single item
//Receives a return value from digest_act that's how much nutrition
//the item should be worth
/obj/belly/proc/digest_item(obj/item/item)
	var/digested = item.digest_act(src, owner)
	if(!digested)
		items_preserved |= item
	else
		owner.adjust_nutrition((nutrition_percent / 100) * 5 * digested)
		if(isrobot(owner))
			var/mob/living/silicon/robot/R = owner
			R.cell.charge += ((nutrition_percent / 100) * 50 * digested)
	return digested

//Determine where items should fall out of us into.
//Typically just to the owner's location.
/obj/belly/drop_location()
	//Should be the case 99.99% of the time
	if(owner)
		return owner.drop_location()
	//Sketchy fallback for safety, put them somewhere safe.
	else
		log_debug("[src] (\ref[src]) doesn't have an owner, and dropped someone at a latespawn point!")
		var/fallback = pick(latejoin)
		return get_turf(fallback)

//Yes, it's ""safe"" to drop items here
/obj/belly/AllowDrop()
	return TRUE

/obj/belly/onDropInto(atom/movable/AM)
	return null

//Handle a mob struggling
// Called from /mob/living/carbon/relaymove()
/obj/belly/proc/relay_resist(mob/living/R, obj/item/C)
	if (!(R in contents))
		if(!C)
			return  // User is not in this belly

	R.setClickCooldown(50)

	if(owner.stat) //If owner is stat (dead, KO) we can actually escape
		to_chat(R, "<span class='warning'>You attempt to climb out of \the [lowertext(name)]. (This will take around [escapetime/10] seconds.)</span>")
		to_chat(owner, "<span class='warning'>Someone is attempting to climb out of your [lowertext(name)]!</span>")

		if(do_after(R, escapetime, owner, incapacitation_flags = INCAPACITATION_DEFAULT & ~INCAPACITATION_RESTRAINED))
			if((owner.stat || escapable)) //Can still escape?
				if(C)
					release_specific_contents(C)
					return
				if(R.loc == src)
					release_specific_contents(R)
					return
			else if(R.loc != src) //Aren't even in the belly. Quietly fail.
				return
			else //Belly became inescapable or mob revived
				to_chat(R,"<span class='warning'>Your attempt to escape [lowertext(name)] has failed!</span>")
				to_chat(owner,"<span class='notice'>The attempt to escape from your [lowertext(name)] has failed!</span>")
				return
			return
	var/struggle_outer_message = pick(struggle_messages_outside)
	var/struggle_user_message = pick(struggle_messages_inside)

	var/living_count = 0
	for(var/mob/living/L in contents)
		living_count++

	struggle_outer_message = replacetext(struggle_outer_message, "%pred", owner)
	struggle_outer_message = replacetext(struggle_outer_message, "%prey", R)
	struggle_outer_message = replacetext(struggle_outer_message, "%belly", lowertext(name))
	struggle_outer_message = replacetext(struggle_outer_message, "%count", contents.len)
	struggle_outer_message = replacetext(struggle_outer_message, "%countprey", living_count)

	struggle_user_message = replacetext(struggle_user_message, "%pred", owner)
	struggle_user_message = replacetext(struggle_user_message, "%prey", R)
	struggle_user_message = replacetext(struggle_user_message, "%belly", lowertext(name))
	struggle_user_message = replacetext(struggle_user_message, "%count", contents.len)
	struggle_user_message = replacetext(struggle_user_message, "%countprey", living_count)

	struggle_outer_message = "<span class='alert'>[struggle_outer_message]</span>"
	struggle_user_message = "<span class='alert'>[struggle_user_message]</span>"

	for(var/mob/M in hearers(4, owner))
		M.show_message(struggle_outer_message, 2) // hearable
	to_chat(R, struggle_user_message)

	var/sound/struggle_snuggle
	var/sound/struggle_rustle = sound(get_sfx("rustle"))

	if(is_wet)
		if(!fancy_vore)
			struggle_snuggle = sound(get_sfx("classic_struggle_sounds"))
		else
			struggle_snuggle = sound(get_sfx("fancy_prey_struggle"))
		playsound(src, struggle_snuggle, vary = 1, vol = 75, falloff = VORE_SOUND_FALLOFF, preference = /datum/client_preference/digestion_noises, volume_channel = VOLUME_CHANNEL_VORE)
	else
		playsound(src, struggle_rustle, vary = 1, vol = 75, falloff = VORE_SOUND_FALLOFF, preference = /datum/client_preference/digestion_noises, volume_channel = VOLUME_CHANNEL_VORE)

	if(escapable) //If the stomach has escapable enabled.
		if(prob(escapechance)) //Let's have it check to see if the prey escapes first.
			to_chat(R, "<span class='warning'>You start to climb out of \the [lowertext(name)].</span>")
			to_chat(owner, "<span class='warning'>Someone is attempting to climb out of your [lowertext(name)]!</span>")
			if(do_after(R, escapetime))
				if(escapable && C)
					release_specific_contents(C)
					to_chat(R,"<span class='warning'>Your struggles successfully cause [owner] to squeeze your container out of their \the [lowertext(name)].</span>")
					to_chat(owner,"<span class='warning'>[C] suddenly slips out of your [lowertext(name)]!</span>")
					for(var/mob/M in hearers(4, owner))
						M.show_message("<span class='warning'>[C] suddenly slips out of [owner]'s [lowertext(name)]!</span>", 2)
					return
				if((escapable) && (R.loc == src) && !R.absorbed) //Does the owner still have escapable enabled?
					release_specific_contents(R)
					to_chat(R,"<span class='warning'>You climb out of \the [lowertext(name)].</span>")
					to_chat(owner,"<span class='warning'>[R] climbs out of your [lowertext(name)]!</span>")
					for(var/mob/M in hearers(4, owner))
						M.show_message("<span class='warning'>[R] climbs out of [owner]'s [lowertext(name)]!</span>", 2)
					return
				else if(!(R.loc == src)) //Aren't even in the belly. Quietly fail.
					return
				else //Belly became inescapable.
					to_chat(R,"<span class='warning'>Your attempt to escape [lowertext(name)] has failed!</span>")
					to_chat(owner,"<span class='notice'>The attempt to escape from your [lowertext(name)] has failed!</span>")
					return

		else if(prob(transferchance) && transferlocation) //Next, let's have it see if they end up getting into an even bigger mess then when they started.
			var/obj/belly/dest_belly
			for(var/belly in owner.vore_organs)
				var/obj/belly/B = belly
				if(B.name == transferlocation)
					dest_belly = B
					break

			if(!dest_belly)
				to_chat(owner, "<span class='warning'>Something went wrong with your belly transfer settings. Your <b>[lowertext(name)]</b> has had it's transfer chance and transfer location cleared as a precaution.</span>")
				transferchance = 0
				transferlocation = null
				return

			to_chat(R, "<span class='warning'>Your attempt to escape [lowertext(name)] has failed and your struggles only results in you sliding into [owner]'s [transferlocation]!</span>")
			to_chat(owner, "<span class='warning'>Someone slid into your [transferlocation] due to their struggling inside your [lowertext(name)]!</span>")
			if(C)
				transfer_contents(C, dest_belly)
				return
			transfer_contents(R, dest_belly)
			return

		else if(prob(absorbchance) && digest_mode != DM_ABSORB) //After that, let's have it run the absorb chance.
			to_chat(R, "<span class='warning'>In response to your struggling, \the [lowertext(name)] begins to cling more tightly...</span>")
			to_chat(owner, "<span class='warning'>You feel your [lowertext(name)] start to cling onto its contents...</span>")
			digest_mode = DM_ABSORB
			return

		else if(prob(digestchance) && digest_mode != DM_DIGEST) //Finally, let's see if it should run the digest chance.
			to_chat(R, "<span class='warning'>In response to your struggling, \the [lowertext(name)] begins to get more active...</span>")
			to_chat(owner, "<span class='warning'>You feel your [lowertext(name)] beginning to become active!</span>")
			digest_mode = DM_DIGEST
			return

		else //Nothing interesting happened.
			to_chat(R, "<span class='warning'>You make no progress in escaping [owner]'s [lowertext(name)].</span>")
			to_chat(owner, "<span class='warning'>Your prey appears to be unable to make any progress in escaping your [lowertext(name)].</span>")
			return

/obj/belly/proc/get_mobs_and_objs_in_belly()
	var/list/see = list()
	var/list/belly_mobs = list()
	see["mobs"] = belly_mobs
	var/list/belly_objs = list()
	see["objs"] = belly_objs
	for(var/mob/living/L in loc.contents)
		belly_mobs |= L
	for(var/obj/O in loc.contents)
		belly_objs |= O

	return see

//Transfers contents from one belly to another
/obj/belly/proc/transfer_contents(atom/movable/content, obj/belly/target, silent = 0)
	if(!(content in src) || !istype(target))
		return
	content.forceMove(target)
	if(isitem(content))
		var/obj/item/I = content
		if(istype(I,/obj/item/weapon/card/id))
			I.gurgle_contaminate(target.contents, target.contamination_flavor, target.contamination_color)
		if(I.gurgled && target.contaminates)
			I.decontaminate()
			I.gurgle_contaminate(target.contents, target.contamination_flavor, target.contamination_color)
	items_preserved -= content
	owner.updateVRPanel()
	if(isanimal(owner))
		owner.update_icon()
	for(var/mob/living/M in contents)
		M.updateVRPanel()

// Belly copies and then returns the copy
// Needs to be updated for any var changes
/obj/belly/proc/copy(mob/new_owner)
	var/obj/belly/dupe = new /obj/belly(new_owner)

	//// Non-object variables
	dupe.name = name
	dupe.desc = desc
	dupe.vore_sound = vore_sound
	dupe.vore_verb = vore_verb
	dupe.human_prey_swallow_time = human_prey_swallow_time
	dupe.nonhuman_prey_swallow_time = nonhuman_prey_swallow_time
	dupe.emote_time = emote_time
	dupe.nutrition_percent = nutrition_percent
	dupe.digest_brute = digest_brute
	dupe.digest_burn = digest_burn
	dupe.immutable = immutable
	dupe.can_taste = can_taste
	dupe.escapable = escapable
	dupe.escapetime = escapetime
	dupe.digestchance = digestchance
	dupe.absorbchance = absorbchance
	dupe.escapechance = escapechance
	dupe.transferchance = transferchance
	dupe.transferlocation = transferlocation
	dupe.bulge_size = bulge_size
	dupe.shrink_grow_size = shrink_grow_size
	dupe.mode_flags = mode_flags
	dupe.item_digest_mode = item_digest_mode
	dupe.contaminates = contaminates
	dupe.contamination_flavor = contamination_flavor
	dupe.contamination_color = contamination_color
	dupe.release_sound = release_sound
	dupe.fancy_vore = fancy_vore
	dupe.is_wet = is_wet
	dupe.wet_loop = wet_loop
	dupe.belly_fullscreen = belly_fullscreen
	dupe.disable_hud = disable_hud
	dupe.egg_type = egg_type
	dupe.emote_time = emote_time
	dupe.emote_active = emote_active

	// ARFS EDIT
	dupe.vorespawn_blacklist = vorespawn_blacklist
	// END ARFS EDIT

	//// Object-holding variables
	//struggle_messages_outside - strings
	dupe.struggle_messages_outside.Cut()
	for(var/I in struggle_messages_outside)
		dupe.struggle_messages_outside += I

	//struggle_messages_inside - strings
	dupe.struggle_messages_inside.Cut()
	for(var/I in struggle_messages_inside)
		dupe.struggle_messages_inside += I

	//digest_messages_owner - strings
	dupe.digest_messages_owner.Cut()
	for(var/I in digest_messages_owner)
		dupe.digest_messages_owner += I

	//digest_messages_prey - strings
	dupe.digest_messages_prey.Cut()
	for(var/I in digest_messages_prey)
		dupe.digest_messages_prey += I

	//examine_messages - strings
	dupe.examine_messages.Cut()
	for(var/I in examine_messages)
		dupe.examine_messages += I

	//emote_lists - index: digest mode, key: list of strings
	dupe.emote_lists.Cut()
	for(var/K in emote_lists)
		dupe.emote_lists[K] = list()
		for(var/I in emote_lists[K])
			dupe.emote_lists[K] += I

	return dupe

/obj/belly/container_resist(mob/M)
	return relay_resist(M)