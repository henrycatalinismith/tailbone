window.pico8 = (canvas => {
  const _pico8 = {};

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

  window.Module = { canvas };
  window.pico8_buttons = [0];
  window.pico8_gpio = new GpioArray();

  _pico8.gpio = (pin, { get, set }) => {
    Object.defineProperty(
      GpioArray.prototype,
      0x5f80 - pin,
      { get, set }
    );
  };

  _pico8.pause = () => Module.pauseMainLoop();
  _pico8.resume = () => Module.resumeMainLoop();

  _pico8.pushX = () => pico8_buttons[0] = 32;
  _pico8.releaseX = () => pico8_buttons[0] = 0;

  return _pico8;
})(document.querySelector("canvas"));

