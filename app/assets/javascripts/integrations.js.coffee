user_email = undefined
lastSyncDateIs = undefined
api_key = undefined
api_id = undefined
syncIs = undefined
dropBoxSync = undefined
accessToken = undefined
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
        console.log user.email
        user_email = user.email
        iam_authenticated = firebase
        db_auth = firebase.database().ref()
        obliged_email = "#{user_email}".replace(/\./g,'|')
        $("#feed_of_user").attr("href", "/feed/#{user.uid}")
        console.log obliged_email
        db_auth.once 'value', (snapshot) ->
          if !snapshot.hasChild(obliged_email)
            $("#integrate-me").css('display', 'block').addClass("disabled")
            $(".makeit-take").css('display', '')
            $(".openmein").css('display', 'none')
            $(".etcstuff").css("display", "block")
            $(".ityourbutfail").css('display', 'block')
            console.log "No data for SYNC"
          else
            db_auth.child("/#{obliged_email}").once 'value', (snapshot) ->
              console.log snapshot.exportVal()
              console.log('animations' in snapshot.val())
              console.log getObjectKeyIndex(snapshot.exportVal(), 'lll')
              mac_address = Object.keys(snapshot.val())[0]
              if getObjectKeyIndex(snapshot.exportVal(), 'evercam') != null
                indexVal = getObjectKeyIndex(snapshot.exportVal(), 'evercam')
                syncIs = Object.values(snapshot.val())[indexVal].syncIsOn
                if syncIs > 0
                  lastSyncDateIs = Object.values(snapshot.val())[indexVal].lastSyncDate
                  $(".am-the-sync").css("display", "block")
                  $("#when-sync-did").html(
                    "
                      Last sync was <time class='timeago' datetime='#{moment.unix(moment().unix()).toISOString()}'>Date</time>
                    "
                  )
                  $("time.timeago").timeago()
                  mac_address = Object.keys(snapshot.val())[0]
                  api_key = Object.values(snapshot.val())[indexVal].apiKey
                  api_id = Object.values(snapshot.val())[indexVal].apiId
                  syncIs = Object.values(snapshot.val())[indexVal].syncIsOn
                  cameraIdIs = "#{mac_address}".replace(/:\s*/g, "").toLowerCase()
                  $(".openmein").html(
                    "
                    <a href='https://dash.evercam.io/v1/cameras/#{cameraIdIs}?api_key=#{api_key}&api_id=#{api_id}' target='_blank'>
                      <button class='ui negative button labeled icon' data-tooltip='Open it in Evercam.' data-delay='500'>
                        <i class='camera retro icon'></i>
                        Evercam
                      </button>
                    </a>
                    "
                  )
                  $("#revoke-me").css('display', 'block')
                  $(".makeit-take").css('display', '')
                  $(".etcstuff").css("display", "none")
                else
                  $(".openmein").html("").css("display", "none")
                  $(".etcstuff").css("display", "block")
                  $(".am-the-sync").css("display", "none")
                  $("#integrate-me").css('display', 'block')
                  $(".makeit-take").css('display', '')
              else
                $("#integrate-me").css('display', 'block')
                $(".am-the-sync").css("display", "none")
                $(".etcstuff").css("display", "block")
                $(".openmein").html("").css("display", "none")
                $(".makeit-take").css('display', '')

              if getObjectKeyIndex(snapshot.exportVal(), 'dropbox') != null
                indexVal = getObjectKeyIndex(snapshot.exportVal(), 'dropbox')
                dropBoxSync = Object.values(snapshot.val())[indexVal].syncIsOn
                if dropBoxSync > 0
                  lastSyncDateIs = Object.values(snapshot.val())[indexVal].lastSyncDate
                  $(".am-the-db-sync").css("display", "block")
                  $("#when-db-sync-did").html(
                    "
                      Last sync was <time class='timeago-db' datetime='#{moment.unix(moment().unix()).toISOString()}'>Date</time>
                    "
                  )
                  $("time.timeago-db").timeago()
                  mac_address = Object.keys(snapshot.val())[0]
                  accessToken = Object.values(snapshot.val())[indexVal].accessToken
                  dropBoxSync = Object.values(snapshot.val())[indexVal].syncIsOn
                  $("#revoke-db-me").css('display', 'block')
                  $(".makeit-take").css('display', '')
                  $(".etcstuffdb").css("display", "none")
                else
                  $(".etcstuffdb").css("display", "block")
                  $(".am-the-db-sync").css("display", "none")
                  $("#drop-box-integrate").css('display', 'block')
                  $(".makeit-take").css('display', '')
              else
                $("#drop-box-integrate").css('display', 'block')
                $(".am-the-db-sync").css("display", "none")
                $(".etcstuff").css("display", "block")
                $(".makeit-take").css('display', '')

        # $('.profile-image').attr 'src', "http://eot.evercam.io/eot.jpg"
        $('.profile-name').text user.displayName
      else
        window.location = '/'
      return
    return

