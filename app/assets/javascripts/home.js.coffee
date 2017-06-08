window.storage = undefined
window.storageRef = undefined
auth_app = undefined
mac_address = undefined
window.iam_authenticated = undefined
globalModal = undefined
user_email = undefined
api_key = undefined
api_id = undefined
lastSyncDateIs = undefined
window.haveLoggedIn = undefined
allVals = []

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
      $(".profile-image").attr("src", result.user.photoURL)
      $(".profile-name").text(result.user.displayName)
      console.log result.user
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
        # console.log Object.values(snapshot.val())[1]
        mac_address = Object.keys(snapshot.val())[0]
        if getObjectKeyIndex(snapshot.exportVal(), 'evercam') != null
          indexVal = getObjectKeyIndex(snapshot.exportVal(), 'evercam')
          lastSyncDateIs = Object.values(snapshot.val())[indexVal].lastSyncDate
          $(".lastSync").text("Last Sync #{moment.unix(lastSyncDateIs).format("MM/DD/YYYY HH-mm-ss")}")
        else
          $(".lastSync").text("Last Sync #{moment.unix(88787777).format("MM/DD/YYYY HH-mm-ss")}")
        #   $(".not-on").css('display', 'none')
        #   $(".already-on").css("display", "block")
        $(".device_id").text("#{mac_address}")
        $("#album").css("display", "block")
        #   lastSyncDateIs = Object.values(snapshot.val())[1].lastSyncDate
        #   api_key = Object.values(snapshot.val())[1].apiKey
        #   api_id = Object.values(snapshot.val())[1].apiId
        # $(".lastSync").text("Last Sync #{moment.unix(88787777).format("MM/DD/YYYY HH-mm-ss")}")
        #   console.log Object.values(snapshot.val())[1].lastSyncDate
        # else
        #   $(".not-on").css('display', 'block')
        #   $(".already-on").css("display", "none")
        #   lastSyncDateIs = moment().unix()
        # mac_address = Object.keys(snapshot.val())[0]
        snapshot.forEach (childSnap) ->
          console.log childSnap
          if childSnap.val().Images != null
            logImageDataOnly(childSnap.val().Images)
            return

isset = (variable) ->
  if typeof variable != typeof undefined then true else false

capitalizeFirstLetter = (string) ->
  string.charAt(0).toUpperCase() + string.slice(1)

logImageDataOnly = (Images) ->
  tags = "all"
  $.each Images, (timestamp, Image) ->
    tangRef = storageRef.child("#{Image.Path}");
    tangRef.getDownloadURL().then((url) ->
      # if timestamp > lastSyncDateIs
        # updateSyncDate(iam_authenticated, user_email, timestamp, api_key, api_id)
        # sendItToSeaweedFS(url, mac_address, timestamp)
      $.each Image.Tags, (i, value) ->
        if value == 1
          tags += " #{i}"
      if tags == "all"
        tags = "all normal"
      console.log tags
      image_tag =
        "<div class='ui card #{tags}'>
          <div class='image'>
            <img src='#{url}'>
          </div>
          <div class='content'>
            <a class='header pop-the-image' href='#{url}' data-time='#{timestamp}' data-mac='#{mac_address}' data-tags='#{tags}'>Date: #{moment.unix(timestamp).format("MM/DD/YYYY HH-mm-ss")}</a>
            <div class='meta'>
              <span class='date'>Device ID: #{mac_address}</span>
            </div>
            <div class='description'>
              Tags: #{tags.replace(/all/g,'')}
            </div>
          </div>
          <div class='extra content'>
            <span class='right floated'>
              <i class='feed icon'></i>
              #{timestamp}
            </span>
            <span>
              <div class='ui checkbox'>
                <input type='checkbox' class='am-image' value='#{url}' name='animateme'>
              </div>
            </span>
          </div>
        </div>"
      $(".my-gallery").append(image_tag)
      $('.ui.checkbox')
        .checkbox()
      tags = "all"
    ).catch (error) ->
      console.log error
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
    $('.ui.modal img').attr('src', $(this).attr('href'))
    $('.ui.modal .to-time').html(
      "
        #{moment.unix($(this).data('time')).format("dddd, DD MMMM YYYY hh-mm-ss A")}
        <div class='meta'>
          <span class='date'>Tags: #{$(this).data('tags').replace(/all/g,'')}</span>
        </div>
      "
    )
    $('.ui.modal').modal("show")

openFilters = ->
 $(".show-me-filter").on "click", ->
  console.log "Hell"
  $('.ui.labeled.icon.sidebar')
    .sidebar('toggle')

onFilterClick = ->
  $(".ui.left .item").on "click", ->
    actual_color = "rgba(255, 255, 255, 0.0784314)"
    clicked_color = "rgb(94, 94, 94)"
    if $(this).css("background-color") == actual_color
      $(this).css("background-color", clicked_color)
    else
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
    $('input:checkbox').prop('checked', true)

onDeselectAllImages = ->
  $(".deselect-all-images").on "click", ->
    $(".deselect-all-images").css("display", "none")
    $(".select-all-images").css("display", "block")
    $('input:checkbox').prop('checked', false)

onCreateAnimation = ->
  $(".createAnimation").on "click", ->
    checkValues = $('input[name=animateme]:checked').map(->
      $(this).val()
    ).get()
    console.log checkValues
    if checkValues.length < 1
      $(".no-images-select").css("display", "block")
    else
      NProgress.start()
      ceateAndSave(checkValues)

ceateAndSave = (image_paths) ->
  data = {}
  data.image_paths = image_paths

  onError = (jqXHR, textStatus, errorThrown) ->
    console.log jqXHR
    # $.notify("#{result.responseText}", "error")
    false

  onSuccess = (data, textStatus, jqXHR) ->
    console.log data
    uploadToFirebase(data)
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
    $(".please-see-animate").css("display", "block")
    NProgress.done()
    console.log 'Uploaded a base64 string!'
  db_auth = firebase.database().ref()
  console.log window.user_email
  obliged_email = "#{window.user_email}".replace(/\./g,'|')
  db_auth.child("/#{obliged_email}").once 'value', (snapshot) ->
    if !snapshot.hasChild("animations")
      animateRef = db_auth.child("#{obliged_email}")
      animateRef.update
        animations:
          filePath: "Animations/#{data.directory_name}.mp4"
    else
      animateRef = db_auth.child("#{obliged_email}").child("animations")
      newAnimateRef = animateRef.push().set
        "filePath": "Animations/#{data.directory_name}.mp4"


      # console.log "am here"
      # postData = {
      #   "filePath": "Animations/#{data.directory_name}.mp4"
      # }
      # animateRef = db_auth.child("#{obliged_email}/animations").push().key
      # updates = {}
      # updates["/#{obliged_email}/animations/"] = postData
      # db_auth.push(updates)
        # filePath: 

  # if db_auth.child("#{obliged_email}/animations")
    # animateRef = db_auth.child("#{obliged_email}/animations")
    # animateRef.update
    #   filePath: "Animations/#{data.directory_name}.mp4"
    # ...
  console.log "done"
  $('input:checkbox').prop('checked', false)

window.initializeHome = ->
  moment.locale()
  startAuth()
  onSignIn()
  onImageSearch()
  onAllClicked()
  onSignOut()
  popTheImage()
  openFilters()
  onFilterClick()
  onSelectAllImages()
  onDeselectAllImages()
  onCreateAnimation()
