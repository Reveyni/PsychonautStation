// Ethereals:
/// How long it takes an ethereal to drain or charge APCs. Also used as a spam limiter.
#define ETHEREAL_APC_DRAIN_TIME (3 SECONDS)
/// How much power ethereals gain/drain from APCs.
#define ETHEREAL_APC_POWER_GAIN (10 * STANDARD_CELL_CHARGE)

// IPCs:
#define IPC_APC_POWER_GAIN (STANDARD_BATTERY_CHARGE)

/obj/machinery/power/apc/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(!can_interact(user))
		return
	if(!user.can_perform_action(src, ALLOW_SILICON_REACH) || !isturf(loc))
		return
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/apc_interactor = user
	var/obj/item/organ/stomach/ethereal/maybe_ethereal_stomach = apc_interactor.get_organ_slot(ORGAN_SLOT_STOMACH)
	if(!istype(maybe_ethereal_stomach))
		togglelock(user)
	else
		if(maybe_ethereal_stomach.cell.charge() >= ETHEREAL_CHARGE_NORMAL)
			togglelock(user)
		ethereal_interact(user, modifiers)

	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/// Special behavior for when an ethereal interacts with an APC.
/obj/machinery/power/apc/proc/ethereal_interact(mob/living/user, list/modifiers)
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/ethereal = user
	var/obj/item/organ/stomach/maybe_stomach = ethereal.get_organ_slot(ORGAN_SLOT_STOMACH)
	// how long we wanna wait before we show the balloon alert. don't want it to be very long in case the ethereal wants to opt-out of doing that action, just long enough to where it doesn't collide with previously queued balloon alerts.
	var/alert_timer_duration = 0.75 SECONDS

	if(!istype(maybe_stomach, /obj/item/organ/stomach/ethereal))
		return
	var/charge_limit = ETHEREAL_CHARGE_DANGEROUS - ETHEREAL_APC_POWER_GAIN
	var/obj/item/organ/stomach/ethereal/stomach = maybe_stomach
	var/obj/item/stock_parts/power_store/stomach_cell = stomach.cell
	if(!((stomach?.drain_time < world.time) && LAZYACCESS(modifiers, RIGHT_CLICK)))
		return
	if(ethereal.combat_mode)
		if(cell.charge <= (cell.maxcharge / 2)) // ethereals can't drain APCs under half charge, this is so that they are forced to look to alternative power sources if the station is running low
			addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, balloon_alert), ethereal, "safeties prevent draining!"), alert_timer_duration)
			return
		if(stomach_cell.charge() > charge_limit)
			addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, balloon_alert), ethereal, "charge is full!"), alert_timer_duration)
			return
		stomach.drain_time = world.time + ETHEREAL_APC_DRAIN_TIME
		addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, balloon_alert), ethereal, "draining power"), alert_timer_duration)
		while(do_after(user, ETHEREAL_APC_DRAIN_TIME, target = src))
			if(cell.charge <= (cell.maxcharge / 2) || (stomach_cell.charge() > charge_limit))
				return
			balloon_alert(ethereal, "received charge")
			stomach.adjust_charge(ETHEREAL_APC_POWER_GAIN)
			cell.use(ETHEREAL_APC_POWER_GAIN)
		return

	if(cell.charge >= cell.maxcharge - ETHEREAL_APC_POWER_GAIN)
		addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, balloon_alert), ethereal, "APC can't receive more power!"), alert_timer_duration)
		return
	if(stomach_cell.charge() < ETHEREAL_APC_POWER_GAIN)
		addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, balloon_alert), ethereal, "charge is too low!"), alert_timer_duration)
		return
	stomach.drain_time = world.time + ETHEREAL_APC_DRAIN_TIME
	addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, balloon_alert), ethereal, "transfering power"), alert_timer_duration)
	if(!do_after(user, ETHEREAL_APC_DRAIN_TIME, target = src))
		return
	if((cell.charge >= (cell.maxcharge - ETHEREAL_APC_POWER_GAIN)) || (stomach_cell.charge() < ETHEREAL_APC_POWER_GAIN))
		balloon_alert(ethereal, "can't transfer power!")
		return
	if(istype(stomach))
		while(do_after(user, ETHEREAL_APC_DRAIN_TIME, target = src))
			balloon_alert(ethereal, "transferred power")
			cell.give(-stomach.adjust_charge(-ETHEREAL_APC_POWER_GAIN))
	else
		balloon_alert(ethereal, "can't transfer power!")

