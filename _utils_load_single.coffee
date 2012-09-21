fs = require "fs"
orient = require "orientdb"
assert = require "assert"

filename = process.argv[2]
catalog = process.argv[3]

server = new orient.Server
  host: "localhost"
  port: 2424

db = new orient.GraphDb "presentz", server,
  user_name: "admin"
  user_password: "admin"

db.open (err) ->
  assert(!err, err)

  db.command "select from V where _type = 'catalog' and id = '#{catalog}'", (err, results) ->
    assert(!err, err)
    
    catalog = results[0]
    
    db.command "select from V where _type = 'user' and twitter_id = '1861911'", (err, results) ->
      assert(!err, err)
  
      user = results[0]

      fs.readFile filename, "utf-8", (err, presentation) ->
        assert(!err, err)

        presentation = JSON.parse presentation
        presentation._type = "presentation"
        presentation.published = true
        presentation.id = filename.substr(0, filename.indexOf(".json"))

        chapters = presentation.chapters
        delete presentation.chapters

        for chapter, chapter_index in chapters
          chapter._type = "chapter"
          chapter._index = chapter_index
          for slide in chapter.media.slides
            slide._type = "slide"

        db.createVertex presentation, (err, presentation) ->
          assert(!err, err)
          db.createEdge user, presentation, { label: "authored" }, (err) ->
            assert(!err, err)
            
            db.createEdge presentation, catalog, { label: "part_of" }, (err) ->
              assert(!err, err)

              link_chapters_to_pres= (chapters, presentation) ->
                return if chapters.length is 0

                chapter = chapters.pop()
                chapter.video = chapter.media.video
                slides = chapter.media.slides
                delete chapter.media

                db.createVertex chapter, (err, chapter) ->
                  assert(!err, err)
                  
                  db.createEdge chapter, presentation, { label: "chapter_of" }, (err) ->
                    assert(!err, err)
                    
                    link_slides_to_chapter= (slides, chapter) ->
                      return link_chapters_to_pres chapters, presentation if slides.length is 0

                      slide = slides.pop()

                      db.createVertex slide, (err, slide) ->
                        assert(!err, err)
                        db.createEdge slide, chapter, { label: "slide_of" }, (err) ->
                          assert(!err, err)
                          link_slides_to_chapter slides, chapter

                    link_slides_to_chapter slides, chapter

              link_chapters_to_pres chapters, presentation
