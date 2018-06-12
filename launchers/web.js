//document.addEventListener("deviceready", () => {
document.addEventListener("DOMContentLoaded", () => {
  const canvas = document.querySelector("canvas");

  const vh = v => (v * window.innerHeight) / 100;
  const vw = v => (v * window.innerWidth) / 100;
  const vmin = v => Math.min(vh(v), vw(v));

  let highScore = JSON.parse(
    localStorage.getItem("highScore") || null
  );

  canvas.width = vmin(100);
  canvas.height = vmin(100);

  pico8.gpio(0x5f80, { set: () => scene("canvas") });

  input.down(pico8.pushX);
  input.up(pico8.releaseX);

  const filename = !!window.location.href.match(/2$/)
    ? "js/disk2.js"
    : "js/disk1.js";

  cart(filename).then(() => {
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
  });
});

