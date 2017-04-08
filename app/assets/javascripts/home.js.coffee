storage = undefined
storageRef = undefined

getAuthWithFirebase = ->
  $("#image_processing").css('display', 'block')
  config = 
    apiKey: AuthData.apiKey
    authDomain: AuthData.authDomain
    databaseURL: AuthData.databaseURL
    storageBucket: AuthData.storageBucket

  firebase.initializeApp config
  storage = firebase.storage()
  storageRef = storage.ref()

  firebase.database().ref().child('/visilabeot@gmail|com').once 'value', (snapshot) ->
    snapshot.forEach (childSnap) ->
      if childSnap.val().Images != null
        logImageDataOnly(childSnap.val().Images)
        return

capitalizeFirstLetter = (string) ->
  string.charAt(0).toUpperCase() + string.slice(1)

logImageDataOnly = (Images) ->
  $.each Images, (i, Image) ->
    tangRef = storageRef.child(capitalizeFirstLetter("#{Image.Path}"));
    tangRef.getDownloadURL().then((url) ->
      console.log Image.Path
      console.log url
      image_tag = "<img data-width='480' data-height='256' src='#{url}' />"
      $(".google-image-layout").append(image_tag)
      GoogleImageLayout.init()
    ).catch (error) ->
      console.log error
      return

window.initializeHome = ->
  getAuthWithFirebase()
  setTimeout (->
    $("#image_processing").css('display', 'none')
    return
  ), 5000
