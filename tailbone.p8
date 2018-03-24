pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--------------------------------
-- gameloop --------------------

function _init()
  poke(0x5f2d, 1)
  dispatch('reset')
end

function _update60()
  tick()
  input()
  update_groundlevel()
  physics()
  dispatch(next(eventloop))

  if shake_frames > 0 then
    shake_frames = shake_frames - 1
  end

  if trick == 'roll' then
    roll_count = roll_count + 1
    if roll_count > roll_limit then
      actions.push()
    end
  end

  if mode == 'play' and paused == false then
    trex:move()
  end
  if trick == 'charge' then
    if charge == 0 then
      sfx(7)
    elseif charge == 16 then
      sfx(7)
    end
    charge = charge + 1
  end
end

function _draw()
  for layer in all(layers) do
    render[layer]()
  end
end

function input()
  jump = btn(5)
  if stat(34) == 1 then
    jump = true
  end
  if getchar() == ' ' then
    jump = true
  end

  if mode == 'attract' then

    if jump then
      after(16, 'play')
    end

  elseif mode == 'play' then

    if trex.offset[2] > 0 then
      --return true
    end

    if jump then
      if trex.alive == false then
        after(16, 'reset')
      elseif trick == 'push' then
        actions.pop()
      elseif trick == 'roll' then
        actions.pop()
      elseif trick == 'pop' then
        actions.ollie()
      elseif trick == 'air' and trex.vector[2] <= 1.4 then
        actions.charge()
      elseif trick == 'charge' and charge > max_charge then
        actions.grab()
      elseif trick == 'grind' then
        actions.pop()
      end
    else
      if trick == 'push' then
        can_pop = true
        can_charge = true
      elseif trick == 'roll' then
        can_pop = true
        can_charge = true
      elseif trick == 'ollie' then
        actions.release()
      elseif trick == 'charge' then --and charge > min_charge then
        actions.grab()
      elseif trick == 'grab' then
        can_charge = true
      elseif trick == 'grind' then
        can_pop = true
        can_charge = true
        --if groundlevel == 0 then
          --actions.release()
        --end
      end
    end

  end
end


-->8
--------------------------------
-- state -----------------------

mode = 'attract'
score = 0
paused = false

frame = 0
timeouts = {}
intervals = {}
eventloop = {}
script = {}

trex = {}
can_pop = true
can_charge = true
min_charge = 2
max_charge = 32
overtaking = false
cue_jump = false
groundlevel = 0
above_lava = 0
above_cable = 0
push_speed = 1
roll_limit = 60
roll_count = 0

shake_frames = 0

cacti = {}
poles = {}
cables = {}
cars = {}
lava = {}

tricks = {
  'none',
  'push',
  'pop',
  'ollie',
  'charge',
  'grab',
  'grind',
  'roll',
}

is_attack = {
  none = false,
  push = false,
  pop = false,
  ollie = false,
  charge = true,
  grab = true,
  grind = false,
  roll = false,
}

trick = 'none'
charge = 0
layers = {
  'sky',
  'cityscape',
  'nearground',
  'foreground',
  'ui',
}

foreground = {}
nearground = {}
cityscape = {}
sky = {}

sprites = {
  roll_1 = { 0, 0, 16, 16, 0, false },
  roll_1 = { 0, 0, 16, 16, 0, false },
  push_1 = { 16, 0, 16, 16, 0, false },
  push_2 = { 32, 0, 16, 16, 0, false },
  push_3 = { 48, 0, 16, 16, 0, false },
  push_4 = { 64, 0, 16, 16, 0, false },
  push_5 = { 80, 0, 16, 16, 0, false },
  push_6 = { 96, 0, 16, 16, 0, false },

  ollie_1 = { 0, 16, 16, 16, 0, false },
  grab_1 = { 16, 16, 16, 16, 0, false },
  grab_2 = { 32, 16, 16, 16, 0, false },
  dead_1 = { 48, 16, 16, 16, 0, false },
  ollie_2 = { 64, 16, 16, 16, 0, false },

  --sparks_1 = { 24, 104, 4, 4, 0, false },
  sparks_1 = { 120, 24, 4, 4, 0, false },
  sparks_2 = { 124, 24, 4, 4, 0, false },
  sparks_3 = { 120, 28, 4, 4, 0, false },
  sparks_4 = { 124, 28, 4, 4, 0, false },
  sparks_5 = { 124, 28, 4, 4, 0, false },
  sparks_6 = { 120, 28, 4, 4, 0, false },
  sparks_7 = { 124, 24, 4, 4, 0, false },
  sparks_8 = { 120, 24, 4, 4, 0, false },

  tower_1 = { 0, 32, 5, 8, 1, false },
  tower_2 = { 6, 32, 14, 8, 1, false },
  tower_3 = { 20, 32, 6, 8, 1, false },

  plant_1 = { 0, 42, 8, 8, 1, false },
  plant_2 = { 8, 42, 8, 8, 1, false },
  plant_3 = { 16, 42, 8, 8, 1, false },
  plant_4 = { 24, 42, 8, 8, 1, false },

  cactus_alive_1 = { 33, 32, 8, 16, 0, false },
  cactus_dead_1 = { 44, 32, 8, 16, 0, false },
  cactus_dead_2 = { 55, 32, 8, 16, 0, false },
  cactus_dead_3 = { 33, 48, 8, 16, 0, false },
  cactus_dead_4 = { 44, 48, 8, 16, 0, false },
  cactus_dead_5 = { 55, 48, 8, 16, 0, false },

  pole = { 64, 32, 8, 4, 0, false },

  car_right_1 = { 0, 115, 24, 12, 13, false },
  car_left_1 = { 24, 115, 24, 12, 1, true },
  car_left_2 = { 48, 115, 24, 12, 1, true },
  road = { 0, 53, 16, 17, 0, false },
  logo = { 0, 64, 96, 32, 0 },
}

