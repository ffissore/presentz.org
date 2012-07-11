fs = require "fs"
orient = require "orientdb"
_s = require "underscore.string"

config = require "./config.development"

server = new orient.Server
  host: config.storage.server.host
  port: config.storage.server.port

db = new orient.GraphDb "presentz", server,
  user_name: config.storage.db.user_name
  user_password: config.storage.db.user_password

db.open ->
  db.createVertex { _type: "root" }, (err, root) ->
    user =
      _type: "user"
      name: "Federico Fissore"
      twitter_id: 1861911
      link: "https://twitter.com/fridrik"
      email: "federico@fsfe.org"

    db.createVertex user, (err, user) ->
      db.createEdge root, user, { label: "user" }, (err, edge) ->
        catalogs = [ "demo", "iad11", "jugtorino", "codemotion12" , "presentations" ]

        load_presentations_for= (user, catalogs) ->
          return db.close() if catalogs.length is 0

          catalog_folder = catalogs.pop()
          fs.readdir catalog_folder, (err, files) ->
            link_user_to_pres= (user, catalog, presentations) ->
              return load_presentations_for user, catalogs if presentations.length is 0

              presentation = presentations.pop()
              chapters = presentation.chapters
              delete presentation.chapters

              db.createVertex presentation, (err, presentation) ->
                db.createEdge user, presentation, { label: "authored" }, ->
                  db.createEdge presentation, catalog, { label: "part_of" }, ->

                    link_chapters_to_pres= (chapters, presentation) ->
                      return link_user_to_pres user, catalog, presentations if chapters.length is 0

                      chapter = chapters.pop()
                      chapter.video = chapter.media.video
                      slides = chapter.media.slides
                      delete chapter.media

                      db.createVertex chapter, (err, chapter) ->
                        db.createEdge chapter, presentation, { label: "chapter_of" }, ->

                          link_slides_to_chapter= (slides, chapter) ->
                            return link_chapters_to_pres chapters, presentation if slides.length is 0

                            slide = slides.pop()

                            db.createVertex slide, (err, slide) ->
                              db.createEdge slide, chapter, { label: "slide_of" }, ->
                                link_slides_to_chapter slides, chapter

                          link_slides_to_chapter slides, chapter

                    link_chapters_to_pres chapters, presentation

            fs.readFile "#{catalog_folder}/catalog.json", "utf-8", (err, catalog) ->
              catalog = JSON.parse catalog
              catalog._type = "catalog"
              catalog.id = catalog_folder

              db.createVertex catalog, (err, catalog) ->
                db.createEdge root, catalog, { label: "catalog" }, ->
                  db.createEdge user, catalog, { label: "admin_of" }, ->
                    presentations_files = (file for file in files when !_s.startsWith(file, "catalog") and _s.endsWith(file, ".json"))
                    presentations = []
                    aliases = 0

                    make_presentation= (file, presentations) ->
                      fs.readFile "#{catalog_folder}/#{file}", "utf-8", (err, presentation) ->
                        presentation = JSON.parse presentation
                        if presentation.alias_of?
                          aliases++
                        else
                          presentation._type = "presentation"
                          presentation.id = file.substr(0, file.indexOf(".json"))
                          for chapter_index in [0...presentation.chapters.length]
                            chapter = presentation.chapters[chapter_index]
                            chapter._type = "chapter"
                            chapter._index = chapter_index
                            for slide in chapter.media.slides
                              slide._type = "slide"
                          presentations.push presentation

                        link_user_to_pres(user, catalog, presentations) if (presentations.length + aliases) is presentations_files.length

                    make_presentation(file, presentations) for file in presentations_files

        load_presentations_for user, catalogs