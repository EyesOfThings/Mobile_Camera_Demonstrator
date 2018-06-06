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
        console.log user.email
        user_email = user.email
        iam_authenticated = firebase
        db_auth = firebase.database().ref()
        obliged_email = "#{user_email}".replace(/\./g,'|')
        console.log obliged_email

        # $('.profile-image').attr 'src', "http://eot.evercam.io/eot.jpg"
        loadWizards()
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

onWizard = ->
  $(".wizards-do").on "click", ->
    $(".show-on-wizard")
      .css("display", "block")
      .css("margin", "10px")
      .fadeIn("slow")

onCancel = ->
  $(".can-wizard").on "click", ->
    $(".show-on-wizard")
      .css("display", "none")
      .css("margin", "10px")
      .fadeOut("slow")

onWizardSave = ->
  $(".wizard_save").on "click", ->
    $(".show-on-wizard")
      .css("display", "none")
      .css("margin", "10px")
      .fadeOut("slow")
    wizardState = $("#wizard_state").val()
    wizardEmail = $("#wizard_email").val()

    data = {}
    data.state = wizardState
    data.email = wizardEmail
    data.is_working = true

    onError = (jqXHR, textStatus, errorThrown) ->
      console.log jqXHR
      $.notify("#{result.responseText}", "error")
      false

    onSuccess = (wizard, textStatus, jqXHR) ->
      wizadData = "
      <div class='ui segment' style='overflow: hidden;'>
        <div class='content' style='float: left;'>
          If <font class='make-it-20'><i class='em em-#{giveState(wizard.state)} layout icon'></i></font> then notify
          <span>
            <i class='announcement icon'></i>
            #{wizard.email}
          </span> 
        </div>
        <div class='content' style='float: right'>
          <div data-content='#{wizardText(wizard.is_working)}' data-id='#{wizard.id}' id='toggleIsWorking' class='wizardPopUp ui toggle button #{isWorking(wizard.is_working)}'>
          </div>
        </div>
      </div>
      "
      $("#wizard_attachment").append(wizadData)
      $("#wizard_attachment").css('display', 'block')
      $('.ui.checkbox').checkbox()
      $('.ui.button.toggle').state()
      $('.ui.dropdown').dropdown()
      $('.ui.radio.checkbox').checkbox()
      $('.wizardPopUp').popup on: 'hover'
      $.notify("Wizard has been created.", "success");
      true

    settings =
      cache: false
      dataType: 'json'
      data: data
      error: onError
      success: onSuccess
      type: "POST"
      url: "/create_wizard"

    $.ajax(settings)

giveState = (state) ->
  switch state
    when "Normal"
      "face_with_cowboy_hat"
    when "Anger"
      "angry"
    when "Disgust"
      "persevere"
    when "Fear"
      "worried"
    when "Happiness"
      "smile"
    when "LargeFaceDetected"
      "zombie"
    when "Neutral"
      "neutral_face"
    when "MotionDetected"
      "juggling"
    when "Sadness"
      "pensive"
    when "Surprise"
      "open_mouth"

isWorking = (is_working) ->
  if is_working == true || is_working == "true"
    "active"
  else
    ""

toggleIsWorking = ->
  $("#wizard_attachment").on "click", "#toggleIsWorking", ->
    isWorking = $(this).hasClass("active")
    if isWorking == true
      $(this).attr('data-content', 'Disable wizard.')
    else
      $(this).attr('data-content', 'Enable wizard.')

    data = {}
    data.is_working = isWorking
    data.id = $(this).data('id')

    onError = (jqXHR, textStatus, errorThrown) ->
      console.log jqXHR
      $.notify("#{result.responseText}", "error")
      false

    onSuccess = (data, textStatus, jqXHR) ->
      console.log data
      $.notify("Wizard has been updated.", "success");
      true

    settings =
      cache: false
      dataType: 'json'
      data: data
      error: onError
      success: onSuccess
      type: "POST"
      url: "/update_wizards"

    $.ajax(settings)

wizardText = (is_working) ->
  if is_working == true || is_working == "true"
    "Disable wizard."
  else
    "Enable wizard."

loadWizards = ->
  data = {}

  onError = (jqXHR, textStatus, errorThrown) ->
    console.log jqXHR
    $.notify("#{result.responseText}", "error")
    false

  onSuccess = (data, textStatus, jqXHR) ->
    console.log data
    if data.length > 0
      data.forEach (wizard) ->
        wizadData = "
        <div class='ui segment' style='overflow: hidden;'>
          <div class='content' style='float: left;'>
            If <font class='make-it-20'><i class='em em-#{giveState(wizard.state)} layout icon'></i></font> then notify
            <span>
              <i class='announcement icon'></i>
              #{wizard.email}
            </span> 
          </div>
          <div class='content' style='float: right'>
            <div data-content='#{wizardText(wizard.is_working)}' data-id='#{wizard.id}' id='toggleIsWorking' class='wizardPopUp ui toggle button #{isWorking(wizard.is_working)}'>
            </div>
          </div>
        </div>
        "
        $("#wizard_attachment").append(wizadData)
        $("#wizard_attachment").css('display', 'block')
      $.notify("Wizard has been loaded.", "success")
    else
      $.notify("No wizards available.", "info");
    $('.ui.checkbox').checkbox()
    $('.ui.button.toggle').state()
    $('.ui.dropdown').dropdown()
    $('.ui.radio.checkbox').checkbox()
    $('.wizardPopUp').popup on: 'hover'
    true

  settings =
    cache: false
    dataType: 'json'
    data: data
    error: onError
    success: onSuccess
    type: "GET"
    url: "/load_wizards"

  $.ajax(settings)

window.initializeWizards = ->
  moment.locale()
  startAuth()
  onLoad()
  onWizard()
  onCancel()
  onSignOut()
  onWizardSave()
  toggleIsWorking()
