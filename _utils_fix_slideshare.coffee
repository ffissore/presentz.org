"use strict"

fs = require "fs"
assert = require "assert"

filename = process.argv[2]
docid = process.argv[3]
url = process.argv[4]

fs.readFile filename, "utf-8", (err, data) ->
  assert !err, err
  presentation = JSON.parse(data)
  for chapter in presentation.chapters
    for slide in chapter.media.slides when slide.url.indexOf(docid) isnt -1
      slide.public_url = url
      
  fs.writeFile filename, JSON.stringify(presentation), (err) ->
    assert !err, err
