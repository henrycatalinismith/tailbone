tailbone
--------

Skateboarding dinosaur game inspired by the Chrome offline page.

<table>
  <tbody>
    <tr>
      <td rowspan="3">
        <img
          alt="Video of gameplay showing the dinosaur repeatedly jumping on cactuses and destroying them while dodging lava pits and meteors"
          src="https://henrycatalinismith.github.io/tailbone/videos/demo-128x128.gif"
        />
      </td>
      <td>
        <a href="https://henrycatalinismith.github.io/tailbone">
          🎮 &nbsp;play the web version
        </a>
      </td>
    </tr>
    <tr>
      <td>
        <a href="https://apps.apple.com/us/app/tailbone/id1391852488">
          🎮 &nbsp;play the iOS app
        </a>
      </td>
    </tr>
    <tr>
      <td>
        <a href="https://www.lexaloffle.com/bbs/?tid=39335">
          🎮 &nbsp;play it on the Lexaloffle BBS
        </a>
      </td>
    </tr>
  </tbody>
</table>

Controls
--------

1. While rolling, tap once to jump.
2. While jumping, tap again and hold for more air time.
3. Release the second tap to slam.

Tapping anywhere on the screen works. Pressing space, x, or clicking the left
mouse button also counts as a tap.

Gameplay
--------

Use your slam attack to skate and destroy. Charge up your special bar by doing
combos of multiple slams without touching the floor between each one. Every time
you fill up your special bar, you get a score bonus and the difficulty
increases.

About
-----

Tailbone's my first ever proper action game. I built it right after I discovered
PICO-8. The PICO-8 platform and community are fantastic and I hope publishing
this code helps other folks who want to try shipping their PICO-8 games to the
App Store. I know it's a common question.

The `index.html` file in this repo is where the actual game lives. The PWA and
the iOS app are both running off that same file. For the web version, I've
avoided the audio autoplay issues by adding a splash screen which delays loading
the PICO-8 runtime until the user clicks "play". For the iOS version, this isn't
necessary thanks to the empty `mediaTypesRequiringUserActionForPlayback` in the
Swift code, so the game loads immediately. There are comments in the Swift code
that'll help you figure that out if you wanna copy it.

License
-------

[![License: CC0-1.0](https://licensebuttons.net/l/zero/1.0/80x15.png)](http://creativecommons.org/publicdomain/zero/1.0/)

Please copy as much of this as you need if you find something here that helps
you ship your game. No need to worry about licensing or attribution or any of
that!

