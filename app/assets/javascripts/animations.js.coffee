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
        # $('.profile-image').attr 'src', "http://eot.evercam.io/eot.jpg"
        $('.profile-name').text user.displayName
        $("#feed_of_user").attr("href", "/feed/#{user.uid}")
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
          if animation.is_public == true
            spanTagFeed =
              "<span class='right floated droping-up' data-content='Remove this from public feed.' data-id='#{animation.id}'>
                <i class='undo icon' style='font-size: 20px;'></i>
              </span>"
          else
            spanTagFeed =
              "<span class='right floated poping-up' data-content='Add this to your public feed.' data-id='#{animation.id}'>
                <i class='share icon' style='font-size: 20px;'></i>
              </span>"

          videoJSHtml = "
            <div class='card'>
              <div class='content'>
                <div class='header'>#{animation.name}</div>
                <div class='meta'>Frames: #{animation.image_count}, Date: #{moment.unix(animation.unix_time).format("MM/DD/YYYY HH-mm-ss")}, File size: #{animation.file_size}, FPS: #{animation.fps}</div>
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
              <div class='extra content'>
                #{spanTagFeed}
                <span class='right floated social-twitter' data-surl='#{animation.path}'>
                  <i class='twitter square icon' style='font-size: 20px;'></i>
                </span>
                <span class='right floated social-facebook' data-surl='#{animation.path}'>
                  <i class='facebook square icon' style='font-size: 20px;'></i>
                </span>
                <span class='right floated social-whatsapp' data-surl='#{animation.path}'>
                  <i class='whatsapp icon' style='font-size: 20px;'></i>
                </span>
                <span class='right floated social-linkedin' data-surl='#{animation.path}'>
                  <i class='linkedin icon' style='font-size: 20px;'></i>
                </span>
              </div>
            </div>
          "
          $(".row-10 > .ui").append(videoJSHtml)
          videojs("my-player-#{animation.id}")
          $('.poping-up').popup on: 'hover'
          $('.droping-up').popup on: 'hover'
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

onTwitterSharingClick = ->
  $(".animate-gallery").on 'click', ".social-twitter", ->
    longUrl = $(this).data('surl')
    shrtUrl = ""
    $("#image_processing")
      .css('display', 'block')
      .css('z-index', "99999")

    setTimeout (->
      $("#image_processing").css('display', 'none')
      get_short_url longUrl, "o_48fmt0av2s", "R_babbcf09f1e946eb98907531b6d7c13a", (short_url) ->
        window.open 'http://twitter.com/share?url=' + short_url + '&text=This is an animation from Eyes of Things: ', '_blank'
      $("#image_processing").css('display', 'none')
      return
    ), 1000

onWhatsAppSharingClick = ->
  $(".animate-gallery").on 'click', ".social-whatsapp", ->
    longUrl = $(this).data('surl')
    shrtUrl = ""
    $("#image_processing")
      .css('display', 'block')
      .css('z-index', "99999")

    setTimeout (->
      $("#image_processing").css('display', 'none')
      get_short_url longUrl, "o_48fmt0av2s", "R_babbcf09f1e946eb98907531b6d7c13a", (short_url) ->
        window.open("https://web.whatsapp.com/send?text=" + short_url, "_blank");
      $("#image_processing").css('display', 'none')
      return
    ), 1000

onLinkedInSharingClick = ->
  $(".animate-gallery").on 'click', ".social-linkedin", ->
    longUrl = $(this).data('surl')
    shrtUrl = ""
    $("#image_processing")
      .css('display', 'block')
      .css('z-index', "99999")

    setTimeout (->
      $("#image_processing").css('display', 'none')
      get_short_url longUrl, "o_48fmt0av2s", "R_babbcf09f1e946eb98907531b6d7c13a", (short_url) ->
        window.open("http://www.linkedin.com/shareArticle?url=#{short_url}&title=Eyes Of Things&summary=This is an animation from Eyes of Things.", "_blank");
      $("#image_processing").css('display', 'none')
      return
    ), 1000

onFBSharingClick = ->
  $(".animate-gallery").on 'click', ".social-facebook", ->
    longUrl = $(this).data('surl')
    shrtUrl = ""
    $("#image_processing")
      .css('display', 'block')
      .css('z-index', "99999")

    setTimeout (->
      $("#image_processing").css('display', 'none')
      get_short_url longUrl, "o_48fmt0av2s", "R_babbcf09f1e946eb98907531b6d7c13a", (short_url) ->
        window.open("http://www.facebook.com/sharer.php?u=#{short_url}", "_blank");
      $("#image_processing").css('display', 'none')
      return
    ), 1000

get_short_url = (long_url, login, api_key, func) ->
  $.getJSON 'http://api.bitly.com/v3/shorten?callback=?', {
    'format': 'json'
    'apiKey': api_key
    'login': login
    'longUrl': long_url
  }, (response) ->
    func response.data.url
    return
  return

onPopUpClick = ->
  $(".animate-gallery").on "click", ".poping-up", ->
    NProgress.start()
    thisIs = $(this)
    animationID = $(this).data('id')
    sendToPublicFeed(animationID, true)
    $.notify("Added to your public feed.", "info");
    NProgress.done()
    # thisIs.addClass("hide")
    thisIs
      .attr('data-content', 'Remove this from public feed.')
      .html("<i class='undo icon'></i>")
      .addClass("droping-up")
      .removeClass("poping-up")

sendToPublicFeed = (animationID, state) ->
  data = {}
  data.id = animationID
  data.is_public = state

  onError = (jqXHR, textStatus, errorThrown) ->
    console.log jqXHR
    $.notify("#{result.responseText}", "error")
    false

  onSuccess = (data, textStatus, jqXHR) ->
    console.log data

  settings =
    cache: false
    dataType: 'json'
    data: data
    error: onError
    success: onSuccess
    type: "POST"
    url: "/change_animation_public"

  $.ajax(settings)  

onDropUpClick = ->
  $(".animate-gallery").on "click", ".droping-up", ->
    NProgress.start()
    thisIs = $(this)
    animationID = $(this).data('id')
    sendToPublicFeed(animationID, false)

    $.notify("Removed from your public feed.", "info");
    NProgress.done()
    # thisIs.addClass("hide")
    thisIs
      .html("<i class='share icon'></i>")
      .removeClass("droping-up")
      .addClass("poping-up")
      .attr('data-content', 'Add this to your public feed.')


window.initializeAnimations = ->
  moment.locale()
  startAuth()
  onLoad()
  onSignOut()
  onTwitterSharingClick()
  onWhatsAppSharingClick()
  onLinkedInSharingClick()
  onFBSharingClick()
  onPopUpClick()
  onDropUpClick()
