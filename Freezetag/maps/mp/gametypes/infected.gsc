#include maps/mp/_utility;
#include common_scripts/utility;
#include maps/mp/gametypes/_globallogic;
#include maps/mp/gametypes/_hud_util;

/**
    T6 Infected.
    Updated: 15/03/2021.
    Version: 0.2.
    Authors: Birchy & JezuzLizard.
	Features:
	-Player quota.
	-Infection countdown.
	-Survivor/Infected/First infected loadouts.
	-Infection behaviour.
	-Survivor/Infected win condition and end text.
	-Team score is player count.
 */

 /**
	TODO (Not all possible as of 12/03/2021):
	-Randomised first spawn.
	-Remove class select prompt.
	-Remove team switch ui.
	-Popups for infection.
	-Score for surviving.
	-Audio queues.
	-Randomised loadouts.
	-Specialist streaks.
	-MOAB.
	-Team names.
	-Gamemode name.
  */

init(){
	level.devmode = getdvarintdefault("infected_devmode", 0);
	level.minplayers = getdvarintdefault("infected_min_players", 3);
	level.loadoutkillstreaksenabled = 0;
	level.disableweapondrop = 1;
	level.allow_teamchange = "0";
	level.killedstub = level.onplayerkilled;
	level.ontimelimit = ::ontimelimit();
	level.onplayerkilled = ::killed();
	level.givecustomloadout = ::loadout();
	level thread infected();
	level thread connect();
}

infected(){
	level waittill("prematch_over");
	infectedtext = createserverfontstring("objective", 1.4);
	infectedtext.label = &"Extra survivors required: ";
	infectedtext setgamemodeinfopoint();
	infectedtext setvalue(2);
	infectedtext.hidewheninmenu = 1;
	if(level.players.size < level.minplayers){
		while(level.players.size < level.minplayers){
			infectedtext setvalue(level.minplayers - level.players.size);
			wait 0.05;
		}
		map_restart(); //TODO: This should just restore time but hey who knows how to do that at the moment.
	}
	infectedtext.label = &"Infection countdown: ";
	for(i = 10; i > 0; i--){
		infectedtext setvalue(i);
		wait 1;
	}
	infectedtext destroy();
	infect();
	for(;;){
		foreach(team in level.teams){
			members = 0;
			for(i = 0; i < level.players.size; i++){
				if(level.players[i].team == team) members++;
			}
			game["teamScores"][team] = members;
			maps/mp/gametypes/_globallogic_score::updateteamscores(team);
			if(team == "allies" && members == 0){ 
				endgame("axis", "Survivors eliminated");
			}else if(team == "axis" && members == 0){
				infect();
			}
		}
		wait 0.05;
	}
}

connect(){
	for(;;){
		level waittill("connected", player);
		player thread devmode();
		player maps\mp\teams\_teams::changeteam("allies");
		player.infected = false;
		player.firstinfected = false;
	}
}

infect(){
	first = level.players[randomint(level.players.size)];
	first.firstinfected = true;
	first.infected = true;
	first maps\mp\teams\_teams::changeteam("axis");
	iprintlnbold(first.name + " infected!");
}

killed(inflictor, attacker, damage, meansofdeath, weapon, dir, hitloc, timeoffset, deathanimduration){
	//TODO: Maybe need to infect them on meansofdeath.
	if(!self.infected){
		if(attacker.firstinfected){
			attacker.firstinfected = false;
			attacker loadout();
		}
		self.infected = true;
		self maps\mp\teams\_teams::changeteam("axis");
	}
	[[level.killedstub]](inflictor, attacker, damage, meansofdeath, weapon, dir, hitloc, timeoffset, deathanimduration);
}

loadout(){
	self clearperks();
	self setperk("specialty_fallheight");
	self setperk("specialty_fastequipmentuse");
	self setperk("specialty_fastladderclimb");
	self setperk("specialty_fastmantle");
	self setperk("specialty_fastmeleerecovery");
	self setperk("specialty_fasttoss");
	self setperk("specialty_fastweaponswitch");
	self setperk("specialty_longersprint");
	self setperk("specialty_sprintrecovery");
	self setperk("specialty_unlimitedsprint");
	self takeallweapons();
	self giveweapon("knife_mp");
	if(self.infected){
		self giveweapon("knife_held_mp");
		self giveweapon("hatchet_mp");
		self giveWeapon("tactical_insertion_mp");
		if(self.firstinfected){
			self giveweapon("pdw57_mp+silencer+extclip");
			self switchtoweapon("pdw57_mp+silencer+extclip");
		}else{
			self switchtoweapon("knife_held_mp");
		}
	}else{
		self setperk("specialty_scavenger");
		self giveweapon("pdw57_mp+silencer+extclip");
		self giveweapon("fiveseven_mp+fmj+extclip");
		self giveweapon("claymore_mp");
		self giveWeapon("flash_grenade_mp");
		self switchtoweapon("pdw57_mp+silencer+extclip");
	}
}

ontimelimit(){
	thread maps/mp/gametypes/_globallogic::endgame("allies", "Survivors win");
}

devmode(){
	if(level.devmode == 0) return;
    self endon("disconnect");
    self notifyonplayercommand("bot", "bot");
	self notifyonplayercommand("time", "time");
	self setclientuivisibilityflag("g_compassShowEnemies", 2);
    for(;;){
        command = self waittill_any_return("bot", "time");
		switch(command){
			case "bot":
				maps\mp\bots\_bot::spawn_bot(self.team);
				break;
			case "time":
				if(getdvarfloat("timescale") == 1.0){
					setdvar("timescale", 5.0);
				}else{
					setdvar("timescale", 1.0);
				}
				break;
		}
    } 
}