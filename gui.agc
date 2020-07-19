/* 
 * **********************************************
 * Constants
 * **********************************************
*/

#constant GUI_BG_SPRITE = 1
#constant GUI_SPLASH_SPRITE = 2

#constant GUI_SPLASH_IMAGE = 1

// Waiting a new state
#constant GUI_READY = 999

// GUI Controls
#constant GUI_CONTROL_TYPE_SPRITE = 1
#constant GUI_CONTROL_TYPE_TEXT = 2

// Events types
#constant GUI_EVENT_CLICK = 1

// Callbacks
#constant GUI_EVENT_CLICK_NAVIGATE = 1
#constant GUI_EVENT_CLICK_OPEN = 2
#constant GUI_EVENT_CLICK_CLOSE = 3
#constant GUI_EVENT_CLICK_PLAY = 4

// Save JSON
#constant GUI_JSON_STATIC_FILE = 1
#constant GUI_SAVED_JSON_FILE = "saved.json"

global GUI_NAME = "GUITemplate" //[IDEGUIADD],string,App Name

global GUI_SCREEN_WIDTH = 300 //[IDEGUIADD],integer,Width
global GUI_SCREEN_HEIGHT = 533 //[IDEGUIADD],integer,Height

global GUI_DEPTH_SCREEN_DEEP = 20 //[IDEGUIADD],integer,Screen Depth
global GUI_DEPTH_SCREEN_BACKGROUND = 10 //[IDEGUIADD],integer,Background Depth
global GUI_DEPTH_SCREEN_LAYER = 5 //[IDEGUIADD],integer,Layer Depth
global GUI_DEPTH_SCREEN_CONTROLS = 0 //[IDEGUIADD],integer,Controls Depth

global GUI_EDIT_CELL_SIZE = 25 //[IDEGUIADD],integer,Cell size
global GUI_EDIT_MODE_ENABLED = 1 //[IDEGUIADD],integer,Edit Mode Enabled

/* 
 * **********************************************
 * TYPES
 * **********************************************
*/

type tGUI_Screen
  id as integer
  name as string
  scenes as tGUI_Scene[]
  tween as integer
  theme as integer
  sprite as integer
endtype

type tGUI_Scene
  id as integer
  name as string
  layers as tGUI_Layer[]
  visible as integer
  active as integer
endtype

type tGUI_Layer
  id as integer
  name as string
  depth as integer
  sprite as integer
  state as integer
  controls as tGUI_Control[]
endtype

type tGUI_Holder
  controls as tGUI_Control[]
endtype

type tGUI_Control
  id as integer
  _type as integer
  _events as tGUI_Event[]
  label as string
  desc as string
  description as string
  parent as integer
  scene as integer
  group as integer
  x as integer
  y as integer
  width as integer
  height as integer
  depth as integer
  sprite as integer
  text as integer
  size as integer
  image as integer
  sound as integer
  tween as integer
  value as integer
  state as integer
  active as integer
  visible as integer
  fgcolor as integer
  bgcolor as integer
  holder as tGUI_Holder
endtype

type tGUI_State
  layer as integer
  scene as integer
endtype

type tGUI_Event
  _type as integer
  callback as integer
  value as integer
endtype

global GUI_Screen         as tGUI_Screen
global GUI_Controls       as tGUI_Control[]
global GUI_State          as tGUI_State
global GUI_Uuid           as integer[]

global GUI_PlayingTheme   as integer = 0

global GUI_DefaultSound   as integer = 0
global GUI_DefaultImage   as integer = 0


global GUI_active_layer   as integer = 0
global GUI_active_scene   as integer = 0

global GUI_EDITING as integer = 0


global GUI_playingSound as integer
global GUI_lastSpriteHover as integer
global GUI_controlPicked as integer

global GUI_pX as integer
global GUI_pY as integer
global GUI_cX as integer
global GUI_cY as integer


