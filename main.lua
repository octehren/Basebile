-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

display.setStatusBar(display.HiddenStatusBar);

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
local gamePaused = false;
local pausesLeft = 3;
--[[ images & image groups ]]
local animationBall = display.newImage("bigBall.png"); animationBall.anchorX = 0.5;
local groundForPlayer = display.newImage("groundForPlayer0.png"); groundForPlayer.rotation = 180; groundForPlayer.anchorY = 0;
local groundForThrower = display.newImage("groundForThrower0.png"); --groundForThrower.anchorY = 0;
local outLabel = display.newImage("outLabel.png");
local startSceneGroup = display.newGroup();
local gameSceneGroup = display.newGroup();
local livesGroup = display.newGroup();
local gameOverPopupGroup = display.newGroup();
--[[ audio files ]]
local soundIsOn = true;
local audio1 = audio.loadSound("soundBatting.wav");
local audio2 = audio.loadSound("soundGameOn.wav");
local audio3 = audio.loadSound("soundCountdown.wav");
local audio4 = audio.loadSound("soundBallSlow.wav");
local audio5 = audio.loadSound("soundBallMedium.wav");
local audio6 = audio.loadSound("soundBallFast.wav");
local audio7 = audio.loadSound("soundGameOver.wav");
local audio8 = audio.loadSound("soundWoosh.wav");
local audio9 = audio.loadSound("soundStreakBoost.wav");
local audio10 = audio.loadSound("soundMissedBall.wav");
--local audio11 = audio.loadSound("soundHit.wav");
local soundBatting = audio1;
local soundGameOn = audio2;
local soundCountdown = audio3;
local soundBallSlow = audio4;
local soundBallMedium = audio5;
local soundBallFast = audio6;
local soundGameOver = audio7;
local soundWoosh = audio8;
local soundStreakBoost = audio9;
local soundMissedBall = audio10;
--local soundHitCrowdCheer = audio11;
--[[ sprites & sprite data ]]
--billy--
local playerImageSheet = graphics.newImageSheet("billySprite0.png", { width = 30, height = 62, numFrames = 4, sheetContentWidth = 121, sheetContentHeight = 62 } );
local playerImageDataWalk = { name = "walk", sheet = playerImageSheet, start = 3, count = 2, time = 250 };
local playerImageDataStill = { name = "still", sheet = playerImageSheet, start = 1, count = 2, time = 500 };
--billy batting--
local playerBattingImageSheet = graphics.newImageSheet("billySpriteBatting0.png", { width = 38, height = 62, numFrames = 4, sheetContentWidth = 152, sheetContentHeight = 62 } );
local playerImageDataBatting = { name = "bat", sheet = playerBattingImageSheet, start = 1, count = 4, loopCount = 1, time = 300 };
--billy sprite--
local playerSprite = display.newSprite(playerImageSheet, { playerImageDataWalk, playerImageDataStill, playerImageDataBatting });

--thrower--
local throwerImageSheet = graphics.newImageSheet("throwerSprite0.png", {width = 33, height = 45, numFrames = 4, sheetContentWidth = 132, sheetContentHeight = 45 } );
local throwerImageDataWalk = { name = "walk", sheet = throwerImageSheet, start = 3, count = 2, time = 250 };
local throwerImageDataStill = { name = "still", sheet = throwerImageSheet, start = 1, count = 2, time = 500 };
--thrower throwing
local throwerThrowingImageSheet = graphics.newImageSheet("throwerThrowingSprite0.png", { width = 33, height = 45, numFrames = 3, sheetContentWidth = 99, sheetContentHeight = 45 });
local throwerImageDataThrowing = { name = "throw", sheet = throwerThrowingImageSheet, start = 1, count = 3, time = 300 };
--thrower sprite--
local throwerSprite = display.newSprite(throwerImageSheet, { throwerImageDataWalk, throwerImageDataStill, throwerImageDataThrowing } );

