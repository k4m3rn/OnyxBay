/* Glass stack types
 * Contains:
 *		Glass sheets
 *		Reinforced glass sheets
 *		Plasma Glass Sheets
 *		Reinforced Plasma Glass Sheets (AKA Holy fuck strong windows)
 *		Glass shards - TODO: Move this into code/game/object/item/weapons
 */

/*
 * Glass sheets
 */
/obj/item/stack/material/glass
	name = "glass"
	singular_name = "glass sheet"
	icon_state = "glass"
	var/created_window = /obj/structure/window/basic
	var/created_windoor_assembly = null
	var/is_reinforced = 0
	var/list/construction_options = list("One Direction", "Full Window")
	default_type = "glass"

/obj/item/stack/material/glass/attack_self(mob/user as mob)
	construct_window(user)

/obj/item/stack/material/glass/attackby(obj/item/W, mob/user)
	..()
	if(!is_reinforced)
		if(isCoil(W))
			var/obj/item/stack/cable_coil/CC = W
			if (get_amount() < 1 || CC.get_amount() < 5)
				to_chat(user, "<span class='warning'>You need five lengths of coil and one sheet of glass to make wired glass.</span>")
				return

			CC.use(5)
			use(1)
			to_chat(user, "<span class='notice'>You attach wire to the [name].</span>")
			new /obj/item/stack/light_w(user.loc)
		else if(istype(W, /obj/item/stack/rods))
			var/obj/item/stack/rods/V  = W
			if (V.get_amount() < 1 || get_amount() < 1)
				to_chat(user, "<span class='warning'>You need one rod and one sheet of glass to make reinforced glass.</span>")
				return

			var/obj/item/stack/material/glass/reinforced/RG = new (user.loc)
			RG.add_to_stacks(user)
			var/obj/item/stack/material/glass/G = src
			src = null
			var/replace = (user.get_inactive_hand()==G)
			V.use(1)
			G.use(1)
			if(!G && replace)
				user.pick_or_drop(RG)

/obj/item/stack/material/glass/proc/construct_window(mob/user as mob)
	if(!user || !src)	return 0
	if(!istype(user.loc,/turf)) return 0
	if(!user.IsAdvancedToolUser())
		return 0
	var/title = "Sheet-[name]"
	title += " ([src.get_amount()] sheet\s left)"
	switch(input(title, "What would you like to construct?") as null|anything in construction_options)
		if("One Direction")
			if(!src)	return 1
			if(src.loc != user)	return 1

			var/list/directions = new /list(cardinal)
			var/i = 0
			for (var/obj/structure/window/win in user.loc)
				i++
				if(i >= 4)
					to_chat(user, "<span class='warning'>There are too many windows in this location.</span>")
					return 1
				directions-=win.dir
				if(!(win.dir in cardinal))
					to_chat(user, "<span class='warning'>Can't let you do that.</span>")
					return 1

			//Determine the direction. It will first check in the direction the person making the window is facing, if it finds an already made window it will try looking at the next cardinal direction, etc.
			var/dir_to_set = 2
			for(var/direction in list( user.dir, turn(user.dir,90), turn(user.dir,180), turn(user.dir,270) ))
				var/found = 0
				for(var/obj/structure/window/WT in user.loc)
					if(WT.dir == direction)
						found = 1
				if(!found)
					dir_to_set = direction
					break
			new created_window( user.loc, dir_to_set, 1 )
			src.use(1)
		if("Full Window")
			if(!src)	return 1
			if(src.loc != user)	return 1
			if(src.get_amount() < 4)
				to_chat(user, "<span class='warning'>You need more glass to do that.</span>")
				return 1
			if(locate(/obj/structure/window) in user.loc)
				to_chat(user, "<span class='warning'>There is a window in the way.</span>")
				return 1
			new created_window( user.loc, SOUTHWEST, 1 )
			src.use(4)
		if("Windoor")
			if(!is_reinforced) return 1


			if(!src || src.loc != user) return 1

			if(isturf(user.loc) && locate(/obj/structure/windoor_assembly/, user.loc))
				to_chat(user, "<span class='warning'>There is already a windoor assembly in that location.</span>")
				return 1

			if(isturf(user.loc) && locate(/obj/machinery/door/window/, user.loc))
				to_chat(user, "<span class='warning'>There is already a windoor in that location.</span>")
				return 1

			if(src.get_amount() < 5)
				to_chat(user, "<span class='warning'>You need more glass to do that.</span>")
				return 1

			new created_windoor_assembly(user.loc, user.dir, 1)
			src.use(5)

	return 0


/*
 * Reinforced glass sheets
 */
/obj/item/stack/material/glass/reinforced
	name = "reinforced glass"
	singular_name = "reinforced glass sheet"
	icon_state = "rglass"
	default_type = "reinforced glass"
	created_window = /obj/structure/window/reinforced
	is_reinforced = 1
	construction_options = list("One Direction", "Full Window", "Windoor")
	created_windoor_assembly = /obj/structure/windoor_assembly

/*
 * Plasma Glass sheets
 */
/obj/item/stack/material/glass/plass
	name = "plass"
	singular_name = "plass sheet"
	icon_state = "plass"
	created_window = /obj/structure/window/plasmabasic
	default_type = "plass"

/obj/item/stack/material/glass/plass/attackby(obj/item/W, mob/user)
	..()
	if( istype(W, /obj/item/stack/rods) )
		var/obj/item/stack/rods/V  = W
		var/obj/item/stack/material/glass/rplass/RG = new (user.loc)
		RG.add_fingerprint(user)
		RG.add_to_stacks(user)
		V.use(1)
		var/obj/item/stack/material/glass/G = src
		src = null
		var/replace = (user.get_inactive_hand()==G)
		G.use(1)
		if(!G && !RG && replace)
			user.pick_or_drop(RG)
	else
		return ..()

/*
 * Reinforced plasma glass sheets
 */
/obj/item/stack/material/glass/rplass
	name = "reinforced plass"
	singular_name = "reinforced plass sheet"
	icon_state = "rplass"
	default_type = "reinforced plass"
	created_window = /obj/structure/window/plasmareinforced
	created_windoor_assembly = /obj/structure/windoor_assembly/plasma
	is_reinforced = 1
	construction_options = list("One Direction", "Full Window", "Windoor")
