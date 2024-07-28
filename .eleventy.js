import fs from "fs"

export default function(eleventyConfig) {
  eleventyConfig.addPassthroughCopy("_headers")
  eleventyConfig.addPassthroughCopy("images/*.png")
  eleventyConfig.addPassthroughCopy("manifest.webmanifest")
  eleventyConfig.addPassthroughCopy("videos")

  eleventyConfig.on(
    "afterBuild",
    function() {
      fs.copyFileSync(
        "./tailbone.html",
        "./_site/tailbone.html",
      )
      fs.mkdirSync("./_sitedisk2")
      fs.copyFileSync(
        "./disk2/index.html",
        "./_site/disk2/index.html",
      )
    }
  )
}

