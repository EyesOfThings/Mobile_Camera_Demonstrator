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
  parent_width = (480 * 200) / 256
  padding_bottom = (256/480)*100
  tags = "image"
  $.each Images, (i, Image) ->
    tangRef = storageRef.child(capitalizeFirstLetter("#{Image.Path}"));
    tangRef.getDownloadURL().then((url) ->
      $.each Image.Tags, (i, value) ->
        if value == 1
          tags += " #{i}"
        # console.log "#{i} : #{value}"
      console.log tags
      image_tag =
        "<div data-tags='#{tags}' class='image-parent' style='width:#{parent_width}px;flex-grow:#{parent_width}'>
          <i style='padding-bottom:#{padding_bottom}%'></i>
          <img class='image-itself' src='#{url}' />
        </div>"
      $("section").append(image_tag)
      tags = "image"
    ).catch (error) ->
      console.log error
      return

filterImages = (e) ->
  regex = new RegExp('\\b\\w*' + e + '\\w*\\b')
  $('.image-parent').hide().filter(->
    regex.test $(this).data('tags')
  ).show()
  return

onImageSearch = ->
  $('.radio-inline').on "click", ->
    console.log $('input[name=optradio]:checked').val()
    selectTag = $('input[name=optradio]:checked').val()
    filterImages(selectTag)
    return

window.initializeHome = ->
  getAuthWithFirebase()
  setTimeout (->
    $("#image_processing").css('display', 'none')
    return
  ), 5000
  onImageSearch()
