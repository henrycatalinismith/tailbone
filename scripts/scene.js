window.scene = (root => {
  const scenes = ["canvas", "loading", "menu"];
  return name => {
    scenes.forEach(s => {
      console.log(name, s);
      if (name === s) {
        root.classList.add(`Scene--${s}`);
      } else {
        root.classList.remove(`Scene--${s}`);
      }
    });
  };
})(document.querySelector(".Scene"));
