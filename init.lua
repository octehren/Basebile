-----------------------------------------------------------------------------------------
--
-- init.lua
--
-----------------------------------------------------------------------------------------
----- here are declared any global (i.e. used accross more than one file) variables.
----- lua execution stack: init.lua first, main.lua last, all the rest must be manually required (see the beginning of main.lua for an example)

--ads = require("ads");
gameNetwork = require( "gameNetwork" );
highscore = 0; -- will be used in 'adsScoreAndGameNetwork.lua'
isAndroidSystem = system.getInfo("platformName") == "Android";
isNotLoggedInGameNetwork = true;
playerMissedBall = nil; -- used in 'ball.lua', needs to be global.
playerName = "";

print("Globals declared.\n");
