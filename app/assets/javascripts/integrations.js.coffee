user_email = undefined

window.startAuth = ->
  config = 
    apiKey: AuthData.apiKey
    authDomain: AuthData.authDomain
    databaseURL: AuthData.databaseURL
    storageBucket: AuthData.storageBucket

  window.firebase.initializeApp config
  window.storage = firebase.storage()
  window.storageRef = storage.ref()

onLoad = ->
  $(window).load ->
    firebase.auth().onAuthStateChanged (user) ->
      if user
        console.log user.email
        user_email = user.email
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

onIntegrate = ->
  $("#integrate-me").on "click", ->
    $('.small.modal').modal('show')

onSaveValues = ->
  $(".lets-integrate").on "click", ->
    api_key = $(".api_key").val()
    api_id = $(".api_id").val()
    $("#integrate-me").css("display", "none")
    $("#revoke-me").css("display", "block")
    addTable(firebase, user_email, api_key, api_id)

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
  onSignOut()