createCameraInEvercam = (api_key, api_id, mac_address) ->
  data = {}
  data.name = "EOT Evercam"
  data.mac_address = "#{mac_address}"
  data.id = "#{mac_address.replace(/:\s*/g, "").toLowerCase()}"
  data.vendor = "other"
  data.model = "other"
  data.jpg_url = "image.jpg"
  data.external_http_port = 80
  data.external_host = "125.25.222.2"
  data.is_public = false
  data.discoverable = false
  data.api_id = "#{api_id}"
  data.api_key = "#{api_key}"

  onError = (result, status, jqXHR) ->
    console.log result
    # $.notify("#{result.responseText}", "error")
    false

  onSuccess = (result, status, jqXHR) ->
    $(".am-after-ajax").css("display", "")
    $("#image_processing").css("display", "none")
    $(".am-the-sync").css("display", "block")
    $("#when-sync-did").css("display", "block").html(
      "
        Last sync was <time class='timeago' datetime='#{moment.unix(moment().unix()).toISOString()}'>Date</time>
      "
    )
    $("time.timeago").timeago()
    $(".amDoneHere").css("display", "block")
    $(".openmein").css("display", "block").html(
      "
      <a href='https://dash.evercam.io/v1/cameras/#{mac_address.replace(/:\s*/g, "").toLowerCase()}?api_key=#{api_key}&api_id=#{api_id}' target='_blank'>
        <button class='ui negative button labeled icon' data-tooltip='Open it in Evercam.' data-delay='500'>
          <i class='camera retro icon'></i>
          Evercam
        </button>
      </a>
      "
    )
    console.log result
    true

  settings =
    cache: false
    dataType: 'json'
    data: data
    error: onError
    success: onSuccess
    type: "POST"
    url: "https://media.evercam.io/v1/cameras"

  $.ajax(settings)

deleteCameraInEvercam = (api_key, api_id, mac_address) ->
  data = {}
  data.api_id = "#{api_id}"
  data.api_key = "#{api_key}"

  onError = (result, status, jqXHR) ->
    console.log result
    # $.notify("#{result.responseText}", "error")
    false

  onSuccess = (result, status, jqXHR) ->
    console.log result
    true

  settings =
    cache: false
    dataType: 'json'
    data: data
    error: onError
    success: onSuccess
    type: "DELETE"
    url: "https://media.evercam.io/v1/cameras/#{mac_address.replace(/:\s*/g, "").toLowerCase()}"

  $.ajax(settings)


getObjectKeyIndex = (obj, keyToFind) ->
  i = 0
  key = undefined
  for key of obj
    `key = key`
    if key == keyToFind
      return i
    i++
  null

letSyncAgain = ->
  $(".letSyncAgain").on "click", ->
    $("#image_processing").css("display", "block").css("z-index", 999)
    startSync(iam_authenticated, user_email)
    $(".am-the-sync").css("display", "block")
    $("#when-sync-did").css("display", "block").html(
      "
        Last sync was <time class='timeago' datetime='#{moment.unix(moment().unix()).toISOString()}'>Date</time>
      "
    )
    $("time.timeago").timeago()
    setTimeout (->
      $("#image_processing").css('display', 'none').css("z-index", "")
      return
    ), 5000

letSyncDBAgain = -> 
  $(".letSyncDBAgain").on "click", ->
    $("#image_processing_db").css("display", "block").css("z-index", 999)
    uploadToDropBox(iam_authenticated, user_email)
    $(".am-the-db-sync").css("display", "block")
    $("#when-db-sync-did").css("display", "block").html(
      "
        Last sync was <time class='timeago_db' datetime='#{moment.unix(moment().unix()).toISOString()}'>Date</time>
      "
    )
    $("time.timeago_db").timeago()
    setTimeout (->
      $("#image_processing_db").css('display', 'none').css("z-index", "")
      return
    ), 5000

