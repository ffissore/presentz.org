everyauth = require "everyauth"

merge_facebook_user_data = (user, ext_user) ->
  user.name ?= ext_user.name
  user.user_name ?= ext_user.username || ext_user.id
  user.link ?= ext_user.link
  user.email ?= ext_user.email
  user.facebook_id ?= ext_user.id

merge_twitter_user_data = (user, ext_user) ->
  user.name ?= ext_user.name || ext_user.screen_name
  user.user_name ?= ext_user.screen_name
  user.link ?= "https://twitter.com/#{ext_user.screen_name}"
  user.twitter_id ?= ext_user.id

merge_google_user_data = (user, ext_user) ->
  user.name ?= ext_user.name || ext_user.given_name
  user.user_name ?= ext_user.id
  user.link ?= ext_user.link
  user.google_id ?= ext_user.id

merge_linkedin_user_data = (user, ext_user) ->
  user.name ?= "#{ext_user.firstName} #{ext_user.lastName}"
  user_name_parts = ext_user.publicProfileUrl.split("/")
  user.user_name = user_name_parts[user_name_parts.length - 1]
  user.link ?= ext_user.publicProfileUrl
  user.linkedin_id ?= ext_user.id

merge_github_user_data = (user, ext_user) ->
  user.name ?= ext_user.name or ext_user.login
  user.user_name ?= ext_user.login
  user.link ?= ext_user.html_url
  user.email ?= ext_user.email
  user.github_id ?= ext_user.login

merge_foursquare_user_data = (user, ext_user) ->
  user.name ?= "#{ext_user.firstName} #{ext_user.lastName}"
  user.user_name ?= ext_user.id
  user.email ?= ext_user.contact.email
  user.foursquare_id ?= ext_user.id

create_or_update_user = (db, results, session, user_data, merge_function, promise) ->
  save_callback = (err, user) ->
    return promise.fail(err) if err?
    promise.fulfill
      id: user["@rid"]

  if session.auth? and session.auth.userId?
    rid = session.auth.userId
  else if results.length > 0
    rid = results[0].rid

  if rid?
    db.loadRecord rid, (err, user) ->
      return promise.fail(err) if err?
      merge_function user, user_data
      db.save user, save_callback
  else
    user =
      _type: "user"
    merge_function user, user_data
    db.createVertex user, (err, user) ->
      db.createEdge "#6:0", user, { label: "user" }, (err) ->
        save_callback(err, user)

find_or_create_user = (db, query_tmpl, merge_function) ->
  return (session, accessToken, accessTokenExtra, user_data) ->
    promise = @Promise()

    db.command "#{query_tmpl}'#{user_data.id}'", (err, results) ->
      return promise.fail(err) if err?

      create_or_update_user db, results, session, user_data, merge_function, promise
    return promise

facebook_init = (config, db) ->
  everyauth.facebook.configure
    appId: config.auth.facebook.app_id
    appSecret: config.auth.facebook.app_secret
    scope: "email"
    myHostname: config.hostname
    findOrCreateUser: find_or_create_user(db, "SELECT @rid FROM V where _type = 'user' and facebook_id = ", merge_facebook_user_data)
    redirectPath: "/r/back_to_referer"

twitter_init = (config, db) ->
  everyauth.twitter.configure
    consumerKey: config.auth.twitter.consumer_key
    consumerSecret: config.auth.twitter.consumer_secret
    myHostname: config.hostname
    findOrCreateUser: find_or_create_user(db, "SELECT @rid FROM V where _type = 'user' and twitter_id = ", merge_twitter_user_data)
    redirectPath: "/r/back_to_referer"

google_init = (config, db) ->
  everyauth.google.configure
    appId: config.auth.google.app_id
    appSecret: config.auth.google.app_secret
    scope: "https://www.googleapis.com/auth/userinfo.profile"
    myHostname: config.hostname
    findOrCreateUser: find_or_create_user(db, "SELECT @rid FROM V where _type = 'user' and google_id = ", merge_google_user_data)
    redirectPath: "/r/back_to_referer"

linkedin_init = (config, db) ->
  everyauth.linkedin.configure
    consumerKey: config.auth.linkedin.consumer_key
    consumerSecret: config.auth.linkedin.consumer_secret
    myHostname: config.hostname
    findOrCreateUser: find_or_create_user(db, "SELECT @rid FROM V where _type = 'user' and linkedin_id = ", merge_linkedin_user_data)
    redirectPath: "/r/back_to_referer"

github_init = (config, db) ->
  everyauth.github.configure
    appId: config.auth.github.app_id
    appSecret: config.auth.github.app_secret
    myHostname: config.hostname
    findOrCreateUser: find_or_create_user(db, "SELECT @rid FROM V where _type = 'user' and github_id = ", merge_github_user_data)
    callbackPath: "/auth/github/callback"
    redirectPath: "/r/back_to_referer"

foursquare_init = (config, db) ->
  everyauth.foursquare.configure
    appId: config.auth.foursquare.app_id
    appSecret: config.auth.foursquare.app_secret
    myHostname: config.hostname
    findOrCreateUser: find_or_create_user(db, "SELECT @rid FROM V where _type = 'user' and foursquare_id = ", merge_foursquare_user_data)
    redirectPath: "/r/back_to_referer"

init = (config, db) ->
  everyauth.everymodule.findUserById (userId, callback) ->
    db.loadRecord userId, callback

  everyauth.everymodule.logoutPath "/byebye"

  facebook_init config, db
  twitter_init config, db
  google_init config, db
  linkedin_init config, db
  github_init config, db
  foursquare_init config, db

  return everyauth

socials_prefixes =
  facebook:
    col: "facebook_id"
    prefix: "fb"
  twitter:
    col: "twitter_id"
    prefix: "tw"
  google:
    col: "google_id"
    prefix: "go"
  linkedin:
    col: "linkedin_id"
    prefix: "in"
  github:
    col: "github_id"
    prefix: "gh"
  foursquare:
    col: "foursquare_id"
    prefix: "fs"

put_user_in_locals = (req, res, next) ->
  if req.user?
    user = req.user
    for key, value of socials_prefixes
      user.catalog = "/u/#{value.prefix}/#{user.user_name}" if user[value.col]?

    res.locals.user = user
    user.admin = true if user.twitter_id is 1861911
  next()

exports.init = init
exports.put_user_in_locals = put_user_in_locals
exports.socials_prefixes = socials_prefixes