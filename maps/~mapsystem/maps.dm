GLOBAL_DATUM_INIT(using_map, /datum/map, text2path(copytext(file2text("data/use_map"),1,-1)) || USING_MAP_DATUM; using_map = new using_map)
GLOBAL_LIST_EMPTY(all_maps)

var/const/MAP_HAS_BRANCH = 1	//Branch system for occupations, togglable
var/const/MAP_HAS_RANK = 2		//Rank system, also togglable

/hook/startup/proc/initialise_map_list()
	for(var/type in typesof(/datum/map) - /datum/map)
		var/datum/map/M
		if(type == GLOB.using_map.type)
			M = GLOB.using_map
			M.setup_map()
		else
			M = new type
		if(!M.path)
			log_error("Map '[M]' does not have a defined path, not adding to map list!")
		else
			GLOB.all_maps[M.name] = M
	return 1


/datum/map
	var/name = "Unnamed Map"
	var/full_name = "Unnamed Map"
	var/path

	var/list/station_levels = list() // Z-levels the station exists on
	var/list/admin_levels = list()   // Z-levels for admin functionality (Centcom, shuttle transit, etc)
	var/list/contact_levels = list() // Z-levels that can be contacted from the station, for eg announcements
	var/list/player_levels = list()  // Z-levels a character can typically reach
	var/list/sealed_levels = list()  // Z-levels that don't allow random transit at edge and vortex teleport
	var/list/empty_levels = null     // Empty Z-levels that may be used for various things (currently used by bluespace jump)

	var/list/map_levels              // Z-levels available to various consoles, such as the crew monitor. Defaults to station_levels if unset.

	var/list/dynamic_z_levels        // Z-levels to load in runtime

	var/list/base_turf_by_z = list() // Custom base turf by Z-level. Defaults to world.turf for unlisted Z-levels
	var/list/usable_email_tlds = list("freemail.nt")
	var/base_floor_type = /turf/simulated/floor/plating/airless // The turf type used when generating floors between Z-levels at startup.
	var/base_floor_area                                 // Replacement area, if a base_floor_type is generated. Leave blank to skip.

	//This list contains the z-level numbers which can be accessed via space travel and the percentile chances to get there.
	var/list/accessible_z_levels = list()

	var/list/allowed_jobs          //Job datums to use.
	                               //Works a lot better so if we get to a point where three-ish maps are used
	                               //We don't have to C&P ones that are only common between two of them
	                               //That doesn't mean we have to include them with the rest of the jobs though, especially for map specific ones.
	                               //Also including them lets us override already created jobs, letting us keep the datums to a minimum mostly.
	                               //This is probably a lot longer explanation than it needs to be.

	var/station_name  = "BAD Station"
	var/station_short = "Baddy"
	var/dock_name     = "THE PirateBay"
	var/boss_name     = "Captain Roger"
	var/boss_short    = "Cap'"
	var/company_name  = "BadMan"
	var/company_short = "BM"
	var/system_name = "Uncharted System"

	var/map_admin_faxes = list()

	var/shuttle_docked_message
	var/shuttle_leaving_dock
	var/shuttle_called_message
	var/shuttle_recall_message
	var/emergency_shuttle_docked_message
	var/emergency_shuttle_leaving_dock
	var/emergency_shuttle_recall_message

	var/list/station_networks = list() 		// Camera networks that will show up on the console.

	var/list/holodeck_programs = list() // map of string ids to /datum/holodeck_program instances
	var/list/holodeck_supported_programs = list() // map of maps - first level maps from list-of-programs string id (e.g. "BarPrograms") to another map
												  // this is in order to support multiple holodeck program listings for different holodecks
	                                              // second level maps from program friendly display names ("Picnic Area") to program string ids ("picnicarea")
	                                              // as defined in holodeck_programs
	var/list/holodeck_restricted_programs = list() // as above... but EVIL!

	var/allowed_spawns = list("Arrivals Shuttle","Gateway", "Cryogenic Storage", "Cyborg Storage")
	var/default_spawn = "Arrivals Shuttle"
	var/flags = 0
	var/evac_controller_type = /datum/evacuation_controller

	var/lobby_icon									// The icon which contains the lobby image(s)
	var/list/lobby_screens = list()                 // The list of lobby screen to pick() from. If left unset the first icon state is always selected.
	var/lobby_music/lobby_music                     // The track that will play in the lobby screen. Handed in the /setup_map() proc.
	var/welcome_sound = 'sound/signals/start1.ogg'	// Sound played on roundstart

	var/default_law_type = /datum/ai_laws/nanotrasen  // The default lawset use by synth units, if not overriden by their laws var.
	var/security_state = /decl/security_state/default // The default security state system to use.

	var/id_hud_icons = 'icons/mob/hud.dmi' // Used by the ID HUD (primarily sechud) overlay.

	var/list/loadout_blacklist	//list of types of loadout items that will not be pickable
	var/legacy_mode = FALSE // When TRUE, some things (like walls and windows) use their classical appearance and mechanics

	//Economy stuff
	var/starting_money = 75000		//Money in station account
	var/department_money = 5000		//Money in department accounts
	var/salary_modifier	= 1			//Multiplier to starting character money
	var/station_departments = list()//Gets filled automatically depending on jobs allowed

	//Factions prefs stuff
	var/list/faction_choices = list(
		"NanoTrasen", // NanoTrasen must be first, else Company Provocation event will break
		"Liu-Je Green Terraforming Industries",
		"Charcoal TestLabs Ltd.",
		"Blue Oceanic Explorers",
		"Milky Way Trade Union",
		"Redknight & Company Dominance Tech",
		"Indigo Special Research Collaboration"
		)

	var/list/citizenship_choices = list(
		"NanoTrasen",
		"Nova Magnitka Government",
		"Gaia Magna",
		"Moghes",
		"Ahdomai",
		"Qerrbalak",
		"Parish of the Parthenonnus Ark"
		)

	var/list/home_system_choices = list(
		"Nova Magnitka",
		"Tau Ceti",
		"Epsilon Ursae Minoris",
		"Zermig VIII",
		"Arcturia",
		"Gaia Magna",
		"Parthenonnus Ark Space Vessel"
		)

	var/list/religion_choices = list(
		"Pan-Christian United Church",
		"Mahadeva Marga",
		"Buddhism",
		"Allah Chosen Devotees",
		"A-Kami",
		"Geng Hao Dao",
		"Jesus Witnesses",
		"Syncretism",
		"Neohumanism",
		"Agnosticism",
		"Atheism"
		)

