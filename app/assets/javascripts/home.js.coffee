window.storage = undefined
window.storageRef = undefined
auth_app = undefined
mac_address = undefined
window.iam_authenticated = undefined
globalModal = undefined
user_email = undefined
api_key = undefined
api_id = undefined
image_count_ani = undefined
lastSyncDateIs = undefined
window.haveLoggedIn = undefined
allVals = []
imagePaths = undefined
window.dateFilter = undefined
globalDeviceKeys = undefined
globalDeviceVals = undefined

sendAJAXRequest = (settings) ->
  token = $('meta[name="csrf-token"]')
  if token.size() > 0
    headers =
      "X-CSRF-Token": token.attr("content")
    settings.headers = headers
  xhrRequestChangeMonth = jQuery.ajax(settings)
  true

window.startAuth = ->
  config = 
    apiKey: AuthData.apiKey
    authDomain: AuthData.authDomain
    databaseURL: AuthData.databaseURL
    storageBucket: AuthData.storageBucket

  window.firebase.initializeApp config
  window.storage = firebase.storage()
  window.storageRef = storage.ref()

onSignIn = ->
  $(".auth-provider").on "click", ".auth-with-google", ->
    storage = firebase.storage()
    storageRef = storage.ref()
    console.log "clicked"
    provider = new (firebase.auth.GoogleAuthProvider)
    firebase.auth().signInWithPopup(provider).then((result) ->
      $("#page-splash").css('display', 'none')
      # $(".profile-image").attr("src", "http://eot.evercam.io/eot.jpg")

      $(".profile-name").text(result.user.displayName)
      console.log result.user
      $("#feed_of_user").attr("href", "/feed?email=#{user.email}")
      console.log result.user.email
      user_email = result.user.email
      iam_authenticated = firebase
      console.log "calling geth auth"
      # getAuthWithFirebase(firebase, "#{result.user.email}")
      return
    ).catch (error) ->
      # Handle Errors here.
      errorCode = error.code
      errorMessage = error.message
      # The email of the user's account used.
      email = error.email
      # The firebase.auth.AuthCredential type that was used.
      credential = error.credential
      # ...
      return

getObjectKeyIndex = (obj, keyToFind) ->
  i = 0
  key = undefined
  for key of obj
    `key = key`
    if key == keyToFind
      return i
    i++
  null

window.getAuthWithFirebase = (auth, email) ->
  db_auth = auth.database().ref()
  obliged_email = "#{email}".replace(/\./g,'|')
  console.log obliged_email
  $("#image_processing")
    .css('display', 'block')
    .css('z-index', "99999")

  $(".after-auth").css('display', 'block')
  setTimeout (->
    $("#image_processing").css('display', 'none')
    return
  ), 5000
  db_auth.once 'value', (snapshot) ->
    if !snapshot.hasChild(obliged_email)
      $(".heyyou").css('display', 'block')
      $("#album").css("display", "none")
      console.log "hello"
    else
      db_auth.child("/#{obliged_email}").once 'value', (snapshot) ->
        # console.log Object.keys(snapshot.val())
        # console.log Object.values(snapshot.val())
        globalDeviceKeys = Object.keys(snapshot.val())
        globalDeviceVals = Object.values(snapshot.val())
        mac_address = Object.keys(snapshot.val())[0]
        if getObjectKeyIndex(snapshot.exportVal(), 'evercam') != null
          indexVal = getObjectKeyIndex(snapshot.exportVal(), 'evercam')
          lastSyncDateIs = Object.values(snapshot.val())[indexVal].lastSyncDate
          $(".lastSync").text("Last Sync #{moment.unix(lastSyncDateIs).format("MM/DD/YYYY HH-mm-ss")}")
        else
          $(".lastSync").text("Last Sync #{moment.unix(88787777).format("MM/DD/YYYY HH-mm-ss")}")
        # $(".device_id").text("#{mac_address}")
        deletedIntegrations = subtractarrays(globalDeviceKeys, ["evercam", "dropbox"])
        addMacsToDorpdown(deletedIntegrations)
        $("#album_items").css("display", "block")
        indExing = 0
        snapshot.forEach (childSnap) ->
          if childSnap.val().Images != null
            console.log childSnap.val().Images
            logImageDataOnly(childSnap.val().Images, deletedIntegrations[indExing])
            indExing++
            return

