-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

display.setStatusBar(display.HiddenStatusBar)
--------------------------------------------------------------------------------------------
-----------------------------[[ local scene variables ]]------------------------------------
--------------------------------------------------------------------------------------------
--[[ positions, numbers, etc ]]
local centerX = display.contentCenterX;
local centerY = display.contentCenterY;
local bgToScreenRatioX;
local bgToScreenRatioY;
local visibleDisplaySizeX = display.viewableContentWidth;
local visibleDisplaySizeY = display.viewableContentHeight;
local screenOffsetX = centerX * 2 - visibleDisplaySizeX;
local screenOffsetY = centerY * 2 - visibleDisplaySizeY;
local transitionTimeInMiliseconds = 500;
--[[ images & image groups ]]
local animationBall = display.newImage("bigBall.png"); animationBall.anchorX = 0.5;
local groundForPlayer = display.newImage("groundForPlayer0.png"); groundForPlayer.rotation = 180; groundForPlayer.anchorY = 0;
local groundForThrower = display.newImage("groundForThrower.png"); groundForThrower.anchorY = 0;
local startSceneGroup = display.newGroup();
local gameSceneGroup = display.newGroup();
local livesGroup = display.newGroup();
--[[ sprites & sprite data ]]
--billy--
local playerImageSheet = graphics.newImageSheet("billySprite.png", { width = 18, height = 41, numFrames = 4, sheetContentWidth = 72, sheetContentHeight = 41 } );
local playerImageDataWalk = { name = "walk", sheet = playerImageSheet, start = 3, count = 2, time = 250 };
local playerImageDataStill = { name = "still", sheet = playerImageSheet, start = 1, count = 2, time = 500 };
--billy batting--
local playerBattingImageSheet = graphics.newImageSheet("billySpriteBatting.png", { width = 25, height = 41, numFrames = 4, sheetContentWidth = 100, sheetContentHeight = 41 } );
local playerImageDataBatting = { name = "bat", sheet = playerBattingImageSheet, start = 1, count = 4, loopCount = 1, time = 300 };
--billy sprite--
local playerSprite = display.newSprite(playerImageSheet, { playerImageDataWalk, playerImageDataStill, playerImageDataBatting });

--thrower--
local throwerImageSheet = graphics.newImageSheet("throwerSprite.png", {width = 30, height = 41, numFrames = 4, sheetContentWidth = 120, sheetContentHeight = 41 } );
local throwerImageDataWalk = { name = "walk", sheet = throwerImageSheet, start = 3, count = 2, time = 250 };
local throwerImageDataStill = { name = "still", sheet = throwerImageSheet, start = 1, count = 2, time = 500 };
--thrower throwing
local throwerThrowingImageSheet = graphics.newImageSheet("throwerThrowingSprite.png", { width = 30, height = 41, numFrames = 3, sheetContentWidth = 90, sheetContentHeight = 41 });
local throwerImageDataThrowing = { name = "throw", sheet = throwerThrowingImageSheet, start = 1, count = 3, time = 300 };
--thrower sprite--
local throwerSprite = display.newSprite(throwerImageSheet, { throwerImageDataWalk, throwerImageDataStill, throwerImageDataThrowing } );
--[[ external files ]]
local ball = require("ball"); -- enables 'instantiateBall()' and 'vanish(obj)' functions
--[[ buttons ]]
local playBtn = display.newImage("playBtn.png");
--[[ balls array & ball-related variables ]]
local balls = {};
local totalBalls = 0;
local ballToBeBattedIndex = 0;
local throwBallIndex = 0;
local initialBallPositionY = 100;
local tooLateToBatBallPositionY = 300; -- ball cannot be hit anymore, misses
local successfulBatBallY = 250; -- homerun hit
local tooSoonToBatBallPositionY = 200; -- was hit too soon, misses
local ballMaxThrowSpeed = 2000;
local ballMinThrowSpeed = 600;
--[[ lives ]]
local missesUntilOut;
local livesArray = {};
local outsArray = {};
--[[ forward function references ]]
local animateBall;
local transitionToGameScene;
local bat;
local checkIfBallToBeBattedWasIndeedBatted;
playerMissedBall = nil; -- used in 'ball.lua', needs to be global.
local repositionGameSceneElements;
local createLivesGroup;
local repositionLivesGroup;
local removeOneLife;
local restoreAllLives;
--[[ timers ]]
local throwBallAnimationTimer; -- the animation to throw the ball
local throwingBallTimer; -- actual throw of ball
local setupStillAnimationTimer = timer.performWithDelay(10, function() end); -- only so timer won't be "nil" and cause a crash at first tap.
--------------------------------------------------------------------------------------------
---------------------------------------[[ functions ]]--------------------------------------
--------------------------------------------------------------------------------------------