/* 
 * ************************************************
 * GUI_Init
 * Initialises the GUI
 * ************************************************
*/
function GUI_Init()
  GUI_DefaultSound = LoadSoundOGG("click.ogg")
  GUI_DefaultImage = LoadImage("blank.png")

  GUI_Screen = GUI_CreateScreen(GUI_NAME, GetFileExists(GUI_SAVED_JSON_FILE))

  GUI_Initialise (GUI_SCREEN_WIDTH, GUI_SCREEN_HEIGHT, GUI_Screen.name, 0)

  if GUI_PlayingTheme = 1 then PlayMusicOGG( GUI_Screen.theme, 2)

  GUI_ShowSplashScreen("splash.png")
  GUI_HideSplashScreen(3) // 3 seconds

  if GUI_EDIT_MODE_ENABLED
    // Edit buttons
    AddVirtualButton ( 1, GUI_SCREEN_WIDTH - 25,  25, 20 ) // Shows the edit grid
    AddVirtualButton ( 2, GUI_SCREEN_WIDTH - 25,  50, 20 ) // Hide the edit grid
    AddVirtualButton ( 3, GUI_SCREEN_WIDTH - 25,  75, 20 ) // Remove the stored json
  endif
endfunction

/* 
 * ************************************************
 * GUI_Init
 * Updates the GUI
 * ************************************************
*/
function GUI_Update()
    select GUI_EDITING
      case 1
        GUI_DrawEditGrid()
        GUI_Screen = GUI_EditHandler(GUI_Screen)
      endcase
      case 0
        select GUI_active_scene
          case GUI_READY
            if(GetPointerPressed() = 1)
              local spriteHit as integer
              spriteHit = GetSpriteHit ( GetPointerX (), GetPointerY () )
              GUI_EventHandler( spriteHit )
            endif
          endcase
          case default
            GUI_DrawScene(GUI_active_scene, GUI_active_layer)
            GUI_active_scene = GUI_READY
          endcase
        endselect
      endcase
    endselect
    if GetVirtualButtonState(1) = 1
      GUI_EDITING = 1
    endif
    if GetVirtualButtonState(2) = 1
      GUI_EDITING = 0
    endif
    if GetVirtualButtonState(3) = 1
      if GetFileExists(GUI_SAVED_JSON_FILE)
        DeleteFile(GUI_SAVED_JSON_FILE)
        Message("Deleted stored config")
      endif
    endif
endfunction

/* 
 * ************************************************
 * GUI_DrawEditGrid
 * Creates a grid for edit purposes
 * ************************************************
*/
function GUI_DrawEditGrid()
  local cellWidthCount as integer
  local cellHeightCount as integer
  cellWidthCount  = GUI_SCREEN_WIDTH  / GUI_EDIT_CELL_SIZE
  cellHeightCount = GUI_SCREEN_HEIGHT / GUI_EDIT_CELL_SIZE
  local i as integer
  for i = 1 to cellWidthCount
    DrawLine( i * GUI_EDIT_CELL_SIZE, 0, i * GUI_EDIT_CELL_SIZE, GUI_SCREEN_HEIGHT, MakeColor(255,0,0), MakeColor(255,0,0))
  next i
  for i = 1 to cellHeightCount
    DrawLine( 0, i * GUI_EDIT_CELL_SIZE, GUI_SCREEN_WIDTH, i * GUI_EDIT_CELL_SIZE, MakeColor(255,0,0), MakeColor(255,0,0))
  next i
endfunction

/* 
 * ************************************************
 * GUI_CreateScreen
 * Creates the main screen and adds a default scene
 * ************************************************
*/
function GUI_CreateScreen(name as string, fromJSON as integer)
  local screen as tGUI_Screen
  if fromJSON
    local json_string as string
    json_string = GUI_loadJSON(GUI_SAVED_JSON_FILE)
    screen.fromJSON( json_string )
    screen = GUI_InitialiseControls(screen)
  else
    // Get the data  from the local txt files
    screen = GUI_LoadScenes   ( screen, "gui_scenes.txt"   )
    screen = GUI_LoadControls ( screen, "gui_controls.txt" )
  endif
  screen.name   = name
  screen.theme  = LoadMusicOGG("theme.ogg")
  screen.sprite = LoadImage ("bg.png")
  CreateSprite  ( GUI_BG_SPRITE, screen.sprite)
  SetSpriteSize ( GUI_BG_SPRITE, GUI_SCREEN_WIDTH, GUI_SCREEN_HEIGHT ) // FIXME
  FixSpriteToScreen (GUI_BG_SPRITE, 1)
