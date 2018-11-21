// Project: GUI_Template
// Created: 2018-11-11

#option_explicit

SetErrorMode(2)

#include "gui.agc"
// #include "game.agc"

GUI_State.scene = 0
GUI_State.layer = 0

GUI_Init()
// GAME_Init()
Do
  // GAME_Update()
  GUI_Update()
  UpdateAllTweens( GetFrameTime() )
  Print( ScreenFPS() )
  Sync ()
Loop