--[[ scene creation ]]
local function createInitialScene()
	local bg = display.newImage("mainScreenBG.png");
	--bgToScreenRatioX = centerX * 2.3 / bg.contentWidth; bgToScreenRatioY = centerY * 2.4 / bg.contentHeight;
	bg.x = centerX; bg.y = centerY;
	local billy = display.newImage("charScreenBG.png");
	billy.anchorX = 1; billy.anchorY = 1; billy.x = centerX * 5; -- places char far from screen center
	billy.y = centerY * 2; -- places char at bottom of screen
	playBtn.anchorX = 0; playBtn.anchorY = 1;
	-- adds above elements to startSceneGroup so they can be moved all at once
	startSceneGroup:insert(bg); startSceneGroup:insert(billy); --startSceneGroup:insert(playBtn);
	-- adds game background to future use game group;

	local function displayPlayButton() -- executed at the end of billy transition
		playBtn.x = centerX * 7; playBtn.y = centerY * 7; playBtn.xScale = 5; playBtn.yScale = 5;
		transition.to(playBtn, {time = 500, x = centerX * 2 - visibleDisplaySizeX - 10, y = visibleDisplaySizeY - 20, xScale = 1, yScale = 1});
	end

	transition.to(billy, {time = 500, x = visibleDisplaySizeX + screenOffsetX, onComplete = displayPlayButton });
	playBtn:addEventListener("tap", goToGameScene);
end

function goToGameScene() -- first load of game scene
	playBtn:removeEventListener("tap", goToGameScene);
	missesUntilOut = 3;
	local bg = display.newImage("gameFieldBG.png");
	bg.anchorY = 1; bg.anchorX = 0.5; bg.y = 0; bg.x = centerX;
	groundForThrower.x = centerX; groundForThrower.y = centerY * -2;
	gameSceneGroup:insert(groundForThrower); gameSceneGroup:insert(groundForPlayer);
	groundForPlayer.x = centerX; groundForPlayer.y = 0;
	startSceneGroup.anchorY = 0;
	animateBall();
	for i = 0, 4 do
		balls[i] = instantiateBall(centerX, initialBallPositionY, centerY * 2, centerX * 2);
		--gameSceneGroup:insert(balls[i]);
		balls[i]:toFront();
	end
	gameSceneGroup:toFront();
	totalBalls = #balls;
	print(totalBalls);
	transition.to(groundForPlayer, { y = centerY * 2 - 36, time = transitionTimeInMiliseconds });
	transition.to(groundForThrower, { y = 30, time = transitionTimeInMiliseconds });
	transition.to(bg, { time = transitionTimeInMiliseconds, y = visibleDisplaySizeY, onComplete = function() displayPlayerAndOpponent(); createLivesGroup(); end });
end

function recreateGameScene() -- second+ loads of game scene
	playBtn:removeEventListener("tap", recreateGameScene);
	playerSprite.y = visibleDisplaySizeY + 100; throwerSprite.y = -10;
	playBtn:toBack();
	missesUntilOut = 3;
	restoreAllLives();
	animateBall();
	timer.performWithDelay(transitionTimeInMiliseconds, displayPlayerAndOpponent);
end

function displayGameOver()
	transition.cancel("ballMovement");
	timer.cancel(throwBallAnimationTimer);
	timer.cancel(throwingBallTimer);
	throwerSprite:setSequence("still"); throwerSprite:play(); -- there's a tiny window of time in which timer that makes thrower still gets canceled
	ballMaxThrowSpeed = 2000;
	ballMinThrowSpeed = 600;
	for i = 0, totalBalls do
		balls[i].isVisible = false; balls[i].xScale = 1; balls[i].yScale = 1;
	end
	playBtn:addEventListener("tap", recreateGameScene);
	playBtn:toFront();
	Runtime:removeEventListener("tap", bat);
	Runtime:removeEventListener("accelerometer", bat);
