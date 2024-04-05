<div align="center">

[![Drugs Banner](https://i.imgur.com/dvfQyWE.png)](https://github.com/inseltreff-net/it-drugs?tab=readme-ov-file#it-drugs "Go to repo")

</div>

## it-drugs
[![FiveM](https://img.shields.io/badge/FiveM-Ready-success)]()
[![GitHub issues](https://img.shields.io/github/issues/inseltreff-net/it-drugs)]()
[![Version](https://img.shields.io/github/v/release/inseltreff-net/it-drugs)]()
[![License](https://img.shields.io/github/license/inseltreff-net/it-drugs)]()

Become a master herbalist with this comprehensive script! Grow a variety of plants, each with unique properties. Process your harvest into consumable concoctions or soothing remedies.


### THIS IS A BETA VERSION AND MAY CONTAIN BUGS. PLEASE REPORT ANY ISSUES YOU ENCOUNTER.

<div align="center">

![Smallheists Banner](https://i.imgur.com/Wi7CEat.png)

</div>

- [x] Growing plants
- [x] Creating drugs yourself
- [x] Processing tables
- [x] Growth speed zones
- [] Sell drugs to NPC (will come in one of the next updates)
- [x] Unlimted plants
- [x] Configurable

### Dependencies
#### Required
- [PolyZone](https://github.com/mkafrin/PolyZone)
- [ox-lib](https://github.com/overextended/ox_lib)
#### Optional
- [ox-target](https://github.com/overextended/ox_target)*
- [qb-target]()

<div align="center">

![Smallheists Banner](https://i.imgur.com/9cXbmut.png)

</div>
<details><summary><b>QbCore</b> (Click to view)</summary>
1. Download the script and put it in your resources folder.<br>
2. Add the items to your `qb-core/shared/items.lua` file <br>
3. Make sure you have all the dependencies installed. (See Dependencies)<br>
4. Make sure that all the dependencies are started before you start this script.
5. Configure the script to your liking.<br>
6. Restart your server and you are good to go!<br>

## Items
Add the following items to your `qb-core/shared/items.lua` file.
You can also change the items in the config files to your liking. You also find the items in the `items/items.lua` file in the script folder.
```lua
--it-smallheists
watering_can                 = {name = "watering_can", 				    label = 'watering can', 			weight = 500, 		type = 'item', 		image = "watering_can.png", 		    unique = false, 	useable = false, 	shouldClose = false,    combinable = nil,   description = 'simple watering can'},
weed_lemonhaze_seed		    = {name = 'weed_lemonhaze_seed', 			label = 'weed lemonhaze seed', 	    weight = 20, 		type = 'item', 		image = 'weed_lemonhaze_seed.png', 		unique = false, 	useable = true, 	shouldClose = true,	    combinable = nil,   description = 'Seeeds'},
weed_lemonhaze				 = {name = 'weed_lemonhaze', 			  	label = 'weed lemonhaze', 			weight = 20, 		type = 'item', 		image = 'weed_lemonhaze.png', 		   	unique = false, 	useable = false, 	shouldClose = false,	combinable = nil,   description = 'Funny Description'},
coca_seed 				     = {name = 'coca_seed', 			  	   	label = 'coca seed', 			    weight = 20, 		type = 'item', 		image = 'coca_seed.png', 		   	    unique = false, 	useable = true, 	shouldClose = true,	    combinable = nil,   description = 'Funny Description'},
coca 				        = {name = 'coca', 			  	   	label = 'coca', 			    weight = 20, 		type = 'item', 		image = 'coca.png', 		   	    unique = false, 	useable = true, 	shouldClose = true,	    combinable = nil,   description = 'Funny Description'},
paper 				 		 = {name = 'paper', 			    		label = 'paper', 					weight = 50, 	    type = 'item', 		image = 'paper.png', 				    unique = false, 	useable = false, 	shouldClose = false,    combinable = nil,   description = 'Funny Description'},
nitrous 				     = {name = 'nitrous', 			    		label = 'nitrous', 					weight = 500, 	    type = 'item', 		image = 'nitrous.png', 				    unique = false, 	useable = false, 	shouldClose = false,    combinable = nil,   description = 'Funny Description'},
fertilizer 				     = {name = 'fertilizer', 			    		label = 'fertilizer', 					weight = 500, 	    type = 'item', 		image = 'nitrous.png', 				    unique = false, 	useable = false, 	shouldClose = false,    combinable = nil,   description = 'Funny Description'},
cocaine 				     = {name = 'cocaine', 			    		label = 'cocaine', 					weight = 20, 	    type = 'item', 		image = 'fertilizer.png', 				    unique = false, 	useable = false, 	shouldClose = false,     combinable = nil,   description = 'Funny Description'},
joint 				 		 = {name = 'joint', 			    		label = 'joint', 					weight = 10, 	    type = 'item', 		image = 'joint.png', 				    unique = false, 	useable = true, 	shouldClose = true,     combinable = nil,   description = 'Funny Description'},
weed_processing_table 		 = {name = 'weed_processing_table', 	    label = 'weed processing table', 	weight = 50, 	    type = 'item', 		image = 'weed_processing_table.png', 	unique = false, 	useable = true, 	shouldClose = true,     combinable = nil,   description = 'Funny Description'},
cocaine_processing_table 	 = {name = 'cocaine_processing_table', 	    label = 'cocaine processing table', weight = 50, 	    type = 'item', 		image = 'cocaine_processing_table.png', unique = false, 	useable = true, 	shouldClose = true,     combinable = nil,   description = 'Funny Description'},
```
</details>


<details><summary><b>ESX</b> (Click to view)</summary>
1. Download the script and put it in your resources folder.<br>
2. Add the items to your `qb-core/shared/items.lua` file <br>
3. Make sure you have all the dependencies installed. (See Dependencies)<br>
4. Make sure that all the dependencies are started before you start this script.<br>
5. Configure the script to your liking.<br>
6. Restart your server and you are good to go!<br>

## Items
Add the following items to your database.
You can also change the items in the config files to your liking. You also find the items in the `items/items.sql` file in the script folder.
```sql
-- Items for it-drugs
INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES
	('watering_can', 'Watering Can', 1, 0, 1),
	('weed_lemonhaze_seed', 'Weed Lemonhaze Seed', 1, 0, 1),
	('weed_lemonhaze', 'Weed Lemonhaze', 1, 0, 1),
	('coca_seed', 'Coca Seed', 1, 0, 1),
	('coca', 'Coca', 1, 0, 1),
	('paper', 'Paper', 1, 0, 1),
	('nitrous', 'nitrous', 1, 0, 1),
	('fertilizer', 'fertilizer', 1, 0, 1),
	('water_bottle', 'water_bottle', 1, 0, 1),
	('cocaine', 'cocaine', 1, 0, 1),
	('joint', 'joint', 1, 0, 1),
	('weed_processing_table', 'weed_processing_table', 1, 0, 1),
	('cocaine_processing_table', 'cocaine_processing_table', 1, 0, 1)
;
```
</details>

<div align="center">

![Smallheists Banner](https://i.imgur.com/DFF7Xh1.png)
### Will be added with one of the next updates
</div>
 