--[[ buttons ]]
local playBtn = display.newImage("playBtn.png");
local soundBtn1 = display.newImage("soundOn.png");
local soundBtn2 = display.newImage("soundOff.png");
local pauseBtn1 = display.newImage("pauseOff.png");
local pauseBtn2 = display.newImage("pauseOn.png");
local rankBtn = display.newImage("btnRank.png");
--[[ balls array & ball-related variables ]]
local balls = {};
local totalBalls = 0;
local ballToBeBattedIndex = 0;
local throwBallIndex = 0;
local initialBallPositionY = throwerSprite.contentHeight + 50;
local tooLateToBatBallPositionY = 300; -- ball cannot be hit anymore, misses
local successfulBatBallY = 250; -- homerun hit
local tooSoonToBatBallPositionY = 200; -- was hit too soon, misses
local ballMaxThrowSpeed = 2400;
local ballMinThrowSpeed = 900;
local playerIsBatting = false;
--[[ lives and score ]]
local missesUntilOut;
local livesArray = {};
local outsArray = {};
local score = 0;
local battingStreak = 0; -- replenishes life and adds 1 to score at every 5x batting streak
local pointsAwardedPerBat = 1; -- + 1 at each 3x batting streak
highscore = 0; -- will be used in 'adsScoreAndGameNetwork.lua'
--[[ external files ]]
local ball = require("ball"); -- enables 'instantiateBall()' and 'vanish(obj)' functions
local adsScoreAndGameNetwork = require("adsScoreAndGameNetwork"); -- enables 'saveScore()', 'loadScore()'
--[[ high-score & game over screen ]]
local highscoreContainer = display.newRoundedRect(centerX, centerY, 200, 300, 10);
highscoreContainer.strokeWidth = 8; highscoreContainer:setStrokeColor(1, 0.95, 0.1); highscoreContainer:setFillColor(0.2, 0.4, 0.9);
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
local turnSoundOnOrOff;
local displayAndPositionScore;
local displayScoreAdder;
local displayScoreAndLifeAdder;
local presentAndPopulateGameOverPopup;
local dismissGameOverPopup;
--local loadHighscore;
--local saveScore;
local updateScores;
local resumeGame;
local pauseGame;
local createPauseButtons;
--[[ time delays (ms) ]]
local hitAnimationDelay = 30;
local scorePopupAnimationDelay = hitAnimationDelay * 9;
local soundStreakPlayDelay = scorePopupAnimationDelay * 0.8;
--[[ font-handling ]]
local scoreText = display.newText("0", centerX * 2 - 15, 5, "PixTall", 32); scoreText.isVisible = false;
local scoreAdderText = display.newText("x2", centerX, -centerY, "PixTall", 40);
local extraLifeText = display.newText("EXTRA CHANCE!", centerX, -100, "PixTall", 40); extraLifeText.alpha = 0;
local scoreLabel = display.newText("SCORE:", centerX, -50, "PixTall", 32);
local highscoreLabel = display.newText("HIGH SCORE:", centerX, 5, "PixTall", 32);
local displayScorePointsLabel = display.newText("0", centerX, -100, "PixTall", 32);
local displayHighscorePointsLabel = display.newText("0", centerX, -50, "PixTall", 32);
local pauseLabel = display.newText("PAUSE 1", centerX, centerY, "PixTall", 50); pauseLabel.isVisible = false;
--[[ timers ]]
local throwBallAnimationTimer; -- the animation to throw the ball
local throwingBallTimer; -- actual throw of ball
local setupStillAnimationTimer = timer.performWithDelay(10, function() end); -- only so timer won't be "nil" and cause a crash at first tap.
--------------------------------------------------------------------------------------------
---------------------------------------[[ functions ]]--------------------------------------
--------------------------------------------------------------------------------------------

