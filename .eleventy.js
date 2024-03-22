const pwa = require("eleventy-plugin-pwa")
const fs = require("fs")

module.exports = function(eleventyConfig) {
  eleventyConfig.addPassthroughCopy("_headers")
  eleventyConfig.addPassthroughCopy("images/*.png")
  eleventyConfig.addPassthroughCopy("manifest.webmanifest")
  eleventyConfig.addPassthroughCopy("videos")

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
      fs.mkdirSync("./_site/disk2")
      fs.copyFileSync(
        "./disk2/index.html",
        "./_site/disk2/index.html",
      )
    }
  )
}

