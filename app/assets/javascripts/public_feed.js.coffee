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
                  # console.log childSnap.val().Images
                  showPublicFeed(childSnap.val().Images)
                  return
            NProgress.done()
        $('.profile-name').text user.displayName
      else
        window.location = '/'
      return
    return

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
                  Tags: #{tags.replace(/all/g,'')}
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