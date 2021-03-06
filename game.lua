local class = require "libs/middleclass"
local stateful = require "libs/stateful"

-- game class
Game = class("Game")
Game:include(stateful)

function Game:initialize(state)
    self:gotoState(state)

    self.scoreLeft = 0
    self.scoreRight = 0
end

-- start state
Start = Game:addState("Start")

function Start:enteredState()
    self.playButton =
        Button:new(
        centerX - 15,
        centerY - 15,
        50,
        37,
        "Play",
        function()
            game:gotoState("Play")
        end
    )
    self.helpButton =
        Button:new(
        centerX - 15,
        centerY + 50,
        50,
        37,
        "Help",
        function()
            game:gotoState("Help")
        end
    )
    self.quitButton =
        Button:new(
        centerX - 15,
        centerY + 115,
        50,
        37,
        "Quit",
        function()
            love.event.quit()
        end
    )
end

function Start:update(dt)
    self.playButton:update(dt)
    self.helpButton:update(dt)
    self.quitButton:update(dt)
end

function Start:draw()
    love.graphics.draw(backgroundImg, 0, 0)

    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(titleImg, windowWidth / 2 - titleImg:getWidth() / 2, 200)
    love.graphics.setColor(213, 186, 29, 255)
    love.graphics.draw(titleImg, windowWidth / 2 - titleImg:getWidth() / 2 + 3, 203)

    self.playButton:draw()
    self.helpButton:draw()
    self.quitButton:draw()
end

function Start:exitedState()
end

-- help state
Help = Game:addState("Help")

function Help:enteredState()
    self.backButton =
        Button:new(
        centerX - 15,
        centerY + 200,
        50,
        37,
        "Back",
        function()
            game:gotoState("Start")
        end
    )
end

function Help:update(dt)
    self.backButton:update(dt)
end

function Help:draw()
    love.graphics.draw(backgroundImg, 0, 0)

    -- draw controls
    love.graphics.setColor(213, 186, 29, 255)
    love.graphics.rectangle("fill", 70, centerY, 120, 50, 2)
    love.graphics.rectangle("fill", windowWidth - 190, centerY, 120, 50, 2)
    love.graphics.setColor(0, 0, 0, 255)
    love.graphics.print("L CTRL", 80, centerY + 15)
    love.graphics.print("R CTRL", windowWidth - 180, centerY + 15)

    -- help info
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.print("Blink when you see a monster", centerX - 220, centerY)
    love.graphics.print("Watch out for the cute creatures", centerX - 220, centerY + 50)
    love.graphics.draw(scaryImgs[4], centerX + 140, centerY - 32, 0, 0.2, 0.2)
    love.graphics.draw(sweetImgs[2], centerX + 180, centerY + 16, 0, 0.2, 0.2)

    self.backButton:draw()
end

-- play state
Play = Game:addState("Play")

function Play:enteredState()
    backgroundMusic:stop()
    tensionMusic:play()

    self.started = true
    self.toMenu = false
    self.isTie = false

    self.roundBeginTimer = 3
    self.timeToTie = 2

    self.jumpscareTimer = love.math.random(2, 10)
    -- print(self.jumpscareTimer) -- [[DEBUG]]

    self.canBlink = false
    self.isSweet = false

    self.leftPlayer = {x = 12, y = centerY - 128, blinked = false, roundWon = false}
    self.rightPlayer = {x = windowWidth - 312, y = centerY - 128, blinked = false, roundWon = false}

    self.stoper = false
    self.playOnce = true

    -- shuffle twice each for better results!
    shuffle(scaryImgs)
    shuffle(sweetImgs)
    shuffle(scaryImgs)
    shuffle(sweetImgs)

    -- choose sweet or scary image
    self.randomArray = love.math.random(2)

    -- game over, go to menu button
    self.menuButton =
        Button:new(
        centerX,
        centerY + 170,
        90,
        37,
        "Go back",
        function()
            game:gotoState("Start")
        end
    )
end