isset = (variable) ->
  if typeof variable != typeof undefined then true else false

addMacsToDorpdown = (macArray) ->
  tagMac = ''
  macArray.forEach (mac) ->
    tagMac = "
      <div class='ui radio checkbox item deviceArea'>
        <input type='radio' name='radio'>
        <label>#{mac}</label>
      </div>
    "
    $(".pushMacs").append(tagMac)

subtractarrays = (array1, array2) ->
  difference = []
  i = 0
  while i < array1.length
    if $.inArray(array1[i], array2) == -1
      difference.push array1[i]
    i++
  difference

capitalizeFirstLetter = (string) ->
  string.charAt(0).toUpperCase() + string.slice(1)

logImageDataOnly = (Images, deviceMac) ->
  console.log deviceMac
  spanTagFeed = ""
  tags = "all"
  $.each Images, (timestamp, Image) ->
    tangRef = storageRef.child("#{Image.Path}")
    tangRef.getMetadata().then((metadata) ->
      if metadata.customMetadata && metadata.customMetadata.isPublic == "true"
        spanTagFeed =
          "<span class='right floated droping-up' data-content='Remove this from public feed.' data-meta='#{Image.Path}'>
            <i class='undo icon' style='font-size: 20px;'></i>
          </span>"
      else
        spanTagFeed =
          "<span class='right floated poping-up' data-content='Add this to your public feed.' data-meta='#{Image.Path}'>
            <i class='share icon' style='font-size: 20px;'></i>
          </span>"
    ).catch (error) ->
      console.log error
    if spanTagFeed is ""
      spanTagFeed =
        "<span class='right floated poping-up' data-content='Add this to your public feed.' data-meta='#{Image.Path}'>
          <i class='share icon' style='font-size: 20px;'></i>
        </span>"
    
    tangRef.getDownloadURL().then((url) ->
      $.each Image.Tags, (i, value) ->
        if value == 1
          tags += " #{i}"
      if tags == "all"
        tags = "all normal"
      console.log tags
      image_tag =
        "<div class='deviceHolds datetime-filter ui card #{tags}' data-mac='#{deviceMac}' data-timefilter='#{moment.unix(timestamp).format("MMMM M, YYYY")}'>
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
          <div class='extra content replacingFirstSpan'>
            #{spanTagFeed}
            <span class='right floated social-twitter' data-surl='#{url}'>
              <i class='twitter square icon' style='font-size: 20px;'></i>
            </span>
            <span class='right floated social-facebook' data-surl='#{url}'>
              <i class='facebook square icon' style='font-size: 20px;'></i>
            </span>
            <span class='right floated social-whatsapp' data-surl='#{url}'>
              <i class='whatsapp icon' style='font-size: 20px;'></i>
            </span>
            <span class='right floated social-linkedin' data-surl='#{url}'>
              <i class='linkedin icon' style='font-size: 20px;'></i>
            </span>
            <span>
              <div class='ui checkbox'>
                <input type='checkbox' class='checkBx am-image' value='#{url}' name='animateme' data-meta='#{Image.Path}'>
              </div>
            </span>
          </div>
        </div>"
      $(".my-gallery").append(image_tag)
      $('.poping-up').popup on: 'hover'
      $('.droping-up').popup on: 'hover'
      $('.ui.checkbox')
        .checkbox()
      tags = "all"
    ).catch (error) ->
      console.log error
      return

showAndHideDevices = ->
  $("#album_items").on "click", ".deviceArea", ->
    deviceMac = $($(this).html()).filter('label').text()
    if deviceMac is "All"
      $('.deviceHolds').each ->
        $(this).show()
    else
      $('.deviceHolds').each ->
        $(this).hide()
        if $(this).data('mac') == "#{deviceMac}"
          $(this).show()
        return

returnTagsWithLabel = (tagings) ->
  labels = ""
  tags = tagings.split(" ")
  $.each tags, (i, value) ->
    if value is ""
      # Ignore this value if its nil
    else
      labels += "<div class='ui label'>#{value}</div>"
  return labels

