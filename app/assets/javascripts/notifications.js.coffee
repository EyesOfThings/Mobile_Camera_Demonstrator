user_email = undefined
lastSyncDateIs = undefined
api_key = undefined
api_id = undefined
syncIs = undefined
mac_address = undefined
iam_authenticated = undefined

getObjectKeyIndex = (obj, keyToFind) ->
  i = 0
  key = undefined
  for key of obj
    `key = key`
    if key == keyToFind
      return i
    i++
  null

window.startAuth = ->
  config = 
    apiKey: AuthData.apiKey
    authDomain: AuthData.authDomain
    databaseURL: AuthData.databaseURL
    storageBucket: AuthData.storageBucket

  window.firebase.initializeApp config
  window.storage = firebase.storage()
  window.storageRef = storage.ref()

sendAJAXRequest = (settings) ->
  token = $('meta[name="csrf-token"]')
  if token.size() > 0
    headers =
      "X-CSRF-Token": token.attr("content")
    settings.headers = headers
  xhrRequestChangeMonth = jQuery.ajax(settings)
  true

onLoad = ->
  $(window).load ->
    firebase.auth().onAuthStateChanged (user) ->
      if user
        console.log user.email
        user_email = user.email
        iam_authenticated = firebase
        db_auth = firebase.database().ref()
        obliged_email = "#{user_email}".replace(/\./g,'|')
        console.log obliged_email

        $('.profile-image').attr 'src', user.photoURL
        $('.profile-name').text user.displayName
      else
        window.location = '/'
      return
    return

onSignOut = ->
  $(".signout").on "click", ->
    firebase.auth().signOut().then(->
      # Sign-out successful.
      window.location = '/'
      console.log "signed out"
      return
    ).catch (error) ->
      # An error happened.
      return

window.initializeNotifications = ->
  moment.locale()
  startAuth()
  onLoad()
  onSignOut()