endfunction screen


/* 
 * ************************************************
 * GUI_InitialiseControls
 * 
 * ************************************************
*/
function GUI_InitialiseControls(screen as tGUI_Screen)
    local i as integer
    local j as integer
    for i = 0 to screen.scenes.length
      for j = 0 to screen.scenes[i].layers[0].controls.length
        GUI_InitialiseControl(screen.scenes[i].layers[0].controls[j])
      next j
    next i
endfunction screen

/* 
 * **********************************************
 * GUI_CreateLayer
 * A layer is the main buttons container
 * Considering a scene can have more than a layer
 * Atm we are working with just a layer (0)
 * Creates a layer ready for a scene
 * **********************************************
*/
function GUI_CreateLayer(id as integer, name as string)
  local layer as tGUI_Layer
  layer.id = id
  layer.name = name
  layer.state = 1
  local controls as tGUI_Control[]
  layer.controls = controls
endfunction layer

/* 
 * **********************************************
 * GUI_CreateScene
 * Creates a scene and adds a layer by default
 * **********************************************
*/
function GUI_CreateScene(id as integer, name as string)
  // Add a default layer
  local layer as tGUI_Layer
  local scene as tGUI_Scene
  layer.id = id
  layer.name = name
  layer = GUI_CreateLayer(0, "default")
  local layers as tGUI_Layer[]
  layers.insert(layer)
  // Creates the scene
  scene.id = id
  scene.name = name
  scene.layers = layers
  scene.visible = 0
endfunction scene

/* 
 * **********************************************
 * GUI_CreateUniqueId
 * Generates an unique id, and adds to the pool
 * **********************************************
*/
function GUI_CreateUniqueId()
  local i as integer
  local uid as integer = 1
  for i = 0 to GUI_Uuid.length
    if GUI_Uuid[i] = 0
      uid = i
      exit
    endif
  next i
  if GUI_Uuid.length + 1 = i then uid = i + 1
  GUI_Uuid.insert(uid)
endfunction uid

/* 
 * **********************************************
 * GUI_RetrieveUniqueId
 * Retrieves the unique id from the pool
 * **********************************************
*/
function GUI_RetrieveUniqueId(control as tGUI_Control)
  local uid as integer
  uid = GUI_Uuid[control.id]
endfunction uid

/* 
 * **********************************************
 * GUI_SpriteCheck
 * Helper for GUI_EventHandler
 * **********************************************
*/
function GUI_SpriteCheck (sprite as integer)
  local result as integer = 0
  if sprite = 0 then exitfunction 0
  if GetSpriteActive(sprite) = 1 and GetSpriteVisible(sprite) = 1 and sprite > 100000 // Only auto-generated ids
    local i as integer
    for i = 0 to GUI_Screen.scenes[GUI_State.scene].layers[GUI_State.layer].controls.length
      if GUI_Screen.scenes[GUI_State.scene].layers[GUI_State.layer].controls[i].sprite = sprite
        result = 1
      endif
    next i
  endif
endfunction result
/* 
 * **********************************************
 * GUI_ControlEventsHandler
 * Handles the main control events
 * **********************************************
*/
function GUI_EventHandler(spriteHit as integer)
    // GUI_Control_Check_Sprite_Effect(spriteHit)
    if spriteHit = 0 then exitfunction
    if GUI_SpriteCheck(spriteHit)
      local control as tGUI_Control
      control = GUI_GetControlBySprite(spriteHit)
      if (control.tween > 0)
        SetTweenSpriteY( control.tween, GetSpriteY(control.sprite) - 10, GetSpriteY(control.sprite), TweenBounce())
        PlayTweenSprite( control.tween, control.sprite, .5 )
      endif
      if (control.sound > 0)
        StopSound(GUI_playingSound)
        PlaySound(control.sound)
        GUI_playingSound = control.sound
      endif
      local i as integer
      for i = 0 to control._events.length
        select control._events[i]._type
          case GUI_EVENT_CLICK
            select control._events[i].callback
              case GUI_EVENT_CLICK_NAVIGATE
                Log("Go scene " + Str(control._events[i].value))
                GUI_active_scene = control._events[i].value
              endcase
              case GUI_EVENT_CLICK_PLAY
                Log("TODO: Play game")
              endcase
              case GUI_EVENT_CLICK_OPEN
                Log("TODO: Open window")
              endcase
              case GUI_EVENT_CLICK_CLOSE
                Log("TODO: Close window")
              endcase
            endselect
          endcase
        endselect
      next i
    endif
