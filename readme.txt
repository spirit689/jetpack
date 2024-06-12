[jetpack] Electric Jetpack v0.1.3

This mod adds an electric jetpack to game.

Depends:
*3d_armor
*hudbars
*player_monoids

How to use:
1. Craft the necessary items

Cable (jetpack:cable)
Jetpack Battery Core (jetpack:battery_core)
Jetpack Battery (jetpack:battery)
Blades (jetpack:blades)
Electric Engine (jetpack:motor)
Jetpack (jetpack:jetpack)
Charging Capsule (jetpack:charging_capsule)

2. Equip jetpack and use the charging capsules. 150000 EU by default gives 10 minutes of flight.
This mod supports мodifications 'technic' and 'elepower'. In this case Charging Capsule not available,
just put jetpack into charging device (Energy Cell or Battery Box).

3. When jetpack is equipped and charged, hold Space to fly up. Release Space while in the air to hover, and hold Shift to fly down.

4. The limit of altitude does not exist, so... don't fall if the power went out)

0.1.3
- recipes for crafting items have been changed
- no more required dependency on 'technic' mod
- added small charging capsules
- added support for Energy Cell from 'elepower'
- takeoff speed slightly reduced
- fixed error with init hudbar on player join
- fixed deprecated get_metadata

0.1.2
- remove derecated player:getpos
- player:meta merged into one variable
- fix swap one jetpack with another in armor slot
- the charge level should be correctly loaded when re-entering the game

0.1.1
- change flight algorithm
- add 'player_monoids' support
- fix case when you leave the game in the air

0.1.0
- up for minetest v5
- refactor code
- add new bugs :P

0.0.1
- first release