window.giveMetaData = (path) ->
  snapRef = storageRef.child("#{path}")
  setValuesMeta = snapRef.getMetadata().then((metaData) ->
    return metaData.customMetadata
  ).catch (error) ->
    return

onSignOut = ->
  $(".signout").on "click", ->
    firebase.auth().signOut().then(->
      # Sign-out successful.
      $(".heyyou").css('display', 'none')
      $("#page-splash").css('display', 'flex')
      $(".after-auth").css('display', 'none')
      $(".no-image").css('display', 'none')
      $("#album_items").css('display', 'none')
      $(".my-gallery").html("")
      console.log "signed out"
      return
    ).catch (error) ->
      # An error happened.
      return

window.getParameterByName = (name, url) ->
  if !url
    url = window.location.href
  name = name.replace(/[\[\]]/g, '\\$&')
  regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)')
  results = regex.exec(url)
  if !results
    return null
  if !results[2]
    return ''
  decodeURIComponent results[2].replace(/\+/g, ' ')

addTable = (auth, email, api_key, api_id) ->
  db_auth = auth.database().ref()
  obliged_email = "#{email}".replace(/\./g,'|')
  evercamRef = db_auth.child("#{obliged_email}")
  evercamRef.update
    evercam:
      apiKey: "#{api_key}"
      apiId: "#{api_id}"
      lastSyncDate: '1293916756'

  console.log "done"

updateSyncDate = (auth, email, timestamp, api_key, api_id) ->
  db_auth = auth.database().ref()
  obliged_email = "#{email}".replace(/\./g,'|')
  evercamRef = db_auth.child("#{obliged_email}")
  evercamRef.update
    evercam:
      apiKey: "#{api_key}"
      apiId: "#{api_id}"
      lastSyncDate: "#{timestamp}"
  console.log "done"  

popTheImage = ->
  $(".my-gallery").on "click", ".pop-the-image", (event) ->
    console.log "hi"
    event.preventDefault()
    $('.ui.imagepage img').attr('src', $(this).attr('href'))
    $('.ui.imagepage .to-time').html(
      "
        #{moment.unix($(this).data('time')).format("dddd, DD MMMM YYYY hh-mm-ss A")}
        <div class='meta'>
          <span class='date'>Tags: #{$(this).data('tags').replace(/all/g,'')}</span>
        </div>
      "
    )
    $('.ui.imagepage').modal("show")

openFilters = ->
 $(".show-me-filter").on "click", ->
  console.log "Hell"
  $('.ui.labeled.icon.sidebar')
    .sidebar('toggle')

onFilterClick = ->
  $(".ui.left .item").on "click", ->
    console.log $(this).css("background-color")

    actual_color = "rgba(255, 255, 255, 0.08)"
    clicked_color = "rgb(94, 94, 94)"
    if $(this).css("background-color") == actual_color
      console.log "hwere"
      $(this).css("background-color", clicked_color)
    else
      console.log "no color"
      $(this).css("background-color", "")

onImageSearch = ->
  $('.ui.left > .item').on "click", ->
    if $(this).hasClass("active_for")
      $(this).removeClass("active_for")
      existed = ".#{$(this).attr("id")}"
      console.log existed
      allVals = removeA(allVals, "#{existed}")
      console.log "i am #{allVals}"
    else
      $(this).addClass("active_for")
      $('.ui.left .active_for').each ->
        allVals.push("." + $(this).attr("id"))
    if allVals.length < 1
      allVals.push(".all")
    if allVals.length > 1
      allVals = removeA(allVals, ".all")
    if $.inArray('.all', allVals) == -1
      $("#all").css("background-color", "")

    console.log unique(allVals)
    $('.my-gallery > div').hide()
    $(allVals.join(',')).show()
    # allVals = []

removeA = (arr) ->
  what = undefined
  a = arguments
  L = a.length
  ax = undefined
  while L > 1 and arr.length
    what = a[--L]
    while (ax = arr.indexOf(what)) != -1
      arr.splice ax, 1
  arr