endfunction

/* 
 * **********************************************
 * GUI_DrawScene
 * Place the sprites for a given scene
 * **********************************************
*/
function GUI_DrawScene(scene as integer, layer as integer)
  Log("GUI_DrawScene " + Str(scene) + " " + Str(layer))
  if GUI_State.scene <> scene
    Log("Draw scene " + Str(scene))
    GUI_ResetLayer(GUI_State.scene, GUI_State.layer, 0)
  endif
  GUI_ResetLayer(scene, layer, 1)
  GUI_DrawLayer(scene, layer)
  
  
  GUI_State.scene = scene
  GUI_State.layer = layer
endfunction

/* 
 * **********************************************
 * GUI_DrawLayer
 * Place the sprites for a given scene
 * **********************************************
*/
function GUI_DrawLayer(scene as integer, layer as integer)
    local a as integer
    local i as integer
    for i = 0 to GUI_Screen.scenes[scene].layers[layer].controls.length
        SetSpritePosition ( GUI_Screen.scenes[scene].layers[layer].controls[i].sprite, GUI_Screen.scenes[scene].layers[0].controls[i].x, GUI_Screen.scenes[scene].layers[0].controls[i].y )
        SetSpriteDepth    ( GUI_Screen.scenes[scene].layers[layer].controls[i].sprite, GUI_DEPTH_SCREEN_LAYER )
        if GUI_Screen.scenes[scene].layers[layer].controls[i].text > 0
          SetTextPosition ( GUI_Screen.scenes[scene].layers[layer].controls[i].text, GUI_Screen.scenes[scene].layers[0].controls[i].x, GUI_Screen.scenes[scene].layers[0].controls[i].y )
          SetTextDepth    ( GUI_Screen.scenes[scene].layers[layer].controls[i].text, GUI_DEPTH_SCREEN_LAYER )
        endif
    next i
endfunction

/* 
 * **********************************************
 * GUI_ResetLayer
 * Place the sprites for a given scene
 * **********************************************
*/
function GUI_ResetLayer(scene as integer, layer as integer, state as integer)
  local depth as integer = GUI_DEPTH_SCREEN_DEEP
  if state then depth = GUI_DEPTH_SCREEN_LAYER
  local i as integer
  GUI_Screen.scenes[scene].layers[layer].depth = depth
  for i = 0 to GUI_Screen.scenes[scene].layers[layer].controls.length
    GUI_ResetControl ( GUI_Screen.scenes[scene].layers[layer].controls[i] , state, depth)
  next i
endfunction