window.startSync = (auth, email) ->
  db_auth = auth.database().ref()
  obliged_email = "#{email}".replace(/\./g,'|')
  console.log obliged_email
  db_auth.once 'value', (snapshot) ->
    if !snapshot.hasChild(obliged_email)
      $(".heyyou").css('display', 'block')
      console.log "No data for SYNC"
    else
      db_auth.child("/#{obliged_email}").once 'value', (snapshot) ->
        indexVal = getObjectKeyIndex(snapshot.exportVal(), 'evercam')
        # if typeof Object.values(snapshot.val())[1] != 'undefined'
        lastSyncDateIs = Object.values(snapshot.val())[indexVal].lastSyncDate
        mac_address = Object.keys(snapshot.val())[0]
        api_key = Object.values(snapshot.val())[indexVal].apiKey
        api_id = Object.values(snapshot.val())[indexVal].apiId
        syncIs = Object.values(snapshot.val())[indexVal].syncIsOn
        console.log syncIs
        snapshot.forEach (childSnap) ->
          console.log childSnap

          if childSnap.val().Images != null
            logImageDataOnly(childSnap.val().Images)
            return

isset = (variable) ->
  if typeof variable != typeof undefined then true else false

logImageDataOnly = (Images) ->
  $.each Images, (timestamp, Image) ->
    tangRef = storageRef.child("#{Image.Path}")
    tangRef.getDownloadURL().then((url) ->
      if syncIs > 0
        console.log lastSyncDateIs
        console.log timestamp
        if timestamp > lastSyncDateIs
          updateSyncDate(iam_authenticated, user_email, timestamp, api_key, api_id, syncIs)
          sendItToSeaweedFS(url, mac_address, timestamp)
      else
        console.log "sync is off"
    ).catch (error) ->
      console.log error
      return

logImageDataOnlyDB = (Images) ->
  $.each Images, (timestamp, Image) ->
    tangRef = storageRef.child("#{Image.Path}")
    tangRef.getDownloadURL().then((url) ->
      if dropBoxSync > 0
        console.log lastSyncDateIs
        console.log timestamp
        if timestamp > lastSyncDateIs
          updateDBSyncDate(iam_authenticated, user_email, timestamp, accessToken, dropBoxSync)
          console.log "upload to DB"
          sendItToDB(url, mac_address, timestamp, accessToken)
      else
        console.log "dropBoxSync is off"
    ).catch (error) ->
      console.log error
      return

updateSyncDate = (auth, email, timestamp, api_key, api_id, syncIs) ->
  db_auth = auth.database().ref()
  obliged_email = "#{email}".replace(/\./g,'|')
  evercamRef = db_auth.child("#{obliged_email}")
  evercamRef.update
    evercam:
      apiKey: "#{api_key}"
      apiId: "#{api_id}"
      lastSyncDate: "#{timestamp}"
      syncIsOn: "#{syncIs}"
  console.log "done"

updateDBSyncDate = (auth, email, timestamp, accessToken, syncIs) ->
  db_auth = auth.database().ref()
  obliged_email = "#{email}".replace(/\./g,'|')
  dropboxRef = db_auth.child("#{obliged_email}")
  dropboxRef.update
    dropbox:
      accessToken: "#{accessToken}"
      lastSyncDate: "#{timestamp}"
      syncIsOn: "#{syncIs}"
  console.log "done"

sendItToDB = (url, mac_address, timestamp, accessToken) ->
  data = {}
  data.url = "#{url}"
  data.dir_name = "#{mac_address}"
  data.timestamp = "#{timestamp}"
  data.accessToken = "#{accessToken}"

  onError = (response) ->
    console.log response

  onSuccess = (response) ->
    console.log response

  settings =
    error: onError
    success: onSuccess
    data: data
    cache: false
    dataType: "json"
    type: "GET"
    url: "/send_to_DB"

  sendAJAXRequest(settings)

sendItToSeaweedFS = (url, mac_address, timestamp) ->
  data = {}
  data.url = "#{url}"
  data.dir_name = "#{mac_address}"
  data.timestamp = "#{timestamp}"

  onError = (response) ->
    console.log response

  onSuccess = (response) ->
    console.log response

  settings =
    error: onError
    success: onSuccess
    data: data
    cache: false
    dataType: "json"
    type: "GET"
    url: "/send_to_seaweedFS"

  sendAJAXRequest(settings)

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

onIntegrate = ->
  $("#integrate-me").on "click", ->
    $('.small.modal.integration').modal('show')

onDropBox = ->
  $("#drop-box-integrate").on "click", ->
    $('.small.modal.db-integration').modal('show')