onAllClicked = ->
  $('#all').on "click", ->
    $('.ui.left .active_for').each ->
      $(this).removeClass("active_for")
      $(this).css("background-color", "")
    allVals = []
    allVals.push(".all")
    console.log allVals
    $('.my-gallery > div').hide()
    $(allVals.join(',')).show()
    allVals = []

unique = (list) ->
  result = []
  $.each list, (i, e) ->
    if $.inArray(e, result) == -1
      result.push e
    return
  result

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

onCreateAnimation = ->
  $(".createAnimation").on "click", ->
    checkValues = $('input[name=animateme]:checked').map(->
      $(this).val()
    ).get()
    console.log checkValues
    if checkValues.length < 1
      $.notify("Please select few images.", "info")
      # $(".no-images-select").css("display", "block")
    else
      imagePaths = checkValues
      image_count_ani = checkValues.length
      $('.ui.animation-name').modal("show")

onNameSave = ->
  $(".save-animate-name").on "click", ->
    console.log "hi"
    NProgress.start()
    animationName = $("#animation-name").val()
    ceateAndSave(imagePaths, animationName)
    $.notify("Your Animation is being processed.", "info");
    # $(".please-see-animate").css("display", "block")
    $('input:checkbox').prop('checked', false)
    $(".deselect-all-images").css("display", "none")
    $(".select-all-images").css("display", "block")
    NProgress.done()


ceateAndSave = (image_paths, animation_name) ->
  data = {}
  data.image_paths = image_paths
  data.animation_name = animation_name
  data.user_email = window.user_email

  onError = (jqXHR, textStatus, errorThrown) ->
    console.log jqXHR
    # $.notify("#{result.responseText}", "error")
    false

  onSuccess = (data, textStatus, jqXHR) ->
    console.log data
    $.notify("Your Animation is ready.", "success");
    # uploadToFirebase(data)
    true

  settings =
    cache: false
    dataType: 'json'
    data: data
    error: onError
    success: onSuccess
    type: "POST"
    url: "/create_animation"

  $.ajax(settings)

uploadToFirebase = (data) ->
  storage = firebase.storage()
  storageRef = storage.ref("Animations/#{data.directory_name}.mp4")
  storageRef.putString(data.base64String, 'base64').then (snapshot) ->
    console.log 'Uploaded a base64 string!'
  console.log window.user_email
  obliged_email = "#{window.user_email}".replace(/\./g,'|')
  console.log "done"
  console.log "Uploading to DB PATH"
  saveMePath(obliged_email, "Animations/#{data.directory_name}.mp4", data.animationId)

saveMePath = (user_email, path, animationId) ->
  data = {}
  data.user_email = user_email
  data.path = path
  data.image_count = image_count_ani
  data.animation_id = animationId

  onError = (jqXHR, textStatus, errorThrown) ->
    console.log jqXHR
    # $.notify("#{result.responseText}", "error")
    false

  onSuccess = (data, textStatus, jqXHR) ->
    console.log data
    $.notify("Your Animation is ready.", "success");
    true

  settings =
    cache: false
    dataType: 'json'
    data: data
    error: onError
    success: onSuccess
    type: "POST"
    url: "/save_animation_path"

  $.ajax(settings)

startCalendar = ->
  dateFilter = $('#date-filter-for').calendar
    type: 'date',
    onChange: (date, text, mode) ->
      $('.datetime-filter').hide().filter("[data-timefilter='#{text}']").show();

removeDateFilter = ->
  $(".clean-show-all").on "click", ->
    $('.datetime-filter').show()

onViewClick = ->
  $(".whole-view").on "click", ->
    $('.poping-up').popup on: 'hover'
    $('.droping-up').popup on: 'hover'

onPopUpClick = ->
  $(".my-gallery").on "click", ".poping-up", ->
    NProgress.start()
    thisIs = $(this)
    forMetaData = $(this).data('meta')
    newMetaData =
      customMetadata:
        isPublic: 'true'
        pFeedDate: "#{moment().unix()}"
        email: "#{user_email.match(/^([^@]*)@/)[1]}"

    storageRef.child("#{forMetaData}").updateMetadata(newMetaData).then((metadata) ->
      console.log metadata
      $.notify("Added to your public feed.", "info");
      NProgress.done()
      # thisIs.addClass("hide")
      thisIs
        .attr('data-content', 'Remove this from public feed.')
        .html("<i class='undo icon'></i>")
        .addClass("droping-up")
        .removeClass("poping-up")
      return
    ).catch (error) ->
      return