/* 
 * **********************************************
 * GUI_InitialiseControl
 * Initialises the control inactive until needed
 * **********************************************
*/
function GUI_InitialiseControl(control as tGUI_Control)
  
  control.id = GUI_CreateUniqueId()

  select control._type
    case GUI_CONTROL_TYPE_SPRITE
      control.sound = GUI_DefaultSound
      
      if control.label = ""
        control.image = GUI_DefaultImage
      else
        control.image = LoadImage( control.label + ".png")
      endif
      
      if(GetFileExists(control.label + ".ogg"))
        //~ Log("Loaded file " + control.label + ".ogg")
        control.sound = LoadSoundOGG( control.label + ".ogg" )
      endif
      
      control.sprite = CreateSprite(control.image)
      FixSpriteToScreen(control.sprite, 1)
      SetSpriteImage ( control.sprite, control.image )
      
      control.depth = GUI_DEPTH_SCREEN_DEEP
      SetSpriteDepth (control.sprite, GUI_DEPTH_SCREEN_DEEP)
      
      SetSpriteGroup(control.sprite, control.group)
      
      local ht as integer
      ht = GetImageHeight(control.image)
      if  ht > control.height
        SetSpriteAnimation(control.sprite, GetImageWidth(control.image),ht/3,3)
        SetSpriteFrame(control.sprite,1)
      endif
      
      SetSpriteSize    ( control.sprite, control.width, control.height )
      
      SetSpriteActive  ( control.sprite, control.active )
      SetSpriteVisible ( control.sprite, control.visible )
      SetSPriteDepth   ( control.sprite, GUI_DEPTH_SCREEN_DEEP)
    endcase
    case GUI_CONTROL_TYPE_TEXT
      // Since we havent GetTextHit() support, is needed to wrap 
      // the text with a transparent sprite to edit the text position
      // More info: https://forum.thegamecreators.com/thread/218640
      control.sprite = CreateSprite(0)
      FixSpriteToScreen(control.sprite, 1)
      SetSpriteSize    ( control.sprite, control.width, control.height )
      SetSpriteColorAlpha (control.sprite, 0)
      SetSpriteActive  ( control.sprite, control.active )
      SetSpriteVisible ( control.sprite, control.visible )
      control.text = CreateText(control.desc)
      FixTextToScreen(control.text, 1)
      SetTextPosition(control.text, control.x, control.y)
      SetTextSize(control.text, control.size)
      SetTextColor(control.text, 30, 110, 120, 255)
      SetTextVisible ( control.text, control.visible )
    endcase
  endselect

  control.fgcolor = MakeColor( 255, 255, 255 )
  control.bgcolor = MakeColor( 0  , 255, 0   )
  control.state = 1

  control.tween  = CreateTweenSprite(1) // TEMP
endfunction control

/* 
 * **********************************************
 * GUI_CreateControl
 * Creates a control and retuns his definition
 * **********************************************
*/
function GUI_CreateControl(_type as integer, parent as integer, s as integer, l as integer, e as integer, c as integer, v as integer, label as string, fs as integer, desc as string, x as integer, y as integer, w as integer, h as integer)
  control as tGUI_Control
  control._type = _type
  control.parent = parent
  control.label = label
  control.desc = desc
  control.group = _type 
  control.x = x
  control.y = y
  control.width = w
  control.height = h
  control.active = 0
  control.visible = 0
  control.size = fs
  control = GUI_InitialiseControl(control)
  
  local event as tGUI_Event
  event._type = e
  event.callback = c
  event.value = v
  
  local events as tGUI_Event[]
  events.insert(event)
  control._events = events
  control.scene = s
endfunction control

/* 
 * **********************************************
 * GUI_GetScene
 * **********************************************
*/
function GUI_GetScene(sid as integer)
  local scene as tGUI_Scene
  scene = GUI_Screen.scenes[sid]
endfunction scene

/* 
 * **********************************************
 * GUI_GetControlBySprite
 * **********************************************
*/
function GUI_GetControlBySprite(spriteId as integer)
  local control as tGUI_Control
  local i as integer
  local j as integer
  for i = 0 to GUI_Screen.scenes.length
    for j = 0 to GUI_Screen.scenes[i].layers[0].controls.length
    if (GUI_Screen.scenes[i].layers[0].controls[j].sprite = spriteId and GetSpriteActive(spriteId))
      control = GUI_Screen.scenes[i].layers[0].controls[j]
      exit
    endif
  next j
  next i
endfunction control

/* 
 * **********************************************
 * GUI_ResetControl
 * **********************************************
*/
function GUI_ResetControl (control as tGUI_Control, state as integer, depth as integer)
    SetSpriteActive  ( control.sprite, state )
    SetSpriteVisible ( control.sprite, state )
    SetSpriteDepth   ( control.sprite, depth )
    if control._type = GUI_CONTROL_TYPE_TEXT
      SetTextVisible ( control.text, state )
      SetTextDepth   ( control.text, depth )
    endif
    control.depth = depth
    control.active = state
    control.visible = state
endfunction control


/* 
 * **********************************************
 * GUI_LoadScenes
 * Scenes local loader for dev purposes
 * **********************************************
*/
Function GUI_LoadScenes(screen as tGUI_Screen, file$ as string)
  local dl$ as string = "|"
  local scenes as tGUI_Scene[]
  local dataFile as integer
  dataFile = OpenToRead(file$)
  local dtl$ as string
  dtl$ = ReadLine(dataFile)
  while not FileEOF(dataFile)
    local scene as tGUI_Scene
    local int1 as integer
    local str1 as string
    int1 = Val(GetStringToken(dtl$, dl$, 1))
    str1 = GetStringToken(dtl$, dl$, 2)
    scene = GUI_CreateScene(int1, str1)
    screen.scenes.insert(scene)
    dtl$ = ReadLine(dataFile)
  endwhile
