window.addEventListener("load", () => {
  const canvas = document.querySelector("canvas");

  const vh = v => (v * window.innerHeight) / 100;
  const vw = v => (v * window.innerWidth) / 100;
  const vmin = v => Math.min(vh(v), vw(v));

  canvas.width = vmin(100);
  canvas.height = vmin(100);

  window.Module = { canvas };
  window.pico8_buttons = [0];

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
