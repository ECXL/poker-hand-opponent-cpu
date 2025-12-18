# Poker Hand Opponent CPU

***work in progress***
**Please check the CREDITS.md for the resources I am using, and code I have adapted**

## Description

For a game I am currently developing, I have been creating a functional Poker game as a mechanic for it. This game requires a CPU for the opponent to play against as it is designed to be a single player game. I wanted to create a CPU that can evaluate what Poker Hand they have and realise the potential hands they could get, in order for it to place fold, check and place bets. With a bit of randomness, once functional it should be able to even bluff.

This code prioritises gameplay feel over accuracy. This is not designed to be a perfect machine learning AI that can bet and bluff accurately, it is designed to feel good for the player to play up against. Despite it bluffing, it should not feel like random chance to beat this CPU, though there should still be that uncertainty that comes with Poker.

## Current Goals and Progress

Currently this code allows for the evaluation of Poker hands and Potential Poker hands. However, the numbers and weighting that comes with those predictions are currently temporary. The framework is in place, but some game testing is required to figure out what those numbers should be. Once a draft of that has been made, we can finally apply it to an opponent CPU that can start using those numbers to fold, check, and raise accordingly. That will be the last of the updating of this Git project, as the rest of the game will be programmed privately until release.