Endfunction screen 

/* 
 * **********************************************
 * GUI_LoadControls
 * Controls local loader for dev purposes
 * **********************************************
*/
Function GUI_LoadControls(screen as tGUI_Screen, file$ as string)
  local dl$ as string = "|"
  local dataFile as integer
  dataFile = OpenToRead(file$)
  local dtl$ as string
  dtl$ = ReadLine(dataFile)
  while not FileEOF(dataFile)
    local control as tGUI_Control
    local int1 as integer
    local int2 as integer
    local int3 as integer
    local int4 as integer
    local int5 as integer
    local int6 as integer
    local int7 as integer
    local str8 as string
    local int9 as integer
    local str10 as string
    local int11 as integer
    local int12 as integer
    local int13 as integer
    local int14 as integer
    int1  = Val(GetStringToken(dtl$, dl$, 1))   // control_type
    int2  = Val(GetStringToken(dtl$, dl$, 2))   // parent
    int3  = Val(GetStringToken(dtl$, dl$, 3))   // scene
    int4  = Val(GetStringToken(dtl$, dl$, 4))   // layer
    int5  = Val(GetStringToken(dtl$, dl$, 5))   // event type
    int6  = Val(GetStringToken(dtl$, dl$, 6))   // callback
    int7  = Val(GetStringToken(dtl$, dl$, 7))   // value
    str8  = GetStringToken(dtl$, dl$, 8)        // label
    int9  = Val(GetStringToken(dtl$, dl$, 9))   // fontsize
    str10 = GetStringToken(dtl$, dl$, 10)       // tooltip
    int11 = Val(GetStringToken(dtl$, dl$, 11))  // x
    int12 = Val(GetStringToken(dtl$, dl$, 12))  // y
    int13 = Val(GetStringToken(dtl$, dl$, 13))  // width
    int14 = Val(GetStringToken(dtl$, dl$, 14))  // height
    control = GUI_CreateControl( int1, int2, int3, int4, int5, int6, int7, str8, int9, str10, int11, int12, int13, int14)
    screen.scenes[int3].layers[int4].controls.insert(control)
    dtl$ = ReadLine(dataFile)
  endwhile
Endfunction screen

/* 
 * **********************************************
 * GUI_loadJSON
 * Populates an object from a json file
 * **********************************************
*/
function GUI_loadJSON( filename$ )
	JSON$ as string = ""
	memBlock as integer
	memBlock = CreateMemblockFromFile( filename$ )
	JSON$ = GetMemblockString( Memblock, 0, GetMemblockSize( memBlock ) )
	DeleteMemblock(memBlock)
endfunction JSON$

/* 
 * **********************************************
 * GUI_Initialise
 * Initialise the screen in a wrapper
 * **********************************************
*/
function GUI_Initialise(w as integer, h as integer, t as string, c as integer)
	// If no size given, use full screen
	if w = 0 or h = 0
		SetWindowSize(0,0,1)
	// else set size and title
	else
		SetWindowSize(w,h,0)
		// Set window title
		SetWindowTitle(t)
	endif
	// Set aspect ratio
	SetDisplayAspect(1.0*w/h)
	// Clear the screen to colour c
	SetClearColor((c&&0xFF0000)>>16,(c&&0xFF00)>>8,c&&0xFF)
	ClearScreen()
	// Set orientations allowed
	SetOrientationAllowed(1,0, 0,0)
  // allow the user to resize the window
  SetWindowAllowResize( 1 ) 
  // 30fps instead of 60 to save battery
  SetSyncRate( 30, 0 ) 
  // doesn't have to match the window
  SetVirtualResolution( w, h ) 
  // use the maximum available screen space, no black borders
  SetScissor( 0,0,0,0 ) 
	// Use vector fonts
	UseNewDefaultFonts(1)
Endfunction

