document.addEventListener("DOMContentLoaded", () => {
  document.body.addEventListener("touchstart", () => {
    console.log('touchstart!');
  });

  document.body.addEventListener("touchend", () => {
    console.log('touchend!');
  });
});