--[[ scene creation ]]
local function createInitialScene()
	rankBtn.isVisible = false; rankBtn.anchorY = 1; rankBtn.anchorX = 0;
	highscore = loadHighscore();
	displayHighscorePointsLabel.text = highscore;
	local bg = display.newImage("mainScreenBG.png");
	bg.x = centerX; bg.y = centerY;
	local billy = display.newImage("charScreenBG.png");
	billy.anchorX = 1; billy.anchorY = 1; billy.x = centerX * 5; -- places char far from screen center
	billy.y = centerY * 2; -- places char at bottom of screen
	playBtn.anchorX = 0; playBtn.anchorY = 1;
	soundBtn1.anchorX = 1; soundBtn1.anchorY = 1; soundBtn2.anchorX = 1; soundBtn2.anchorY = 1;
	local logo = display.newImage("basebileLogo.png"); logo.anchorY = 0; logo.y = -500; logo.x = centerX;
	-- adds above elements to startSceneGroup so they can be moved all at once
	startSceneGroup:insert(bg); startSceneGroup:insert(billy); startSceneGroup:insert(logo);

	-- adds game background to future use game group;
	local function enableButtons()
		soundBtn2.x = soundBtn1.x; soundBtn2.y = soundBtn1.y;
		soundBtn2.isVisible = false;
		rankBtn.x = centerX; rankBtn.y = centerY + 125;
		rankBtn.isVisible = false;
		playBtn:addEventListener("tap", goToGameScene);
		soundBtn1:addEventListener("tap", turnSoundOnOrOff);
		soundBtn2:addEventListener("tap", turnSoundOnOrOff);
		rankBtn:addEventListener("tap", scorePost);
	end
	local function displayPlayAndSoundButtons() -- executed at the end of billy transition
		audio.play(soundWoosh);
		playBtn.x = centerX * 7; playBtn.y = centerY * 7; playBtn.xScale = 5; playBtn.yScale = 5;
		soundBtn1.x = centerX * 7; soundBtn1.y = centerY * 7; soundBtn1.xScale = 5; soundBtn1.yScale = 5;
		transition.to(playBtn, {time = 500, x = centerX * 2 - visibleDisplaySizeX - 5, y = visibleDisplaySizeY - 5, xScale = 1, yScale = 1 });
		transition.to(soundBtn1, {time = 500, x = visibleDisplaySizeX + 5, y = visibleDisplaySizeY - 5, xScale = 1, yScale = 1, onComplete = enableButtons });
	end
	audio.play(soundWoosh);
	createGameOverPopup();
	transition.to(logo, {time = 500, y = 10 });
	transition.to(billy, {time = 500, x = visibleDisplaySizeX + screenOffsetX, onComplete = displayPlayAndSoundButtons });
end

function goToGameScene() -- first load of game scene
	audio.stop();
	playBtn:removeEventListener("tap", goToGameScene);
	playBtn.isVisible = false; soundBtn1.isVisible = false; soundBtn2.isVisible = false;
	missesUntilOut = 3;
	local bg = display.newImage("gameFieldBG0.png");
	bg.anchorY = 1; bg.anchorX = 0.5; bg.y = 0; bg.x = centerX;
	groundForThrower.x = centerX; groundForThrower.y = centerY * -2;
	gameSceneGroup:insert(groundForThrower); gameSceneGroup:insert(groundForPlayer);
	groundForPlayer.x = centerX; groundForPlayer.y = 0;
	startSceneGroup.anchorY = 0;
	gameSceneGroup:toFront();
	throwerSprite:toFront();
	for i = 0, 4 do
		balls[i] = instantiateBall(centerX, initialBallPositionY, centerY * 2, centerX * 2);
		balls[i]:toFront();
	end
	totalBalls = #balls;
	scoreText.isVisible = true; scoreText:toFront();
	animateBall();
	transition.to(groundForPlayer, { y = centerY * 2 - 36, time = transitionTimeInMiliseconds });
	transition.to(groundForThrower, { y = initialBallPositionY, time = transitionTimeInMiliseconds });
	transition.to(bg, { time = transitionTimeInMiliseconds, y = visibleDisplaySizeY, onComplete = function()
		playBtn:addEventListener("tap", recreateGameScene);
		displayPlayerAndOpponent();
		createLivesGroup();
		createPauseButtons();
		displayAndPositionScore();
		playBtn:toFront(); soundBtn2:toFront(); soundBtn1:toFront(); rankBtn:toFront();
		display.remove(startSceneGroup);
	end 
	});
