mac_address = undefined
db_auth = undefined
whoUserEmail = undefined
imagePaths = undefined

getUrlParameter = (sParam) ->
  sPageURL = decodeURIComponent(window.location.search.substring(1))
  sURLVariables = sPageURL.split('&')
  sParameterName = undefined
  i = undefined
  i = 0
  while i < sURLVariables.length
    sParameterName = sURLVariables[i].split('=')
    if sParameterName[0] == sParam
      return if sParameterName[1] == undefined then true else sParameterName[1]
    i++
  return

onLoad = ->
  $(window).load ->
    getAllPathsForEmail(getUrlParameter('email'))
    obliged_email = "#{getUrlParameter('email')}".replace(/\./g,'|')
    $("#feed_of_user").attr("href", "/feed?email=#{getUrlParameter('email')}")
    $(".signout").hide()
    $(".avatar-parts").hide()

    config = 
      apiKey: AuthData.apiKey
      authDomain: AuthData.authDomain
      databaseURL: AuthData.databaseURL
      storageBucket: AuthData.storageBucket

    firebase.initializeApp config
    storage = firebase.storage()
    storageRef = storage.ref()

    firebase.database().ref().once 'value', (snapshot) ->
      console.log snapshot
      if !snapshot.hasChild(obliged_email)
        $.notify("No data to show in public feed.", "info");
        NProgress.done()
        console.log "No data for show."
      else
        console.log "hrurr"
        firebase.database().ref().child("/#{obliged_email}").once 'value', (snapshot) ->
          mac_address = Object.keys(snapshot.val())[0]
          globalDeviceKeys = Object.keys(snapshot.val())
          deletedIntegrations = subtractarrays(globalDeviceKeys, ["evercam", "dropbox"])
          indexDevice = 0
          snapshot.forEach (childSnap) ->
            console.log childSnap
            if childSnap.val().Images != null
              showPublicFeed(childSnap.val().Images, deletedIntegrations[indexDevice], storageRef)
              indexDevice++
        NProgress.done()

subtractarrays = (array1, array2) ->
  difference = []
  i = 0
  while i < array1.length
    if $.inArray(array1[i], array2) == -1
      difference.push array1[i]
    i++
  difference

getLastPart = ->
  url = $(location).attr('href')
  parts = url.split('/')
  parts[parts.length - 1]

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
              <span>
                <div class='ui checkbox'>
                  <input type='checkbox' class='checkBx am-image' value='#{animation.path} mp4' name='forDropBox'>
                </div>
              </span>
            </div>
          </div>
        "
        $(".row-26 > .ui").append(videoJSHtml)
        $('.ui.checkbox')
        .checkbox()
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
    url: "/load_public_animation_path"

  $.ajax(settings)

showPublicFeed = (Images, deviceMac, storageRef) ->
  spanTagFeed = ""
  tags = "all"
  $.each Images, (timestamp, Image) ->
    tangRef = storageRef.child("#{Image.Path}")
    tangRef.getMetadata().then((metadata) ->
      if metadata.customMetadata && metadata.customMetadata.isPublic == "true"
        tangRef.getDownloadURL().then((url) ->
          $.each Image.Tags, (i, value) ->
            if value == 1
              tags += " #{i}"
          if tags == "all"
            tags = "all normal"
          console.log tags
          image_tag =
            "<div class='datetime-filter ui card #{tags}' data-timefilter='#{moment.unix(timestamp).format("MMMM M, YYYY")}'>
              <a class='pop-the-image filer-on-date' href='#{url}' data-mac='#{deviceMac}' data-tags='#{tags}' data-time='#{timestamp}'>
                <div class='image'>
                  <img src='#{url}'>
                </div>
              </a>
              <div class='content'>
                <a class='header' data-time='#{timestamp}' data-mac='#{deviceMac}' data-tags='#{tags}'>Date: #{moment.unix(timestamp).format("MMMM M, YYYY, HH-mm-ss")}</a>
                <div class='meta'>
                  <span class='date'>Device ID: #{deviceMac}</span>
                </div>
                <div class='description'>
                  #{returnTagsWithLabel(tags.replace(/all/g,''))}
                </div>
              </div>
              <div class='extra content'>
                <span>
                  <div class='ui checkbox'>
                    <input type='checkbox' class='checkBx am-image' value='#{url} jpeg' name='forDropBox'>
                  </div>
                </span>
              </div>
            </div>"
          $(".public-gallery").append(image_tag)
          $('.ui.checkbox')
            .checkbox()
          tags = "all"
        ).catch (error) ->
          console.log "error"
          return
      else
        console.log "error"
    ).catch (error) ->
      console.log "error"

onSelectAllImages = ->
  $(".select-all-images").on "click", ->
    $(".deselect-all-images").css("display", "block")
    $(".select-all-images").css("display", "none")
    $('.checkBx:visible').prop('checked', true)

onDeselectAllImages = ->
  $(".deselect-all-images").on "click", ->
    $(".deselect-all-images").css("display", "none")
    $(".select-all-images").css("display", "block")
    $('.checkBx:visible').prop('checked', false)

onSendToDB = ->
  $(".sendToDB").on "click", ->
    checkValues = $('input[name=forDropBox]:checked').map(->
      $(this).val()
    ).get()
    console.log checkValues
    if checkValues.length < 1
      $.notify("Please select few images.", "info")
      # $(".no-images-select").css("display", "block")
    else
      imagePaths = checkValues
      image_count_ani = checkValues.length
      $('.ui.dropboxcode-name').modal("show")

onTokenAdd = ->
  $(".save-dropbox-token").on "click", ->
    $('.ui.dropboxcode-name').modal("hide")
    $('input:checkbox').prop('checked', false)
    $.notify("Feed has been sent to Dropbox.", "info")

    tokenValue = $("#dropbox-name").val()

    data = {}
    data.tokenValue = tokenValue
    data.whoUserEmail = whoUserEmail
    data.imagePaths = imagePaths

    onError = (jqXHR, textStatus, errorThrown) ->
      console.log jqXHR
      # $.notify("#{result.responseText}", "error")
      false

    onSuccess = (data, textStatus, jqXHR) ->
      console.log data
      true

    settings =
      cache: false
      dataType: 'json'
      data: data
      error: onError
      success: onSuccess
      type: "POST"
      url: "/upload_feed_to_db"

    $.ajax(settings)

returnTagsWithLabel = (tagings) ->
  labels = ""
  tags = tagings.split(" ")
  $.each tags, (i, value) ->
    if value is ""
      # Ignore this value if its nil
    else
      labels += "<div class='ui label'>#{value}</div>"
  return labels

feedTheImage = ->
  $(".public-gallery").on "click", ".pop-the-image", (event) ->
    console.log "hi"
    event.preventDefault()
    $('.ui.feedImage img').attr('src', $(this).attr('href'))
    $('.ui.feedImage .to-time').html(
      "
        #{moment.unix($(this).data('time')).format("dddd, DD MMMM YYYY hh-mm-ss A")}
        <div class='meta'>
          <span class='date'>Tags: #{$(this).data('tags').replace(/all/g,'')}</span>
        </div>
      "
    )
    $('.ui.feedImage').modal("show")

window.initializeFeeds = ->
  moment.locale()
  onLoad()
  feedTheImage()
  onSendToDB()
  onSelectAllImages()
  onDeselectAllImages()
  onTokenAdd()