function add_cactus(x)
  add(cacti, {
    offset = { x, 0 },
    size = { 6, 16 },
    alive = true,
  })
end

function add_pole(x, h)
  add(poles, {
    offset = { x, -2 },
    size = { 1, h },
  })
end

function add_cable(x1, y1, x2, y2)
  add(cables, { x1, y1, x2, y2 })
end

function add_lava(x1, x2)
  add(lava, { x1, x2 })
end

-->8
--------------------------------
-- actions ---------------------

set_pieces = {
  'cactus_lava_gap',
  --'cactus_rail',
  --'quad_cactus',
  --'rail_gap',
}

actions = {
  cactus = function()
    if mode == 'play' and paused == false then
      nextx = trex.offset[1] + 120
      add_cactus(nextx)
      after(128, 'next')
    end
  end,

  cactus_lava_gap = function()
    x = trex.offset[1] + 120
    --add_cactus(x + 0)
    add_cactus(x + 32)
    add_lava(x + 40, x + 92)
    add_cactus(x + 96)
    --add_cactus(x + 128)

    after(200, 'next')
  end,

  cactus_rail = function()
    if mode != 'play' or paused then
      return
    end

    x = trex.offset[1] + 120

    add_cactus(x)
    add_pole(x + 40, 32)
    add_pole(x + 104, 32)
    add_cable(
      x + 40, -32,
      x + 104, -32
    )
    add_cactus(x + 224)

    after(256, 'next')
  end,

  charge = function()
    if trick == 'chrage' or can_charge == false then
      return
    end
    --clear('charge_limit')
    trick = 'charge'
    charge = 0
    trex.vector[2] = -0.5

    parallax(2)

    --sfx(3)
    --after(64, 'charge_limit')
    can_charge = false
  end,

  charge_limit = function()
    if trick == 'charge' then
      actions.grab()
    end
  end,

  destroy_cactus = function(cactus)
    sfx(0)
    shake_frames = 10
    trick = 'air'
    trex.offset[2] = (
      cacti[1].offset[2] -
      cacti[1].size[2] - 4
    )
    --parallax(1)
    cactus.alive = false
    cactus.died = frame
    trex.vector[2] = -4
  end,

  destroy_car = function()
    sfx(-2, 3)
    sfx(0)
    shake_frames = 10
    trick = 'air'
    trex.offset[2] = (
      cars[1].offset[2] -
      cars[1].size[2]
    )
    --parallax(1)
    trex.vector[2] = -4
  end,

  gc = function()
    for i,cactus in pairs(cacti) do
      if cactus.offset[1] < foreground.offset[1] then
        del(cacti, i)
      end
    end

    for i,car in pairs(cars) do
      d = foreground.offset[1] + 64 - car.offset[1]
      if d > 256 then
        del(cars, i)
      end
    end

    printh(stat(1))
    for i,l in pairs(lava) do
      if l[2] < foreground.offset[1] then
        printh('gc')
        printh(l[2])
        del(lava, l)
      end
    end

    for i,pole in pairs(poles) do
      if pole.offset[1] < foreground.offset[1] - 64 then
        poles[i] = nil
        del(poles, poles[i])
      end
    end
  end,

  gameover = function()
    if paused == false and trex.alive == true then
      paused = true
      sfx(2)
      trick = 'none'
      trex.alive = false
    end
  end,

  grab = function()
    sfx(8)
    trick = 'grab'
    trex.vector[2] = 7
  end,

  grind = function()
    parallax(2)
    trick = 'grind'
    trex.offset[1] = ceil(trex.offset[1])
    trex.offset[2] = groundlevel
    trex.vector[2] = 0
  end,

  land = function()
    if trex.alive then
      if trick == 'grab' then
        sfx(3)
        shake_frames = 20
      else
        sfx(1)
      end
      trick = 'roll'
      roll_count = 0
    end

    --parallax(1)
    trex.offset[2] = 0
    trex.vector[2] = 0
  end,

  lava_gap = function()
    if mode != 'play' or paused then
      return
    end

    x = trex.offset[1] + 120

    add_lava(x + 0, x + 32)

    after(120, 'next')
  end,

  next = function()
    if mode != 'play' or paused then
      return
    end

    action = script[1]
    del(script, action)
    add(eventloop, action)

    key = flr(rnd(#set_pieces)) + 1
    add(script, set_pieces[key])
  end,

  add_pole = function()
    if mode != 'play' or paused then
      return
    end

    if #poles > 0 then
      poles = nil
      poles = {}
      after(16, 'next')
      return
    end

    nextx = trex.offset[1] + 120

    for i = 0,2 do
      add(poles, {
        offset = { nextx + i * 64, -3 },
        size = { 8, 32 },
      })
    end
    after(16, 'next')
  end,

  pop = function()
    if can_pop == false then
      return
    end
    if trick == 'grind' then
      trex.vector[2] = -4
    else
      trex.vector[2] = -3.2
    end
    trick = 'pop'

    sfx(0)
    can_pop = false
  end,

  push = function()
    trick = 'push'
    roll_count = 0
    parallax(1)
  end,

  ollie = function()
    trick = 'ollie'
  end,

  quad_cactus = function()
    if mode != 'play' or paused then
      return
    end

    x = trex.offset[1] + 120
    add_cactus(x + 0)
    add_cactus(x + 32)
    add_cactus(x + 96)
    add_cactus(x + 128)

    after(200, 'next')
  end,

  rail_gap = function()
    if mode != 'play' or paused then
      return
    end

    x = trex.offset[1] + 120

    add_pole(x + 0, 32)
    add_pole(x + 64, 32)
    add_cable(
      x + 0, -32,
      x + 64, -32
    )
    add_cactus(x + 128)
    add_pole(x + 192, 32)
    add_pole(x + 256, 32)
    add_cable(
      x + 192, -32,
      x + 256, -32
    )

    after(200, 'next')
  end,

  start_overtake = function()
    if mode == 'play' and paused == false then
      overtaking = true
      x = trex.offset[1] - 64
      s = 2.0
      add(cars, {
        offset = { x, 6 },
        size = { 21, 8 },
        vector = { s, 0 },
      })
      after(16, 'next')
      --after(128 + 64, 'end_overtake')
      sfx(9, 2)
    end
  end,

  end_overtake = function()
    overtaking = false
    sfx(-2, 2)
  end,

  play = function()
    if mode == 'play' then
      return true
    end

    mode = 'play'
    trex.offset[1] = foreground.offset[1] + trex.size[1]

    --add(script, 'start_ram')
    add(script, 'cactus_lava_gap')
    --add(script, 'rail_gap')
    --add(script, 'cactus_rail')
    --add(script, 'add_pole')
    --add(script, 'start_overtake')
    --add(script, 'cactus')
    add(eventloop, 'next')
  end,

  start_ram = function()
    if mode == 'play' and paused == false then
      x = trex.offset[1] + 128
      s = -1
      sfx(11, 3)
      add(cars, {
        offset = { x, 0 },
        size = { 21, 8 },
        vector = { s, 0 },
      })
      after(64, 'end_ram')
    end
  end,

  end_ram = function()
    sfx(-2, 3)
    after(32, 'next')
  end,

  release = function()
    trick = 'air'
  end,

  reset = function()
    score = 0
    trick = 'push'
    mode = 'attract'
    paused = false
    roll_count = 0

    for k,v in pairs(timeouts) do
      del(timeouts, k)
    end
    for k,v in pairs(script) do
      del(script, k)
    end
    for k,v in pairs(lava) do
      del(lava, k)
    end
    for k,v in pairs(cacti) do
      del(cacti, k)
    end
    for k,v in pairs(cars) do
      del(cars, k)
    end
    for k,v in pairs(poles) do
      del(poles, k)
      del(poles, poles[k])
    end
    for k,v in pairs(cables) do
      del(cables, k)
      del(cables, poles[k])
    end


    timeouts = nil
    timeouts = {}

    intervals = nil
    intervals = {}

    cars = nil
    cars = {}

    cacti = nil
    cacti = {}

    poles = nil
    poles = {}

    script = nil
    script = {}

    cables = nil
    cables = {}

    lava = nil
    lava = {}

    groundlevel = 0
    trex.alive = true
    trex.trick = 'push'
    trex.offset = { 10, 0 }
    trex.vector = { push_speed, 0 }
    trex.size = { 16, 16 }
    foreground.offset = { -10, -96 }
    foreground.vector = { trex.vector[1], 0 }
    nearground.offset = { -10, -92 }
    nearground.vector = { 1, 0 }
    cityscape.offset = { -10, -82 }
    cityscape.vector = { 1, 0 }
    sky.offset = { -10, -96 }
    sky.vector = { 0.5, 0 }
    parallax(1)
    every(60, 'gc')
    cls()
  end,

}

-->8
--------------------------------
-- rendering -------------------

function parallax(speed)
  foreground.offset[1] = trex.offset[1] - 16
  if speed == 1 then
    trex.vector[1] = push_speed
    foreground.vector[1] = trex.vector[1]
    nearground.vector[1] = 0.5
    cityscape.vector[1] = 0.5
    sky.vector[1] = 0.25
  elseif speed == 2 then
    trex.vector[1] = 2
    foreground.vector[1] = trex.vector[1]
    nearground.vector[1] = 1.5
    cityscape.vector[1] = 1.5
    sky.vector[1] = 1
  end
end

function draw(id, pos)
  if sprites[id] == nil then
    printh('draw - no such '..id)
    return
  end
  b = sprites[id]
  sx = b[1]
  sy = b[2]
  sw = b[3]
  sh = b[4]
  alpha = b[5]
  flip_x = b[6]

  for i = 0,15 do
    transparent = i == alpha
    palt(i, transparent)
  end

  sspr(
    sx,
    sy,
    sw,
    sh,
    flr(pos[1]),
    flr(pos[2]) - sh,
    sw,
    sh,
    flip_x
  )
end

render = {
  ui = function()
    camera(0, 0)

    if mode == 'attract' then
      draw('logo', { 16, 64 })
    end

    if trick == 'charge' then
      --print(charge .. '', 3, 3, 7)
    end

    if groundlevel != 0 then
      print(groundlevel .. '', 3, 3, 7)
    end

    if paused == true then
      rectfill(
        54 - 10,
        54 - 10,
        54 + 33,
        54 + 5,
        0
      )

      print(
        "game over",
        54 - 5,
        54 - 5,
        7
      )
    end

    if paused == true then
      rectfill(
        54 - 10,
        64 - 10,
        54 + 33,
        64 + 5,
        0
      )
      print(
        ""..score,
        54 - 5,
        64 - 5,
        6
      )
    end
  end,

  foreground = function()
    x = flr(foreground.offset[1])
    y = flr(foreground.offset[2])

    if shake_frames > 0 then
      y = y + (rnd(2)-1)
    end

    camera(x, y)
    width = 16
    tiles = 128 / width

    rectfill(x, 0, x + 128, 64, 4)

    for i = (x - 15),(x + 128) do
      if i % 16 == 0 then
        draw('road', { i, 16 })
      end
    end

    draw_lava()

    draw_cables()
    for pole in all(poles) do
      --h = hitboxes.cactus(cactus)
      --rectfill(
        --h.offset[1],
        --h.offset[2],
        --h.offset[1] + h.size[1],
        --h.offset[2] + h.size[2],
        --14
      --)
      draw_pole(pole)
    end

    if mode == 'play' then
      --h = hitboxes.trex()
      --rectfill(
        --h.offset[1],
        --h.offset[2],
        --h.offset[1] + h.size[1],
        --h.offset[2] + h.size[2],
        --14
      --)
      draw_trex()
    end

    for cactus in all(cacti) do
      --h = hitboxes.cactus(cactus)
      --rectfill(
        --h.offset[1],
        --h.offset[2],
        --h.offset[1] + h.size[1],
        --h.offset[2] + h.size[2],
        --14
      --)
      draw_cactus(cactus)
    end

    for car in all(cars) do
      --h = hitboxes.car(car)
      --rectfill(
        --h.offset[1],
        --h.offset[2],
        --h.offset[1] + h.size[1],
        --h.offset[2] + h.size[2],
        --14
      --)
      draw_car(car)
    end
  end,

  nearground = function()
    x = ceil(nearground.offset[1])
    y = ceil(nearground.offset[2])
    camera(x, y)
    rectfill(x, 0, x + 128, 3, 4)
    for plant in all(plants(x)) do
      draw(plant[1], { plant[2], 3 })
    end
  end,

  cityscape = function()
    x = ceil(cityscape.offset[1])
    y = ceil(cityscape.offset[2])
    camera(x, y)
    rectfill(x, 9, x + 128, 9, 2)
    for building in all(buildings(x)) do
      draw(building[1], { building[2], 10 })
    end
  end,

  sky = function()
    x = ceil(sky.offset[1])
    y = ceil(sky.offset[2])
    camera(x, y)
    rectfill(x, y, x + 128, 0, 1)
    for star in all(stars(x)) do
      circfill(star[1], star[2], 0, 6)
    end
  end,
}

function plants(x)
  p = {}
  for i = (x - 15),(x + 128) do
    if i % 256 == 0 then
      add(p, { 'plant_4', i })
    elseif i % 128 == 0 then
      add(p, { 'plant_3', i })
    elseif i % 96 == 0 then
      add(p, { 'plant_2', i })
    elseif i % 64 == 0 then
      add(p, { 'plant_1', i })
    end
  end
  return p
end

function buildings(x)
  b = {}
  for i = (x - 15),(x + 128) do
    if i % 98 == 0 then
      add(b, { 'tower_1', i })
    elseif i % 128 == 0 then
      add(b, { 'tower_2', i })
    end
  end
  return b
end

function stars(x)
  s = {}
  for i = (x - 15),(x + 128)do
    if i % 4 < 1 then
      add(s, {
        i,
        -10 - (i % 30) * 10,
      })
    end
  end
  return s
end

function draw_cactus(cactus)
  if cactus.alive then
    draw('cactus_alive_1', cactus.offset)
  else
    fsd = frame - cactus.died
    sprite = 'cactus_dead_' .. min(flr(fsd / 4) + 1, 5)
    draw(sprite, cactus.offset)
  end
end

function draw_lava()
  for l in all(lava) do
    x1 = l[1]
    x2 = l[2]
    w = x2 - x1

    rectfill(
      x1,
      -2,
      x2,
      3,
      4
    )

    rectfill(
      x1,
      1,
      x2,
      9,
      9
    )

    cx = x1 - foreground.offset[1]
    cy = -8
    cw = x2 - x1
    ch = 16
    clip(cx, cy, w, 110)
    bn = 1
    for x = x1 - 10,x2 - 1 do
      if x % 8 < 1 then
        r = loop(60, 7) + 1
        x = x + r
        y = r
        circfill(x, y, r, 9)
      end
      bn = bn + 1
    end
    clip()

    --h = hitboxes.lava(l)
    --rectfill(
      --h.offset[1],
      --h.offset[2],
      --h.offset[1] + h.size[1],
      --h.offset[2] + h.size[2],
      --14
    --)

  end
end

function draw_pole(pole)
  draw('pole', {
    pole.offset[1] - 3,
    pole.offset[2] - pole.size[2] + 6
  })
  line(
    pole.offset[1],
    pole.offset[2],
    pole.offset[1],
    pole.offset[2] - pole.size[2] + 6,
    13
  )
end

function draw_cables()
  for c in all(cables) do
    tx = trex.offset[1]
    x1 = c[1]
    y1 = c[2]
    x2 = c[3]
    y2 = c[4]

    if tx > x1 and tx < x2 and trick == 'grind' then
      line(x1, y1, tx, groundlevel - 2, 5)
      line(tx, groundlevel - 2, x2, y2, 5)
    else
      line(x1, y1, x2, y2, 5)
    end
  end
end

function draw_car(car)
  if car.vector[1] > 0 then
    direction = 'right'
    sprite_n = 1
  else
    direction = 'left'
    sprite_n = loop(32, 2) + 1
  end
  sprite_id = 'car_' .. direction .. '_' .. sprite_n
  draw(sprite_id, car.offset)
end

function draw_trex()
  if trex.alive == false then
    sprite_name = 'dead_1'
  elseif trick == 'none' then
    sprite_name = 'roll_1'
  elseif trick == 'roll' then
    sprite_name = 'roll_1'
  elseif trick == 'push' then
    sprite_n = loop(32, 5) + 1
    sprite_name = 'push_'..sprite_n
  elseif trick == 'pop' then
    sprite_name = 'ollie_1'
  elseif trick == 'ollie' then
    sprite_name = 'ollie_2'
  elseif trick == 'air' then
    sprite_name = 'ollie_1'
  elseif trick == 'grab' then
    sprite_name = 'grab_1'
  elseif trick == 'charge' then
    sprite_name = 'grab_1'
  elseif trick == 'grind' then
    sprite_name = 'roll_1'
  end

  if trick == 'charge' then
    --print(charge .. '', 3, 3, 7)
    circ(
      ceil(trex.offset[1]) + 8,
      trex.offset[2] - 8,
      charge / 3,
      10
    )
  end

  if trick == 'grind' then
    spark = 'sparks_' .. loop(32, 7) + 1
    draw(spark, {
      ceil(trex.offset[1]) - 2,
      trex.offset[2],
    })
    draw(spark, {
      ceil(trex.offset[1]) + 6,
      trex.offset[2],
    })
  end

  draw(sprite_name, {
    ceil(trex.offset[1]),
    trex.offset[2],
  })
end



-->8
--------------------------------
-- math -----------------------

function intersect(a, b)

  ax1 = a.offset[1]
  ax2 = a.offset[1] + a.size[1]
  ay1 = a.offset[2]
  ay2 = a.offset[2] + a.size[2]

  bx1 = b.offset[1]
  bx2 = b.offset[1] + b.size[1]
  by1 = b.offset[2]
  by2 = b.offset[2] + b.size[2]

  --left
  if ax2 < bx1 then
    return false
  end

  --right
  if ax1 > bx2 then
    return false
  end

  --above
  if ay2 < by1 then
    return false
  end

  --below
  if ay1 > by2 then
    return false
  end

  return true
end

function angle(a, b)
  return atan2(
    b[2] - a[2],
    b[1] - a[1]
  )
end

function distance(a, b)
  distance_x = abs(a[1] - b[1])
  distance_y = abs(a[2] - b[2])
  distance_2 = abs(
    (distance_x * distance_x)
    + (distance_y * distance_y)
  )
  return sqrt(distance_2)
end

function tan(a) return sin(a)/cos(a) end

function cable_buckle(p1, p2)
  tx = trex.offset[1]
  x1 = p1.offset[1]
  a = tx - x1
  if trick != 'grind' then
    b = 0
  elseif a > 24 and a < 40 then
    b = 6
  elseif a > 16 and a < 38 then
    b = 5
  elseif a > 8 and a < 56 then
    b = 4
  elseif a > 4 or a < 60 then
    b = 3
  else
    b = 2
  end

  return b
end


-->8
--------------------------------
-- physics ---------------------

function physics()
  gravity()

  sky.offset[1] = (
      sky.offset[1]
    + sky.vector[1]
  )
  cityscape.offset[1] = (
      cityscape.offset[1]
    + cityscape.vector[1]
  )
  nearground.offset[1] = (
      nearground.offset[1]
    + nearground.vector[1]
  )
  foreground.offset[1] = ceil(
      foreground.offset[1]
    + foreground.vector[1]
  )

  if mode == 'play' and paused == false then
    t = hitboxes.trex()
    for cactus in all(cacti) do
      c = hitboxes.cactus(cactus)
      if intersect(t, c) then
        if is_attack[trick] then
          actions.destroy_cactus(cactus)
        else
          add(eventloop, 'gameover')
        end
      end
    end

    for l in all(lava) do
      lh = hitboxes.lava(l)
      if intersect(t, lh) then
        add(eventloop, 'gameover')
      end
    end

    for car in all(cars) do
      car.offset[1] = ceil(car.offset[1] + car.vector[1])
      car.offset[2] = car.offset[2] + car.vector[2]

      c = hitboxes.car(car)
      if intersect(t, c) then
        if is_attack[trick] then
          actions.destroy_car()
        else
          add(eventloop, 'gameover')
        end
      end

      if trex.offset[1] == car.offset[1] then
        score = score + 10
      end
    end
  end
end



function gravity()
  if trex.offset[2] >= groundlevel then
    return
  end

  air = abs(trex.offset[2]) / 128

  if trick == 'charge' then
    --nothing lol
  elseif trick == 'grind' and groundlevel != 0 then
    trex.offset[2] = groundlevel
  elseif trex.vector[2] < 0 then
    if trick == 'ollie' then
      mul = 0.6
    else
      mul = 1
    end
    --pop
    trex.vector[2] = trex.vector[2] + (0.25 * mul)
  elseif trex.vector[2] < 0.5 and trick == 'ollie' then
    --hang
    trex.vector[2] = trex.vector[2] + 0.25 * 0.1
  else
    --drop
    trex.vector[2] = min(
      trex.vector[2] + 0.95 * air,
      5
    )
  end
end

function update_groundlevel()
  tx = trex.offset[1]
  tx1 = trex.offset[1]
  tx2 = trex.offset[1] + trex.size[1]
  ty = trex.offset[2] -- trex.size[2]

  for l in all(lava) do
    x1 = l[1]
    x2 = l[2]

    if tx1 >= x1 and tx2 <= x2 then
      above_lava = true
      groundlevel = 3
      return
    end
  end
  above_lava = false

  for c in all(cables) do
    x1 = c[1]
    y1 = c[2]
    x2 = c[3]
    y2 = c[4]

    if tx >= x1 and tx <= x2 then
      p1 = { offset = {x1, y1} }
      p2 = { offset = {x2, y2} }
      buckle = cable_buckle(p1, p2)
      if trick == 'grind' or ty <= y1 + buckle + 1 then
        above_cable = true
        groundlevel = y1 + buckle
        return
      end
    end
  end
  above_cable = false
  groundlevel = 0
end

hitboxes = {
  cactus = function(c)
    return {
      offset = {
        c.offset[1] + 2,
        c.offset[2] - c.size[2],
      },
      size = {
        c.size[1] - 4,
        c.size[2],
      }
    }
  end,

  car = function(c)
    return {
      offset = {
        c.offset[1] + 1,
        c.offset[2] - c.size[2] + 2,
      },
      size = {
        c.size[1],
        c.size[2] - 3,
      },
    }
  end,

  lava = function (l)
    x1 = l[1]
    x2 = l[2]
    return {
      offset = { x1, 1 },
      size = { x2 - x1, 8 }
    }
  end,

  trex = function()
    if trick == 'grab' then
      return {
        offset = {
          trex.offset[1] + 2,
          trex.offset[2] - trex.size[2],
        },
        size = {
          12,
          trex.size[2] * 1
        }
      }
    end

    return {
      offset = {
        trex.offset[1] + 2,
        trex.offset[2] - trex.size[2] + 8,
      },
      size = { 8, 6 }
    }

  end,
}

function trex:move()
  if self.alive == false then
    decel = 0.1
    if self.vector[1] - decel < 0 then
      self.vector[1] = 0
    else
      self.vector[1] = self.vector[1] - decel
    end
  end
  self.offset[1] = ceil(self.offset[1] + self.vector[1])
  if (trick == 'roll' or trick == 'push') and groundlevel > 0 then
    trex.offset[2] = trex.offset[2] + 3
    actions.gameover()
  elseif trick == 'grind' and groundlevel == 0 then
    actions.release()
    self.offset[2] = self.offset[2]
  elseif trick == 'grind' then
    self.offset[2] = groundlevel - 2
  else
    self.offset[2] = self.offset[2] + self.vector[2]
  end
  if self.alive and self.offset[2] > groundlevel then
    if groundlevel == 0 then
      add(eventloop, 'land')
    else
      actions.grind()
    end
  end
end



-->8
--------------------------------
-- timekeeping -----------------

function dispatch(action)
  if actions[action] ~= nil then
    --printh(action)
    actions[action]()
  end
end

function next(queue)
  local v = queue[1]
  del(queue, v)
  return v
end

function tick()
  frame = frame + 1
  for timeout in all(timeouts) do
    if frame == timeout[1] then
      add(eventloop, timeout[2])
      del(timeouts, timeout)
    end
  end
  for interval in all(intervals) do
    if frame % interval[1] == 0 then
      if interval[2] ~= nil then
        add(eventloop, interval[2])
      end
    end
  end
end

function cron(interval)
  remainder = frame % interval
  return remainder == 0
end

function loop(interval, limit)
  remainder = frame % interval
  chunk_size = flr(interval / limit)
  n = flr(remainder / chunk_size)
  return n
end

function clear(action)
  for i,timeout in pairs(timeouts) do
    if timeout[2] == action then
      del(timeouts, i)
    end
  end
end

function after(frames, action)
  add(timeouts, { frame + frames, action })
end

function every(interval, action)
  add(intervals, { interval, action })
end


-->8
--------------------------------
-- anything --------------------


kb_chars=" !\"#$%&'()*+,-./0123456789:;<=>?@abcdefghijklmnopqrstuvwxyz[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
function getchar()
  local n=0
  local i=0
  for i=0,5 do
    if btn(i,7) then
      n+=2^i
    end
  end
  if(btn(0,6)) then
    n+=63
  end
  if (n==0) then
    return nil
  end
  return sub(kb_chars,n,n)
end

__gfx__
00000000888800000000000088880000000000008888000000000000000000000000000000000000000000000000000000000000888800000000000000000000
00000008877880000000000887788000000000088778800000000000888800000000000088880000000000008888000000000008877880000000000000000000
0000000887c888800000000887c888800000000887c888800000000887788000000000088778800000000008877880000000000887c888800000000000000000
0000000887788880000000088778888000000008877888800000000887c888800000000887c888800000000887c8888000000008877888800000000000000000
00000008888888800000000888888880000000088888888000000008877888800000000887788880000000088778888000000008888888800000000000000000
00000008888000000000000888800000000000088880000000000008888888800000000888888880080000088888888008000008888000000000000000000000
08000088888880000800008888888000000000888888800000000008888000000800000888800000080000088880000008000088888880000000000000000000
08800888880000000880088888000000800008888800000080000088888880000880008888888000088000888888800008800888880000000000000000000000
08888888888800000888888888880000888888888888000088888888880000000888888888000000088888888800000008888888888800000000000000000000
08888888880800000888888888080000088888888808000008888888888800000888888888880000088888888888000008888888880800000000000000000000
00888888880000000088888888000000008888888800000000888888880800000088888888080000008888888808000000888888880000000000000000000000
00088888800000000008888880000000000888888000000000088888800000000008888880000000000888888000000000088888800000000000000000000000
00000800800000000000088080000000000008808000000000000880800000000000888080000000000008808000000000000880800000000000000000000000
0cc0088088cc00000cc0088088cc00000cc0080088cc00000cc0080088cc00000c88800088cc00000cc0080088cc00000cc0008088cc00000000000000000000
000cccccccc00000000ccc8cccc00000000cc8ccccc00000000c88ccccc00000008cccccccc00000000cc8ccccc00000000ccc88ccc000000000000000000000
00070000070000000007008807000000000708800700000000078000070000000007000007000000000700000700000000070000070000000000000000000000
00000000888800000000000085880000000000008588000000000000000000000000000088880000000000000000000000000000000000000000000000000000
00000008877880000000000887588000000000088758800000000000000000000000000887788000000000000000000000000000000000000000000000000000
00000008877888800000000887758880000000088775888000000000000000000000000887788880000000000000000000000000000000000000000000000000
0000000887c888800000000887c888800000000887c8888000000000000000000000000887c88880000000000000000000000000000000000000000000000000
00000008888888800000000888888880000000088888888000000000000000000000000888888880000000000000000000000000000000000000000000000000
08000008888770000800000888877000000000088887700000000000000000000800000888877000000000000000000000000000000000000000000000000000
08000088888880000800008888888000000000888888800000000000000000000800008888888000000000000000000000000000000000000000000000000000
08800888880000000880088888000000800008888800000000008888888888800880088888000000000000000000000000000000000000000000000000000000
0888888888880000088888888888c000888888888888c00000888888888888880888888888880000000000000000000000000000000000000000000000000000
0888888888080000088888888808c000088888888808c00008888888888875880888888888080000000000000000000000000000000000000000000000000000
008888888800000000888888880c000000888888880c0000088888888888c58800888888880c000000000000000000000000000000000000000000000000000a
00088888800000000008888800c070000008888800c0700088888800808888880008888880cc0000000000000000000000000000000000000000000000090a0a
0000080080000000000008088c000000000008088c0000008888088080888880000008008cc000000000000000000000000000000000000000000000000aa0a0
0cc0088088cc000000000880c000000000000880c00000000880008000888800000cc80cc070000000000000000000000000000000000000000000000a000000
000cccccccc00000000000cc07000000000000cc0700000008880000008888000000ccc000000000000000000000000000000000000000000000000000000009
000700000700000000000000000000000000000000000000008888000000000000000070000000000000000000000000000000000000000000000000aa090a00
111111111111111111111111111111110000b0000000900000000009000a0000d00000d000000007c000000000000007c000000000000007c000000000000000
11111111111111111111111111111111000bbb0b0000000ba0000000000000000d666d0000000007c000000000000007c000000000000007c000000000000000
222221111111111111111111111111110b0bbb0b000090bbb0b0000900ba000000d0d00000000007c000000000000007c000000000000007c000000000000000
2e2e21122222222222111111122222110b0bbb0b0000b0bbb0b000090bbbab00000d0000aaaaaaaaaaaaaaaa9999999999999999888888888888888800000000
22222112e2ee22222211111112e2e2110b0bbb0b0000b0bbb0b0000b0bbb0b0000000000aaaaaaaaa99aaaaa99999aa999999889888889988888888800000000
2e2e21222222222222221112222222210b0bbb0b0000b0bbb0b000ab0bbb0b0000000000aaaaaaaaa99a99aa9aa99aa999999889889989988888888800000000
2222212ee2ee222222e21122e22222220b0bbbbb000ab0bbb0b0000b0bbb0b0000000000aaaaaaaaaaaa99aa9aaa999998899999889988888888888800000000
222221222222222222221122222222220b0bbbb00000b0bbbbb900ab0bbb0b0000000000aaaaaaaaaaaaaaaa99aa999998899999888888888888888800000000
111111111111111111111111111111110b0bbb00000ab0bbbb0000ab0bbbbb900000d000aaaaaaaaaa99aaaa9999aa9999999999888899888888888800000000
111111111111111111111111113311330bbbbb00000ab0bbb00900ab0bbbb0000000d000aaaaaaaaaa99a99a9aa9aa9999999889899899888888888800000000
11111111111111111111131131131331000bbb00000abbbbb00000ab0bbb0a900000d000aaaaaaaaaaaaa99a9aa9999999999889899888888888888800000000
11111111133111111331331133131311000bbb00000000bbba0000abbbbb00000000d000aaaaaaaaaaaaaaaa9999999999999999888888888888888800000000
11111111111311111133311113333311000bbb00000000bbb90000000bbb90000000d00000000007c000000000000007c000000000000007c000000000000000
11131111111311111113111111333111000bbb00000000bbb00000000bbb90000000d00000000007c000000000000007c000000000000007c000000000000000
11131111111311111113111111131111000bbb00000000bbb00000000bbb00000000d00000000007c000000000000007c000000000000007c000000000000000
11131111111311111113111111131111000bbb00000000bbb00000000bbb00000000d00000000007c000000000000007c000000000000007c000000000000000
44444444444444444444444444444444000900000000009000000000000000000000d00000000000000000000000000000000000000000004444444444444444
44444444444444444444444444444444000000000000000000000000000000000000d00000000000000000000000000000000000000000004444444444444444
44444444444444444444444444444444000900000000009000a00000000000000000d00000000000000000000000000000000000000000004444444444444444
4444444444444444444444444444444409093a00000000900000000000000a000000d00000000000000000000000000000000000000000004444444444444444
44444444444444444444444444444444099333a30000909390a0000000a000000000d00000000000000000000000000000000000000000004444444444444444
55555555555555555555555555555555a303330300a099933aa0000000000a000000d00000000000000000000000000000000000000000005555444444445555
5555555555555555555555555555555503033303000039333a3000000000a0000000d000000000000000000000000000000000000000000055d5444444445555
dddddddddddddddddddddddddddddddda393330300a039333a309000a000a0000000d00000000000000000000000000000000000000000008d8d99999999d8d8
dddddddddddddddddddddddddddddddda303330300aa39333a30000000aaa0000000d0000000000000000000000000000000000000000000dddd99999999dddd
dddd66666666dddddddd66666666dddda3933333000a39333039000aa0aaa0000000d0000000000000000000000000000000000000000000dddd99999999dddd
dddddddddddddddddddddddddddddddda3933330a00a39333339000a9999a0a00000d0000000000000000000000000000000000000000000dddd99999999dddd
dddddddddddddddddddddddddddddddda393330a000a39333399000a933900000000d0000000000000000000000000000000000000000000dddd99999999dddd
dddddddddddddddddddddddddddddddda3333309000a39333990000a933390a00000d0000000000000000000000000000000000000000000dddd99999999dddd
5555555555555555555555555555555500033390000a33333900000a93339aa00000d00000000000000000000000000000000000000000005555999999995555
5555555555555555555555555555555500033390000000333900000093339a000000d00000000000000000000000000000000000000000005555999999995555
5555555555555555555555555555555500033390000000333000000093339a000000d00000000000000000000000000000000000000000005555999999995555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777777777777777770000000000000000000000077777777777777777777770000000000000000000000000000000000000000000000000000000
00000000777777777777777777777700000000000000077777777777777777777777777777777000000000000000000000000000000000000000000000000000
00007777777777777777777777777777777777777777777777777777777777777777777777777777700000000000000000000000000000000000000000000000
00007777777771111111111777777777777777777777777777711111117711117771111777777777777000000000000000000000000000000000000000000000
00007711111111888888881111117777777777771111111117718888811118811771888111111177777000000000000000000000000000000000000000000000
00007718888888888888881888817111111111171888888811188888881188811711888188888111777000000000000000000000000000000000000000000000
00007718888888888888888888817188811888171888888881188888888188881118888188888881777700000000000000000000000000000000000000000000
00007718888888888111888888811188811888171888888881188811888188881118881188888881777700000000000000000000000000000000000000000000
00007711111111888171888888881188811888171888188881188811888188888118881188888881777700000000000000000000000000000000000000000000
00007777777771888171888888881188811888171888188881188811888188888118881888111111777700000000000000000000000000000000000000000000
00007777777771888171888118881188811888171888888811188811888188888818881888111117777000000000000000000000000000000000000000000000
00007777777771888171888118881188811888171888888881188811888188888818881888888817777000000000000000000000000000000000000000000000
00000000077771888171888888881188811888171888888881188811888188888888881888888817777000000000000000000000000000000000000000000000
00000000007771888171888888881188811888171888118881188811888188881888881888888817777000000000000000000000000000000000000000000000
00000000007771888171888888881188811888171888118881188811888188881888881888111117777000000000000000000000000000000000000000000000
00000000007771888171888118881188811888111888888881188888888188881888881888111117777000000000000000000000000000000000000000000000
00000000007771888171888118881111111888888888888881188888888188881188881888888811777700000000000000000000000000000000000000000000
00000000007771888171888111111777771888888888888881118888881188881188881888888881777700000000000000000000000000000000000000000000
00000000007771111171111177777777771888888888111111111111111111111111111888888881777700000000000000000000000000000000000000000000
00000000007777777777777777777777771111111111177777777777777777777777771888888811777700000000000000000000000000000000000000000000
00000000000777777777777770000000777777777777777777777777777777777777771111111117777700000000000000000000000000000000000000000000
00000000000000000000000000000000077777777777777000000000000000007777777777777777777000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000777777777777770000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d00000d00000000000000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00d666d6666666666666666666d666d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000d0d000000000000000000000d0d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000d00000000000000000000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000d00000000000000000000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000d00000000000000000000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000d00000000000000000000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000d00000000000000000000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000d00000000000000000000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000d00000000000000000000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000d00000000000000000000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000d00000000000000000000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000d00000000000000000000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000d00000000000000000000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000d00000000000000000000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000d00000000000000000000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddd11111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddd11111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000
ddddddddd1212ddddddddddd111111111c8c8111111111111111111118c8c1111111111100000000000000000000000000000000000000000000000000000000
dddddddd666666dddddddddd11111111666666111111111111111111666666111111111100000000000000000000000000000000000000000000000000000000
ddddd6667655556ddddddddd11111666765555611111111111111666765555611111111100000000000000000000000000000000000000000000000000000000
dddd677776555556dddddddd11116777765555561111111111116777765555561111111100000000000000000000000000000000000000000000000000000000
ddd6600666666666666666dd11166006666666666666661111166006666666666666661100000000000000000000000000000000000000000000000000000000
d66600006677a7766000066d166600006677a77660000661166600006677a7766000066100000000000000000000000000000000000000000000000000000000
d6600770067a9a760077006d16600770067a9a760077006116600770067a9a760077006100000000000000000000000000000000000000000000000000000000
d6600770067a9a760077006d16600770067a9a760077006116600770067a9a760077006100000000000000000000000000000000000000000000000000000000
d66000000677a7760000006d166000000677a77600000061166000000677a7760000006100000000000000000000000000000000000000000000000000000000
dddd0000ddddddddd0000ddd11110000111111111000011111110000111111111000011100000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddd11111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000
__sfx__
000000000151001510015200152001530015300254003540035400454004540055500555006530095200a52007200062000020000200002000020000200002000020000200002000020000200002000020000200
0102000009010090100901009010026000260002600016000160005600016000b6000e600086010460104605026000060009600046000260009600036000a6000860004600006000860006600066000560000000
0000000001200062000e5200e5300f5400f5400f5400f540095500955009540095400954005540055400554005530055200552001520015200152001520015200151001510042000220001200012001020000000
01040000015100151001510005100051000510015000150001500015000150001500015001b000100001300016000190001c00021000260002b0002d0001b00020000260002c00034000380003d0003f0003f400
01100000037500375500700007000f7500f75500700007000a7500a75516700007000b7500b7550070000700087500875500700007000b7500b75500700007000675006755007000070005750057550030000300
01100000176151760517615000002b615376030000000000176150000500005000052b6152b6050000500005176150000517615000052b615376050000500005176150000500005000052b6152b6052b6152b615
00100000037540375203752037550f7540f7520f7520f7550a7540a7520a7520a7550b7540b7520b7520b755087540875208752087550b7540b7520b7520b7550675406752067520675505754057520575205755
01100000017140b7120b712067130b003020000200001000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000d01101011000151000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000019000000000000000000000000000000000
010201200101203012010120301201012030120101203012010120301201012030120101203012010120301201012030120101203012010120301201012030120101203012010120301201012030120101203012
010200000101001011010110101101021010210102101021030210302103021030210303103031030310303106031060310603106031060410604106041060410804108041080410804108051080510805108051
014001031a731157311a7211940000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
02 04054040
02 06054040
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000

