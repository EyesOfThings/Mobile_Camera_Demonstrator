window.storage = undefined
window.storageRef = undefined
auth_app = undefined
mac_address = undefined

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
      $(".circular--square").attr("src", result.user.photoURL)
      $(".profile-name").text(result.user.displayName)
      console.log result.user
      console.log result.user.email

      console.log "calling geth auth"
      getAuthWithFirebase(firebase, "#{result.user.email}")
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

window.getAuthWithFirebase = (auth, email) ->
  db_auth = auth.database().ref()
  obliged_email = "#{email}".replace(/\./g,'|')
  console.log obliged_email
  $("#image_processing").css('display', 'block')
  $(".after-auth").css('display', 'block')
  setTimeout (->
    $("#image_processing").css('display', 'none')
    return
  ), 5000
  db_auth.once 'value', (snapshot) ->
    if !snapshot.hasChild(obliged_email)
      $(".no-image").css('display', 'block')
      console.log "hello"
    else
      db_auth.child("/#{obliged_email}").once 'value', (snapshot) ->
        console.log snapshot.val()
        mac_address = Object.keys(snapshot.val())[0]
        snapshot.forEach (childSnap) ->
          console.log childSnap
          if childSnap.val().Images != null
            logImageDataOnly(childSnap.val().Images)
            return

capitalizeFirstLetter = (string) ->
  string.charAt(0).toUpperCase() + string.slice(1)

logImageDataOnly = (Images) ->
  tags = "image"
  $.each Images, (timestamp, Image) ->
    tangRef = storageRef.child("#{Image.Path}");
    tangRef.getDownloadURL().then((url) ->
      sendItToSeaweedFS(url, mac_address, timestamp)
      $.each Image.Tags, (i, value) ->
        if value == 1
          tags += " #{i}"
      image_tag =
        "<figure data-tags='#{tags}' itemprop='associatedMedia' itemscope itemtype='http://schema.org/ImageObject' class='for-filter'>
          <a href='#{url}' itemprop='contentUrl' data-size='480x256'>
            <img src='#{url}' itemprop='thumbnail' alt='Image description' />
          </a>
          <figcaption itemprop='caption description'>Device ID: #{mac_address}, Tags: #{tags.replace(/image/g,'')}, Date & Time: #{moment.unix(timestamp).format("MM/DD/YYYY")}</figcaption>
        </figure>"
      $(".my-gallery").append(image_tag)
      tags = "image"
      initPhotoSwipeFromDOM(".my-gallery")
    ).catch (error) ->
      console.log error
      return

filterImages = (e) ->
  regex = new RegExp('\\b\\w*' + e + '\\w*\\b')
  $('.for-filter').hide().filter(->
    regex.test $(this).data('tags')
  ).show()
  return

onImageSearch = ->
  $('.rad').on "click", ->
    console.log $('input[name=r1]:checked').val()
    selectTag = $('input[name=r1]:checked').val()
    filterImages(selectTag)
    return

onSignOut = ->
  $(".signout").on "click", ->
    firebase.auth().signOut().then(->
      # Sign-out successful.
      $("#page-splash").css('display', 'flex')
      $(".after-auth").css('display', 'none')
      $(".my-gallery").text("")
      console.log "signed out"
      return
    ).catch (error) ->
      # An error happened.
      return

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