/// Special behavior for when an ipc interacts with an APC.
/obj/machinery/power/apc/proc/ipc_interact(mob/living/user, click_parameters)
	if(!ishuman(user))
		return
	var/list/modifiers = params2list(click_parameters)
	var/mob/living/carbon/human/ipc = user
	var/obj/item/organ/internal/stomach/maybe_stomach = ipc.get_organ_slot(ORGAN_SLOT_STOMACH)
	var/obj/item/organ/internal/maybe_protector = ipc.get_organ_slot(ORGAN_SLOT_VOLTPROTECT)
	var/obj/item/organ/internal/voltage_protector/protector
	if(maybe_protector)
		if(istype(maybe_protector, /obj/item/organ/internal/voltage_protector))
			protector = maybe_protector
	// how long we wanna wait before we show the balloon alert. don't want it to be very long in case the ipc wants to opt-out of doing that action, just long enough to where it doesn't collide with previously queued balloon alerts.
	var/alert_timer_duration = 0.75 SECONDS

	if(!istype(maybe_stomach, /obj/item/organ/internal/stomach/ipc))
		return
	var/obj/item/organ/internal/stomach/ipc/stomach = maybe_stomach
	if(!stomach.cell)
		return
	var/obj/item/stock_parts/power_store/cell/ipccell = stomach.cell
	var/apcpowergain = min(ipccell.maxcharge - ipccell.charge, IPC_APC_POWER_GAIN)
	var/charge_limit = ipccell.maxcharge - apcpowergain
	if(stomach.drain_time >= world.time)
		return
	if(LAZYACCESS(modifiers, LEFT_CLICK))
		if(cell.charge <= (cell.maxcharge / 2))
			addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, balloon_alert), ipc, "safeties prevent draining!"), alert_timer_duration)
			return
		if(ipccell.charge > charge_limit)
			addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, balloon_alert), ipc, "charge is full!"), alert_timer_duration)
			return
		stomach.drain_time = world.time + ETHEREAL_APC_DRAIN_TIME
		addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, balloon_alert), ipc, "draining power"), alert_timer_duration)
		if(!protector)
			do_sparks(4, TRUE, src)
		else
			do_sparks(1, TRUE, src)
		if(do_after(user, ETHEREAL_APC_DRAIN_TIME, target = src))
			if(cell.charge <= (cell.maxcharge / 2) || (ipccell.charge > charge_limit))
				return
			balloon_alert(ipc, "received charge")
			stomach.adjust_charge(apcpowergain)
			cell.use(apcpowergain)
			charging = APC_CHARGING
			update_appearance()
			if(!protector)
				shock(user, 75)
		return
	else if(LAZYACCESS(modifiers, RIGHT_CLICK))
		if(cell.charge >= cell.maxcharge - apcpowergain)
			addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, balloon_alert), ipc, "APC can't receive more power!"), alert_timer_duration)
			return
		if(ipccell.charge < apcpowergain)
			addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, balloon_alert), ipc, "charge is too low!"), alert_timer_duration)
			return
		stomach.drain_time = world.time + ETHEREAL_APC_DRAIN_TIME
		addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, balloon_alert), ipc, "transfering power"), alert_timer_duration)
		if(!do_after(user, ETHEREAL_APC_DRAIN_TIME, target = src))
			return
		if((cell.charge >= (cell.maxcharge - apcpowergain)) || (ipccell.charge < apcpowergain))
			balloon_alert(ipc, "can't transfer power!")
			return
		if(istype(stomach))
			balloon_alert(ipc, "transfered power")
			cell.give(-stomach.adjust_charge(-IPC_APC_POWER_GAIN))
		else
			balloon_alert(ipc, "can't transfer power!")
	return

// attack with hand - remove cell (if cover open) or interact with the APC
/obj/machinery/power/apc/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return

	if(opened && (!issilicon(user)))
		if(cell)
			user.visible_message(span_notice("[user] removes \the [cell] from [src]!"))
			balloon_alert(user, "cell removed")
			user.put_in_hands(cell)
		return
	if((machine_stat & MAINT) && !opened) //no board; no interface
		return

/obj/machinery/power/apc/blob_act(obj/structure/blob/B)
	atom_break()

/obj/machinery/power/apc/take_damage(damage_amount, damage_type = BRUTE, damage_flag = "", sound_effect = TRUE, attack_dir, armor_penetration = 0)
	// APC being at 0 integrity doesnt delete it outright. Combined with take_damage this might cause runtimes.
	if(machine_stat & BROKEN && atom_integrity <= 0)
		if(sound_effect)
			play_attack_sound(damage_amount, damage_type, damage_flag)
		return
	return ..()

/obj/machinery/power/apc/run_atom_armor(damage_amount, damage_type, damage_flag = 0, attack_dir)
	if(machine_stat & BROKEN)
		return damage_amount
	. = ..()

/obj/machinery/power/apc/proc/can_use(mob/user, loud = 0) //used by attack_hand() and Topic()
	if(isAdminGhostAI(user))
		return TRUE
	if(!HAS_SILICON_ACCESS(user))
		return TRUE
	. = TRUE
	if(isAI(user) || iscyborg(user))
		if(aidisabled)
			. = FALSE
		else if(istype(malfai) && !(malfai == user || (user in malfai.connected_robots)))
			. = FALSE
	if (!. && !loud)
		balloon_alert(user, "it's disabled!")
	return .

/obj/machinery/power/apc/proc/shock(mob/user, prb)
	if(!prob(prb))
		return FALSE
	do_sparks(5, TRUE, src)
	if(isalien(user))
		return FALSE
	if(electrocute_mob(user, src, src, 1, TRUE))
		return TRUE
	else
		return FALSE

#undef IPC_APC_POWER_GAIN
#undef ETHEREAL_APC_DRAIN_TIME
#undef ETHEREAL_APC_POWER_GAIN
