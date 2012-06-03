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

        load_presentations_for = (user, catalogs) ->
          return db.close() if catalogs.length is 0

          catalog_folder = catalogs.pop()
          fs.readdir catalog_folder, (err, files) ->
            link_user_to_pres = (user, catalog, presentations) ->
              return load_presentations_for user, catalogs if presentations.length is 0

              db.createVertex presentations.pop(), (err, presentation) ->
                db.createEdge user, presentation, { label: "authored" }, ->
                  db.createEdge presentation, catalog, { label: "part_of" }, ->
                    link_user_to_pres user, catalog, presentations

            fs.readFile "#{catalog_folder}/catalog.json", "utf-8", (err, catalog) ->
              catalog = JSON.parse catalog
              catalog._type = "catalog"
              catalog.id = catalog_folder

              db.createVertex catalog, (err, catalog) ->
                db.createEdge root, catalog, { label: "catalog" }, ->
                  db.createEdge user, catalog, { label: "admin_of" }, ->
                    presentations_files = (file for file in files when !_s.startsWith(file, "catalog") and _s.endsWith(file, ".json"))
                    presentations = []

                    make_presentation = (file, presentations) ->
                      fs.readFile "#{catalog_folder}/#{file}", "utf-8", (err, presentation) ->
                        presentation = JSON.parse presentation
                        presentation._type = "presentation"
                        presentation.id = file.substr(0, file.indexOf(".json"))
                        presentations.push presentation

                        link_user_to_pres(user, catalog, presentations) if presentations.length is presentations_files.length
                    
                    make_presentation(file, presentations) for file in presentations_files

        load_presentations_for user, catalogs