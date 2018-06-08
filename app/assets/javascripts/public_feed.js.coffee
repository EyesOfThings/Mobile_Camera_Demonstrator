mac_address = undefined

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
        getAllPathsForEmail(user_email)
        $("#feed_of_user").attr("href", "/feed/#{user.uid}")
        console.log obliged_email
        db_auth.once 'value', (snapshot) ->
          if !snapshot.hasChild(obliged_email)
            $.notify("No data to show in public feed.", "info");
            NProgress.done()
            console.log "No data for show."
          else
            console.log "hrurr"
            db_auth.child("/#{obliged_email}").once 'value', (snapshot) ->
              mac_address = Object.keys(snapshot.val())[0]
              snapshot.forEach (childSnap) ->
                console.log childSnap
                if childSnap.val().Images != null
                  if getLastPart() == user.uid
                    showPublicFeed(childSnap.val().Images)
                  else
                    $.notify("This user doesn't exist.", "info")
                  return
            NProgress.done()
        $('.profile-name').text user.displayName
      else
        window.location = '/'
      return
    return

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
          </div>
        "
        $(".row-26 > .ui").append(videoJSHtml)
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

showPublicFeed = (Images) ->
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
              <a class='pop-the-image filer-on-date' href='#{url}' data-mac='#{mac_address}' data-tags='#{tags}' data-time='#{timestamp}'>
                <div class='image'>
                  <img src='#{url}'>
                </div>
              </a>
              <div class='content'>
                <a class='header' data-time='#{timestamp}' data-mac='#{mac_address}' data-tags='#{tags}'>Date: #{moment.unix(timestamp).format("MMMM M, YYYY, HH-mm-ss")}</a>
                <div class='meta'>
                  <span class='date'>Device ID: #{mac_address}</span>
                </div>
                <div class='description'>
                  #{returnTagsWithLabel(tags.replace(/all/g,''))}
                </div>
              </div>
            </div>"
          $(".public-gallery").append(image_tag)
          tags = "all"
        ).catch (error) ->
          console.log "error"
          return
      else
        console.log "error"
    ).catch (error) ->
      console.log "error"

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
  startAuth()
  onLoad()
  feedTheImage()