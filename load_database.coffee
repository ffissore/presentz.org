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
  db.createVertex {}, (err, root) ->
    user =
      _type: "user"
      name: "Federico Fissore"
      twitter_id: 1861911
      link: "https://twitter.com/fridrik"
      email: "federico@fsfe.org"

    db.createVertex user, (err, user) ->
      db.createEdge root, user, { label: "user" }, ->
        catalogs = [ "demo", "iad11", "jugtorino", "codemotion12" , "presentations" ]

        load_presentations_for = (user, catalogs) ->
          return db.close() if catalogs.length is 0

          catalog = catalogs.pop()
          fs.readdir catalog, (err, files) ->
            link_user_to_pres = (user, presentations) ->
              return load_presentations_for user, catalogs if presentations.length is 0

              db.createVertex presentations.pop(), (err, presentation) ->
                db.createEdge user, presentation, { label: "authored" }, ->
                  link_user_to_pres user, presentations

            files = (file for file in files when !_s.startsWith(file, "catalog") and _s.endsWith(file, ".json"))
            presentations = []
            for file in files
              fs.readFile "#{catalog}/#{file}", "utf-8", (err, presentation) ->
                presentation = JSON.parse presentation
                presentation._type = "presentation"
                presentations.push presentation

                link_user_to_pres(user, presentations) if presentations.length is files.length

        load_presentations_for user, catalogs