function Play:update(dt)
    if love.keyboard.isDown("lctrl") and not self.leftPlayer.blinked and not self.rightPlayer.blinked then
        blinkSound:play()
        self.leftPlayer.blinked = true

        if self.canBlink and not self.isSweet then
            self.scoreLeft = self.scoreLeft + 1
            self.leftPlayer.roundWon = true
        elseif self.canBlink and self.isSweet then
            self.scoreLeft = self.scoreLeft - 1
            self.rightPlayer.roundWon = true
        elseif not self.canBlink then
            self.scoreLeft = self.scoreLeft - 1
            self.rightPlayer.roundWon = true
        end
    end
    if love.keyboard.isDown("rctrl") and not self.rightPlayer.blinked and not self.leftPlayer.blinked then
        blinkSound:play()
        self.rightPlayer.blinked = true

        if self.canBlink and not self.isSweet then
            self.scoreRight = self.scoreRight + 1
            self.rightPlayer.roundWon = true
        elseif self.canBlink and self.isSweet then
            self.scoreRight = self.scoreRight - 1
            self.leftPlayer.roundWon = true
        elseif not self.canBlink then
            self.scoreRight = self.scoreRight - 1
            self.leftPlayer.roundWon = true
            self.canBlink = false
        end
    end

    if self.toMenu then
        self.menuButton:update(dt)
    end
end

function Play:draw()
    love.graphics.draw(backgroundImg, 0, 0)

    -- print scores
    love.graphics.print("Score: " .. self.scoreLeft, 8, 6)
    love.graphics.print("Score: " .. self.scoreRight, windowWidth - 116, 6)

    if self.started then
        self.started = false
        Timer.after(
            self.jumpscareTimer,
            function()
                self.canBlink = true

                -- print("Jumpscare") -- [[DEBUG]]

                if self.randomArray == 1 then
                    self.isSweet = true

                    Timer.after(
                        self.timeToTie,
                        function()
                            if not self.leftPlayer.roundWon and not self.rightPlayer.roundWon then
                                self.isTie = true
                            end
                        end
                    )
                elseif self.randomArray == 2 then
                    self.isSweet = false
                end
            end
        )
    end

    if self.scoreLeft == 10 or self.scoreRight == 10 then
        self.toMenu = true

        self.menuButton:draw()

        if self.scoreLeft == 10 then
            love.graphics.print("Left player wins!", centerX - 100, centerY - 10)
        elseif self.scoreRight == 10 then
            love.graphics.print("Right players wins!", centerX - 103, centerY - 10)
        end
    end

    if not self.toMenu then
        if not self.leftPlayer.blinked then
            if self.rightPlayer.roundWon then
                love.graphics.draw(leftDeadImg, self.leftPlayer.x, self.leftPlayer.y)
            else
                love.graphics.draw(leftPlayerImg, self.leftPlayer.x, self.leftPlayer.y)
            end
        else
            love.graphics.draw(leftBlinkImg, self.leftPlayer.x, self.leftPlayer.y)
        end
        if not self.rightPlayer.blinked then
            if self.leftPlayer.roundWon then
                love.graphics.draw(rightDeadImg, self.rightPlayer.x, self.rightPlayer.y)
            else
                love.graphics.draw(rightPlayerImg, self.rightPlayer.x, self.rightPlayer.y)
            end
        else
            love.graphics.draw(rightBlinkImg, self.rightPlayer.x, self.rightPlayer.y)
        end

        if self.canBlink == true and (not self.leftPlayer.roundWon and not self.rightPlayer.roundWon) then
            tensionMusic:stop()
            
            if self.isSweet then
                love.graphics.draw(sweetImgs[1], centerX - 256, centerY - 256)
                love.graphics.print("So sweet!", centerX - 50, windowHeight - 50)

                if self.playOnce then
                    self.playOnce = false
                    sweetSound:play()
                end

                if self.isTie then
                    love.graphics.print("Tie!", centerX - 30, 75)
                end
            elseif not self.isSweet then
                love.graphics.draw(scaryImgs[1], centerX - 256, centerY - 256)
                love.graphics.print("Blink now!", centerX - 50, windowHeight - 50)

                if self.playOnce then
                    self.playOnce = false
                    scarySound:play()
                end
            end
        end

        if self.isTie or (self.leftPlayer.roundWon or self.rightPlayer.roundWon) then
            love.graphics.print("Another round starting soon..", centerX - 180, 100)

            if not self.stoper then
                self.stoper = true

                local counter = 3

                Timer.every(
                    1,
                    function()
                        -- print(counter) -- [[DEBUG]]

                        if counter == 0 then
                            Timer.clear()
                            game:gotoState("Play")
                        end

                        counter = counter - 1
                    end
                )
            end
        end
    end
end

function Play:exitedState()
end
