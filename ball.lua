function instantiateBall(centerX, positionY, finalPositionY, screenWidth)
	local ball = display.newImage("ball.png");

	ball.throw = function(self, throwTime)
		self.y = positionY; self.rotation = 0; self.x = centerX;
		self.isVisible = true;
		self.speed = throwTime;
		transition.to( self, { y = finalPositionY, time = throwTime, rotation = math.random(360, 1080) , tag = "ballMovement", onComplete = function(ball) ball.isVisible = false; playerMissedBall(); end } );
	end
	ball.successfulHit = function(self)
		local ballScale = math.random(2, 5);
		local ballX;
		if math.random(0,3) >= 1.5 then
			ballX = math.random(0,centerX - 20);
		else
			ballX = math.random(centerX + 20, screenWidth);
		end
		timer.performWithDelay(self.speed / 15, function() transition.cancel(self); transition.to( self, { y = 0, x = ballX, time = math.random(300, 600), tag = "ballMovement", xScale = ballScale, yScale = ballScale, rotation = math.random(360, 1080), onComplete = function(ball) ball.isVisible = false; self.xScale = 1; self.yScale = 1; end }); end);
	end
	ball.failedHit = function(self)
		transition.cancel(self);
		transition.to( self, { y = math.random(200, 320), time = math.random(100, 300), tag = "ballMovement", onComplete = function(ball) ball.isVisible = false; ball.xScale = 1; ball.yScale = 1; playerMissedBall(); end } );
	end

	ball.isVisible = false;
	return ball;
end