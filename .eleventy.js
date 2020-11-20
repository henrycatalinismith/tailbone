const fs = require("fs")

module.exports = function(eleventyConfig) {
  eleventyConfig.on(
    "afterBuild",
    function() {
      fs.copyFileSync(
        "./index.html",
        "./_site/index.html",
      )
    }
  )
  eleventyConfig.addPassthroughCopy("images")
}

