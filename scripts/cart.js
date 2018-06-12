window.cart = (body => {
  return filename => new Promise(resolve => {
    const script = document.createElement("script");

    script.src = filename;
    script.onload = () => {
      resolve(c);
    };

    body.appendChild(script);
  });
})(document.body);