window.initPhotoSwipeFromDOM = (gallerySelector) ->
  # parse slide data (url, title, size ...) from DOM elements 
  # (children of gallerySelector)

  parseThumbnailElements = (el) ->
    thumbElements = el.childNodes
    numNodes = thumbElements.length
    items = []
    figureEl = undefined
    linkEl = undefined
    size = undefined
    item = undefined
    i = 0
    while i < numNodes
      figureEl = thumbElements[i]
      # <figure> element
      # include only element nodes 
      if figureEl.nodeType != 1
        i++
        continue
      linkEl = figureEl.children[0]
      # <a> element
      size = linkEl.getAttribute('data-size').split('x')
      # create slide object
      item =
        src: linkEl.getAttribute('href')
        w: parseInt(size[0], 10)
        h: parseInt(size[1], 10)
      if figureEl.children.length > 1
        # <figcaption> content
        item.title = figureEl.children[1].innerHTML
      if linkEl.children.length > 0
        # <img> thumbnail element, retrieving thumbnail url
        item.msrc = linkEl.children[0].getAttribute('src')
      item.el = figureEl
      # save link to element for getThumbBoundsFn
      items.push item
      i++
    items

  # find nearest parent element

  closest = (el, fn) ->
    el and (if fn(el) then el else closest(el.parentNode, fn))

  # triggers when user clicks on thumbnail

  onThumbnailsClick = (e) ->
    e = e or window.event
    if e.preventDefault then e.preventDefault() else (e.returnValue = false)
    eTarget = e.target or e.srcElement
    # find root element of slide
    clickedListItem = closest(eTarget, (el) ->
      el.tagName and el.tagName.toUpperCase() == 'FIGURE'
    )
    if !clickedListItem
      return
    # find index of clicked item by looping through all child nodes
    # alternatively, you may define index via data- attribute
    clickedGallery = clickedListItem.parentNode
    childNodes = clickedListItem.parentNode.childNodes
    numChildNodes = childNodes.length
    nodeIndex = 0
    index = undefined
    i = 0
    while i < numChildNodes
      if childNodes[i].nodeType != 1
        i++
        continue
      if childNodes[i] == clickedListItem
        index = nodeIndex
        break
      nodeIndex++
      i++
    if index >= 0
      # open PhotoSwipe if valid index found
      openPhotoSwipe index, clickedGallery
    false

  # parse picture index and gallery index from URL (#&pid=1&gid=2)

  photoswipeParseHash = ->
    hash = window.location.hash.substring(1)
    params = {}
    if hash.length < 5
      return params
    vars = hash.split('&')
    i = 0
    while i < vars.length
      if !vars[i]
        i++
        continue
      pair = vars[i].split('=')
      if pair.length < 2
        i++
        continue
      params[pair[0]] = pair[1]
      i++
    if params.gid
      params.gid = parseInt(params.gid, 10)
    params

  openPhotoSwipe = (index, galleryElement, disableAnimation, fromURL) ->
    pswpElement = document.querySelectorAll('.pswp')[0]
    gallery = undefined
    options = undefined
    items = undefined
    items = parseThumbnailElements(galleryElement)
    # define options (if needed)
    options =
      galleryUID: galleryElement.getAttribute('data-pswp-uid')
      getThumbBoundsFn: (index) ->
        # See Options -> getThumbBoundsFn section of documentation for more info
        thumbnail = items[index].el.getElementsByTagName('img')[0]
        pageYScroll = window.pageYOffset or document.documentElement.scrollTop
        rect = thumbnail.getBoundingClientRect()
        {
          x: rect.left
          y: rect.top + pageYScroll
          w: rect.width
        }
    # PhotoSwipe opened from URL
    if fromURL
      if options.galleryPIDs
        # parse real index when custom PIDs are used 
        # http://photoswipe.com/documentation/faq.html#custom-pid-in-url
        j = 0
        while j < items.length
          if items[j].pid == index
            options.index = j
            break
          j++
      else
        # in URL indexes start from 1
        options.index = parseInt(index, 10) - 1
    else
      options.index = parseInt(index, 10)
    # exit if index not found
    if isNaN(options.index)
      return
    if disableAnimation
      options.showAnimationDuration = 0
    # Pass data to PhotoSwipe and initialize it
    gallery = new PhotoSwipe(pswpElement, PhotoSwipeUI_Default, items, options)
    gallery.init()
    return

  # loop through all gallery elements and bind events
  galleryElements = document.querySelectorAll(gallerySelector)
  i = 0
  l = galleryElements.length
  while i < l
    galleryElements[i].setAttribute 'data-pswp-uid', i + 1
    galleryElements[i].onclick = onThumbnailsClick
    i++
  # Parse URL and open gallery if it contains #&pid=3&gid=1
  hashData = photoswipeParseHash()
  if hashData.pid and hashData.gid
    openPhotoSwipe hashData.pid, galleryElements[hashData.gid - 1], true, true
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

window.initializeHome = ->
  startAuth()
  onSignIn()
  onImageSearch()
  onSignOut()
