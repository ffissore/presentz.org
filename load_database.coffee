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
      db.createEdge root, user, ->

        fs.readdir "demo", (err, files) ->
          files = (file for file in files when !_s.startsWith(file, "catalog") and _s.endsWith(file, ".json"))
          files_done = []
          for file in files
            fs.readFile "demo/#{file}", "utf-8", (err, presentation) ->
              presentation = JSON.parse presentation
              presentation._type = "presentation"

              db.createVertex presentation, (err, presentation) ->
                delete user["@version"]
                db.createEdge user, presentation, ->
                  files_done.push file
                  db.close() if files_done.length is files.length
