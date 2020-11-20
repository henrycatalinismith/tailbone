const pwa = require("eleventy-plugin-pwa")
const fs = require("fs")

module.exports = function(eleventyConfig) {
  eleventyConfig.addPassthroughCopy("images")
  eleventyConfig.addPassthroughCopy("manifest.webmanifest")

  eleventyConfig.addPlugin(pwa, {
    swDest: "./_site/sw.js",
  })

  eleventyConfig.on(
    "afterBuild",
    function() {
      fs.copyFileSync(
        "./index.html",
        "./_site/index.html",
      )
    }
  )
}

