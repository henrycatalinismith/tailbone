window.input = (body => {
  return {
    down: cb => {
      body.addEventListener("touchstart", cb);
      body.addEventListener("mousedown", cb);
      document.body.addEventListener("keydown", event => {
        (event.keyCode === 32) && cb();
      });
    },

    up: cb => {
      body.addEventListener("touchend", cb);
      body.addEventListener("mouseup", cb);
      document.body.addEventListener("keyup", event => {
        (event.keyCode === 32) && cb();
      });
    },
  };
})(document.body);
