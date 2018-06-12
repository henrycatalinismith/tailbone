//document.addEventListener("deviceready", () => {
document.addEventListener("DOMContentLoaded", () => {
  const scene = document.querySelector(".Scene");
  const canvas = document.querySelector("canvas");

  const vh = v => (v * window.innerHeight) / 100;
  const vw = v => (v * window.innerWidth) / 100;
  const vmin = v => Math.min(vh(v), vw(v));

  let highScore = JSON.parse(
    localStorage.getItem("highScore") || null
  );

  canvas.width = vmin(100);
  canvas.height = vmin(100);

  pico8.gpio(0x5f80, {
    set: v => {
      scene.classList.remove("Scene--loading");
      scene.classList.add("Scene--canvas");
    },
  });

  const up = () => pico8_buttons[0] = 0;
  const down = () => pico8_buttons[0] = 32;
  const pause = () => Module.pauseMainLoop();
  const resume = () => Module.resumeMainLoop();

  document.body.addEventListener("touchstart", down);
  document.body.addEventListener("touchend", up);

  document.body.addEventListener("mousedown", down);
  document.body.addEventListener("mouseup", up);

  document.body.addEventListener("keydown", event => {
    if (event.keyCode === 32) {
      down();
    }
  });

  document.body.addEventListener("keyup", event => {
    if (event.keyCode === 32) {
      up();
    }
  });

  document.body.addEventListener("pause", pause);
  document.body.addEventListener("resume", resume);

  const filename = !!window.location.href.match(/2$/)
    ? "js/disk2.js"
    : "js/disk1.js";

  const game = document.createElement("script");
  game.src = filename;
  game.onload = () => {
    setTimeout(() => {
      const segments = document.querySelectorAll(".LoadingScreen__segment");
      let count = 0;
      const interval = setInterval(() => {
        if (count > 7) {
          clearInterval(interval);
          return;
        }

        segments[count].style.opacity = 1;
        count++;
      }, 20);
    }, 2000);
  }
  document.head.appendChild(game);
});

