document.addEventListener("deviceready", () => {
  const canvas = document.querySelector("canvas");

  const vh = v => (v * window.innerHeight) / 100;
  const vw = v => (v * window.innerWidth) / 100;
  const vmin = v => Math.min(vh(v), vw(v));

  let highScore = JSON.parse(
    localStorage.getItem("highScore") || null
  );

  canvas.width = vmin(100);
  canvas.height = vmin(100);

  const GpioArray = function () {
    Array.call(this, 128);
  }

  GpioArray.prototype = Object.create(Array.prototype, {
    length: {
      value: 128,
      writable: false,
    }
  });

  GpioArray.prototype.constructor = GpioArray;

  // 0x5f80
  Object.defineProperty(GpioArray.prototype, 0, {
    set: v => {
      // Module.pico8ToggleSound();
      document.body.classList.remove("loading");
      document.body.classList.add("loaded");
    },
  });

  window.Module = { canvas };
  window.pico8_buttons = [0];
  window.pico8_gpio = new GpioArray();

  const up = () => pico8_buttons[0] = 0;
  const down = () => pico8_buttons[0] = 32;
  const pause = () => Module.pauseMainLoop();
  const resume = () => Module.resumeMainLoop();

  document.body.addEventListener("touchstart", down);
  document.body.addEventListener("touchend", up);
  document.body.addEventListener("pause", pause);
  document.body.addEventListener("resume", resume);

  const game = document.createElement("script");
  game.src = "js/tailbone.js";
  // game.onload = () => Module.pico8ToggleSound();
  document.head.appendChild(game);
});