/datum/map/New()
	if(!map_levels)
		map_levels = station_levels.Copy()
	if(!allowed_jobs)
		allowed_jobs = subtypesof(/datum/job)

/datum/map/proc/setup_map()
	if(dynamic_z_levels)
		for(var/level = 1; level <= length(dynamic_z_levels); level++)
			log_to_dd("Loading map '[dynamic_z_levels[level]]' at [level]")
			maploader.load_map(dynamic_z_levels[level], 1, 1, level, FALSE, FALSE, TRUE, FALSE)

	world.update_status()
	var/list/antags = GLOB.all_antag_types_
	for(var/id in antags)
		var/datum/antagonist/A = antags[id]
		A.get_starting_locations()

/datum/map/proc/send_welcome()
	return

/datum/map/proc/perform_map_generation()
	return

// Used to apply various post-compile procedural effects to the map.
/datum/map/proc/refresh_mining_turfs(zlevel)

	set background = 1
	set waitfor = 0

	for(var/thing in mining_walls["[zlevel]"])
		var/turf/simulated/mineral/M = thing
		M.update_icon()
	for(var/thing in mining_floors["[zlevel]"])
		var/turf/simulated/floor/asteroid/M = thing
		if(istype(M))
			M.updateMineralOverlays()

/datum/map/proc/get_network_access(network)
	return 0

// By default transition randomly to another zlevel
/datum/map/proc/get_transit_zlevel(current_z_level)
	var/list/candidates = GLOB.using_map.accessible_z_levels.Copy()
	candidates.Remove(num2text(current_z_level))

	if(!candidates.len)
		return current_z_level
	return text2num(pickweight(candidates))

/datum/map/proc/get_empty_zlevel()
	if(empty_levels == null)
		world.maxz++
		empty_levels = list(world.maxz)
	return pick(empty_levels)


/datum/map/proc/setup_economy()
	news_network.CreateFeedChannel("Nyx Daily", "SolGov Minister of Information", 1, 1)
	news_network.CreateFeedChannel("The Gibson Gazette", "Editor Mike Hammers", 1, 1)

	for(var/loc_type in typesof(/datum/trade_destination) - /datum/trade_destination)
		var/datum/trade_destination/D = new loc_type
		weighted_randomevent_locations[D] = D.viable_random_events.len
		weighted_mundaneevent_locations[D] = D.viable_mundane_events.len

	if(!station_account)
		station_account = create_account("[station_name()] Primary Account", starting_money)

	for(var/job in allowed_jobs)
		var/datum/job/J = decls_repository.get_decl(job)
		if(J.department)
			station_departments |= J.department
	for(var/department in station_departments)
		department_accounts[department] = create_account("[department] Account", department_money)

	department_accounts["Vendor"] = create_account("Vendor Account", 0)
	vendor_account = department_accounts["Vendor"]

/datum/map/proc/map_info(client/victim)
	return
// Access check is of the type requires one. These have been carefully selected to avoid allowing the janitor to see channels he shouldn't
// This list needs to be purged but people insist on adding more cruft to the radio.
/datum/map/proc/default_internal_channels()
	return list(
		num2text(PUB_FREQ)   = list(),
		num2text(AI_FREQ)    = list(access_synth),
		num2text(ENT_FREQ)   = list(),
		num2text(ERT_FREQ)   = list(access_cent_specops),
		num2text(COMM_FREQ)  = list(access_heads),
		num2text(ENG_FREQ)   = list(access_engine_equip, access_atmospherics),
		num2text(MED_FREQ)   = list(access_medical_equip),
		num2text(MED_I_FREQ) = list(access_medical_equip),
		num2text(SEC_FREQ)   = list(access_security),
		num2text(SEC_I_FREQ) = list(access_security),
		num2text(SCI_FREQ)   = list(access_tox,access_robotics,access_xenobiology),
		num2text(SUP_FREQ)   = list(access_cargo),
		num2text(SRV_FREQ)   = list(access_janitor, access_hydroponics),
	)
