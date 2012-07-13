everyauth = require "everyauth"

merge_facebook_user_data = (user, fb_user) ->
  user.name ?= fb_user.name
  user.email ?= fb_user.email
  user.link ?= fb_user.link
  user.facebook_id ?= fb_user.id

merge_twitter_user_data = (user, twitter_user) ->
  user.name ?= twitter_user.name || twitter_user.screen_name
  user.link ?= "https://twitter.com/#{twitter_user.screen_name}"
  user.twitter_id ?= twitter_user.id

create_or_update_user = (db, session, user_data, merge_function, promise) ->
  save = (user) ->
    db.createVertex user, (err, user) ->
      db.loadRecord "#6:0", (err, root) ->
        db.createEdge root, user, { label: "user" }, (err) ->
          return promise.fail(err) if err?
          promise.fulfill
            id: user["@rid"]

  save_callback = (err, user) ->
    return promise.fail(err) if err?
    promise.fulfill
      id: user["@rid"]

  if session.auth? and session.auth.userId?
    db.loadRecord session.auth.userId, (err, user) ->
      return promise.fail(err) if err?
      merge_function user, user_data
      db.save user, save_callback
  else
    user =
      _type: "user"
    merge_function user, user_data
    db.createVertex user, (err, user) ->
      db.loadRecord "#6:0", (err, root) ->
        db.createEdge root, user, { label: "user" }, (err) ->
          save_callback(err, user)

find_or_create_user = (db, query_tmpl, merge_function) ->
  return (session, accessToken, accessTokenExtra, user_data) ->
    promise = @Promise()

    db.command "#{query_tmpl}'#{user_data.id}'", (err, results) ->
      return promise.fail(err) if err?

      if results.length isnt 0
        promise.fulfill
          id: results[0].rid
      else
        create_or_update_user db, session, user_data, merge_function, promise

    return promise

facebook_init = (config, db) ->
  everyauth.facebook.configure
    appId: config.auth.facebook.app_id
    appSecret: config.auth.facebook.app_secret
    findOrCreateUser: find_or_create_user(db, "SELECT @rid FROM V where _type = 'user' and facebook_id = ", merge_facebook_user_data)
    scope: "email"
    redirectPath: "/r/back_to_referer"

twitter_init = (config, db) ->
  everyauth.twitter.configure
    consumerKey: config.auth.twitter.consumer_key
    consumerSecret: config.auth.twitter.consumer_secret
    findOrCreateUser: find_or_create_user(db, "SELECT @rid FROM V where _type = 'user' and twitter_id = ", merge_twitter_user_data)
    redirectPath: "/r/back_to_referer"

exports.init = (config, db) ->
  everyauth.everymodule.findUserById (userId, callback) ->
    db.loadRecord userId, callback

  facebook_init config, db
  twitter_init config, db

  return everyauth

exports.expose_user = (req, res, next) ->
  if req.user?
    res.locals.user = req.user
  next()