end

function recreateGameScene() -- second+ presentation of game scene
	playerSprite.y = visibleDisplaySizeY + 100; throwerSprite.y = -10;
	playBtn.isVisible = false; soundBtn1.isVisible = false; soundBtn2.isVisible = false; pauseBtn1.isVisible = false; pauseBtn2.isVisible = false;
	missesUntilOut = 3;
	pausesLeft = 3;
	score = 0;
	ballMaxThrowSpeed = 2400;
	ballMinThrowSpeed = 900;
	scoreText.text = score;
	restoreAllLives();
	animateBall();
	dismissGameOverPopup();
	timer.performWithDelay(transitionTimeInMiliseconds, displayPlayerAndOpponent);
end

function displayGameOver()
	transition.cancel("ballMovement");
	timer.cancel(throwBallAnimationTimer);
	timer.cancel(throwingBallTimer);
	throwerSprite:setSequence("still"); throwerSprite:play(); -- there's a tiny window of time in which timer that makes thrower still gets canceled
	for i = 0, totalBalls do
		balls[i].isVisible = false; balls[i].xScale = 1; balls[i].yScale = 1;
	end
	Runtime:removeEventListener("touch", bat);
	Runtime:removeEventListener("accelerometer", bat);
	pauseBtn1.isVisible = false;
	pauseBtn2.isVisible = false;
	audio.play(soundGameOver);
	presentAndPopulateGameOverPopup();
end

function createGameOverPopup()
	gameOverPopupGroup:insert(highscoreContainer);
	gameOverPopupGroup:insert(scoreLabel); scoreLabel.y = 135;
	gameOverPopupGroup:insert(displayScorePointsLabel); displayScorePointsLabel.x = centerX; displayScorePointsLabel.y = 160;
	gameOverPopupGroup:insert(highscoreLabel); highscoreLabel.y = 185;
	gameOverPopupGroup:insert(displayHighscorePointsLabel); displayHighscorePointsLabel.y = 210;
	gameOverPopupGroup:insert(outLabel); outLabel.x = centerX; outLabel.y = 95;
	gameOverPopupGroup.y = -gameOverPopupGroup.contentHeight * 2;
end

--[[ animations & transitions ]]
function animateBall() --ball animation for scene transition
	animationBall:toFront();
	audio.play(soundBallMedium);
	animationBall.y = screenOffsetY; animationBall.xScale = ballContentScale; 
	animationBall.yScale = ballContentScale; animationBall.x = centerX; animationBall.rotation = 0;
	transition.to(animationBall, { time = transitionTimeInMiliseconds + 150, y = visibleDisplaySizeY + animationBall.contentHeight, rotation = 180 }); -- + 100 so ball can descend 'glued' to the bottom of game screen
end

function displayPlayerAndOpponent()
	playerSprite.anchorY = 1; playerSprite.y = visibleDisplaySizeY; playerSprite.x = centerX;
	playerSprite:toFront();
	throwerSprite.anchorY = 1; throwerSprite.y = -10; throwerSprite.x = centerX - (0.25 * throwerSprite.contentHeight / 4) -- 4 here = the number of sprites in throwerSprite
	--throwerSprite:toFront(); thrower sprite is ':toFront()' in goToGameScene function, so Z index of thrower is smaller than the thrown ball's
	--initialBallPositionY = throwerSprite.contentHeight + 20;
	local function playerOpponentGetStill() -- also displays pause buttons
		playerSprite.anchorX = 1; playerSprite.x = centerX;
		playerSprite:setSequence( "still" );
		playerSprite:play();
		throwerSprite:setSequence( "still" );
		throwerSprite:play();
		Runtime:addEventListener( "touch", bat );
		Runtime:addEventListener( "accelerometer", bat ); -- bats on shaking phone
		successfulBatBallY = playerSprite.y - playerSprite.contentHeight - playerSprite.contentHeight / 3;
		tooLateToBatBallPositionY = playerSprite.y - playerSprite.contentHeight + playerSprite.contentHeight / 5;
		oneTwoThreeGameStart();
	end
	playerSprite:setSequence( "walk" ); playerSprite:play(); throwerSprite:setSequence( "walk" ); throwerSprite:play();
	transition.to( playerSprite , { time = 500, y = playerSprite.y - 60 } );
	transition.to( throwerSprite , { time = 500, y = initialBallPositionY, onComplete = playerOpponentGetStill } );
