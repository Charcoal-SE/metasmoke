# From glennfu on Github Gist: https://gist.github.com/glennfu/936548b58091f284dbb5c1a769130bfc

OldHttpRequest = Turbolinks.HttpRequest

class Turbolinks.CachedHttpRequest extends Turbolinks.HttpRequest
  constructor: (_, location, referrer) ->
    super(this, location, referrer)

  requestCompletedWithResponse: (response, redirectedToLocation) ->
    @response = response
    @redirect = redirectedToLocation

  requestFailedWithStatusCode: (code) ->
    @failCode = code

  oldSend: ->
    if @xhr and not @sent
      @notifyApplicationBeforeRequestStart()
      @setProgress(0)
      @xhr.send()
      @sent = true
      @delegate?.requestStarted?()

  send: () ->
    if @failCode
      @delegate.requestFailedWithStatusCode(@failCode, @failText)
    else if @response
      @delegate.requestCompletedWithResponse(@response, @redirect)
    else
      @oldSend()


class Turbolinks.HttpRequest
  constructor: (delegate, location, referrer) ->
    cache = Turbolinks.controller.cache.get("prefetch" + location)
    if cache
      Turbolinks.controller.cache.delete("prefetch" + location)
      cache.delegate = delegate
      return cache
    else
      return new OldHttpRequest(delegate, location, referrer)

(Turbolinks.Cache || Turbolinks.SnapshotCache)::delete = (location) ->
  key = Turbolinks.Location.wrap(location).toCacheKey()
  delete @snapshots[key]

preload = (event) ->
  if link = Turbolinks.controller.getVisitableLinkForNode(event.target)
    if location = Turbolinks.controller.getVisitableLocationForLink(link)
      if Turbolinks.controller.applicationAllowsFollowingLinkToLocation(link, location)
        if (method = link.attributes["data-method"])? && method.value != 'get'
          return
        if location.anchor or location.absoluteURL.endsWith("#")
          return
        if location.absoluteURL == window.location.href
          return

        # If Turbolinks has already cached this location internally, use that default behavior
        # otherwise we can try and prefetch it here
        cache = Turbolinks.controller.cache.get(location)
        if !cache
          cache = Turbolinks.controller.cache.get("prefetch" + location)

        if !cache
          request = new Turbolinks.CachedHttpRequest(null, location, window.location)
          Turbolinks.controller.cache.put("prefetch" + location, request)
          request.send()

document.addEventListener("touchstart", preload)
document.addEventListener("mouseover", preload)
