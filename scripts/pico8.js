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

  _pico8.gpio = (pin, { get, set }) => {
    Object.defineProperty(
      GpioArray.prototype,
      0x5f80 - pin,
      { get, set }
    );
  };

  window.Module = { canvas };
  window.pico8_buttons = [0];
  window.pico8_gpio = new GpioArray();

  return _pico8;
})(document.querySelector("canvas"));

