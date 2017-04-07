storage = undefined
storageRef = undefined

getAuthWithFirebase = ->
  config = 
    apiKey: 'FAKE'
    authDomain: 'FAKE'
    databaseURL: 'FAKE'
    storageBucket: 'FAKE'

  firebase.initializeApp config
  storage = firebase.storage()
  storageRef = storage.ref()

  firebase.database().ref().child('/visilabeot@gmail|com').once 'value', (snapshot) ->
    snapshot.forEach (childSnap) ->
      if childSnap.val().Images != null
        logImageDataOnly(childSnap.val().Images)
        return

logImageDataOnly = (Images) ->
  console.log Images
  $.each Images, (i, Image) ->
    console.log Image.Path
    # storageRef.child("#{Image.Path}").getDownloadURL().then((url) ->
    #   # `url` is the download URL for 'images/stars.jpg'
    #   # This can be downloaded directly:
    #   xhr = new XMLHttpRequest
    #   xhr.responseType = 'blob'

    #   xhr.onload = (event) ->
    #     blob = xhr.response
    #     return

    #   xhr.open 'GET', url
    #   xhr.send()
    #   console.log url
    #   # Or inserted into an <img> element:
    #   # img = document.getElementById('myimg')
    #   # img.src = url
    #   # return
    # ).catch (error) ->
    #   # Handle any errors
    #   return

    # console.log Image.Path
    # console.log Image.Tags

window.initializeHome = ->
  console.log CurrentUser.oauth_token
  getAuthWithFirebase()
  console.log "hi"