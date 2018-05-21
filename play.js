window.addEventListener("load", () => {
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

  const persist = (hex, name) => {
    Object.defineProperty(GpioArray.prototype, hex-0x5f80, {
      get: () => {
        const value = JSON.parse(localStorage.getItem(name) || null);
        console.log(`get ${name}:${value}`);
        return value;
      },

      set: v => {
        console.log(`set ${name}:${v}`);
        localStorage.setItem(name, v);
      },
    });
  }

  persist(0x5f80, "highScore");

  window.Module = { canvas };
  window.pico8_buttons = [0];
  window.pico8_gpio = new GpioArray();

  document.body.addEventListener("touchstart", () => {
    pico8_buttons[0] = 32;
  });

  document.body.addEventListener("touchend", () => {
    pico8_buttons[0] = 0;
  });

  const game = document.createElement("script");
  game.src = "tailbone.js";
  document.head.appendChild(game);
});

