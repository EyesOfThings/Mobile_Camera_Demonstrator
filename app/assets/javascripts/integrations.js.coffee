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
        console.log user.email
        user_email = user.email
        iam_authenticated = firebase
        db_auth = firebase.database().ref()
        obliged_email = "#{user_email}".replace(/\./g,'|')
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
              mac_address = Object.keys(snapshot.val())[0]
              if typeof Object.values(snapshot.val())[2] != 'undefined'
                syncIs = Object.values(snapshot.val())[2].syncIsOn
                if syncIs > 0
                  lastSyncDateIs = Object.values(snapshot.val())[2].lastSyncDate
                  $(".am-the-sync").css("display", "block")
                  $("#when-sync-did").html(
                    "
                      Last sync was <time class='timeago' datetime='#{moment.unix(moment().unix()).toISOString()}'>Date</time>
                    "
                  )
                  $("time.timeago").timeago()
                  startSync(iam_authenticated, user_email)
                  mac_address = Object.keys(snapshot.val())[0]
                  api_key = Object.values(snapshot.val())[2].apiKey
                  api_id = Object.values(snapshot.val())[2].apiId
                  syncIs = Object.values(snapshot.val())[2].syncIsOn
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
        $('.profile-image').attr 'src', user.photoURL
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
  data.jpg_url = "imag.jpg"
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
        # if typeof Object.values(snapshot.val())[1] != 'undefined'
        lastSyncDateIs = Object.values(snapshot.val())[2].lastSyncDate
        mac_address = Object.keys(snapshot.val())[0]
        api_key = Object.values(snapshot.val())[2].apiKey
        api_id = Object.values(snapshot.val())[2].apiId
        syncIs = Object.values(snapshot.val())[2].syncIsOn
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

onRevoke = ->
  $(".yesrevoke").on "click", ->
    deleteCameraInEvercam(api_key, api_id, mac_address)
    $("#integrate-me").css("display", "block")
    $(".etcstuff").css("display", "block")
    $("#revoke-me").css("display", "none")
    $(".openmein").css("display", "none").html("")
    $(".am-the-sync").css("display", "none")
    updateSyncDate(firebase, user_email, lastSyncDateIs, api_key, api_id, "0")

onRevokeMe = ->
  $("#revoke-me").on "click", ->
    $('.small.modal.revoke').modal('show')  

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

window.initializeIntegrations = ->
  moment.locale()
  startAuth()
  onLoad()
  onIntegrate()
  onSaveValues()
  onRevoke()
  onRevokeMe()
  letSyncAgain()
  onSignOut()
