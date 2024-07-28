import fs from "fs"

export default function(eleventyConfig) {
  eleventyConfig.addPassthroughCopy("_headers")
  eleventyConfig.addPassthroughCopy("images/*.png")
  eleventyConfig.addPassthroughCopy("manifest.webmanifest")
  eleventyConfig.addPassthroughCopy("videos")

  eleventyConfig.on(
    "afterBuild",
    function() {
      fs.mkdirSync("./_site/play")
      fs.copyFileSync(
        "./play/index.html",
        "./_site/play/index.html",
      )
      fs.mkdirSync("./_site/disk2")
      fs.copyFileSync(
        "./disk2/index.html",
        "./_site/disk2/index.html",
      )
    }
  )
}

