/datum/species/ipc
	name = "\improper IPC"
	id = SPECIES_IPC
	examine_limb_id = SPECIES_HUMAN
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_PRIDE | MIRROR_MAGIC | RACE_SWAP | ERT_SPAWN
	inherent_biotypes = MOB_ROBOTIC | MOB_HUMANOID
	species_language_holder = /datum/language_holder/synthetic
	sexes = FALSE
	inherent_traits = list(
		TRAIT_NO_UNDERWEAR,
		TRAIT_GENELESS,
		TRAIT_NOBREATH,
		TRAIT_RESISTCOLD,
		TRAIT_LIVERLESS_METABOLISM,
		TRAIT_RADIMMUNE,
		TRAIT_TOXIMMUNE,
		TRAIT_NO_DNA_COPY,
		TRAIT_XENO_IMMUNE,
		TRAIT_NOHUNGER,
		TRAIT_NOTOOLFLASH,
		TRAIT_VIRUSIMMUNE,
		TRAIT_LIGHTBULB_REMOVER,
	)
	meat = null
	exotic_blood = /datum/reagent/fuel/oil
	exotic_bloodtype = "LPG"
	siemens_coeff = 0.8
	no_equip_flags = ITEM_SLOT_EYES | ITEM_SLOT_MASK
	mutanteyes = /obj/item/organ/internal/eyes/robotic/basic
	mutantears = /obj/item/organ/internal/ears/cybernetic
	mutanttongue = /obj/item/organ/internal/tongue/robot
	mutantbrain = /obj/item/organ/internal/brain/ipc
	mutantheart = null
	mutantlungs = null
	mutantliver = null
	mutantstomach = /obj/item/organ/internal/stomach/ipc
	mutantappendix = null
	bodypart_overrides = list(
		BODY_ZONE_HEAD = /obj/item/bodypart/head/ipc,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/ipc,
		BODY_ZONE_L_ARM = /obj/item/bodypart/arm/left/ipc,
		BODY_ZONE_R_ARM = /obj/item/bodypart/arm/right/ipc,
		BODY_ZONE_L_LEG = /obj/item/bodypart/leg/left/ipc,
		BODY_ZONE_R_LEG = /obj/item/bodypart/leg/right/ipc,
	)
	gibspawner = /obj/effect/gibspawner/robot/android


/datum/species/ipc/on_species_gain(mob/living/carbon/human/ipc, datum/species/old_species, pref_load)
	. = ..()
	var/datum/sprite_accessory/ipc_chassis/chassis_of_choice = SSaccessories.ipc_chassis_list[ipc.dna.features["ipc_chassis"]]
	for(var/obj/item/bodypart/BP as() in ipc.bodyparts)
		BP.icon = 'icons/psychonaut/mob/human/species/ipc/bodyparts.dmi'
		BP.change_appearance('icons/psychonaut/mob/human/species/ipc/bodyparts.dmi', chassis_of_choice.icon_state, FALSE, FALSE)
		BP.update_limb()

/datum/species/ipc/randomize_features()
	var/list/features = ..()
	features["ipc_chassis"] = SSaccessories.ipc_chassis_list[pick(SSaccessories.ipc_chassis_list)]
	return features

/datum/species/ipc/get_features()
	var/list/features = ..()

	features += "feature_ipc_chassis"

	return features

/datum/species/ipc/get_species_description()
	return "The newest in artificial life, IPCs are entirely robotic, synthetic life, made of motors, circuits, and wires \
	- based on newly developed Postronic brain technology."

/datum/species/ipc/get_species_lore()
	return list(
		"Positronic intelligence really took off in the 26th century, and it is not uncommon to see independent, free-willed \
		robots on many human stations, particularly in fringe systems where standards are slightly lax and public opinion less relevant \
		to corporate operations.",
		"IPCs (Integrated Positronic Chassis) are a loose category of self-willed robots with a humanoid form, \
		generally self-owned after being 'born' into servitude; they are reliable and dedicated workers, albeit more than slightly \
		inhuman in outlook and perspective."
	)

/datum/species/ipc/create_pref_unique_perks()
	var/list/to_add = list()

	to_add += list(
		list(
			SPECIES_PERK_TYPE = SPECIES_POSITIVE_PERK,
			SPECIES_PERK_ICON = "bolt",
			SPECIES_PERK_NAME = "Shockingly Tasty",
			SPECIES_PERK_DESC = "IPCs can feed on electricity from APCs, and do not otherwise need to eat.",
		),
		list(
			SPECIES_PERK_TYPE = SPECIES_NEUTRAL_PERK,
			SPECIES_PERK_ICON = "robot",
			SPECIES_PERK_NAME = "Robotic",
			SPECIES_PERK_DESC = "IPCs have an entirely robotic body, meaning medical care is typically done through Robotics or Engineering. \
			Whether this is helpful or not is heavily dependent on your coworkers. It does, however, mean you are usually able to perform self-repairs easily.",
		),
		list(
			SPECIES_PERK_TYPE = SPECIES_NEGATIVE_PERK,
			SPECIES_PERK_ICON = "battery-quarter",
			SPECIES_PERK_NAME = "Cell Battery",
			SPECIES_PERK_DESC = "If you run out of charge, you can't move.",
		),
		list(
			SPECIES_PERK_TYPE = SPECIES_NEGATIVE_PERK,
			SPECIES_PERK_ICON = "magnet",
			SPECIES_PERK_NAME = "EMP Vulnerable",
			SPECIES_PERK_DESC = "IPCs organs are cybernetic, and thus susceptible to electromagnetic interference.",
		),
		list(
			SPECIES_PERK_TYPE = SPECIES_NEGATIVE_PERK,
			SPECIES_PERK_ICON = "droplet",
			SPECIES_PERK_NAME = "Short Circuit",
			SPECIES_PERK_DESC = "IPCs are not resistant to water, water creates a short circuit in IPC's.",
		),
	)

	return to_add

/datum/species/ipc/handle_environment_pressure(mob/living/carbon/human/H, datum/gas_mixture/environment, seconds_per_tick, times_fired)
	. = ..()

	var/pressure = environment.return_pressure()
	var/adjusted_pressure = H.calculate_affecting_pressure(pressure)

	if(adjusted_pressure >= HAZARD_HIGH_PRESSURE && !HAS_TRAIT(H, TRAIT_RESISTHIGHPRESSURE))
		H.adjustBruteLoss(min(((adjusted_pressure / HAZARD_HIGH_PRESSURE) - 1) * PRESSURE_DAMAGE_COEFFICIENT, MAX_HIGH_PRESSURE_DAMAGE) * 1.5 * H.physiology.pressure_mod * seconds_per_tick, required_bodytype = BODYTYPE_ORGANIC | BODYTYPE_IPC)
	else if(adjusted_pressure < HAZARD_LOW_PRESSURE && !HAS_TRAIT(H, TRAIT_RESISTLOWPRESSURE))
		H.adjustBruteLoss(LOW_PRESSURE_DAMAGE * 1.5 * H.physiology.pressure_mod * seconds_per_tick, required_bodytype = BODYTYPE_ORGANIC | BODYTYPE_IPC)
