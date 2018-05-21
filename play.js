document.addEventListener("DOMContentLoaded", () => {
  window.Module = {
    canvas: document.querySelector("canvas"),
  };

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
