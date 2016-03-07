--[[ score-loading, social network, ads, etc ]]
------------------------------------------------
--------------[[ game networks ]]---------------
------------------------------------------------
local gameNetwork = require( "gameNetwork" )
local playerName;
local isAndroidSystem = false;
local ads = require("ads");
local vungleId = "56d28e9e521c9a040300000b";
local function loadLocalPlayerCallback( event )
   playerName = event.data.alias
   --saveSettings()  --save player data locally using your own "saveSettings()" function
end
 
local function gameNetworkLoginCallback( event )
   gameNetwork.request( "loadLocalPlayer", { listener=loadLocalPlayerCallback } )
   return true
end
 
local function gpgsInitCallback( event )
   gameNetwork.request( "login", { userInitiated=true, listener=gameNetworkLoginCallback } )
end
 
local function gameNetworkSetup()
   if ( system.getInfo("platformName") == "Android" ) then
      isAndroidSystem = true;
      --gameNetwork.init( "google", gpgsInitCallback );
   else
      gameNetwork.init( "gamecenter", gameNetworkLoginCallback )
   end
end
 
------HANDLE SYSTEM EVENTS------
local function systemEvents( event )
   print("systemEvent " .. event.type)
   if ( event.type == "applicationSuspend" ) then
      print( "suspending..........................." )
   elseif ( event.type == "applicationResume" ) then
      print( "resuming............................." )
   elseif ( event.type == "applicationExit" ) then
      print( "exiting.............................." )
   elseif ( event.type == "applicationStart" ) then
      gameNetworkSetup()  --login to the network here
   end
   return true
end

------------------------------------------------
-----------[[ leaderboards n sheit ]]-----------
------------------------------------------------
local function showLeaderboards()
   if (isAndroidSystem) then
      gameNetwork.show( "leaderboards" )
   else
      gameNetwork.show( "leaderboards", { leaderboard = {timeScope="AllTime"} } )
   end
   return true
end

-- will be associated with button
function postScoreSubmit( event )
   --whatever code you need following a score submission; function will be executed after successful post score request
   showLeaderboards();
   return true;
end

local function scorePost()
  --for GameCenter, default to the leaderboard name from iTunes Connect
  local myCategory = "otamm.corona.basebile.basebile";
   
  if ( system.getInfo( "platformName" ) == "Android" ) then
     --for GPGS, reset "myCategory" to the string provided from the leaderboard setup in Google
     myCategory = "CgkJtbq23agVEAIQAQ";
  end
   
  gameNetwork.request( "setHighScore",
  {
     localPlayerScore = { category=myCategory, value=tonumber(highscore) },
     listener = postScoreSubmit
  });
end

------------------------------------------------
--------------[[ score storage ]]---------------
------------------------------------------------

function saveScore(value)
	-- will save specified value to specified file
    local theFile = "highscore.data";
    local theValue = tostring(value);
    local path = system.pathForFile( theFile, system.DocumentsDirectory );
    -- io.open opens a file at path. returns nil if no file found
    local file = io.open( path, "w+" );
    if file then
      -- write game score to the text file
      file:write( theValue );
      io.close( file );
	end
end

function loadHighscore()
	-- will load specified file, or create new file if it doesn't exist
    local theFile = "highscore.data"
    local path = system.pathForFile( theFile, system.DocumentsDirectory )
    -- io.open opens a file at path. returns nil if no file found
    local file = io.open( path, "r" )
      if file then
      -- read all contents of file into a string
        local contents = file:read( "*a" )
        io.close( file )
        return tonumber(contents);
      else
        -- create file b/c it doesn't exist yet
        file = io.open( path, "w" )
        file:write( "0" )
        io.close( file )
        return 0;
    end
end

------------------------------------------------
---------------[[ ads n sheit ]]----------------
------------------------------------------------

local function vungleListener( event )
   -- Video ad not yet downloaded and available
   if ( event.type == "adStart" and event.isError ) then
      if ( isAndroidSystem ) then
         --ads:setCurrentProvider( "admob" )
      else
         ads:setCurrentProvider( "iAds" )
      end
      ads.show( "interstitial")
   elseif ( event.type == "adEnd" ) then
      -- Ad was successfully shown and ended; hide the overlay so the app can resume.
      storyboard.hideOverlay()
 
   else
      print( "Received event", event.type )
   end
   return true
end
 
local function iAdsListener( event )
   if ( event.isError ) then
      storyboard.showOverlay( "selfpromo" )
   end
   ads:setCurrentProvider("vungle")
   return true
end
 
local function adMobListener( event )
   if ( event.isError ) then
      storyboard.showOverlay( "selfpromo" )
   end
   return true
end

------------------------------------------------
-----------[[ initializing stuff ]]-------------
------------------------------------------------

Runtime:addEventListener( "system", systemEvents );

if ( isAndroidSystem ) then
   --ads.init( "admob", "your-ad-unit-id-here", adMobListener );
   vungleId = "56d2923abc1a2d860300007e"
else
   ads.init( "iads", "otamm.corona.basebile", iAdsListener );
end
ads.init( "vungle", vungleId, vungleListener );

function showInterstitialAd()
  print("AAAA");
  ads:show("interstitial")
end
