everyauth = require "everyauth"

merge_facebook_user_data = (user, fb_user) ->
  user.name ?= fb_user.name
  user.email ?= fb_user.email
  user.link ?= fb_user.link

merge_twitter_user_data = (user, twitter_user) ->
  user.name ?= twitter_user.name || twitter_user.screen_name
  user.twitter_id ?= twitter_user.id
  user.link ?= "https://twitter.com/#{twitter_user.screen_name}"

create_or_update_user = (db, session, user_data, merge, promise) ->
  save= (doc) ->
    db.save doc, (err, document) ->
      return promise.fail(err) if err?
      promise.fulfill
        id: document["@rid"]

  if session.auth? && session.auth.userId?
    db.loadRecord session.auth.userId, (err, user) ->
      merge user, user_data
      save user
  else
    user =
      "@class": "User"
    merge user, user_data
    save user

facebook_init = (config, db) ->
  everyauth.facebook.appId(config.auth.facebook.app_id).appSecret(config.auth.facebook.app_secret).findOrCreateUser(
    (session, accessToken, accessTokenExtra, fb_user) ->
      promise = @Promise()

      db.command "SELECT @rid FROM V where _type = 'user' and email = '#{fb_user.email}'", (err, results) ->
        return promise.fail(err) if err?

        if results.length isnt 0
          promise.fulfill
            id: results[0]["@rid"]
        else
          create_or_update_user db, session, fb_user, merge_facebook_user_data, promise

      return promise
  ).redirectPath("/")
  everyauth.facebook.scope("email")

twitter_init = (config, db) ->
  everyauth.twitter.consumerKey(config.auth.twitter.consumer_key).consumerSecret(config.auth.twitter.consumer_secret).findOrCreateUser(
    (session, accessToken, accessSecret, twitter_user) ->
      promise = @Promise()

      db.command "SELECT @rid FROM V where _type = 'user' and twitter_id = '#{twitter_user.id}'", (err, results) ->
        return promise.fail(err) if err?

        if results.length isnt 0
          promise.fulfill
            id: results[0].rid
        else
          create_or_update_user db, session, twitter_user, merge_twitter_user_data, promise

      return promise
  ).redirectPath("/")

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