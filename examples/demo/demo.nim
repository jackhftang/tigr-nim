import tigr, math, system/ansi_c

var
  playerx = 160f
  playery = 200'f
  playerxs, playerys: float
  standing = true
  remaining: float
  backdrop, screen: ptr Tigr

proc myUpdate(dt: float) =
  if remaining > 0:
    remaining -= dt

  # Read the keyboard and move the player.
  if standing and (keyDown(screen, TK_SPACE) != 0):
    playerys -= 200
  if screen.keyDown(TK_LEFT)!=0 or keyHeld(screen, 'A'.ord)!=0:
    playerxs -= 10
  if screen.keyDown(TK_RIGHT)!=0 or keyHeld(screen, 'D'.ord)!=0:
    playerxs += 10

  var oldx = playerx; var oldy = playery

  # Apply simply physics.
  playerxs *= exp(-10f * dt)
  playerys *= exp(-2f * dt)
  playerys += dt * 200f
  playerx += dt * playerxs
  playery += dt * playerys

  # Apply collision
  if playerx.int < 8:
    playerx = 8f; playerxs = 0f

  if playerx.int > screen.w - 8:
    playerx = screen.w.float - 8
    playerxs = 0

  # Apply playfield collision and stepping.
  var
    dx = (playerx - oldx) / 10
    dy = (playery - oldy) / 10
  standing = false
  for i in 0..<10:
    var p = get(backdrop, oldx.cint, oldy.cint - 1)
    if p.r == 0 and p.g == 0 and p.b == 0:
      oldy -= 1
    p = get(backdrop, oldx.cint, oldy.cint)
    if p.r == 0 and p.g == 0 and p.b == 0 and playerys > 0:
      standing = true
      playerys = 0
      dy = 0
    oldx += dx
    oldy += dy

  playerx = oldx
  playery = oldy

proc main() =
  # Load out sprite
  let squinkle = loadImage("squinkle.png")
  if squinkle.isNil: error(nil, "Cant load squinkle.png")

  # Load some UTF8 text
  let greeting = cast[cstring](readFile("greeting.txt", nil))
  if greeting.isNil: error(nil, "Cant load greeting.txt")

  # Make a window and an off-screen backdrop
  screen = window(320, 240, greeting, TIGR_2X)
  backdrop = bitmap(screen.w, screen.h)

  # Fill in the background
  clear(backdrop, RGB(80, 180, 255))
  fill(backdrop, 0, 200, 320, 40, RGB(60, 120, 60))
  fill(backdrop, 0, 200, 320, 3, tigr.RGB(0, 0, 0))
  line(backdrop, 0, 201, 320, 201, RGB(0xff, 0xff, 0xff))

  # Enable post fx
  screen.setPostFX(1, 1, 1, 2f)

  # Maintain a list of characters entered.
  var chars: array[16, char]
  c_memset(chars[0].addr, '_'.cint, 16)
  var
    dt: float
    x, y, b: cint
    prevx, prevy, prev: cint

  # Repeat till they close the window.
  while screen.closed() == 0 and
  screen.keyDown(TK_ESCAPE) == 0:
    # Update game
    dt = tigr.time()
    myUpdate(dt)

    # Read the mouse and draw when pressed.
    screen.mouse(x.addr, y.addr, b.addr)
    if (b and 1) > 0:
      if prev != 0:
        line(backdrop, prevx, prevy, x, y, RGB(0, 0, 0))
      prevx = x; prevy = y; prev = 1
    else: prev = 0

    # Composite the backdrop and sprite onto the screen.
    screen.blit(backdrop, 0, 0, 0, 0, backdrop.w, backdrop.h)
    screen.blitAlpha(squinkle, playerx.cint - squinkle.w div 2, playery.cint - squinkle.h, 0, 0, squinkle.w, squinkle.h, 1.0f)
    screen.print(tfont, 10, 10, RGBA(0xc0, 0xd0, 0xff, 0xc0), greeting)
    screen.print(tfont, 10, 222, RGBA(0xff, 0xff, 0xff, 0xff), "A D + SPACE")

    #Grab any chars and add them to our buffer.
    while true:
      let c = screen.readChar()
      if c == 0: break
      for n in 1..<16:
        chars[n - 1] = chars[n]
      chars[15] = c.chr

    # Print out the character buffer too.
    var
      tmp {.global.} : array[100, char]
      p = cast[cstring](tmp[0].addr)
    for n in 0..<16:
      p = encodeUTF8(p, chars[n].cint)
    screen.print(tfont, 160, 222, RGB(0xff, 0xff, 0xff), "Chars: %s", tmp[0].addr)
    zeroMem(tmp[0].addr, tmp.sizeof)

    # Update the window
    screen.update()

  squinkle.free()
  backdrop.free()
  screen.free()

main()