end

--[[ animations & transitions ]]
function animateBall() --ball animation for scene transition
	animationBall.y = screenOffsetY; animationBall.xScale = ballContentScale; 
	animationBall.yScale = ballContentScale; animationBall.x = centerX; animationBall.rotation = 0;
	animationBall:toFront();
	transition.to(animationBall, { time = transitionTimeInMiliseconds + 150, y = visibleDisplaySizeY + animationBall.contentHeight, rotation = 180 }); -- + 100 so ball can descend 'glued' to the bottom of game screen
end

function displayPlayerAndOpponent()
	playerSprite.anchorY = 1; playerSprite.y = visibleDisplaySizeY; playerSprite.x = centerX;
	playerSprite:toFront();
	throwerSprite.anchorY = 1; throwerSprite.y = -10; throwerSprite.x = centerX - (0.25 * throwerSprite.contentHeight / 4) -- 4 here = the number of sprites in throwerSprite
	throwerSprite:toFront();
	initialBallPositionY = throwerSprite.contentHeight + 20;
	local function playerOpponentGetStill()
		playerSprite.anchorX = 1; playerSprite.x = centerX;
		playerSprite:setSequence( "still" );
		playerSprite:play();
		throwerSprite:setSequence( "still" );
		throwerSprite:play();
		Runtime:addEventListener( "tap", bat );
		Runtime:addEventListener( "accelerometer", bat ); -- bats on shaking phone
		successfulBatBallY = playerSprite.y - (balls[0].contentHeight / 2) - playerSprite.contentHeight;
		tooLateToBatBallPositionY = playerSprite.y - (playerSprite.contentHeight / 2);
		oneTwoThreeGameStart();
	end
	playerSprite:setSequence( "walk" ); playerSprite:play(); throwerSprite:setSequence( "walk" ); throwerSprite:play();
	transition.to( playerSprite , { time = 500, y = playerSprite.y - 60 } );
	transition.to( throwerSprite , { time = 500, y = initialBallPositionY, onComplete = playerOpponentGetStill } );
end

function oneTwoThreeGameStart()
	local oneImg = display.newImage("one.png"); oneImg.x = centerX; oneImg.y = centerY; oneImg.isVisible = false;
	local twoImg = display.newImage("two.png"); twoImg.x = centerX; twoImg.y = centerY; twoImg.isVisible = false;
	local threeImg = display.newImage("three.png"); threeImg.x = centerX; threeImg.y = centerY; threeImg.isVisible = false;
	local infoBox = display.newImage("infoBox.png"); infoBox.x = centerX; infoBox.y = centerY; infoBox.isVisible = false;

	local function displayGameStartAndThrowFirstBall()
		infoBox.isVisible = true;
		local function shakeInfoBox4()
			transition.to( infoBox, { rotation = -20, xScale = 1.3, yScale = 1.3, alpha = 0, time = 250, onComplete = throwBallAnimation } );
		end
		local function shakeInfoBox3()
			transition.to( infoBox, { rotation = 20, xScale = 1.3, yScale = 1.3, time = 250, onComplete = shakeInfoBox4 } );
		end
		local function shakeInfoBox2()
			transition.to( infoBox, { rotation = -20, xScale = 1.3, yScale = 1.3, time = 250, onComplete = shakeInfoBox3 } );
		end
		transition.to( infoBox, { rotation = 20, xScale = 1.3, yScale = 1.3, time = 250, onComplete = shakeInfoBox2 } );
	end
	local function three()
		threeImg.xScale = 0.5; threeImg.yScale = 0.5; threeImg.rotation = 270; threeImg.isVisible = true;
		transition.to( threeImg, { rotation = 0, xScale = 1, yScale = 1, alpha = 0, time = 350, onComplete = displayGameStartAndThrowFirstBall } );
	end
	local function two()
		twoImg.xScale = 0.5; twoImg.yScale = 0.5; twoImg.rotation = 270; twoImg.isVisible = true;
		transition.to( twoImg, { rotation = 0, xScale = 1, yScale = 1, alpha = 0, time = 350, onComplete = three } );
	end
	local function one()
		oneImg.xScale = 0.5; oneImg.yScale = 0.5; oneImg.rotation = 270; oneImg.isVisible = true;
		transition.to( oneImg, { rotation = 0, xScale = 1, yScale = 1, alpha = 0, time = 350, onComplete = two } );
	end
	--throwBallAnimation();
	one();