/* 
 * **********************************************
 * GUI_ShowSplashScreen
 * Displays the splash Screen
 * **********************************************
*/
Function GUI_ShowSplashScreen(f as string)
  LoadImage(GUI_SPLASH_IMAGE, f)
	CreateSprite(GUI_SPLASH_SPRITE, GUI_SPLASH_IMAGE)
  FixSpriteToScreen(GUI_SPLASH_SPRITE, 1)
	SetSpriteSize(GUI_SPLASH_SPRITE, GUI_SCREEN_WIDTH, GUI_SCREEN_HEIGHT)
	Sync()
Endfunction

/* 
 * **********************************************
 * GUI_HideSplashScreen
 * Hide the Splash screen in a given time
 * **********************************************
*/
Function GUI_HideSplashScreen(s as integer)
	ResetTimer()
	// Wait for time up or click
	while Timer() < s and GetPointerPressed() = 0
		Sync()
	endwhile
	// Delete sprite and image
	DeleteSprite ( GUI_SPLASH_SPRITE )
	DeleteImage  ( GUI_SPLASH_IMAGE  )
Endfunction

/* 
 * **********************************************
 * GUI_SetControlFrame
 * Set control sprite frame
 * **********************************************
*/
function GUI_SetControlFrame(control as tGUI_Control, frame as integer)
  control.state = frame
  SetSpriteFrame(control.sprite, frame)
endfunction

/* 
 * **********************************************
 * GUI_EditHandler
 * Editable controls handler
 * **********************************************
*/
function GUI_EditHandler(screen as tGUI_Screen)
  Print("Editing")
  // Credits here goes for baxslash : https://forum.thegamecreators.com/thread/191730#msg2286445
  if getPointerPressed() = 1
    local GUI_hit as integer
    GUI_hit = GetSPriteHit(getPointerX(), getPointerY())
    if GUI_hit > 0
      GUI_controlPicked = GUI_hit
      GUI_pX = getPointerX()
      GUI_pY = getPointerY()
    endif
  else
    local control as tGUI_Control
    if GUI_SpriteCheck(GUI_controlPicked)
      if getPointerState() > 0
        GUI_cX = GetPointerX()
        GUI_cY = GetPointerY()
        control = GUI_GetControlBySprite(GUI_controlPicked)
        SetSpritePosition(GUI_controlPicked,GUI_pX,GUI_pY)
        Print("ID: " + Str(control.id))
        Print("SpriteId: " + Str(control.sprite))
        Print(Str(GUI_pX) + ", " + Str(GUI_pY))
        if control.text > 0
          SetTextPosition(control.text, GUI_pX, GUI_pY)
        endif
        GUI_pX = GUI_cX
        GUI_pY = GUI_cY
        local color as integer
        color = MakeColor(0,255,0)
        DrawBox(GUI_pX, GUI_pY, GUI_pX + control.width, GUI_pY + control.height, color, color, color, color, 0)
      else
        control = GUI_GetControlBySprite(GUI_controlPicked)
        local i as integer
        for i = 0 to screen.scenes[GUI_State.scene].layers[GUI_State.layer].controls.length
          if GUI_controlPicked = screen.scenes[GUI_State.scene].layers[GUI_State.layer].controls[i].sprite
            screen.scenes[GUI_State.scene].layers[GUI_State.layer].controls[i].x = GUI_pX
            screen.scenes[GUI_State.scene].layers[GUI_State.layer].controls[i].y = GUI_pY
            SetSpritePosition(GUI_controlPicked, GUI_pX, GUI_pY)
            if screen.scenes[GUI_State.scene].layers[GUI_State.layer].controls[i].text > 0
              SetTextPosition(screen.scenes[GUI_State.scene].layers[GUI_State.layer].controls[i].text, GUI_pX, GUI_pY)
            endif
          endif
        next i
        GUI_controlPicked = 0
        
        // Saving the change
        OpenToWrite(GUI_JSON_STATIC_FILE, GUI_SAVED_JSON_FILE, 0) 
        WriteString(GUI_JSON_STATIC_FILE, screen.toJSON())
        CloseFile(GUI_JSON_STATIC_FILE)
      endif
    endif
  endif
endfunction screen

// 1|1|0|0|1|1|0|window|12|A window example|20|20|200|355