end

function presentAndPopulateGameOverPopup()
	updateScores();
	gameOverPopupGroup:toFront();
	transition.to(gameOverPopupGroup, { y = centerY - 250, time = 400, onComplete = function() 
		playBtn.isVisible = true;
		rankBtn.isVisible = true; rankBtn:toFront();
		if soundIsOn then
			soundBtn1.isVisible = true;
		else
			soundBtn2.isVisible = true;
		end
		-- removed ads
		--showInterstitialAd(); 
	  end 
	} );
end

function dismissGameOverPopup()
	rankBtn.isVisible = false;
	transition.to(gameOverPopupGroup, { y = gameOverPopupGroup.contentHeight * 2, time = 400, onComplete = function() gameOverPopupGroup.y = -gameOverPopupGroup.contentHeight * 2; end})
end

function oneTwoThreeGameStart()
	pauseLabel.isVisible = false;
	pauseBtn2.isVisible = false;
	local oneImg = display.newImage("one.png"); oneImg.x = centerX; oneImg.y = centerY; oneImg.isVisible = false;
	local twoImg = display.newImage("two.png"); twoImg.x = centerX; twoImg.y = centerY; twoImg.isVisible = false;
	local threeImg = display.newImage("three.png"); threeImg.x = centerX; threeImg.y = centerY; threeImg.isVisible = false;
	local infoBox = display.newImage("infoBox.png"); infoBox.x = centerX; infoBox.y = centerY; infoBox.isVisible = false;

	local function displayGameStartAndThrowFirstBall()
		audio.play(soundGameOn);
		infoBox.isVisible = true;
		local function shakeInfoBox4()
			transition.to( infoBox, { rotation = -20, xScale = 1.3, yScale = 1.3, alpha = 0, time = 250, onComplete = function()
				  if gamePaused then
				  	resumeGame();
				  else
				  	pauseBtn1.isVisible = true;
				    throwBallAnimation();
				  end
			    end
			} );
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
		audio.play(soundCountdown);
		threeImg.xScale = 0.5; threeImg.yScale = 0.5; threeImg.rotation = 270; threeImg.isVisible = true;
		transition.to( threeImg, { rotation = 0, xScale = 1, yScale = 1, alpha = 0, time = 350, onComplete = displayGameStartAndThrowFirstBall } );
	end
	local function two()
		audio.play(soundCountdown);
		twoImg.xScale = 0.5; twoImg.yScale = 0.5; twoImg.rotation = 270; twoImg.isVisible = true;
		transition.to( twoImg, { rotation = 0, xScale = 1, yScale = 1, alpha = 0, time = 350, onComplete = three } );
	end
	local function one()
		audio.play(soundCountdown);
		oneImg.xScale = 0.5; oneImg.yScale = 0.5; oneImg.rotation = 270; oneImg.isVisible = true;
		transition.to( oneImg, { rotation = 0, xScale = 1, yScale = 1, alpha = 0, time = 350, onComplete = two } );
	end
	one();
end

