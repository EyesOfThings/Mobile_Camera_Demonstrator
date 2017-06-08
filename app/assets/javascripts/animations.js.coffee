user_email = undefined
lastSyncDateIs = undefined
api_key = undefined
api_id = undefined
syncIs = undefined
mac_address = undefined
iam_authenticated = undefined

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
            db_auth.child("/#{obliged_email}").once 'value', (snapshot) ->
              mac_address = Object.keys(snapshot.val())[0]
              console.log Object.keys(snapshot.val())[1]
              if Object.keys(snapshot.val())[1] != "evercam"
                animationPath = Object.values(snapshot.val())[1].filePath
                console.log animationPath
                tangRef = storageRef.child("#{animationPath}")
                tangRef.getDownloadURL().then((url) ->
                  console.log url
                  videoJSHtml = "
                    <div class='ui card'>
                      <div class='content'>
                        <div class='header'>Animation</div>
                        <div class='meta'>2 days ago</div>
                        <div class='description'>
                          <video
                              id='my-player'
                              class='video-js'
                              controls
                              preload='auto'
                              poster=''
                              data-setup='{}'>
                            <source src='#{url}' type='video/mp4'></source>
                          </video>
                        </div>
                      </div>
                    </div>
                  "
                  $(".row-10").html(videoJSHtml)
                  videojs('my-player')
                  NProgress.done()
                ).catch (error) ->
                  console.log error
                  return
              else
                $(".no-animations").css('display', 'block')

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

window.initializeAnimations = ->
  moment.locale()
  startAuth()
  onLoad()
  onSignOut()
