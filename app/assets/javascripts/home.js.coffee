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
  tags = "image"
  $.each Images, (i, Image) ->
    tangRef = storageRef.child(capitalizeFirstLetter("#{Image.Path}"));
    tangRef.getDownloadURL().then((url) ->
      $.each Image.Tags, (i, value) ->
        if value == 1
          tags += " #{i}"
      image_tag =
        "<figure data-tags='#{tags}' itemprop='associatedMedia' itemscope itemtype='http://schema.org/ImageObject' class='for-filter'>
          <a href='#{url}' itemprop='contentUrl' data-size='480x256'>
            <img src='#{url}' itemprop='thumbnail' alt='Image descriptio' />
          </a>
          <figcaption itemprop='caption description'>#{tags}</figcaption>
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
  # $('.rad').on 'click', ->
  #   val = $(this).closest('input').find('input[name=\'r1\']').val()

    # console.log val
  $('.rad').on "click", ->
    console.log $('input[name=r1]:checked').val()
    selectTag = $('input[name=r1]:checked').val()
    filterImages(selectTag)
    return

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

window.initializeHome = ->
  getAuthWithFirebase()
  setTimeout (->
    $("#image_processing").css('display', 'none')
    return
  ), 5000
  onImageSearch()
