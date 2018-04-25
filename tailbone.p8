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

  if new_score > score then
    score = ceil(tween(
      old_score, new_score,
      landed, landed + 20
    ))
  else
    old_score = score
  end

  if new_combo_score > combo_score then
    combo_score = ceil(tween(
      old_combo_score, new_combo_score,
      tricked, tricked + 20
    ))
  else
    old_combo_score = combo_score
  end

  move()
  if trick == 'charge' then
    if charge == 0 then
      sfx(7)
    elseif charge == 16 then
      sfx(7)
    end
    charge = charge + 1
  elseif trick == 'grind' and frame % 4 == 0 then
    combo_score = combo_score + 5
  end
end

function _draw()
  -- sky
  x = ceil(sky.offset[1])
  y = ceil(sky.offset[2])
  camera(x, y)
  rectfill(x, y, x + 128, 0, 1)

  for star in all(stars(x)) do
    circfill(star[1], star[2], 0, 6)
  end

  -- cityscape
  x = ceil(cityscape.offset[1])
  y = ceil(cityscape.offset[2])
  camera(x, y)
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

  -- nearground
  x = ceil(nearground.offset[1])
  y = ceil(nearground.offset[2])
  camera(x, y)
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

  for meteor in all(meteors) do
    draw_meteor(meteor)
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

  for biscuit in all(biscuits) do
    draw('biscuit', biscuit)
  end

  if mode == 'play' and alive == false then
    draw_board()
    draw_skull()
  end

  -- ui
  camera(0, 0)

  if mode == 'attract' then
    spr(64, 16, 32, 12, 4)
  end

  if trick == 'charge' then
    --print(charge .. '', 3, 3, 7)
  end

  score_x = 120 - (#(''..score)) * 4

  score_colors = {0,7}

  start_y = 8

  if #combo > 1 then
    last_age = frame - combo[#combo].frame
    slide = max(0, 10 - last_age)
    start_y = (8 - (#combo - 1) * 10) + slide
  end

  n = combo_score
  if alive == false then
    n = max(0, n - flr(((frame-died) / 50) * n))
    if n == 0 then
      combo = {}
    end
  end

  if alive == true and paused == false and mode == 'play' then
    st = ''..time
    x = 56
    if time > 9 then
      bg = {10, 9, 0}
    else
      bg = {2, 8, 7}
      x = 60
    end
    printr(sub(st, 1, 1), x, 24, bg)
    printr(sub(st, 2, -1), x+8, 24, bg)
  end

  if #combo > 0 then
    if combo[1].bailed then
      colors = {0,8}
    elseif combo[1].landed then
      colors = {0,11}
    else
      colors = {0,7}
    end
    printr(''..n, 8, 8, colors)
  end


  for i,t in pairs(combo) do
    x = #(''..combo_score) * 4
    y = start_y + ((i-1) * 10)

    if t.bailed then
      text_colors = {0,8}
    elseif t.landed then
      age = frame - t.landed
      text_colors = {0,11}
      score_colors = {0,11}
    else
      text_colors = {0,12}
    end

    --printr(''..t.score, x, y, {7,0})
    printr(t.text, x + 16, y, text_colors)

    if t.landed and age > 20 then
      del(combo, t)
      combo_score = 0
    end
  end
  printr(score, score_x, 8, score_colors)

  if paused == true and alive == false then
    if frame - died > 60 then
      dead_for = flr(min(frame - died - 60, 40) / 10 * 2)
      sw = ({20,36,52,60,78,92,112,128})[dead_for]
      sspr(0, 64, sw, 32, 0, 32)
    end
  end

end

function input()
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
        actions.meteor()
      elseif trick == 'grind' then
        actions.pop()
      elseif trick == 'meteor' then
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
        actions.meteor()
      elseif trick == 'meteor' then
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

frames_per_beat = 33
frames_per_bar = 128
frames_per_phrase = 254

function bm(n) return ((n-1)*33)/1 end
function bt(n) return n*16 end

mode = 'attract'
level = 1
score = 0
time = 0
old_score = 0
new_score = 0
combo_score = 0
new_combo_score = 0
old_combo_score = 0
landed = nil
tricked = nil
paused = false
alive = false
jump = false
distance = 0
altitude = 0
speed = 0
lift = 0

frame = 0
timeouts = {}
intervals = {}
eventloop = {}
script = {}
combo = {}
skull = {}
board = {}
died = nil
charge_trail = {}
meteor_trail = {}

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
meteor_start_height = 0

shake_frames = 0

cacti = {}
poles = {}
cables = {}
lava = {}
biscuits = {}
meteors = {}
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

foreground = {}
nearground = {}
cityscape = {}
sky = {}

sprites = {
  roll_1 = {  0, 8, 8, 8, 0, false },
  push_1 = {  8, 8, 8, 8, 0, false },
  push_2 = { 16, 8, 8, 8, 0, false },
  push_3 = { 24, 8, 8, 8, 0, false },
  push_4 = { 32, 8, 8, 8, 0, false },
  push_5 = { 40, 8, 8, 8, 0, false },
  push_6 = { 48, 8, 8, 8, 0, false },
  grab_1 =  { 56, 8, 8, 8, 0, false },
  ollie_1 =  { 64, 8, 8, 8, 0, false },

  smile = {  0, 0, 8, 8, 0, false },
  yikes = {  8, 0, 8, 8, 0, false },
  growl = { 16, 0, 8, 8, 0, false },

  tail_0 = { 24, 0, 8, 8, 0, false },
  tail_1 = { 32, 0, 8, 8, 0, false },
  tail_2 = { 40, 0, 8, 8, 0, false },
  tail_3 = { 48, 0, 8, 8, 0, false },
  tail_4 = { 56, 0, 8, 8, 0, false },

  arm = { 64, 0, 8, 8, 0, false },

  board_flat = { 72, 0, 8, 8, 0, false },
  board_high = { 80, 0, 8, 8, 0, false },
  board_half = { 88, 0, 8, 8, 0, false },

  biscuit = { 88, 16, 8, 8, 0, false },

  board_1 = { 72,  0, 8, 8, 0, false },
  board_2 = { 80,  0, 8, 8, 0, false },
  board_3 = { 80, 16, 8, 8, 0, false },
  board_4 = { 80,  0, 8, 8, 0, false, true },
  board_5 = { 72,  0, 8, 8, 0, false, true },
  board_6 = { 80,  0, 8, 8, 0, true, true },
  board_7 = { 80, 16, 8, 8, 0, true },
  board_8 = { 80,  0, 8, 8, 0, true },

  legs_0 = {  0, 8, 8, 8, 0, false },
  legs_1 = {  8, 8, 8, 8, 0, false },
  legs_2 = { 16, 8, 8, 8, 0, false },
  legs_3 = { 24, 8, 8, 8, 0, false },
  legs_4 = { 32, 8, 8, 8, 0, false },
  legs_5 = { 40, 8, 8, 8, 0, false },
  legs_6 = { 48, 8, 8, 8, 0, false },
  legs_7 = { 56, 8, 8, 8, 0, false },
  legs_8 = { 64, 8, 8, 8, 0, false },

  sparks_1 = { 72, 8, 4, 4, 0, false },
  sparks_2 = { 76, 8, 4, 4, 0, false },
  sparks_3 = { 72, 12, 4, 4, 0, false },
  sparks_4 = { 76, 12, 4, 4, 0, false },
  sparks_5 = { 76, 12, 4, 4, 0, false },
  sparks_6 = { 72, 12, 4, 4, 0, false },
  sparks_7 = { 76, 8, 4, 4, 0, false },
  sparks_8 = { 72, 8, 4, 4, 0, false },

  cactus_alive_1 = { 33, 32, 8, 16, 0, false },
  cactus_dead_1 = { 44, 32, 8, 16, 0, false },
  cactus_dead_2 = { 55, 32, 8, 16, 0, false },
  cactus_dead_3 = { 33, 48, 8, 16, 0, false },
  cactus_dead_4 = { 44, 48, 8, 16, 0, false },
  cactus_dead_5 = { 55, 48, 8, 16, 0, false },

  cactus_alive_1 = { 0, 16, 8, 16, 0, false },
  cactus_dead_1 =  { 11, 16, 8, 16, 0, false },
  cactus_dead_2 =  { 22, 16, 8, 16, 0, false },
  cactus_dead_3 =  { 33, 16, 8, 16, 0, false },
  cactus_dead_4 =  { 44, 16, 8, 16, 0, false },
  cactus_dead_5 =  { 55, 16, 8, 16, 0, false },

  cactus_legs = { 64, 24, 8, 8, 0, false },
  cactus_head_1 = { 72, 24, 8, 8, 0, false },
  cactus_head_2 = { 80, 24, 8, 8, 0, false },
  cactus_head_3 = { 88, 24, 8, 8, 0, false },

  skull_1 =  { 64, 16, 8, 8, 0, false },
  skull_2 =  { 72, 16, 8, 8, 0, false },
  skull_3 =  { 64, 16, 8, 8, 0, true, true },
  skull_4 =  { 72, 16, 8, 8, 0, true, true },
}

levels = {
  -- level 1
  {
    'lone_cactus',
    'double_cactus',
    'double_wide',
    'quad_cactus',
    'lava_pool',
  },

  -- level 2
  {
    'volcano_pool',
    'fs_half_volcano_pool',
    'indoor_lake',
    'volcano_lake_runway',
  },

  -- level 3
  {
    'bs_half_volcano_lake',
    'fs_half_volcano_lake',
    'volcano_ocean_runway',
  },

  -- level 4
  {
    --'volcano_ocean_runway_meteor',
    'volcano_deathtrap_runway',
  }
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
  -- lavadubs -
  -- 'double_puddle',
  -- 'double_pool',
  -- 'double_lake',
  -- 'double_ocean',
  -- 'double_deathtrap',
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
  -- ½volcanos -
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

spots = {
  open_road = {
    soundtrack = 9,
    length = bt(4),
  },
  interstate = { length = bt(8) },

  lone_cactus = {
    length = bt(4),
    cacti = { bm(3) },
  },

  twin_cactus = {
    length = bt(4),
    cacti = { bm(3), bm(3.5) },
  },

  fs_half_twin_cactus = {
    length = bt(4),
    cacti = { bm(3) },
  },

  bs_half_twin_cactus = {
    length = bt(4),
    cacti = { bm(3.5) },
  },

  double_cactus = {
    length = bt(4),
    cacti = { bm(3), bm(4) },
  },

  fs_half_double_cactus = {
    length = bt(4),
    cacti = { bm(3) },
  },

  bs_half_double_cactus = {
    length = bt(4),
    cacti = { bm(4) },
  },

  double_wide = {
    length = bt(8),
    cacti = { bm(3), bm(5) },
  },

  fs_half_double_wide = {
    length = bt(8),
    cacti = { bm(3) },
  },

  bs_half_double_wide = {
    length = bt(8),
    cacti = { bm(5) },
  },

  double_lighthouse = {
    length = bt(8),
    cacti = { bm(3), bm(6) },
  },

  fs_half_double_lighthouse = {
    length = bt(8),
    cacti = { bm(3) },
  },

  bs_half_double_lighthouse = {
    length = bt(8),
    cacti = { bm(6) },
  },

  double_clifftop = {
    length = bt(8),
    cacti = { bm(3), bm(8) },
  },

  fs_half_double_clifftop = {
    length = bt(8),
    cacti = { bm(3) },
  },

  bs_half_double_clifftop = {
    length = bt(8),
    cacti = { bm(8) },
  },

  triple_cactus = {
    length = bt(8),
    cacti = { bm(3), bm(7), bm(8) },
  },

  quad_cactus = {
    length = bt(8),
    cacti = { bm(3), bm(4), bm(7), bm(8) },
  },

  lava_puddle = {
    length = bt(4),
    lava = {{ bm(3)+8, bm(3.5) }},
  },

  lava_pool = {
    length = bt(2),
    lava = {{ bm(3)+8, bm(4) }},
  },

  lava_lake = {
    length = bt(4),
    lava = {{ bm(3)+8, bm(5)-2 }},
  },

  lava_ocean = {
    length = bt(8),
    lava = {{ bm(3)+8, bm(6) }},
  },

  lava_deathtrap = {
    length = bt(8),
    lava = {{ bm(3)+8, bm(8) }},
  },

  double_puddle = {
    length = bt(8),
    lava = {
      { bm(3), bm(3.5) },
      { bm(7), bm(7.5) },
    },
  },

  double_pool = {
    length = bt(8),
    lava = {
      { bm(3), bm(4) },
      { bm(7), bm(8) },
    },
  },

  double_lake = {
    length = bt(8),
    lava = {
      { bm(3), bm(5) },
      { bm(7), bm(9) },
    },
  },

  double_ocean = {
    length = bt(16),
    lava = {
      { bm(3), bm(6) },
      { bm(11), bm(14) },
    },
  },

  double_deathtrap = {
    length = bt(16),
    lava = {
      { bm(3), bm(8) },
      { bm(11), bm(16) },
    },
  },

  cactus_lava_gap = {
    length = bt(16),
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

  powerslide = {
    length = bt(8),
    cables = {{ bm(1), bm(3)}}
  },

  double_powerslide = {
    length = bt(8),
    cables = {
      { bm(1), bm(3)},
      { bm(3), bm(5)},
    }
  },

  triple_powerslide = {
    length = bt(8),
    cables = {
      { bm(1), bm(3)},
      { bm(3), bm(5)},
      { bm(5), bm(7)},
    }
  },

  volcano_puddle = {
    length = bt(4),
    layers = {
      {'twin_cactus'},
      {'lava_puddle'},
    }
  },

  volcano_pool = {
    length = bt(4),
    layers = {
      {'double_cactus'},
      {'lava_pool'},
    }
  },

  volcano_lake = {
    length = bt(4),
    biscuits = {
      { bt(2), 48 },
    },
    layers = {
      {'double_wide'},
      {'lava_lake'},
    }
  },

  volcano_ocean = {
    length = bt(8),
    layers = {
      {'double_lighthouse'},
      {'lava_ocean'},
    }
  },

  volcano_deathtrap = {
    length = bt(8),
    layers = {
      {'double_clifftop'},
      {'lava_deathtrap'},
    }
  },

  indoor_lake = {
    length = bt(4),
    layers = {
      {'powerslide'},
      {'lava_lake'},
    }
  },

  indoor_ocean = {
    length = bt(8),
    layers = {
      {'double_powerslide'},
      {'lava_ocean'},
    }
  },

  indoor_volcano_lake = {
    length = bt(4),
    layers = {
      {'double_wide'},
      {'powerslide'},
      {'lava_lake'},
    }
  },

  indoor_volcano_ocean = {
    length = bt(8),
    layers = {
      {'double_lighthouse'},
      {'double_powerslide'},
      {'lava_ocean'},
    }
  },

  lake_runway = {
    length = bt(8),
    layers = {{
      'powerslide',
      'lava_lake',
    }}
  },

  ocean_runway = {
    length = bt(8),
    layers = {{
      'powerslide',
      'lava_ocean'
    }}
  },

  deathtrap_runway = {
    length = bt(8),
    layers = {{
      'powerslide',
      'lava_deathtrap',
    }}
  },

  fs_half_volcano_puddle = {
    length = bt(4),
    layers = {
      {'fs_half_twin_cactus'},
      {'lava_puddle'},
    }
  },

  bs_half_volcano_puddle = {
    length = bt(4),
    layers = {
      {'bs_half_twin_cactus'},
      {'lava_puddle'},
    }
  },

  fs_half_volcano_pool = {
    length = bt(4),
    layers = {
      {'fs_half_double_cactus'},
      {'lava_pool'},
    }
  },

  bs_half_volcano_pool = {
    length = bt(4),
    layers = {
      {'bs_half_double_cactus'},
      {'lava_pool'},
    }
  },

  fs_half_volcano_lake = {
    length = bt(4),
    layers = {
      {'fs_half_double_wide'},
      {'lava_lake'},
    }
  },

  bs_half_volcano_lake = {
    length = bt(4),
    layers = {
      {'bs_half_double_wide'},
      {'lava_lake'},
    }
  },

  fs_half_volcano_ocean = {
    length = bt(8),
    layers = {
      {'fs_half_double_lighthouse'},
      {'lava_ocean'},
    }
  },

  bs_half_volcano_ocean = {
    length = bt(4),
    layers = {
      {'bs_half_double_lighthouse'},
      {'lava_ocean'},
    }
  },

  fs_half_volcano_deathtrap = {
    length = bt(8),
    layers = {
      {'fs_half_double_clifftop'},
      {'lava_deathtrap'},
    }
  },

  bs_half_volcano_deathtrap = {
    length = bt(8),
    layers = {
      {'bs_half_double_clifftop'},
      {'lava_deathtrap'},
    }
  },

  volcano_lake_runway = {
    length = bt(8),
    layers = {{
      'powerslide',
      'lava_lake',
      'bs_half_double_cactus',
    }}
  },

  volcano_ocean_runway = {
    length = bt(8),
    layers = {{
      'powerslide',
      'lava_ocean',
    }},
    cacti = {bm(8)},
  },

  volcano_deathtrap_runway = {
    length = bt(8),
    layers = {{
      'powerslide',
      'lava_deathtrap',
    }},
    cacti = {bm(10)},
  },

  volcano_ocean_runway_meteor = {
    length = bt(8),
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

  apocalypse = {
    length = bt(1),
    meteors = {
      {
        bm(5),
        -push_speed*1,
        push_speed*3,
        17,
      },
    }
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
        x+m[1] - bm(3), --1 x pos
        -128,           --2 y pos
        m[2],           --3 x vec
        m[3],           --4 y vec
        m[4],           --5 radius
        {},             --6 trail
        true,           --7 alive
      })
    end
  end

  for b in all(spot.biscuits) do
    add(biscuits, {
      x + b[1],
      0 - b[2],
    })
  end
  for c in all(spot.cables) do
    add_pole(x + c[1], 32)
    add_pole(x + c[2], 32)
    add_cable(
      x + c[1], -32,
      x + c[2], -32
    )
  end
  for l in all(spot.layers) do
    pplus = distance + 128
    for spot_name in all(l) do
      cue_spot(spots[spot_name], pplus)
      pplus = pplus + spots[spot_name].length / 2
    end
  end
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

function extend_combo(score, text)
  add(combo, {
    text = text,
    frame = frame,
    score = score,
  })
  --combo_score = combo_score + score
  new_combo_score = combo_score+score
  old_combo_score = combo_score
  tricked = frame
end

-->8
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
    elseif trick == 'meteor' then
      --add(eventloop, 'pop')
    end

    if trick == 'meteor' then
      lift = max(meteor_start_height/14, -4.5)
      cactus.burn = true
      extend_combo(50, 'asteroid')
    else
      lift = -3
      cactus.fall = true
      extend_combo(20, 'stomp')
    end

    trick = 'air'
    can_charge = false
    after(16, 'enable_charge')
    altitude = (
      cacti[1].offset[2] -
      cacti[1].size[2] - 4
    )
    --parallax(1)
    cactus.alive = false
    cactus.died = frame
    charge_trail = {}
  end,

  destroy_meteor = function()
    destroying[3] = 0
    destroying[4] = 0

    if trick == 'meteor' then
      lift = max(meteor_start_height/14, -4.5)
      extend_combo(50, 'asteroid')
    else
      lift = -3
      extend_combo(20, 'stomp')
    end

    trick = 'air'
    can_charge = false
  end,

  enable_charge = function()
    can_charge = true
  end,

  gc = function()
    for i,cactus in pairs(cacti) do
      if cactus.offset[1] < foreground.offset[1] then
        del(cacti, i)
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

    for m in all(meteors) do
      if m[1] < foreground.offset[1] then
        del(meteors, m)
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
    if paused == false and alive == true then
      paused = true

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
    end
  end,

  grab = function()
    sfx(8, 3)
    trick = 'grab'
    charge_trail = {}
    --lift = 7
    --meteor_trail = {}
  end,

  impact = function()
    if crashing then
      shake_frames = 20
      del(meteors, crashing)

      add(lava, {
        crashing[1] - crashing[5],
        crashing[1] + crashing[5],
      })

      crashing = nil
    end
  end,

  meteor = function()
    sfx(-1, 3)
    sfx(8, 3)
    trick = 'meteor'
    lift = 7
    meteor_trail = {}
    meteor_start_height = altitude
  end,

  grind = function()
    parallax(2)
    trick = 'grind'
    distance = ceil(distance)
    altitude = groundlevel
    lift = 0
    charge_trail = {}
    meteor_trail = {}
    extend_combo(10, 'powerslide')
  end,

  land = function()
    sfx(-1, 3)
    landed = frame
    charge_trail = {}
    meteor_trail = {}
    if alive then
      if trick == 'meteor' then
        sfx(3, 3)
        shake_frames = 20
      else
        sfx(1, 3)
      end
      trick = 'push'

      time = time + #combo
    end

    level = max(#combo, level)
    level = min(#levels, level)
    --if #combo > 1 and level == 1 then
      --level = 2
    --elseif #combo > 2 and level == 2 then
      --level = 3
    --elseif #combo > 2 and level == 2 then
      --level = 3
    --end

    if #combo > 0 then
      for c in all(combo) do
        c.landed = frame
      end
      old_score = score
      new_score = score+combo_score
      --score = score + combo_score
      --combo = {}
      --combo_score = 0
      sfx(18, 3)
    end
    new_combo_score = 0
    old_combo_score = combo_score

    --parallax(1)
    altitude = 0
    lift = 0
  end,

  music_start = function()
    music(7)
  end,

  music_next = function()
    music(8)
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

  phrase = function()
  end,

  play = function()
    if mode == 'play' then
      return true
    end

    music(7)

    mode = 'play'
    distance = foreground.offset[1] + trex.size[1]

    every(frames_per_beat*2, 'tick')
    every(frames_per_phrase, 'phrase')
    script = {'open_road'}
    pool = medium_pool
    add(eventloop, 'next')
    after(frames_per_phrase/2, 'music_start')
  end,

  release = function()
    trick = 'air'
  end,

  reset = function()
    time = 45
    score = 0
    new_score = 0
    old_score = 0
    combo_score = 0
    new_combo_score = 0
    old_combo_score = 0
    landed = nil
    tricked = nil
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

    cacti = {}
    meteors = {}
    poles = {}
    script = {}
    cables = {}
    lava = {}
    charge_trail = {}
    meteor_trail = {}

    groundlevel = 0
    alive = true
    trex.trick = 'push'
    distance = 0
    altitude = 0
    trex.vector = { push_speed, 0 }
    trex.size = { 16, 16 }
    foreground.offset = { -10, -108 }
    foreground.vector = { speed, 0 }
    foreground.zoom = 1
    nearground.offset = { -10, -104 }
    nearground.vector = { 1, 0 }
    cityscape.offset = { -10, -94 }
    cityscape.vector = { 1, 0 }
    sky.offset = { -10, -108 }
    sky.vector = { 0.5, 0 }
    parallax(2)
    every(60, 'gc')
    cls()
  end,

  tick = function()
    time = max(time - 1, 0)
    if time == 0 then
      --add(eventloop, 'gameover')
      script = {'apocalypse'}
      pool = {'apocalypse'}
    end
  end,
}

-->8
--------------------------------
-- rendering -------------------

function parallax(s)
  foreground.offset[1] = distance - 16
  if s == 0 then
    --speed = 0
    foreground.vector[1] = 0
    nearground.vector[1] = 0
    cityscape.vector[1] = 0
    sky.vector[1] = 0
  elseif s == 1 then
    speed = push_speed
    foreground.vector[1] = speed
    nearground.vector[1] = 0.5
    cityscape.vector[1] = 0.5
    sky.vector[1] = 0.25
  elseif s == 2 then
    speed = 2
    foreground.vector[1] = speed
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
  flip_y = b[7]

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
      --circfill(meteor[1], meteor[2], 2, 7)
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

    cx = x1 - foreground.offset[1]
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
  elseif trick == 'meteor' then
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
        --line(from[1], fl(0), to[1], tl(0), 14)
        --line(from[1], from[2] - 0 + drop, to[1], to[2] - 0 + drop, 14)
      elseif age < 6 then
        circfill(from[1]+5, fl(5), flrrnd(2), 8)
        --circfill(from[1]+4, fl(4), flrrnd(2), 9)
        --circfill(from[1]+3, fl(3), flrrnd(2), 10)
        --circfill(from[1]+2, fl(2), flrrnd(2), 11)
        circfill(from[1]+1, fl(1), flrrnd(2), 12)
        --circfill(from[1], from[2] - 0+drop, flrrnd(2), 14)
      end

      if age > 6 then
        del(charge_trail, t)
      end

    end
  end

  for t in all(meteor_trail) do
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

  if mode == 'play' then
    for m in all(meteors) do
      mh = hitboxes.meteor(m)
      if intersect(t, mh) then
        destroying = m
        if jump or trick == 'charge' or trick == 'meteor' then
          m[7] = false
          m[8] = frame
          add(eventloop, 'destroy_meteor')
        elseif m[7] and alive == true then
          add(eventloop, 'gameover')
        end
      end
    end

    for m in all(meteors) do
      if m[2] > 0 then
        crashing = m
        add(eventloop, 'impact')
      end
    end

    for m in all(meteors) do
      add(m[6], {m[1], m[2], frame})
      m[1] = m[1] + m[3]
      m[2] = m[2] + m[4]
    end
  end

  if mode == 'play' and paused == false then
    t = hitboxes.trex()
    for cactus in all(cacti) do
      c = hitboxes.cactus(cactus)
      if intersect(t, c) then
        if jump or trick == 'charge' or trick == 'meteor' then
          if jump then
            can_charge = false
          end
          actions.destroy_cactus(cactus)
        elseif cactus.alive == true then
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

  end
end



function gravity()
  if alive == false then
    if skull.offset[2] < groundlevel then
      skull.vector[2] = skull.vector[2] + 0.25
    end
    if board.offset[2] < groundlevel then
      board.vector[2] = board.vector[2] + 0.25
    end
  end

  if altitude >= groundlevel then
    return
  end

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
  elseif trick == 'meteor' then
    speedup = false
    nearest = true
    height = 0-altitude
    for c in all(cacti) do
      ahead = c.offset[1] > distance
      if ahead == true then
        gap = c.offset[1] - distance
        if nearest == true then

          if gap < 32 and height > 32 then
            lift = 8
            speedup = true
          elseif gap < 8 and height > 64 then
            lift = 9
            speedup = true
          elseif gap < 8 and height > 20 then
            lift = 4
            speedup = true
          elseif gap < 4 and height > 10 then
            lift = 5
            speedup = true
          end
          nearest = false
        end
      end
    end
    if speedup == false then
      lift = 3
    end
  else
    --drop
    lift = min(
      lift + 0.95 * air,
      2.5
    )
  end
end

function update_groundlevel()
  tx = distance
  tx1 = distance
  tx2 = distance + trex.size[1]
  ty = altitude -- trex.size[2]

  for c in all(cables) do
    x1 = c[1]
    y1 = c[2]
    x2 = c[3]
    y2 = c[4]
    if tx+8 >= x1 and tx <= x2 then
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
    if trick == 'meteor' then
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

function move()
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
    return
  end

  distance = ceil(distance + speed)
  if trick == 'push' and groundlevel > 0 then
    altitude = altitude + 3
    actions.gameover()
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

  if trick == 'meteor' and flr(distance) % 2 == 0 and altitude < -8 then
    add(meteor_trail, {
      distance,
      altitude,
      frame,
    })
  end

end



-->8
--------------------------------
-- timekeeping -----------------

function dispatch(action)
  if actions[action] ~= nil then
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

function tween(from, to, first_frame, last_frame)
  frame_count = last_frame - first_frame
  value_space = to - from
  per_frame = value_space / frame_count
  frames_now = frame - first_frame
  return from + (per_frame * frames_now)
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00800000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00800000008000080080000800000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00880008008800880088008808000088080000080008888888888800000000000000000000000000000000000000000000000000000000000000000000000000
00888888008888880088888808888888088888880888888888888880000000000000000000000000000000000000000000000000000000000000000000000000
00888888008888880088888800888888008888888888888888875880000000000000000000000000000000000000000000000000000000000000000000000000
000888880008888800088888000888880008888888888888888c5880000000000000000000000000000000000000000000000000000000000000000000000000
00008888000088880000888800008888000088888888800808888880000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000008880880808888800000000000000000000000000000000000000000000000000000000000000000000000000
0000d00000000000000000000000d000000000008800080008888000000000000000000000000000000000000000000000000000000000000000000000000000
0000d00000000000000000000000d000000000008880000008888000000000000000000000000000000000000000000000000000000000000000000000000000
0000d00000000000000000000000d000000000000888800000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
000100000d51001510015200152001530015300254003540035400454004540055500555006530095200a52007200062000020000200002000020000200002000020000200002000020000200002000020000200
0102000009010090100901009010026000260002600016000160005600016000b6000e600086010460104605026000060009600046000260009600036000a6000860004600006000860006600066000560000000
0000000001200062000e5200e5300f5400f5400f5400f540095500955009540095400954005540055400554005530055200552001520015200152001520015200151001510042000220001200012001020000000
01040000015100151001510005100051000510015000150001500015000150001500015001b000100001300016000190001c00021000260002b0002d0001b00020000260002c00034000380003d0003f0003f400
01100000037500375500700007000f7500f75500700007000a7500a75516700007000b7500b7550070000700087500875500700007000b7500b75500700007000675006755007000070005750057550030000300
01100000176251760517625000002b625376030000000000176250000500005000052b6452b6050000500005176250000517625000052b625376050000500005176250000500005000052b6452b6002b6452b645
01100000037540375203752037550f7540f7520f7520f7550a7540a7520a7520a7550b7540b7520b7520b755087540875208752087550b7540b7520b7520b7550675406752067520675505754057520575205755
01100000017140b7120b712067130b003020000200001000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000d01101011000151000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000019000000000000000000000000000000000
010201200101203012010120301201012030120101203012010120301201012030120101203012010120301201012030120101203012010120301201012030120101203012010120301201012030120101203012
010200000101001011010110101101021010210102101021030210302103021030210303103031030310303106031060310603106031060410604106041060410804108041080410804108051080510805108051
014001031a731157311a7211940000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000004210102000421010200042100421500000000001000000000100002b600136102b600136101361011000110001100000000000000000000000000000421007200042100720004210042100420004210
011000000b6150b6050b615000001f6150760300000000000b6150000500005000051f6150760500005000050b615000050b615000051f6150760500005000050b6150000500005000051f6152b6052b6002b600
0110000003750037510f750007000f7500f75500700007000a7500a7510b750007000b7500b7550070000700087500875500700007000b7500b75500700007000675006751057500070005750057510375003700
01100000032140321203412034140f2140f2120f4120f4140a2140a2120a4120a4140b2140b2120b4120b414082140821208412084140b2140b2120b4120b4140621406212064120641405214052120541205414
01100000176252360523605180002b625136030c0000c000176250c0050c005240052b6252b6050c0050c00517625240052f605240052b625136051d0000c005176250c00524005240052b6251f6052b6002b600
011000000b6150b6052f605240001361513605136150c0000b61518005136150c005136151f60500005000050b615180052360518005136151f60513615180000b615180051361518005136152b6052b6002b600
01030000157301a7401a7401574015740157301573015730157301572015720157100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000176152b6052b6152b615176152b6052b6152b6150f7500a7520b7520675205752057520575205755176050000517605000052b605376050000500005176050000500005000052b6052b6052b6002b600
011000030c5101a510185102400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018000
01100000032100321500200002000f2100f21500200003000a3100a3150a2150a3000b3100b3150b2150b215082100821500200002000b2100b21500300003000631006315062150030005310053150521505215
01040000055500555005550055500555005551101000e100045500255002550045500455002100021000210002550025500050000500005500055002500025010255102550025500255002550025500255002551
0104000011710117101171011710117101171011710117150c5000050000500005000051000510005100051000510005100051000510025010250002500025000251002510025100251002510025100251002515
0110000000605006050c6250060500625006250062500605006250062500625006050c6250c6050c6250030500000000000000000000000000000000000000000000000000000000000000000000000000000000
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
03 04114040
03 06054040
03 04050c40
03 0d404040
03 0e0d4140
03 0f054040
03 10404040
03 11044040
03 15114040
03 18404040
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

