pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--------------------------------
-- gameloop --------------------

function _init()
  poke(0x5f2d, 1)
  actions.reset()
end

function _update60()

  frame = frame + 1

  for i,action in pairs(coroutines) do
    if frame % action[2] == action[3] then
      status = costatus(action[1])
      if status == "suspended" then
        coresume(action[1])
      else
        del(coroutines, action)
      end
    end
  end

  for i,action in pairs(queue) do
    status = costatus(action)
    if status == "suspended" then
      coresume(action)
    else
      actions[i] = nil
    end
  end

  for timeout in all(timeouts) do
    if frame == timeout[1] then
      add(eventloop, timeout[2])
      del(timeouts, timeout)
    end
  end

  for interval in all(intervals) do
    if frame % interval[1] == interval[3] then
      if interval[2] ~= nil then
        add(eventloop, interval[2])
      end
    end
  end

  jump = btn(5)
  if stat(34) == 1 then
    --jump = true
  end
  if getchar() == ' ' then
    jump = true
  end

  if mode == 'attract' then

    if jump then
      after(16, 'play')
    end

  elseif mode == 'play' then

    if altitude > 0 then
      --return true
    end

    if jump then
      if alive == false and (frame-died)>60 then
        after(16, 'reset')
      elseif trick == 'push' then
        actions.pop()
      elseif trick == 'roll' then
        actions.pop()
      elseif trick == 'pop' then
        actions.ollie()
      elseif trick == 'air' then
        actions.charge()
      elseif trick == 'charge' and charge > max_charge then
        --actions.pop()
        can_pop = false
        actions.slam()
      elseif trick == 'grind' then
        actions.pop()
      elseif trick == 'slam' then
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
        actions.slam()
      elseif trick == 'slam' then
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

  update_groundlevel()

  -- gravity

  -- add(fireworks, {
  -- 1  cityscape.offset[1], -- x offset
  -- 2  0, -- y offset
  -- 3  0, -- angular speed
  -- 4  3, -- lift
  -- 5  2, -- fuel
  -- 6  20, -- fuse
  -- 7  4, -- gunpowder
  -- 8  12, -- color
  --  })

  for f in all(fireworks) do
    if f[6] > 0 then
      if f[5] > 0 then
        f[5] = f[5] - 1 -- burn fuel
        f[4] = f[4] + 1 -- accelerate
      end
      f[2] = f[2] - f[4] -- fly
      f[4] = max(f[4] - 1, -2) -- fall
      f[6] = f[6] - 1 -- burn fuse
    else
      if f[9] == nil then
        f[10] = frame
        f[9] = {}
        for i = 1,16 do
          add(f[9], {
            f[1],
            f[2],
            f[3] + (1-rnd(2))/2,
            f[4] + (1-rnd(2))/2,
          })
        end
      end
      for p in all(f[9]) do
        p[1] = p[1] - p[3] -- fly
        p[2] = p[2] - p[4] -- fly
        p[4] = max(p[4] - 0.1, -2) -- fall
      end
    end
  end

  if alive == false then
    if skull.offset[2] < groundlevel then
      skull.vector[2] = skull.vector[2] + 0.25
    end
    if board.offset[2] < groundlevel then
      board.vector[2] = board.vector[2] + 0.25
    end
  end

  if altitude < groundlevel then
    air = abs(altitude) / 128

    if trick == 'charge' then
      ru1 = 3.14159 / 32
      run = ru1 * (charge+8) / 1
      vec = sin(run) * 0.6
      --lift = vec
      lift = min(lift + vec / 50, 0.1)
      mul = 0.1
      if charge > 30 then
        mul = 0.5
      elseif charge > 20 then
        mul = 0.3
      end
      --lift = lift + vec * 0.1

      if altitude < -63 then
        lift = lift + 0.1
      end
      if altitude > -8 and lift > 1 then
        lift = lift - 1
        lift = 0
      end
      --nothing lol
    elseif trick == 'grind' and groundlevel != 0 then
      altitude = groundlevel
    elseif lift < 0 then
      if trick == 'ollie' then
        mul = 0.6
      else
        mul = 1
      end
      --pop
      lift = lift + (0.25 * mul)
    elseif lift < 0.5 and trick == 'ollie' then
      --hang
      lift = lift + 0.25 * 0.1
    elseif trick == 'slam' then
      nearest = true
      height = 0-altitude
      lift = 3
      for c in all(cacti) do
        ahead = c.offset[1] > distance
        if ahead == true then
          gap = c.offset[1] - distance
          if nearest == true then
            if gap < 32 and height > 32 then
              lift = 8
            elseif gap < 8 and height > 64 then
              lift = 9
            elseif gap < 8 and height > 20 then
              lift = 4
            elseif gap < 4 and height > 10 then
              lift = 5
            end
            nearest = false
          end
        end
      end
    else
      --drop
      lift = min(
        lift + 0.95 * air,
        2.5
      )
    end
  end


  -- movement

  sky_offset = (
      sky_offset
    + sky_speed
  )
  cityscape_offset = (
      cityscape_offset
    + cityscape_speed
  )
  nearground_offset = (
      nearground_offset
    + nearground_speed
  )
  foreground_offset = ceil(
      foreground_offset
    + foreground_speed
  )

  if mode == 'play' then
    for m in all(meteors) do
      mh = hitboxes.meteor(m)
      if intersect(t, mh) then
        destroying = m
        if jump or trick == 'charge' or trick == 'slam' then
          m[7] = false
          m[8] = frame
          add(eventloop, 'destroy_meteor')
        elseif m[7] and alive == true then
          add(queue, cocreate(gameover))
        end
      end
    end

    for m in all(meteors) do
      if m[2] > 0 then
        crashing = m

        shake_frames = 20
        del(meteors, m)

        lx1 = m[1] - m[5] - 3
        lx2 = m[1] + m[5] + 3
        add(lava, { lx1, lx2 })

        for c in all(cacti) do
          if c.offset[1] > lx1 and c.offset[1] < lx2 then
            del(cacti, c)
          end
        end
      end
    end

    for m in all(meteors) do
      if m[8] <= frame then
        add(m[6], {m[1], m[2], frame})
        m[1] = m[1] + m[3]
        m[2] = m[2] + m[4]
      end
    end
  end

  if mode == 'play' and paused == false then
    t = hitboxes.trex()
    for cactus in all(cacti) do
      c = hitboxes.cactus(cactus)
      if intersect(t, c) then
        if frame-last_attack<2 then
          --nothing lol
        elseif jump or trick == 'charge' or trick == 'slam' or frame-last_attack<2 then
          if jump then
            can_charge = false
          end
          actions.destroy_cactus(cactus)
        elseif cactus.alive == true then
          --add(queue, cocreate(gameover))
          next(gameover)
        end
      end
    end

    for l in all(lava) do
      lh = hitboxes.lava(l)
      if intersect(t, lh) then
        next(gameover)
      end
    end

  end

  local action = eventloop[1]
  del(eventloop, action)
  if actions[action] ~= nil then
    actions[action]()
  end

  if shake_frames > 0 then
    shake_frames = shake_frames - 1
  end

  if new_combo_score > combo_score and alive == true then
    --combo_score = ceil(tween(10, 1, tricked, tricked+20))
    combo_score = ceil(tween(
      old_combo_score, new_combo_score,
      tricked, tricked + 20
    ))
  else
    old_combo_score = combo_score
  end

  if alive == false then
    board_decel = 0.01
    skull_decel = 0.04

    if board.vector[1] - board_decel < 0 then
      board.vector[1] = 0
    else
      board.vector[1] = board.vector[1] - board_decel
    end
    if board.offset[2] > groundlevel then
      board.offset[2] = groundlevel
    end

    if skull.vector[1] - skull_decel < 0 then
      skull.vector[1] = 0
    else
      skull.vector[1] = skull.vector[1] - skull_decel
    end
    if skull.offset[2] > groundlevel then
      skull.offset[2] = groundlevel
    end

    board.offset[1] = ceil(board.offset[1] + board.vector[1])
    board.offset[2] = board.offset[2] + board.vector[2]
    skull.offset[1] = ceil(skull.offset[1] + skull.vector[1])
    skull.offset[2] = skull.offset[2] + skull.vector[2]
  else

    distance = ceil(distance + speed)
    if trick == 'push' and groundlevel > 0 then
      altitude = altitude + 3
      next(gameover)
    elseif trick == 'grind' and groundlevel == 0 then
      actions.release()
      altitude = altitude
    elseif trick == 'grind' then
      altitude = groundlevel - 2
    else
      altitude = altitude + lift
    end
    if alive and altitude > groundlevel then
      if groundlevel == 0 then
        add(eventloop, 'land')
      else
        actions.grind()
      end
    end

    if trick == 'charge' then

      ru1 = 3.14159 / 32
      run = ru1 * (charge+8) / 1
      vec = sin(run) * 0.6
      mul = 0.1
      if charge > 30 then
        mul = 2
      elseif charge > 20 then
        mul = 0.3
      end
      y = altitude - 1 + vec * mul

      add(charge_trail, {
        distance + 6,
        y,
        frame,
      })
    end

    if trick == 'slam' and flr(distance) % 2 == 0 and altitude < -8 then
      add(slam_trail, {
        distance,
        altitude,
        frame,
      })
    end

  end

  if trick == 'charge' then
    if charge == 0 then
      sfx(7)
    elseif charge == 16 then
      sfx(7)
    end
    charge = charge + 1
  elseif trick == 'grind' and frame % 4 == 0 then
    combo_score = combo_score + 8
    if frame % 16 == 0 then
      increase_special(8)
    end
  end
