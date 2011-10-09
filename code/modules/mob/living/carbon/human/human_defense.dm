/*
Contains most of the procs that are called when a mob is attacked by something

bullet_act
ex_act
meteor_act
emp_act

*/

/mob/living/carbon/human/bullet_act(var/obj/item/projectile/P, var/def_zone)
	if(check_shields(P.damage, "the [P.name]"))
		P.on_hit(src, 2)
		return 2
	return (..())


/mob/living/carbon/human/getarmor(var/def_zone, var/type)
	var/armorval = 0
	var/organnum = 0

	if(def_zone)
		if(isorgan(def_zone))
			return checkarmor(def_zone, type)
		var/datum/organ/external/affecting = get_organ(ran_zone(def_zone))
		return checkarmor(affecting, type)
		//If a specific bodypart is targetted, check how that bodypart is protected and return the value.

	//If you don't specify a bodypart, it checks ALL your bodyparts for protection, and averages out the values
	for(var/datum/organ/external/organ in organs)
		if(istype(organ))
			armorval += checkarmor(organ, type)
			organnum++
	return armorval/max(organnum, 1)


/mob/living/carbon/human/proc/checkarmor(var/datum/organ/external/def_zone, var/type)
	if(!type)	return 0
	var/protection = 0
	var/list/body_parts = list(head, wear_mask, wear_suit, w_uniform)
	for(var/bp in body_parts)
		if(!bp)	continue
		if(bp && istype(bp ,/obj/item/clothing))
			var/obj/item/clothing/C = bp
			if(C.body_parts_covered & def_zone.body_part)
				protection += C.armor[type]
	return protection


/mob/living/carbon/human/proc/check_shields(var/damage = 0, var/attack_text = "the attack")
	var/list/hand_held_shields = list("/obj/item/weapon/shield/riot","/obj/item/weapon/melee/energy/sword")
	if(l_hand && is_type_in_list(l_hand, hand_held_shields))//Current base is the prob(50-d/3)
		if(prob(50 - round(damage / 3)))
			show_message("\red You block [attack_text] with your [l_hand.name]!", 4)
			return 1
	if(r_hand && is_type_in_list(r_hand, hand_held_shields))
		if(prob(50 - round(damage / 3)))
			show_message("\red You block [attack_text] with your [l_hand.name]!", 4)
			return 1
	return 0


/mob/living/carbon/human/emp_act(severity)
	for(var/obj/O in src)
		if(!O)	continue
		O.emp_act(severity)
	..()


/mob/living/carbon/human/proc/attacked_by(var/obj/item/I, var/mob/living/user, var/def_zone)
	if(!I || !user)	return 0

	var/datum/organ/external/affecting = get_organ(ran_zone(user.zone_sel.selecting))
	var/hit_area = parse_zone(affecting.name)

	visible_message("\red <B>[src] has been attacked in the [hit_area] with [I.name] by [user]!</B>")

	if(check_shields(I.force, "the [I.name]"))
		return 0
	var/armor = run_armor_check(affecting, "melee", "Your armor has protected you from a hit to the [hit_area].", "Your armor has softened hit to your [hit_area].")
	if(armor >= 2)	return 0
	apply_damage(I.force, I.damtype, affecting, armor)

	var/bloody = 0
	if((I.damtype == BRUTE) && prob(25 + (I.force * 2)))
		src.add_blood(src)
		if(prob(33))
			bloody = 1
			var/turf/location = loc
			if(istype(location, /turf/simulated))
				location.add_blood(src)
			if(ishuman(user))
				var/mob/living/carbon/human/H = user
				if(H.gloves)			H.gloves.add_blood(src)
				else					H.add_blood(src)
				if(H.wear_suit)			H.wear_suit.add_blood(src)
				else if(H.w_uniform)	H.w_uniform.add_blood(src)

		switch(hit_area)
			if("head")//Harder to score a stun but if you do it lasts a bit longer
				if(prob(I.force))
					apply_effect(20, PARALYZE, armor)
					visible_message("\red <B>[src] has been knocked unconscious!</B>")
					if(src != user)
						ticker.mode.remove_revolutionary(mind)

				if(bloody)//Apply blood
					if(wear_mask)				wear_mask.add_blood(src)
					if(head)					head.add_blood(src)
					if(glasses && prob(33))		glasses.add_blood(src)

			if("chest")//Easier to score a stun but lasts less time
				if(prob((I.force + 10)))
					apply_effect(5, WEAKEN, armor)
					visible_message("\red <B>[src] has been knocked down!</B>")

				if(bloody)
					if(src.wear_suit)	src.wear_suit.add_blood(src)
					if(src.w_uniform)	src.w_uniform.add_blood(src)
	src.UpdateDamageIcon()