onSaveValues = ->
  $(".lets-integrate").on "click", ->
    api_key = $(".api_key").val()
    api_id = $(".api_id").val()
    $("#integrate-me").css("display", "none")
    $("#revoke-me").css("display", "block")
    $(".etcstuff").css("display", "none")
    $(".am-after-ajax").css("display", "block")
    $("#image_processing").css("display", "block")
    addTable(firebase, user_email, api_key, api_id)
    createCameraInEvercam(api_key, api_id, mac_address)
    startSync(firebase, user_email)

onDBSaveValues = ->
  $(".lets-db-integrate").on "click", ->
    accessToken = $(".DROPBOX_ACCESS_TOKEN").val()
    $("#drop-box-integrate").css("display", "none")
    $(".etcstuffdb").css("display", "none")
    $("#revoke-db-me").css("display", "block")
    $(".am-after-ajax").css("display", "block")
    $("#image_processing_db").css("display", "block")
    addDBTokenToTable(firebase, user_email, accessToken)
    uploadToDropBox(firebase, user_email)

uploadToDropBox = (auth, email) ->
  db_auth = auth.database().ref()
  obliged_email = "#{email}".replace(/\./g,'|')
  console.log obliged_email
  db_auth.once 'value', (snapshot) ->
    if !snapshot.hasChild(obliged_email)
      $(".heyyou").css('display', 'block')
      console.log "No data for SYNC"
    else
      db_auth.child("/#{obliged_email}").once 'value', (snapshot) ->
        indexVal = getObjectKeyIndex(snapshot.exportVal(), 'dropbox')
        # if typeof Object.values(snapshot.val())[1] != 'undefined'
        lastSyncDateIs = Object.values(snapshot.val())[indexVal].lastSyncDate
        mac_address = Object.keys(snapshot.val())[0]
        accessToken = Object.values(snapshot.val())[indexVal].accessToken
        dropBoxSync = Object.values(snapshot.val())[indexVal].syncIsOn
        console.log dropBoxSync
        snapshot.forEach (childSnap) ->
          console.log childSnap

          if childSnap.val().Images != null
            logImageDataOnlyDB(childSnap.val().Images)
            return

onRevoke = ->
  $(".yesrevoke").on "click", ->
    deleteCameraInEvercam(api_key, api_id, mac_address)
    $("#integrate-me").css("display", "block")
    $(".etcstuff").css("display", "block")
    $("#revoke-me").css("display", "none")
    $(".openmein").css("display", "none").html("")
    $(".am-the-sync").css("display", "none")
    updateSyncDate(firebase, user_email, lastSyncDateIs, api_key, api_id, "0")

onRevokeDB = ->
  $(".yesrevokedb").on "click", ->
    $("#drop-box-integrate").css("display", "block")
    $(".etcstuffdb").css("display", "block")
    $("#revoke-db-me").css("display", "none")
    $(".am-the-db-sync").css("display", "none")
    updateDBSyncDate(firebase, user_email, lastSyncDateIs, accessToken, "0")

onRevokeMe = ->
  $("#revoke-me").on "click", ->
    $('.small.modal.revoke').modal('show')

onRevokeDBMe = ->
  $("#revoke-db-me").on "click", ->
    $('.small.modal.revokedb').modal('show')

addTable = (auth, email, api_key, api_id) ->
  db_auth = auth.database().ref()
  obliged_email = "#{email}".replace(/\./g,'|')
  evercamRef = db_auth.child("#{obliged_email}")
  evercamRef.update
    evercam:
      apiKey: "#{api_key}"
      apiId: "#{api_id}"
      syncIsOn: "1"
      lastSyncDate: '1293916756'

  console.log "done"

addDBTokenToTable = (auth, email, accessToken) ->
  db_auth = auth.database().ref()
  obliged_email = "#{email}".replace(/\./g,'|')
  dropboxRef = db_auth.child("#{obliged_email}")
  dropboxRef.update
    dropbox:
      accessToken: "#{accessToken}"
      syncIsOn: "1"
      lastSyncDate: '1293916756'

  console.log "done"
  $("#image_processing_db").css("display", "none")
  $(".am-the-db-sync").css("display", "block")
  $("#when-db-sync-did").html(
    "
      Last sync was <time class='timeago-db' datetime='#{moment.unix(moment().unix()).toISOString()}'>Date</time>
    "
  )
  $("time.timeago-db").timeago()

window.initializeIntegrations = ->
  moment.locale()
  startAuth()
  onLoad()
  onIntegrate()
  onSaveValues()
  onRevoke()
  onRevokeMe()
  letSyncAgain()
  onDropBox()
  onDBSaveValues()
  onRevokeDBMe()
  onRevokeDB()
  letSyncDBAgain()
  onSignOut()