end

function _draw()
  -- sky
  x = ceil(sky_offset)
  y = -108
  camera(x, y)
  rectfill(x, y, x + 128, 0, 1)

  for star in all(stars(x)) do
    circfill(star[1], star[2], 0, 6)
  end

  -- cityscape
  x = ceil(cityscape_offset)
  camera(x, -94)
  rectfill(x, 9, x + 128, 9, 2)
  for i = (x - 15),(x + 128) do
    if i % 98 == 0 then
      sspr(96, 0, 5, 8, i, 1)
    elseif i % 128 == 0 then
      sspr(102, 0, 14, 8, i, 1)
    elseif i % 256 == 0 then
      sspr(118, 0, 10, 8, i, 1)
    end
  end

  -- add(fireworks, {
  --    cityscape.offset[1], -- x offset
  --    0, -- y offset
  --    0, -- angular speed
  --    3, -- lift
  --    20, -- fuse
  --    4, -- gunpowder
  --    12, -- color
  --  })
  for f in all(fireworks) do
    if f[6] > 0 then
      circfill(f[1], f[2], 0, 10)
    else
      for p in all(f[9]) do
        --circfill(p[1], p[2], 0, f[8])
        circfill(p[1], p[2], 0,
          ({11,12,8,14})[flrrnd(4)+1]
        )
      end
    end
  end

  -- nearground
  x = ceil(nearground_offset)
  camera(x, -104)
  rectfill(x, 0, x + 128, 3, 4)

  -- plants
  for i = (x - 15),(x + 128) do
    if i % 256 == 0 then
      spr(28, i, -7)
    elseif i % 128 == 0 then
      spr(29, i, -7)
    elseif i % 96 == 0 then
      spr(30, i, -7)
    elseif i % 64 == 0 then
      spr(31, i, -7)
    end
  end

  -- foreground
  x = flr(foreground_offset)
  y = -108

  if shake_frames > 0 then
    y = y + (rnd(2)-1)
  end

  camera(x, y)
  width = 16
  tiles = 128 / width

  rectfill(x, 0, x + 128, 64, 4)

  for i = (x - 15),(x + 128) do
    if i % 16 == 0 then
      sspr(96, 21, 16, 17, i, -1);
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

  if mode == 'play' and alive then
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

  for meteor in all(meteors) do
    if meteor[8] <= frame then
      draw_meteor(meteor)
    end
  end

  if mode == 'play' and alive == false then
    draw_board()
    draw_skull()
  end

  -- ui
  camera(0, 0)

  --printr(''..bar, 4, 120, {0,7})
  --printr(''..beat, 12, 120, {0,7})
  --printr(''..#coroutines, 120, 120, {0,7})

  if mode == 'attract' then
    spr(64, 16, 32, 12, 4)
  end

  if trick == 'charge' then
    --print(charge .. '', 3, 3, 7)
  end

  n = combo_score
  if alive == false then
    n = max(0, n - flr(((frame-died) / 50) * n))
    if n == 0 then
      combo = {}
    end
  end

  if show_bonus == true then
    string = '+1000'
    per_n = 8
    x = 60 - (((#string+1)/2)*per_n)
    ccolors = {7,1,8}
    for i=1,#string do
      ccolors = {loop(32,5),7,1,8}
      asasas = 0 - loop(16, 2)
      printr(sub(string, i, i), x+i*per_n, 32+asasas, ccolors)
    end
  end

  score_x = 120 - (#(''..n)) * 4

  score_colors = {0,7}

  start_y = 8

  for i,t in pairs(combo) do
    --x = #(''..combo_length) * 4
    --y = start_y + ((i-1) * 10)

    if t.bailed then
      text_colors = {0,8}
    elseif t.landed then
      age = frame - t.landed
      text_colors = {0,11}
      score_colors = {0,11}
      time_colors = {0,11,0}
    else
      text_colors = {0,12}
    end

    --printr(''..t.score, x, y, {7,0})

    if t.landed and age > 20 then
      del(combo, t)
      --combo_score = 0
    end
  end
  if mode == 'play' and (alive == true or frame-died<60) then
    printr(n, score_x, 8, score_colors)
    --printr(n, 8, 8, score_colors)
  end

  --if alive == true or frame-died<60 then
  if mode=='play' and alive == true then
    local barw = 64
    local spew = special
    if spew != lspew and lspew != nil and frame-special_changed<20 then
      spew = min(
        64,
        tween(lspew, spew+1, special_changed, special_changed+20)
      )
    end

    if (spew > 0) then
      rect(6, 6, 6+barw+4, 16, 5)
      if show_bonus == true then
        ibc = ({11,12,8,14})[flrrnd(4)+1]
      else
        ibc = 13
      end
      rect(7, 7, 7+barw+2, 15, ibc)
      if spew > 0 then
        rectfill(8, 8, 8+spew, 14, 8)
      end
    end
    lspew = spew
  end

  if paused == true and alive == false then
    if frame - died > 60 then
      dead_for = flr(min(frame - died - 60, 40) / 10 * 2)
      sw = ({20,36,52,60,78,92,112,128})[dead_for]
      sspr(0, 64, sw, 32, 0, 32)
    end
    if frame - died > 120 then
      --printr('lol', 64, 64, {7,0})
      string = ''..final_score
      per_n = 8
      local x = 60 - (((#string+1)/2)*per_n)
      ccolors = {7,1,8}
      for i=1,#string do
        printr(sub(string, i, i), x+i*per_n, 72, ccolors)
      end

    end
  end

end


--------------------------------
-- state -----------------------

frames_per_beat = 33
frames_per_bar = 128
frames_per_phrase = 254

function bm(n) return ((n-1)*32)/1 end
--function bt(n) return n*16 end

mode = 'attract'
level = 1
score = 0
special = 0
special_changed = 0
special_animating = false
has_specialed = false
specialed_on = 0
beat_frame = 0
combo_score = 0
new_combo_score = 0
old_combo_score = 0
landed = nil
tricked = nil
show_bonus = false
bonused = nil
last_attack = 0
paused = false
alive = false
jump = false
distance = 0
altitude = 0
speed = 0
lift = 0

frame = 0
beat = 0
bar = 0
phrase = 0
coroutines = {}
queue = {}
timeouts = {}
intervals = {}
eventloop = {}
script = {}
combo = {}
max_combo = 0
skull = {}
board = {}
died = nil
charge_trail = {}
slam_trail = {}

trex = {}
has_grabbed = false
can_pop = true
can_charge = true
min_charge = 2
max_charge = 64
overtaking = false
cue_jump = false
groundlevel = 0
above_lava = 0
above_cable = 0
push_speed = 1
slam_start_height = 0

shake_frames = 0

cacti = {}
poles = {}
cables = {}
lava = {}
meteors = {}
fireworks = {}
crashing = nil
destroying = nil

tricks = {
  'none',
  'push',
  'pop',
  'ollie',
  'charge',
  'meteor',
  'grind',
}

trick = 'none'
charge = 0

sky = {}

function split(string)
  table={}
  while #string > 0 do
   local d=sub(string,1,1)
   if d!="," then
    add(table,d)
   end
   string=sub(string,2)
  end
  return table
end

function splitn(string)
  table=split(string)
  for k,v in pairs(table) do
    table[k] = tonum(v)
  end
  return table
end

sprites = {
  roll_1 = {  0 },
  push_1 = {  8 },
  push_2 = { 16 },
  push_3 = { 24 },
  push_4 = { 32 },
  push_5 = { 40 },
  push_6 = { 48 },
  grab_1 =  { 56 },
  ollie_1 =  { 64 },

  smile = {  0, 0 },
  yikes = {  8, 0 },
  growl = { 16, 0 },

  tail_0 = { 24, 0 },
  tail_1 = { 32, 0 },
  tail_2 = { 40, 0 },
  tail_3 = { 48, 0 },
  tail_4 = { 56, 0 },

  arm = { 64, 0 },

  board_flat = { 72, 0 },
  board_high = { 80, 0 },
  board_half = { 88, 0 },

  board_1 = { 72,  0 },
  board_2 = { 80,  0 },
  board_3 = { 80, 16 },
  board_4 = { 80,  0, 8, 8, 0, false, true },
  board_5 = { 72,  0, 8, 8, 0, false, true },
  board_6 = { 80,  0, 8, 8, 0, true, true },
  board_7 = { 80, 16, 8, 8, 0, true },
  board_8 = { 80,  0, 8, 8, 0, true },

  legs_0 = {  0 },
  legs_1 = {  8 },
  legs_2 = { 16 },
  legs_3 = { 24 },
  legs_4 = { 32 },
  legs_5 = { 40 },
  legs_6 = { 48 },
  legs_7 = { 56 },
  legs_8 = { 64 },

  sparks_1 = { 72, 8, 4, 4 },
  sparks_2 = { 76, 8, 4, 4 },
  sparks_3 = { 72, 12, 4, 4 },
  sparks_4 = { 76, 12, 4, 4 },
  sparks_5 = { 76, 12, 4, 4 },
  sparks_6 = { 72, 12, 4, 4 },
  sparks_7 = { 76, 8, 4, 4 },
  sparks_8 = { 72, 8, 4, 4 },

  cactus_alive_1 = { 33, 32, 8, 16 },
  cactus_dead_1 = { 44, 32, 8, 16 },
  cactus_dead_2 = { 55, 32, 8, 16 },
  cactus_dead_3 = { 33, 48, 8, 16 },
  cactus_dead_4 = { 44, 48, 8, 16 },
  cactus_dead_5 = { 55, 48, 8, 16 },

  cactus_alive_1 = { 0, 16, 8, 16 },
  cactus_dead_1 =  { 11, 16, 8, 16 },
  cactus_dead_2 =  { 22, 16, 8, 16 },
  cactus_dead_3 =  { 33, 16, 8, 16 },
  cactus_dead_4 =  { 44, 16, 8, 16 },
  cactus_dead_5 =  { 55, 16, 8, 16 },

  cactus_legs = { 64, 24 },
  cactus_head_1 = { 72, 24 },
  cactus_head_2 = { 80, 24 },
  cactus_head_3 = { 88, 24 },

  skull_1 =  { 64, 16 },
  skull_2 =  { 72, 16 },
  skull_3 =  { 64, 16, 8, 8, 0, true, true },
  skull_4 =  { 72, 16, 8, 8, 0, true, true },
}

level_music = {
  12,
  13,
  14,
  10,
  7,
  7,
  2,
  4,
  8,
}

levels = {
  {'lone_cactus'},
  {'double_cactus'},
  {'volcano_pool'},
  {'indoor_lake'},

  --{ 'deathtrap_runway', },
  --{ 'apocalypse' },
  --{ 'fs_twin_cactus_crater', 'bs_twin_cactus_crater', },
  --{ 'lone_cactus', 'double_cactus', },
  --{ 'lone_cactus', 'double_cactus', 'overhead', },
  --{ 'overhead' },
  --{ 'sudden_nearmiss' },
  --{ 'near_miss' },
  --{ 'crater' },
  --{ 'direct_hit' },
  --{ 'volcano_ocean_runway_meteor' },
  --{ --'volcano_ocean_runway_meteor', 'lone_cactus', 'double_cactus', },
  --{ 'double_cactus', 'double_wide', 'quad_cactus', 'lava_pool', },
  --{ 'lone_cactus', 'double_cactus', 'double_wide', 'volcano_pool', 'fs_half_volcano_pool', 'indoor_lake', 'volcano_lake_runway', },
  --{ 'lone_cactus', 'double_wide', 'volcano_pool', 'volcano_lake', 'bs_half_volcano_lake', 'fs_half_volcano_lake', 'volcano_ocean_runway', },
  --{ --'volcano_ocean_runway_meteor', 'volcano_deathtrap_runway', }

}

pool = {
  -- road -----
  --'open_road',
  --'interstate',
  --
  -- cactus ---
  --'lone_cactus',
  --'double_cactus',
  --'double_wide',
  --'double_lighthouse',
  --'triple_cactus',
  --'quad_cactus',
  --
  -- lava -----
  --'lava_puddle',
  --'lava_pool',
  --'lava_lake',
  --'lava_ocean',
  --'lava_deathtrap',
  --
  -- cables ---
  -- 'powerslide',
  -- 'double_powerslide',
  -- 'triple_powerslide',
  --
  -- volcanos -
  -- 'volcano_puddle',
  -- 'volcano_pool',
  -- 'volcano_lake',
  -- 'volcano_ocean',
  -- 'volcano_deathtrap',
  --
  -- Â½volcanos -
  -- 'fs_half_volcano_puddle',
  -- 'bs_half_volcano_puddle',
  -- 'fs_half_volcano_pool',
  -- 'bs_half_volcano_pool',
  -- 'fs_half_volcano_lake',
  -- 'bs_half_volcano_lake',
  -- 'fs_half_volcano_ocean',
  -- 'bs_half_volcano_ocean',
  -- 'fs_half_volcano_deathtrap',
  -- 'bs_half_volcano_deathtrap',
  --
  -- special ---
  -- 'cactus_lava_gap',
  --
  -- indoors ---
  -- 'indoor_lake',
  -- 'indoor_ocean',
  --
  -- indovol --
  -- 'indoor_volcano_lake',
  -- 'indoor_volcano_ocean',
  --
  -- runways --
  -- 'lake_runway',
  -- 'ocean_runway',
  -- 'deathtrap_runway',
  --
  -- volcano runways
  -- 'volcano_lake_runway',
  -- 'volcano_ocean_runway',
  -- 'volcano_deathtrap_runway',

  -- with meteors
  'volcano_ocean_runway_meteor',
}

function layers(length, ...)
  local layers = {}
  for l in all({...}) do
    if type(l) == "string" then
      add(layers, {l})
    else
      add(layers, l)
    end
  end
  return {
    length = length,
    layers = layers,
  }
end

function cables(length, ...)
  local cables = {}
  for c in all({...}) do
    add(cables, c)
  end
  return {
    length = length,
    cables = cables,
  }
end

function cactus(length, ...)
  local cacti = {}
  for c in all({...}) do
    add(cacti, c)
  end
  return {
    length = length,
    cacti = cacti,
  }
end

function lava(length, ...)
  local lava = {}
  for l in all({...}) do
    add(lava, l)
  end
  return {
    length = length,
    lava = lava,
  }
end

function meteor(length, ...)
  local m = {...}
  return {
    length = length,
    meteors = {m},
  }
end

spots = {

  -- .... .... .... ....
  open_road = layers(64),

  -- .... .... .... .... .... .... .... ....
  interstate = layers(128),

  -- .... .... .... ...ððµ
  lone_cactus = cactus(64, 64),

  -- .... .... .... ...ððµ ...ððµ
  twin_cactus = cactus(64, 64, 80),

  -- .... .... .... ...ððµ .... ...ððµ
  double_cactus = cactus(64, 64, 96),

  -- .... .... .... ...ððµ .... .... .... ...ððµ
  double_wide = cactus(128, 64, 128),

  -- .... .... .... ...ððµ .... .... .... .... .... ...ððµ
  double_lighthouse = cactus(128, 64, 160),

  -- .... .... .... ...ððµ .... .... .... .... .... .... .... .... .... ...ððµ
  double_clifftop = cactus(128, 64, 224),

  -- .... .... .... ...ððµ .... .... .... .... .... .... .... ...ððµ .... ...ððµ
  triple_cactus = cactus(128, 64, 192, 224),

  -- .... .... .... ...ððµ .... ...ððµ .... .... .... .... .... ...ððµ .... ...ððµ
  quad_cactus = cactus(128, 64, 96, 192, 224),

  -- .... .... .... ...ððµ ...ððµ ...ððµ ...ððµ ....
  cactus_woods = cactus(128, 64, 80, 96, 112),

  -- .... .... .... ...ððµ ...ððµ ...ððµ ...ððµ ...ððµ ...ððµ ...ððµ ...ððµ
  cactus_forest = cactus(
    128,
    64, 80, 96, 112,
    128, 144, 160, 176
  ),

  -- .... .... .... ...ððµ ...ððµ ...ððµ ...ððµ ...ððµ ...ððµ ...ððµ ...ððµ ...ððµ ...ððµ ...ððµ ...ððµ
  cactus_jungle = cactus(
    128,
    64, 80, 96, 112,
    128, 144, 160, 176,
    192, 208, 224, 240
  ),

  fs_half_twin_cactus = cactus(64, 64),
  bs_half_twin_cactus = cactus(64, 80),
  fs_half_double_cactus = cactus(64, 64),
  bs_half_double_cactus = cactus(64, 96),
  fs_half_double_wide = cactus(128, 64),
  bs_half_double_wide = cactus(128, 128),
  fs_half_double_lighthouse = cactus(128, 64),
  bs_half_double_lighthouse = cactus(128, 160),
  fs_half_double_clifftop = cactus(128, 64),
  bs_half_double_clifftop = cactus(128, 224),

  easy_headshot = meteor(16, 128, -1, 2, 8),
  sudden_headshot = meteor(16, 192, -2, 2, 8),
  easy_crater = meteor(16, 192, -1, 2, 8),
  sudden_crater = meteor(16, 224, -2, 2, 8),
  apocalypse = meteor(16, 128, -1, 3, 17),
  bs_badluck = meteor(16, 138, -1, 2.5, 6),
  fs_badluck = meteor(16, 120, -1, 2.5, 6),

  fs_twin_cactus_crater = layers(
    64,
    'twin_cactus',
    'fs_badluck'
  ),

  bs_twin_cactus_crater = layers(
    64,
    'twin_cactus',
    'bs_badluck'
  ),

  jungle_valley = layers(
    128, {
    'powerslide',
    'cactus_jungle'
  }),

  indoor_volcano_lake_jungle_valley = layers(
    128,
    'jungle_valley',
    'lava_lake'
  ),

  lava_puddle = {
    length = 64,
    lava = {{ bm(3)+8, bm(3.5) }},
  },

  lava_pool = {
    length = 32,
    lava = {{ bm(3)+8, bm(4) }},
  },

  lava_lake = {
    length = 64,
    lava = {{ bm(3)+8, bm(5)-2 }},
  },

  lava_ocean = {
    length = 128,
    lava = {{ bm(3)+8, bm(6) }},
  },

  lava_deathtrap = {
    length = 128,
    lava = {{ bm(3)+8, bm(8) }},
  },

  cactus_lava_gap = {
    length = 1024,
    soundtrack = 8,
    cacti = {
      bm(3), bm(5),
      bm(11), bm(13),
    },
    lava = {
      {bm(3)+8, bm(5)-2},
      {bm(11)+8, bm(13)-2},
    }
  },

  powerslide = cables(128, {0, 64}),

  double_powerslide = cables(
    128,
    {0, 64},
    {64, 128}
  ),

  triple_powerslide = cables(
    128,
    {0, 64},
    {64, 128},
    {128, 192}
  ),

  volcano_puddle = layers(
    64,
    'twin_cactus',
    'lava_puddle'
  ),

  volcano_pool = layers(
    64,
    'double_cactus',
    'lava_pool'
  ),

  volcano_lake = layers(
    64,
    'double_wide',
    'lava_lake'
  ),

  volcano_ocean = layers(
    64,
    'double_lighthouse',
    'lava_ocean'
  ),

  volcano_deathtrap = layers(
    128,
    'double_clifftop',
    'lava_deathtrap'
  ),

  indoor_lake = layers(
    64,
    'powerslide',
    'lava_lake'
  ),

  indoor_ocean = layers(
    128,
    'double_powerslide',
    'lava_ocean'
  ),

  indoor_volcano_lake = layers(
    64,
    'double_wide',
    'powerslide',
    'lava_lake'
  ),

  indoor_volcano_ocean = layers(
    128,
    'double_lighthouse',
    'double_powerslide',
    'lava_ocean'
  ),

  lake_runway = layers(
    64, {
    'powerslide',
    'lava_lake'
  }),

  ocean_runway = layers(
    128, {
    'powerslide',
    'lava_ocean'
  }),

  deathtrap_runway = layers(
    128, {
    'powerslide',
    'lava_deathtrap'
  }),

  fs_half_volcano_puddle = layers(
    64,
    'fs_half_twin_cactus',
    'lava_puddle'
  ),

  bs_half_volcano_puddle = layers(
    64,
    'bs_half_twin_cactus',
    'lava_puddle'
  ),

  fs_half_volcano_pool = layers(
    64,
    'fs_half_double_cactus',
    'lava_pool'
  ),

  bs_half_volcano_pool = layers(
    64,
    'bs_half_double_cactus',
    'lava_pool'
  ),

  fs_half_volcano_lake = layers(
    64,
    'fs_half_double_wide',
    'lava_lake'
  ),

  bs_half_volcano_lake = layers(
    64,
    'bs_half_double_wide',
    'lava_lake'
  ),

  fs_half_volcano_ocean = layers(
    128,
    'fs_half_double_lighthouse',
    'lava_ocean'
  ),

  bs_half_volcano_ocean = layers(
    128,
    'bs_half_double_lighthouse',
    'lava_ocean'
  ),

  fs_half_volcano_deathtrap = layers(
    128,
    'fs_half_double_clifftop',
    'lava_deathtrap'
  ),

  bs_half_volcano_deathtrap = layers(
    128,
    'bs_half_double_clifftop',
    'lava_deathtrap'
  ),

  volcano_lake_runway = layers(
    128, {
    'lake_runway',
    'bs_half_double_cactus'
  }),

  volcano_ocean_runway = layers(
    128,
    'ocean_runway',
    'bs_half_double_clifftop'
  ),

  volcano_deathtrap_runway = layers(
    128, {
    'deathtrap_runway',
    'bs_half_double_cactus'
  }),

  volcano_ocean_runway_meteor = {
    length = 128,
    layers = {{
      'powerslide',
      'lava_ocean',
    }},
    cacti = {bm(8)},
    meteors = {
      {
        bm(5),
        -push_speed*1,
        push_speed*2,
        8
      }
    }
  },

  overtake = {
    length = 16,
    meteors = {{
      bm(-3),
      push_speed*3.5,
      push_speed*1.0,
      8
    }}
  },

  overhead = {
    length = 16,
    meteors = {{
      bm(6),
      -push_speed*1.5,
      push_speed,
      8
    }}
  },

  easy_nearmiss = {
    length = 16,
    meteors = {{
      bm(4),
      -push_speed*1,
      push_speed*2,
      8
    }}
  },

  sudden_nearmiss = {
    length = 16,
    meteors = {{
      bm(6),
      -push_speed*2,
      push_speed*2,
      8
    }}
  },

  easy_headshot = {
    length = 16,
    meteors = {{
      bm(5),
      -push_speed*1,
      push_speed*2,
      8,
      nil,
    }}
  },

}


function cue_spot(spot, plus)
  if plus ~= nil then
    x = plus
  else
    x = distance + 128
  end
  if spot.soundtrack ~= nil then
    music(spot.soundtrack, 0, 3)
  end
  for c in all(spot.cacti) do
    add(cacti, {
      offset = { x + c - bm(3), 0 },
      size = { 6, 16 },
      alive = true,
    })
  end

  for l in all(spot.lava) do
    add(lava, {
      x+l[1] - bm(3),
      x+l[2] - bm(3),
    })
  end

  if alive == true then
    for m in all(spot.meteors) do
      add(meteors, {
        x+m[1] - bm(3),      --1 x pos
        m[5] or -128,        --2 y pos
        m[2],                --3 x vec
        m[3],                --4 y vec
        m[4],                --5 radius
        {},                  --6 trail
        true,                --7 alive
        frame + (m[6] or 0), --8 delay
      })
    end
  end

  for c in all(spot.cables) do

    add(poles, {
      offset = { x+c[1], -2 },
      size = { 1, 32 },
    })

    add(poles, {
      offset = { x+c[2], -2 },
      size = { 1, 32 },
    })

    add(cables, {
      x + c[1], -32,
      x + c[2], -32
    })
  end
  for l in all(spot.layers) do
    pplus = distance + 128
    for spot_name in all(l) do
      cue_spot(spots[spot_name], pplus)
      pplus = pplus + spots[spot_name].length / 2
    end
  end
end

function extend_combo(score, text)
  combo_length = combo_length + 1
  --add(combo, {
    --text = text,
    --frame = frame,
    --score = score,
  --})
  if combo_length > max_combo then
    max_combo = combo_length
  end

  new_combo_score = combo_score+score
  old_combo_score = combo_score
  tricked = frame
end

function gameover()
  if paused == false and alive == true then
    paused = true
    final_score = combo_score

    fireworks_budget = flr(final_score / 1000)
    afterc(128, function()
      if alive == false and mode == 'play' then
        everyc(16, function()
          while alive == false and mode == 'play' and fireworks_budget > 0 do
            firework(flrrnd(128))
            fireworks_budget = fireworks_budget - 1
            yield()
          end
        end)
      end
    end)

    board.offset = {distance, altitude}
    board.vector = {}
    board.vector[1] = speed - 1
    board.vector[2] = lift - 6

    skull.offset = {distance, altitude}
    skull.vector = {}
    skull.vector[1] = speed
    skull.vector[2] = lift - 2

    --combo = nil
    --combo = {}
    for c in all(combo) do
      c.bailed = frame
    end

    script = {}
    pool = {}
    parallax(0)
    sfx(2, 3)
    music(-1)
    sfx(19, 2)
    trick = 'none'
    died = frame
    alive = false
    reset_special()
  end
end

function firework(fx)
  add(fireworks, {
    cityscape_offset + (fx or 100), -- x offset
    0, -- y offset
    0, -- angular speed
    2, -- lift
    6, -- fuel
    6, -- fuse
    4, -- gunpowder
    ({11,12,8,14})[flrrnd(4)+1], -- color
  })
end

function increase_special(n)
  special = min(64, special + n)
  special_changed = frame

  if special >= 64 and frame-specialed_on>60 then
    sfx(18)
    show_bonus = true
    has_specialed = true
    specialed_on = frame
    new_combo_score = combo_score+1000
    old_combo_score = combo_score
    afterc(30, hide_bonus)
    afterc(30, reset_special)
    firework()
    afterc(8, firework)
    afterc(16, firework)
    afterc(24, firework)
  end
end

function hide_bonus()
  show_bonus = false
end

function reset_special()
  special = 0
  special_changed = frame
end

--------------------------------
-- actions ---------------------

actions = {
  charge = function()
    if trick == 'chrage' or can_charge == false then
      return
    end
    trick = 'charge'
    charge = 0
    --lift = -0.5 --undome
    --can_pop = true

    sfx(23, 3)
    can_charge = false
  end,

  destroy_cactus = function(cactus)
    sfx(-1, 3)
    sfx(0, 3)
    shake_frames = 10

    if trick == 'charge' then
    elseif trick == 'slam' then
      --add(eventloop, 'pop')
    end

    if trick == 'slam' then
      lift = max(slam_start_height/14, -2.5)
      cactus.burn = true
      extend_combo(50, 'asteroid')
      can_charge = false
      after(4, 'enable_charge')
      increase_special(16)
    else
      lift = -3
      cactus.fall = true
      extend_combo(20, 'stomp')
      can_charge = false
      after(16, 'enable_charge')
      increase_special(8)
    end

    trick = 'air'
    altitude = (
      cacti[1].offset[2] -
      cacti[1].size[2] - 4
    )
    --parallax(1)
    cactus.alive = false
    cactus.died = frame
    charge_trail = {}
    last_attack = frame
  end,

  destroy_meteor = function()
    destroying[3] = 0
    destroying[4] = 0

    if trick == 'slam' then
      lift = max(slam_start_height/14, -4.5)
      extend_combo(50, 'asteroid')
      increase_special(32)
    else
      lift = -3
      extend_combo(20, 'stomp')
      increase_special(16)
    end

    trick = 'air'
    can_charge = false
    after(16, 'enable_charge')
    last_attack = frame
  end,

  enable_charge = function()
    can_charge = true
  end,

  gc = function()
    for i,cactus in pairs(cacti) do
      if cactus.offset[1] < foreground_offset then
        del(cacti, i)
      end
    end

    printh(stat(1))
    for i,l in pairs(lava) do
      if l[2] < foreground_offset then
        printh('gc')
        printh(l[2])
        del(lava, l)
      end
    end

    for f in all(fireworks) do
      if f[10] != nil and frame-f[10]>60 then
        del(fireworks, f)
      end
    end

    for m in all(meteors) do
      if m[1] < foreground_offset and m[3] < 0 then
        del(meteors, m)
      end
    end

    for i,pole in pairs(poles) do
      if pole.offset[1] < foreground_offset - 64 then
        poles[i] = nil
        del(poles, poles[i])
      end
    end
  end,


  grab = function()
    sfx(8, 3)
    trick = 'grab'
    charge_trail = {}
    --lift = 7
    --slam_trail = {}
  end,

  slam = function()
    sfx(-1, 3)
    sfx(8, 3)
    trick = 'slam'
    lift = 7
    slam_trail = {}
    slam_start_height = altitude
  end,

  grind = function()
    parallax(2)
    trick = 'grind'
    distance = ceil(distance)
    altitude = groundlevel
    lift = 0
    charge_trail = {}
    slam_trail = {}
    extend_combo(10, 'powerslide')
  end,

  land = function()
    sfx(-1, 3)
    special = 0
    special_changed = frame
    landed = frame
    charge_trail = {}
    slam_trail = {}
    combo_length = 0
    if alive then
      if trick == 'slam' then
        sfx(3, 3)
        shake_frames = 20
      else
        sfx(1, 3)
      end
      trick = 'push'
    end

    new_combo_score = 0
    old_combo_score = combo_score

    altitude = 0
    lift = 0
  end,

  music_play = function()
    music(-1)
    if alive == true then
      music(level_music[level])
    end
  end,

  start_difficulty_tick = function()
    every(32*8, 'harder')
  end,

  music_start = function()
    if alive == false then
      return
    end
    music(-1)
    music(level_music[level])
    --every(frames_per_phrase*4, 'harder')
    --every(32*4*4, 'harder')
    --every(32*8, 'harder')
    beat = 1
    bar = 1
    --every(32, 'next_beat')
    everyc(32, actions.next_beat)
  end,

  next = function()
    if mode != 'play' or paused then
      return
    end

    name = script[1]
    del(script, name)

    spot = spots[name]
    cue_spot(spot)
    after(spot.length, 'next')

    key = flr(rnd(#levels[level])) + 1
    add(script, levels[level][key])
  end,

  pop = function()
    if can_pop == false then
      return
    end
    if trick == 'charge' then
      lift = -9
    elseif trick == 'grind' then
      lift = -4
    else
      lift = -3.2
    end
    trick = 'pop'

    sfx(0, 3)
    can_pop = false
    can_charge = true
  end,

  push = function()
    trick = 'push'
    parallax(2)
  end,

  ollie = function()
    trick = 'ollie'
  end,

  harder = function()
    if alive == true and has_specialed == true and level < #levels then
      level = level + 1

      script = {}
      key = flr(rnd(#levels[level])) + 1
      add(script, levels[level][key])

      has_specialed = false
      after(32, 'music_play')
      --actions.music_play()
    end
  end,

  next_beat = function()
    while alive do
      beat=beat%4+1
      beat_frame = frame
      if beat == 1 then
        bar=bar+1
      end
      yield()
    end
  end,

  play = function()
    if mode == 'play' then
      return true
    end

    music(9)

    beat = 0
    bar = 0
    phrase = 0
    mode = 'play'
    distance = foreground_offset + trex.size[1]

    script = {'open_road'}
    pool = medium_pool
    add(eventloop, 'next')
    after(32*4, 'music_start')
    after(32*3, 'start_difficulty_tick')
  end,

  release = function()
    trick = 'air'
  end,

  reset = function()
    combo_score = 0
    special = 0
    special_changed = 0
    has_specialed = false
    specialed_on = 0
    combo_length = 0
    new_combo_score = 0
    old_combo_score = 0
    landed = nil
    tricked = nil
    show_bonus = false
    bonused = nil
    last_attack = 0
    trick = 'push'
    mode = 'attract'
    paused = false
    crashing = nil
    destroying = nil

    music(3)

    timeouts = {}

    intervals = nil
    intervals = {}

    combo = nil
    combo = {}
    max_combo = 0

    cacti = {}
    meteors = {}
    fireworks = {}
    poles = {}
    script = {}
    cables = {}
    lava = {}
    charge_trail = {}
    slam_trail = {}

    level = 1
    groundlevel = 0
    alive = true
    trex.trick = 'push'
    distance = 0
    altitude = 0
    trex.vector = { push_speed, 0 }
    trex.size = { 16, 16 }
    foreground_offset = -10
    foreground_speed = speed
    nearground_offset = - 10
    nearground_speed = 1
    cityscape_offset = -10
    cityscape_speed = 1
    sky_offset = -10
    sky_speed = 0.5
    parallax(2)
    every(60, 'gc')
    cls()
  end,

}

--------------------------------
-- rendering -------------------

function parallax(s)
  foreground_offset = distance - 16
  if s == 0 then
    foreground_speed = 0
    nearground_speed = 0
    cityscape_speed = 0
    sky_speed = 0
  elseif s == 1 then
    speed = push_speed
    foreground_speed = speed
    nearground_speed = 0.5
    cityscape_speed = 0.5
    sky_speed = 0.25
  elseif s == 2 then
    speed = 2
    foreground_speed = speed
    nearground_speed = 1.5
    cityscape_speed = 1.5
    sky_speed = 1
  end
end

function draw(id, pos)
  if sprites[id] == nil then
    printh('draw - no such '..id)
    return
  end

  b = sprites[id]
  sx = b[1]
  sy = b[2] or 8
  sw = b[3] or 8
  sh = b[4] or 8
  alpha = b[5] or 0
  flip_x = b[6] or false
  flip_y = b[7] or false

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
    flip_x,
    flip_y
  )
end

function printb(text, x, y, fg, bg)
  r = 2
  for i=x-r,x+r do
    for j=y-r,y+r do
      print(text, i, j, bg)
    end
  end
  print(text, x, y, fg)
end

function printr(text, x, y, colors)
  for ir,col in pairs(colors) do
    r = #colors - ir
    for i=x-r,x+r do
      for j=y-r,y+r do
        print(text, i, j, col)
      end
    end
  end
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
  elseif cactus.burn then
    fsd = frame - cactus.died
    sprite = 'cactus_dead_' .. min(flr(fsd / 4) + 1, 5)
    draw(sprite, cactus.offset)
  elseif cactus.fall then
    draw('cactus_legs', cactus.offset)
    fsd = frame - cactus.died
    sprite = 'cactus_head_' .. min(flr(fsd / 4) + 1, 4)
    draw(sprite, {cactus.offset[1], cactus.offset[2] - 8})
  end
end

function draw_meteor(meteor)
  if meteor[7] then
    for t in all(meteor[6]) do
      if meteor[5] == 17 then
        ro = 17 - (frame-t[3])*1.4
        ry = -1
      else
        ro = meteor[5] - max(0, (frame - t[3])*0.4)
        ry = meteor[5] - max(0, (frame - t[3])*0.5)
      end
      xtra = flrrnd(2)
      circfill(t[1]-1+xtra, t[2]-0, ro, 9)
      circfill(t[1]-1+xtra, t[2]-0, ry, 10)
    end
    circfill(meteor[1], meteor[2], meteor[5], 9)
    circfill(meteor[1], meteor[2], meteor[5]-1, 10)
  else
    diedago = frame-meteor[8]
    for i = 1,10 do
      px = flrrnd(meteor[5])+diedago
      py = flrrnd(meteor[5]) + diedago/2
      r = 2 - flr(diedago / 5)
      circfill(meteor[1]+px, meteor[2]+py, r, 9)
    end
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

    cx = x1 - foreground_offset
    cy = 0
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

  end
end

function draw_pole(pole)
  spr(
    26,
    pole.offset[1]-3,
    pole.offset[2]-pole.size[2]+2
  )
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
    tx = distance
    ty = altitude
    x1 = c[1] + 3
    y1 = c[2] + 1
    x2 = c[3] - 3
    y2 = c[4] + 1

    if tx > x1 and tx < x2 and ty >= y1 + 1 and trick == 'grind' then
      line(x1, y1, tx, groundlevel - 2, 5)
      line(tx, groundlevel - 2, x2, y2, 5)
    else
      line(x1, y1, x2, y2, 5)
    end
  end
end

function draw_board()
  if board.offset[2] < 0 then
    board_sprite = 'board_' .. loop(32, 8)+1
  else
    board_sprite = 'board_flat'
  end
  draw(board_sprite, board.offset)
end

function draw_skull()
  if skull.vector[1] > 0 then
    skull_sprite = 'skull_' .. loop(32, 4)+1
  else
    skull_sprite = 'skull_1'
  end
  draw(skull_sprite, skull.offset)
end

function draw_trex()
  head_bob = 0
  tail_sprite = 'tail_3'
  board_sprite = 'board_flat'
  head_offset = { 0, 0 }
  board_offset = { 2, 2 }

  offsets = {{
    distance,
    altitude,
  }}

  if alive == false then
    -- nothing lol
  elseif trick == 'none' then
    face_sprite = 'smile'
    tail_sprite = 'tail_2'
    legs_sprite = 'roll_1'
  elseif trick == 'roll' then
    face_sprite = 'smile'
    tail_sprite = 'tail_2'
    legs_sprite = 'roll_1'
  elseif trick == 'push' then
    sprite_n = loop(frames_per_beat, 5) + 1
    if sprite_n == 3 or sprite_n == 4 or sprite_n == 5 then
      head_bob = 1
    end
    face_sprite = 'smile'
    legs_sprite = 'push_'..sprite_n
    tailmap = {
      push_1 = 'tail_1',
      push_2 = 'tail_2',
      push_3 = 'tail_3',
      push_4 = 'tail_3',
      push_5 = 'tail_2',
      push_6 = 'tail_1',
    }
    tail_sprite = tailmap[legs_sprite]
    board_offset[1] = 3
  elseif trick == 'pop' then
    face_sprite = 'yikes'
    legs_sprite = 'roll_1'
    board_sprite = 'board_high'
  elseif trick == 'ollie' then
    face_sprite = 'yikes'
    legs_sprite = 'ollie_1'
    board_sprite = 'board_half'
    board_offset[1] = 2
    board_offset[2] = 1
  elseif trick == 'air' then
    face_sprite = 'yikes'
    tail_sprite = 'tail_2'
    legs_sprite = 'roll_1'
    board_sprite = 'board_flat'
    board_offset[1] = 2
  elseif trick == 'slam' then
    face_sprite = 'growl'
    legs_sprite = 'grab_1'
    board_sprite = 'board_high'
    board_offset[1] = 5
    board_offset[2] = 0
  elseif trick == 'charge' then
    face_sprite = 'growl'
    tail_sprite = 'tail_0'
    legs_sprite = 'grab_1'
    board_sprite = 'board_high'
    board_offset[1] = 5
    board_offset[2] = 1
  elseif trick == 'grind' then
    face_sprite = 'smile'
    legs_sprite = 'roll_1'
  end

  if trick == 'grind' then
    spark = 'sparks_' .. 8 - (loop(frames_per_beat, 7) + 1)
    draw(spark, {
      ceil(distance) - 2,
      altitude,
    })
  end

  for i,t in pairs(charge_trail) do
    --r = 4 - max(0, (frame-t[3])/4)
    r = 1
    if t != charge_trail[#charge_trail] then
      age = frame - t[3]
      from = {t[1], t[2]}
      to = {charge_trail[i+1][1],charge_trail[i+1][2]}
      raggedy = (charge / 32) * 6
      --drop =
      ru1 = 3.14159 / 32
      run = ru1 * (age+8) / 10
      drop = -1* sin(run) * 6
      fl = function(n) return from[2] - n + drop - 2 end
      tl = function(n) return to[2] - n + drop - 2 end
      --drop = 0

      if charge > 36 and charge % 4 == 0 then
        -- flicker!!!
      elseif age < raggedy and charge > 10 then
        line(from[1]+5, fl(5), to[1]+5, tl(5), 8)
        line(from[1]+4, fl(4), to[1]+4, tl(4), 9)
        line(from[1]+3, fl(3), to[1]+3, tl(3), 10)
        line(from[1]+2, fl(2), to[1]+2, tl(2), 11)
        line(from[1]+1, fl(1), to[1]+1, tl(1), 12)
      elseif age < 6 then
        circfill(from[1]+5, fl(5), flrrnd(2), 8)
        circfill(from[1]+1, fl(1), flrrnd(2), 12)
      end

      if age > 6 then
        del(charge_trail, t)
      end
    end
  end

  for t in all(slam_trail) do
    ro = 7 - max(0, (frame - t[3])*1.4)
    ry = 6 - max(0, (frame - t[3])*2)
    circfill(t[1]+6, t[2]-8, ro, 9)
    circfill(t[1]+6, t[2]-8, ry, 10)
  end

  for o in all(offsets) do
    draw(tail_sprite, {
      ceil(o[1]) - 1,
      o[2] - 3 + head_bob,
    })

    draw('arm', {
      ceil(o[1]) + 4,
      o[2] - 2 + head_bob,
    })

    draw(board_sprite, {
      ceil(o[1]) + board_offset[1],
      o[2] + board_offset[2],
    })

    if legs_sprite then
      draw(legs_sprite, {
        ceil(o[1]) + 1,
        o[2],
      })
    end

    draw(face_sprite, {
      ceil(o[1]) + 7 + head_offset[1],
      o[2] - 8 + head_bob + head_offset[2],
    })
  end

end

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

--function angle(a, b)
  --return atan2(
    --b[2] - a[2],
    --b[1] - a[1]
  --)
--end

function distance(a, b)
  distance_x = abs(a[1] - b[1])
  distance_y = abs(a[2] - b[2])
  distance_2 = abs(
    (distance_x * distance_x)
    + (distance_y * distance_y)
  )
  return sqrt(distance_2)
end

--function tan(a) return sin(a)/cos(a) end

function cable_buckle(p1, p2)
  tx = distance
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


--------------------------------
-- physics ---------------------

function update_groundlevel()
  for c in all(cables) do
    x1 = c[1]
    y1 = c[2]
    x2 = c[3]
    y2 = c[4]
    if distance+8 >= x1 and distance <= x2 then
      p1 = { offset = {x1, y1} }
      p2 = { offset = {x2, y2} }
      buckle = cable_buckle(p1, p2)
      if trick == 'grind' or altitude <= y1 + buckle + 1 then
        above_cable = true
        groundlevel = y1 + buckle
        return
      end
    end
  end

  for l in all(lava) do
    x1 = l[1]
    x2 = l[2]

    if distance >= x1 and (distance+trex.size[1]) <= x2 then
      above_lava = true
      groundlevel = 3
      return
    end
  end
  above_lava = false

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

  lava = function (l)
    x1 = l[1]
    x2 = l[2]
    return {
      offset = { x1, 1 },
      size = { x2 - x1, 8 }
    }
  end,

  meteor = function (m)
    return {
      offset = { m[1] - m[5]/2, m[2] - m[5]/2 },
      size = { m[5], m[5] }
    }
  end,

  trex = function()
    if trick == 'slam' then
      return {
        offset = {
          distance + 2,
          altitude - trex.size[2],
        },
        size = {
          16,
          trex.size[2] * 1
        }
      }
    end

    if trick == 'charge' then
      return {
        offset = {
          distance + 2,
          altitude - trex.size[2] + 8,
        },
        size = { 8, 8 }
      }
    end

    return {
      offset = {
        distance + 2,
        altitude - trex.size[2] + 8,
      },
      size = { 8, 6 }
    }

  end,
}


--------------------------------
-- timekeeping -----------------

--function next(queue)
  --local v = queue[1]
  --del(queue, v)
  --return v
--end

function tween(from, to, first_frame, last_frame)
  frame_count = last_frame - first_frame
  value_space = to - from
  per_frame = value_space / frame_count
  frames_now = frame - first_frame
  return from + (per_frame * frames_now)
end

--function cron(interval)
  --remainder = frame % interval
  --return remainder == 0
--end

function loop(interval, limit)
  remainder = frame % interval
  chunk_size = flr(interval / limit)
  local num = flr(remainder / chunk_size)
  return num
end

--function clear(action)
  --for i,timeout in pairs(timeouts) do
    --if timeout[2] == action then
      --del(timeouts, i)
    --end
  --end
--end

function after(frames, action)
  add(timeouts, { frame + frames, action })
end

function every(interval, action)
  add(intervals, {
    interval,
    action,
    frame % interval,
  })
end

function everyc(interval, action)
  add(coroutines, {
    cocreate(action),
    interval,
    frame % interval,
  })
end

function afterc(frames, action)
  add(coroutines, {
    cocreate(action),
    frame + frames,
    0,
  })
end

function next(c)
  add(coroutines, {
    cocreate(c),
    frame + 1,
    0
  })
end

--------------------------------
-- anything --------------------

function magnitude(v)
  return sqrt(v[1]*v[1] + v[2]*v[2])
end

function flrrnd(n)
  return flr(rnd(n))
end

function choose(table)
  return table[flrrnd(#table) + 1]
end

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
08888000088880000858800000800000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88778800887788008875880000800000008000080080000800000008000000000000000000000000000000c00000000000000000000000000000000000000000
887c8888887788888877588800880008008800880088008808000088080000080008888800000000000000c00000000022222000000000000000000000000000
88778888887c8888887c8888008888880088888800888888088888880888888800888808cc0000cc00000c00000000002e2e2002222222222200000002222200
8888888888888888888888880088888800888888008888880088888800888888008880000cccccc00000c070000000cc22222002e2ee22222200000002e2e200
88880000888877008888770000088888000888880008888800088888000888880000000007000070000c0000000cccc02e2e2022222222222222000222222220
888888008888880088888800000088880000888800008888000088880000888800000000000000000cc07000ccc000702222202ee2ee222222e20022e2222222
88800000888000008880000000000000000000000000000000000000000000000000000000000000000000000700000022222022222222222222002222222222
00000008000000080000000800000008000000080000000800000008000000000000000000000000d00000d08888888000000000000000000000000000000000
000000080000000800000008000000080000000800000008000000080000000800000000000000000d666d008888888800000000000000000000000000330033
0000008800000088000000880000008800000088000000880000008800000008000000080000000a00d0d0008888758800000000000000000000030030030330
00088880000888800008888000088880000088800000888000008880000008880000088800090a0a000d00008888c58800000000033000000330330033030300
000800800008808000088080000880800088808000088080000080800008880000888808000aa0a0000d00008888888800000000000300000033300003333300
0008808000088088000800880008008888800088000800880000808800080880008000080a000000000d00000808888000030000000300000003000000333000
00000000000080000008000000880000800000000008000000008800000880000080000000000009000d00000808880000030000000300000003000000030000
000000000000880000088000008000000000000000000000000000000000000000000000aa090a00000d00000008880000030000000300000003000000030000
0000b0000000900000000009000a0000000090000000000900000000000000000666600006666660000c00000000000044444444444444444444444444444444
000bbb0b0000000ba000000000000000000000000000000000000000000000006655660066666666000cc7000028820044444444444444444444444444444444
0b0bbb0b000090bbb0b0000900ba00000000900000000009000a00000000000066556666666655560000c000028ee82044444444444444444444444444444444
0b0bbb0b0000b0bbb0b000090bbbab00009093a00000000900000000000000a066556666066655560000c00008eeee8044444444444444444444444444444444
0b0bbb0b0000b0bbb0b0000b0bbb0b000099333a30000909390a0000000a000066666666060666660000c00008eeee8044444444444444444444444455555555
0b0bbb0b0000b0bbb0b000ab0bbb0b000a303330300a099933aa0000000000a066660000060666600000c000028ee82055555555555555555555555555555555
0b0bbbbb000ab0bbb0b0000b0bbb0b00003033303000039333a3000000000a006666660000066600000cc70000288200555555555555555555555555dddddddd
0b0bbbb00000b0bbbbb900ab0bbb0b000a393330300a039333a309000a000a000660000000066600000c000000000000dddddddddddddddddddddddd44444444
0b0bbb00000ab0bbbb0000ab0bbbbb900a303330300aa39333a30000000aaa000b0bbb00000b0b0bbb00000000000000dddddddddddddddddddddddddddddddd
0bbbbb00000ab0bbb00900ab0bbbb0000a3933333000a39333039000aa0aaa000bbbbb00bb000000000000bb00000000dddd66666666dddddddd66666666dddd
000bbb00000abbbbb00000ab0bbb0a900a3933330a00a39333339000a9999a0a000bbb00b00bbb00b000b0000000b000dddddddddddddddddddddddddddddddd
000bbb00000000bbba0000abbbbb00000a393330a000a39333399000a9339000000bbb000b0bbb0b0b00bb000000bb00dddddddddddddddddddddddddddddddd
000bbb00000000bbb90000000bbb90000a3333309000a39333990000a933390a000bbb000b0bbb0b0000bb000000b000dddddddddddddddddddddddddddddddd
000bbb00000000bbb00000000bbb9000000033390000a33333900000a93339aa000bbb000b0bbb0bbb0bbb0b000bbb0055555555555555555555555555555555
000bbb00000000bbb00000000bbb0000000033390000000333900000093339a0000bbb000b0bbbbbb00bbbbb000bbb0055555555555555555555555555555555
000bbb00000000bbb00000000bbb0000000033390000000333000000093339a0000bbb000b0bbbb00b0bbbb00000bbb055555555555555555555555555555555
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000888888880000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000088888888000000000000888808888888888888880008888800000000000088888000000000000000000000000000088888880000088888000000
00000088888888888888008888800000888808888888888888880008888800088888000088888000000000088888000000888888888888880000088888000000
00000088888888888888008888880008888808888888888888880008888800088888000088888000000008888888008888888888888888880000088888000000
00000088888888888888008888880088888808888888888888880008888800088888800088888000000088888888088888888888888888880000088888000000
00000088888888888888008888888888888008888888888800000008888800088888800088888000000888888888088888888888888888880000088888000000
00000088888888880000008888888888880000000088888000000008888800888888880088888000008888888888088888888888888880000000088888000000
00000088888800000000000888888888800000000088888000000008888800888888880088888000088888880000088888888888880000000000088888000000
00000008888800000000000088888888800000000088888000000008888800888888888088888000088888800000088888800888880000000000088888000000
00000008888888880000000008888888000000000088888000000008888800888888888888888000088888800000000000000888880000000000088888000000
00000008888888880000000000888880000000000088888000000008888800888888888888888000088888000000000000000888880000000000088888000000
00000008888888880000000000888880000000000088888000000008888800888888888888888000088888000000000000000888880000000000088888000000
00000008888888880000000000888880000000000088888000000008888800888888888888888800088888000000000000000888880000000000088888000000
00000008888888880000000008888888000000000088888000000008888800888880888888888800088888000000000000000888880000000000088888000000
00000008888800000000000088888888000000000088888000000008888808888880088888888800088888800000000000000888880000000000088888000000
00000088888800000000000088888888800000000088888000000008888808888880088888888800088888800000000000000888880000000000088888000000
00000088888888888880088888888888880000000088888000000008888808888880008888888800088888880000000000000888880000000000088888000000
00000088888888888880088888800888888000000088888000000008888808888880000888888800088888888888000000000888880000000000000000000000
00000088888888888880088888800888888000000088888000000008888808888800000088888800008888888888000000000888880000000000000000000000
00000088888888888880088888800088888000000088888000000008888808888800000088888800008888888888000000000888880000000000088888000000
00000088888888888880088888000008888000000088888000000000000008888800000008888800000888888888000000000888880000000000088888000000
00000000000000000000000000000000000000000000000000000000000000000000000008888800000888888888000000000888880000000000088888000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000008888888000000000888880000000000088888000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088888000000
__sfx__
000100000d51001510015200152001530015300254003540035400454004540055500555006530095200a52007200062000020000200002000020000200002000020000200002000020000200002000020000200
0102000009010090100901009010026000260002600016000160005600016000b6000e600086010460104605026000060009600046000260009600036000a6000860004600006000860006600066000560000000
0000000001200062000e5200e5300f5400f5400f5400f540095500955009540095400954005540055400554005530055200552001520015200152001520015200151001510042000220001200012001020000000
01040000015100151001510005100051000510015000150001500015000150001500015001b000100001300016000190001c00021000260002b0002d0001b00020000260002c00034000380003d0003f0003f400
01100000030450304003145007000f0450f04003145030050a0450a0400a145000000b0450b0400b14500000080450804008145000000b0450b0400b145000000604506040061450000005045050400514505105
011000000b6050b6050b6050c000136053760300000000000b605000050000500005136050760500005000050b605000050b60500005136051360500005000050b60500005000050000513605136001360513605
01100000037540375203752037550f7540f7520f7520f7550a7540a7520a7520a7550b7540b7520b7520b755087540875208752087550b7540b7520b7520b7550675406752067520675505754057520575205755
01100000017140b7120b712067130b003020000200001000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000d01101011000151000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000019000000000000000000000000000000000
010201200101203012010120301201012030120101203012010120301201012030120101203012010120301201012030120101203012010120301201012030120101203012010120301201012030120101203012
010200000101001011010110101101021010210102101021030210302103021030210303103031030310303106031060310603106031060410604106041060410804108041080410804108051080510805108051
014001031a731157311a7211940000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000004210102000421010200042100421500000000000b61500000100002b600136152b60013610136100b615000050b61500005136150000000000000000421007200042100720004210042100420004210
011000000b6150b6050b615000001f6150760300000000000b6150000500005000051f6150760500005000050b615000050b615000051f6150760500005000050b6150000500005000051f6152b6052b6002b600
0110000003750037510f750007000f7500f75500700007000a7500a7510b750007000b7500b7550070000700087500875500700007000b7500b75500700007000675006751057500070005750057510375003700
01100000032140321203412034140f2140f2120f4120f4140a2140a2120a4120a4140b2140b2120b4120b414082140821208412084140b2140b2120b4120b4140621406212064120641405214052120541205414
01100000176252360523605180002b625136030c0000c000176250c0050c005240052b6252b6050c0050c00517625240052f605240052b625136051d0000c005176250c00524005240052b6251f6052b6002b600
011000000b6150b6052f605240001361513605136150c0000b61518005136150c005136151f60500005000050b615180052360518005136151f60513615180000b6150b6151361518005136152b6051361513615
01030000157301a7401a7401574015740157301573015730157301572015720157100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000176152b6052b6152b615176152b6052b6152b6150f7500a7520b7520675205752057520575205755176050000517605000052b605376050000500005176050000500005000052b6052b6052b6002b600
011000030c5101a510185102400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018000
01100000032100321500200002000f2100f21500200003000a3100a3150a2150a3000b3100b3150b2150b215082100821500200002000b2100b21500300003000631006315062150030005310053150521505215
01040000055500555005550055500555005551101000e100045500255002550045500455002100021000210002550025500050000500005500055002500025010255102550025500255002550025500255002551
0104000011710117101171011710117101171011710117150c5000050000500005000051000510005100051000510005100051000510025010250002500025000251002510025100251002510025100251002515
011000000f0450f0000f145006050a0450a0400a145006050f0450f04003145090000f0450f1050f1050030500000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000006150061500615000000b616096150b61609616006150061500615000000b616096160b6150961500000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000030400304503105007000f0400f04503105030050a0400a0450a100000000b0400b0450b10500000080400804508105000000b0400b0450b105000000604006045061050000005040050450510505105
011000000b6150b6052f605240001361513605136150c0000b61518005136050c005136151f60500005000050b615180052360518005136151f60513615180000b6150b6051361518005136152b6051360513615
011000000b6150b6150b615240001361513605136150c0000b61518005136150c005136151f60500005000050b615180050b61518005136151f60513615180000b6150b6151361518005136152b6051361513605
0110000003040030450f0450f0400f0400f04503105030050a0400a0450b0450b0400b0400b0450b1050000008040080450b0450b0400b0400b0450b105000000604006045050450504505040050450504505045
0110000003140031450f7450f7400f7400f74503105030050a1400a1450b7450b7400b7400b7450b1050000008140081450b7450b7400b7400b7450b105000000614006145057450574505740057450574505745
0110000003540035450f5450f5450f5400f5450f5450f5450a5400a5450b5450b5450b5400b5450b5450b54508540085450b5450b5450b5400b5450b5450b5450654006545055450554505540055450554505545
0110000003040030450f0050f0000f0400f04503105030050a0400a0450b0450b0400b0400b0450b1050000008040080450b0050b0000b0400b0450b105000000604006045050450504505040050450504505045
010b00000065000655106000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
03 04114040
03 06054040
03 04450c40
03 0d404040
03 0e0d4140
03 0f054040
03 10404040
03 11044040
03 15114040
03 18194040
03 1a1b4040
03 1a1c4040
03 1d114040
03 1e114040
03 1f114140
03 20114040
00 00000000
00 00000000
00 01000000
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