end

function throwBallAnimation()
	if not balls[throwBallIndex].isVisible then
		-- animate character throwing ball, execute 'throwBall()' at the end of animation
		throwerSprite:setSequence( "throw" );
		throwerSprite:play();
		throwingBallTimer = timer.performWithDelay(300, function()
			local ballSpeed = math.random(ballMinThrowSpeed, ballMaxThrowSpeed);
			balls[throwBallIndex]:toFront();
			balls[throwBallIndex]:throw(ballSpeed);
			throwBallIndex = (throwBallIndex + 1) % totalBalls;
			if ballMaxThrowSpeed > 500 then
				ballMaxThrowSpeed = ballMaxThrowSpeed - 4;
				ballMinThrowSpeed = ballMinThrowSpeed - 1;
			end
			throwerSprite:setSequence( "still" );
			throwerSprite:play();
		end);
	end
	throwBallAnimationTimer = timer.performWithDelay(math.random(ballMinThrowSpeed * 1.3, ballMaxThrowSpeed * 1.1) , throwBallAnimation);
end

--[[ gameplay & game logic ]]
function bat()
	playerSprite:setSequence( "bat" );
	timer.cancel(setupStillAnimationTimer);
	setupStillAnimationTimer = timer.performWithDelay(300, function() playerSprite:setSequence("still"); playerSprite:play(); end); -- 250 = bat sequence duration
	playerSprite:play();
	for i = 0, totalBalls do
		if balls[i].isVisible then
			if balls[i].y >= successfulBatBallY then
				if balls[i].y <= tooLateToBatBallPositionY then
					balls[i]:successfulHit();
					--return;
				end
			end
		end
	end
end

function playerMissedBall()
	missesUntilOut = missesUntilOut - 1;
	removeOneLife();
	if missesUntilOut == 0 then
		displayGameOver();
	end
end
--[[ lives-handling functions ]]
function createLivesGroup()
	--livesGroup.anchorY = centerY; livesGroup.anchorX = centerX; livesGroup.x = 0; livesGroup.y = 0;
	for i = 1, 3 do
		print("i: " .. i)
		outsArray[i] = display.newImage("out.png");
		--livesGroup:insert(outsArray[i]);
		outsArray[i].anchorX = 0; outsArray[i].anchorY = 0;
		outsArray[i].x = 5 + outsArray[i].contentWidth * i;
		outsArray[i].y = 5; --outsArray[i].contentHeight;
		outsArray[i].isVisible = false; -- outsArray[i]:toFront();
	end
	local function resizeLives(life)
		life.xScale = outsArray[1].contentWidth / life.contentWidth;
		life.yScale = outsArray[1].contentHeight / life.contentHeight;
	end
	for i = 1, 3 do
		livesArray[i] = display.newImage("ball.png");
		--livesGroup:insert(livesArray[i]);
		resizeLives(livesArray[i]);
		livesArray[i].anchorX = 0; livesArray[i].anchorY = 0;
		livesArray[i].x = 5 + livesArray[i].contentWidth * i;
		livesArray[i].y = 5; --livesArray[i].contentHeight;
		outsArray[i]:toFront();
	end
	--livesGroup:toFront();
end

function repositionLivesGroup()
	livesGroup.x = 0; livesGroup.y = 0; livesGroup.xScale = 200; livesGroup:toFront();
end

function restoreOneLife()
	outsArray[missesUntilOut + 1].isVisible = false;
end

function removeOneLife()
	outsArray[missesUntilOut + 1].isVisible = true;
end

function restoreAllLives()
	for i = 1, 3 do
		outsArray[i].isVisible = false;
	end
end

createInitialScene();