function throwBallAnimation()
	if not balls[throwBallIndex].isVisible then
		-- animate character throwing ball, execute 'throwBall()' at the end of animation
		throwerSprite:setSequence( "throw" );
		throwerSprite:play();
		throwingBallTimer = timer.performWithDelay(300, function()
			local ballSpeed = math.random(ballMinThrowSpeed, ballMaxThrowSpeed);
			balls[throwBallIndex]:throw(ballSpeed);
			if ballSpeed > 1300 then
				audio.play(soundBallSlow);
			elseif ballSpeed > 900 then
				audio.play(soundBallMedium);
			else
				audio.play(soundBallFast);
			end
			throwBallIndex = (throwBallIndex + 1) % totalBalls;
			if ballMaxThrowSpeed > 800 then
				ballMaxThrowSpeed = ballMaxThrowSpeed - 5;
				ballMinThrowSpeed = ballMinThrowSpeed - 2;
			end
			throwerSprite:setSequence( "still" );
			throwerSprite:play();
		end);
	end
	throwBallAnimationTimer = timer.performWithDelay(math.random(ballMinThrowSpeed * 1.3, ballMaxThrowSpeed * 1.1) , throwBallAnimation);
end

--[[ gameplay & game logic ]]
function bat(event)
	if not (playerIsBatting or gamePaused) then
		if event.phase == "began" or event.isShake then
			playerIsBatting = true;
			audio.play(soundWoosh);
			playerSprite:setSequence( "bat" );
			timer.cancel(setupStillAnimationTimer);
			setupStillAnimationTimer = timer.performWithDelay(300, function() playerIsBatting = false; playerSprite:setSequence("still"); playerSprite:play(); end); -- 250 = bat sequence duration
			playerSprite:play();
			for i = 0, totalBalls do
				if balls[i].isVisible then
					if balls[i].y >= successfulBatBallY then
						if balls[i].y <= tooLateToBatBallPositionY then
							audio.play(soundBatting);
							timer.performWithDelay(hitAnimationDelay, function() balls[i]:successfulHit(); end);
							score = score + pointsAwardedPerBat;
							scoreText.text = score;
							battingStreak = battingStreak + 1;
							if battingStreak % 3 == 0 then
								pointsAwardedPerBat = pointsAwardedPerBat + 1;
								if battingStreak % 6 == 0 then
									-- 'extra point & extra life' animation
									if missesUntilOut < 3 then
										-- playerMissedBall() performed with delay of 50, life-displaying and score-adding functions are performed with delay of 45
										timer.performWithDelay(scorePopupAnimationDelay, function()
											displayScoreAndLifeAdder();
											restoreOneLife();
										end);
									else
										timer.performWithDelay(scorePopupAnimationDelay, displayScoreAdder);
									end
								else
									-- 'extra point' animation
									timer.performWithDelay(scorePopupAnimationDelay, displayScoreAdder);
								end
								timer.performWithDelay(soundStreakPlayDelay, function()
									audio.play(soundStreakBoost);
								end);
							end
							--return;
						end
					end
				end
			end
		end
	end
end

function playerMissedBall()
	removeOneLife();
	battingStreak = 0;
	pointsAwardedPerBat = 1;
	audio.play(soundMissedBall);
	if missesUntilOut == 0 then
		displayGameOver();
	end
end
--[[ lives-handling functions ]]
function createLivesGroup()
	for i = 1, 3 do
		outsArray[i] = display.newImage("out.png");
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
		resizeLives(livesArray[i]);
		livesArray[i].anchorX = 0; livesArray[i].anchorY = 0;
		livesArray[i].x = 5 + livesArray[i].contentWidth * i;
		livesArray[i].y = 5; --livesArray[i].contentHeight;
		outsArray[i]:toFront();
	end
end

function restoreOneLife()
	missesUntilOut = missesUntilOut + 1;
	outsArray[missesUntilOut].isVisible = false;
end

function removeOneLife()
	outsArray[missesUntilOut].isVisible = true;
	missesUntilOut = missesUntilOut - 1;
end

function restoreAllLives()
	for i = 1, 3 do
		outsArray[i].isVisible = false;
	end
