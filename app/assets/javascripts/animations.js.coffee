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
        NProgress.start()
        console.log user
        console.log user.email
        user_email = user.email
        iam_authenticated = firebase
        db_auth = firebase.database().ref()
        obliged_email = "#{user_email}".replace(/\./g,'|')
        console.log obliged_email
        db_auth.once 'value', (snapshot) ->
          if !snapshot.hasChild(obliged_email)
            $(".no-animations").css('display', 'block')
            console.log "No data for show."
          else
            getAllPathsForEmail(user_email)
        $('.profile-image').attr 'src', user.photoURL
        $('.profile-name').text user.displayName
      else
        window.location = '/'
      return
    return

getAllPathsForEmail = (email) ->
  data = {}
  data.user_email = email

  onError = (jqXHR, textStatus, errorThrown) ->
    console.log jqXHR
    # $.notify("#{result.responseText}", "error")
    false

  onSuccess = (data, textStatus, jqXHR) ->
    console.log data
    # console.log animationPath
    if data.length > 0
      data.forEach (animation) ->
        if animation.progress == 1
          console.log animation.progress
          videoJSHtml = "
            <div class='card'>
              <div class='content'>
                <div class='header'>#{animation.name}</div>
                <div class='meta'>Frames: #{animation.image_count}</div>
                <div class='description'>
                  <div class='ui active centered inline loader'></div>
                </div>
              </div>
            </div>
          "
          $(".row-10 > .ui").append(videoJSHtml) 
        else
          videoJSHtml = "
            <div class='card'>
              <div class='content'>
                <div class='header'>#{animation.name}</div>
                <div class='meta'>Frames: #{animation.image_count}, Date: #{moment.unix(animation.unix_time).format("MM/DD/YYYY HH-mm-ss")}, File size: #{animation.file_size}</div>
                <div class='description'>
                  <video
                      id='my-player-#{animation.id}'
                      class='video-js my-animate'
                      controls
                      preload='auto'
                      poster=''
                      data-setup='{}'>
                    <source src='#{animation.path}' type='video/mp4'></source>
                  </video>
                </div>
              </div>
            </div>
          "
          $(".row-10 > .ui").append(videoJSHtml)
          videojs("my-player-#{animation.id}")
    else
      $.notify("You have no animations.", "info");
    NProgress.done()
    true

  settings =
    cache: false
    dataType: 'json'
    data: data
    error: onError
    success: onSuccess
    type: "GET"
    url: "/load_animation_path"

  $.ajax(settings)

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

window.initializeAnimations = ->
  moment.locale()
  startAuth()
  onLoad()
  onSignOut()