onDropUpClick = ->
  $(".my-gallery").on "click", ".droping-up", ->
    NProgress.start()
    thisIs = $(this)
    forMetaData = $(this).data('meta')
    newMetaData = 
      customMetadata:
        isPublic: 'false'
        pFeedDate: "#{moment().unix()}"
        email: "#{user_email.match(/^([^@]*)@/)[1]}"

    storageRef.child("#{forMetaData}").updateMetadata(newMetaData).then((metadata) ->
      console.log metadata
      $.notify("Removed from your public feed.", "info");
      NProgress.done()
      # thisIs.addClass("hide")
      thisIs
        .html("<i class='share icon'></i>")
        .removeClass("droping-up")
        .addClass("poping-up")
        .attr('data-content', 'Add this to your public feed.')
      return
    ).catch (error) ->
      return

onTwitterSharingClick = ->
  $(".my-gallery").on 'click', ".social-twitter", ->
    longUrl = $(this).data('surl')
    shrtUrl = ""
    $("#image_processing")
      .css('display', 'block')
      .css('z-index', "99999")

    setTimeout (->
      $("#image_processing").css('display', 'none')
      get_short_url longUrl, "o_48fmt0av2s", "R_babbcf09f1e946eb98907531b6d7c13a", (short_url) ->
        window.open 'http://twitter.com/share?url=' + short_url + '&text=This is a photo from Eyes of Things: ', '_blank'
      $("#image_processing").css('display', 'none')
      return
    ), 1000

onWhatsAppSharingClick = ->
  $(".my-gallery").on 'click', ".social-whatsapp", ->
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
  $(".my-gallery").on 'click', ".social-linkedin", ->
    longUrl = $(this).data('surl')
    shrtUrl = ""
    $("#image_processing")
      .css('display', 'block')
      .css('z-index', "99999")

    setTimeout (->
      $("#image_processing").css('display', 'none')
      get_short_url longUrl, "o_48fmt0av2s", "R_babbcf09f1e946eb98907531b6d7c13a", (short_url) ->
        window.open("http://www.linkedin.com/shareArticle?url=#{short_url}&title=Eyes Of Things&summary=This is a photo from Eyes of Things.", "_blank");
      $("#image_processing").css('display', 'none')
      return
    ), 1000

onFBSharingClick = ->
  $(".my-gallery").on 'click', ".social-facebook", ->
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

shareToPublicFeed = ->
  $(".goesToPublicFeed").on "click", ->
    checkValues = $('input[name=animateme]:checked').map(->
      $(this).data('meta')
    ).get()
    console.log checkValues
    if checkValues.length < 1
      $.notify("Please select few images.", "info")
    else
      imagePaths = checkValues
      $.notify("Images are added to your Public Feed.", "info")
      $('input:checkbox').prop('checked', false)
      imagePaths.forEach (MetaPath) ->
        newMetaData =
          customMetadata:
            isPublic: 'true'
            pFeedDate: "#{moment().unix()}"

        storageRef.child("#{MetaPath}").updateMetadata(newMetaData).then((metadata) ->
          return
        ).catch (error) ->
          return

window.initializeHome = ->
  moment.locale()
  startAuth()
  onSignIn()
  onImageSearch()
  onAllClicked()
  onSignOut()
  startCalendar()
  popTheImage()
  onNameSave()
  openFilters()
  onFilterClick()
  onSelectAllImages()
  onDeselectAllImages()
  onCreateAnimation()
  removeDateFilter()
  onViewClick()
  onPopUpClick()
  onDropUpClick()
  onTwitterSharingClick()
  onWhatsAppSharingClick()
  onLinkedInSharingClick()
  onFBSharingClick()
  shareToPublicFeed()
  showAndHideDevices()