end

--[[ sound-handling function ]]
function turnSoundOnOrOff()
	if soundIsOn then
		soundBtn1.isVisible = false;
		soundBtn2.isVisible = true;
		soundIsOn = false;
		soundBatting = nil;
		soundGameOn = nil;
		soundCountdown = nil;
		soundBallSlow = nil;
		soundBallMedium = nil;
		soundBallFast = nil;
		soundGameOver = nil
		soundWoosh = nil;
		soundStreakBoost = nil;
		soundMissedBall = nil;
	else
		soundBtn1.isVisible = true;
		soundBtn2.isVisible = false;
		soundIsOn = true;
		soundBatting = audio1;
		soundGameOn = audio2;
		soundCountdown = audio3;
		soundBallSlow = audio4;
		soundBallMedium = audio5;
		soundBallFast = audio6;
		soundGameOver = audio7;
		soundWoosh = audio8;
		soundStreakBoost = audio9;
		soundMissedBall = audio10;
	end
end

--[[ font-handling functions ]]
function displayAndPositionScore()
	scoreText.anchorY = 0; scoreText.anchorX = 1;
	scoreText.x = centerX * 2 - 30; 
	scoreText.y = 5; 
	scoreText.isVisible = true; 
	scoreText:toFront();
	scoreAdderText:toFront();
	extraLifeText:toFront();
end

function displayScoreAdder()
	scoreAdderText.y = centerY; scoreAdderText.alpha = 1;
	scoreAdderText.text = "x" .. pointsAwardedPerBat;
	transition.to(scoreAdderText, {y = centerY - 80, alpha = 0, time = 500 });
end

function displayScoreAndLifeAdder()
	scoreAdderText.y = centerY; scoreAdderText.alpha = 1;
	scoreAdderText.text = "x" .. pointsAwardedPerBat;
	extraLifeText.y = centerY + 40; extraLifeText.alpha = 1;
	transition.to(scoreAdderText, {y = centerY - 80, alpha = 0, time = 500 });
	transition.to(extraLifeText, {y = centerY - 40, alpha = 0, time = 500 });
end

function updateScores()
	displayScorePointsLabel.text = score;
	if score > highscore then
		highscore = score;
		displayHighscorePointsLabel.text = highscore;
		saveScore(highscore);
	end
end
-- [[ pause stuff functions ]]
function createPauseButtons()
  pauseBtn1.x = centerX; pauseBtn1.y = 20; pauseBtn1:toFront();
  pauseBtn2.x = centerX; pauseBtn2.y = 20; pauseBtn2:toFront(); 
  pauseBtn1:addEventListener("tap", pauseGame);
  pauseBtn2:addEventListener("tap", oneTwoThreeGameStart);
  pauseBtn1.isVisible = false;
  pauseBtn2.isVisible = false;
  pauseLabel:toFront();
end

function pauseGame()
	if pausesLeft >= 0 then
	  pausesLeft = pausesLeft - 1;
	  if pausesLeft == 0 then
	  	pauseLabel.text = "LAST PAUSE";
	  else
	  	pauseLabel.text = "PAUSE " .. 3 - pausesLeft;
	  end
	  pauseLabel.isVisible = false;
	  pauseBtn1.isVisible = false;
	  pauseBtn2.isVisible = true;
	  pauseLabel.isVisible = true;
	  gamePaused = true;
	  timer.pause(throwBallAnimationTimer);
	  timer.pause(throwingBallTimer);
	  transition.pause("ballMovement");
	  throwerSprite:setSequence("still"); throwerSprite:play();
	end
end

function resumeGame()
  if pausesLeft > 0 then
    pauseBtn1.isVisible = true;
  end
  --pauseBtn2.isVisible = false; pauseBtn2 being made invisible in oneTwoThreeGameStart
  gamePaused = false;
  timer.resume(throwBallAnimationTimer);
  timer.resume(throwingBallTimer);
  transition.resume("ballMovement");
end

createInitialScene();