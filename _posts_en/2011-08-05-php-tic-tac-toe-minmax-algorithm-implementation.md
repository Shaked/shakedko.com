---
layout: post
title: "PHP Tic-Tac-Toe MinMax algorithm implementation"
date: 2011-08-05 17:04:00 -0500
categories: PHP
tags: [MinMax algo, MinMax Algorithm, PHP TicTacToe, TicTacToe implementation, TicTacToe MinMax]
author: Shaked Klein Orbach
summary: |
  Today I want to share my [Tic-Tac-Toe](http://en.wikipedia.org/wiki/Tic-tac-toe) game. A week ago I got a nice assignment: create Tic-Tac-Toe game with PHP where the player won't be able to win the game using [MinMax algorithm](http://en.wikipedia.org/wiki/Minimax).
redirect_from:
  - /php-tic-tac-toe-minmax-algorithm-implementation
  - /php-tic-tac-toe-minmax-algorithm-implementation.html
---

Hey again, long time not writing here.

Today I want to share my
[Tic-Tac-Toe](http://en.wikipedia.org/wiki/Tic-tac-toe "What is TicTacToe?")
game.

A week ago I got a nice assignment, I was needed to create Tic-Tac-Toe
game with PHP while the important task is that the player won't be able
to win the game (which means computer wins or game is over with a
draw).
There was only one clue, "use [MinMax
algorithm](http://en.wikipedia.org/wiki/Minimax "MinMax Algorithm")".
Since I wasn't familiar with MinMax algorithm I was need to read a bit
about it ([Wikipedia](http://en.wikipedia.org/wiki/Minimax), and [nice
article](http://www.progtools.org/games/tutorials/ai_contest/minmax_contest.pdf "Introducing the Min-Max Algorithm by Paulo Pinto")
by Paulo Pinto).

This was a nice task, and after I finished it I got some comments about
"how to make it better", so I\`v implement my changes which may be found
on
[GitHub](https://github.com/Shaked/TicTacToe/tree/master/TicTacToe "TicTacToe MinMax algorithm implementation by Shaked Klein Orbach")

You may try and play with my
[Demo](/assets/examples/tictactoe/ "Tic-Tac-Toe MinMax algorithm implementation by Shakd Klein Orbac")

Hope it will help you somehow.

