const sharp = require("sharp")

module.exports = function(eleventyConfig) {
  eleventyConfig.addPassthroughCopy("index.html")
  eleventyConfig.addPassthroughCopy("images")

  sharp("./Assets.xcassets/AppIcon.appiconset/1024.png")
    .resize(192)
    .toFile(`./images/touch-icon-192x192.png`)

  ;([57, 180, 152, 144, 120, 114, 76, 72]).forEach(n => {
    sharp("./Assets.xcassets/AppIcon.appiconset/1024.png")
      .resize(n)
      .toFile(`./images/apple-touch-icon-${n}x${n}.png`)
  })
}

