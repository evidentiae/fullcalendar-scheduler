
# NOTE: for public methods, always be sure of the return value. for chaining

class CalendarExtension extends Calendar

	resourceManager: null


	initialize: -> # don't need to call super or anything
		@resourceManager = new ResourceManager(this)


	instantiateView: (viewType) ->
		spec = @getViewSpec(viewType)
		viewClass = spec['class']

		if @options.resources and spec.options.resources != false
			if spec.queryResourceClass
				viewClass = spec.queryResourceClass(spec) or viewClass # might return falsy
			else if spec.resourceClass
				viewClass = spec.resourceClass

		new viewClass(this, viewType, spec.options, spec.duration)


	# for the API only
	# retrieves what is currently in memory. no fetching
	getResources: ->
		@resourceManager.topLevelResources


	addResource: (resourceInput, scroll=false) -> # assumes all resources already loaded
		promise = @resourceManager.addResource(resourceInput)

		if scroll and @view.scrollToResource
			promise.done (resource) =>
				@view.scrollToResource(resource)

		return


	removeResource: (idOrResource) -> # assumes all resources already loaded
		@resourceManager.removeResource(idOrResource)


	refetchResources: -> # for API
		@resourceManager.fetchResources()
		return


	rerenderResources: -> # for API
		@view.redisplayResources?()
		return


	getEventResourceId: (event) ->
		@resourceManager.getEventResourceId(event)


	# this method will take effect for *all* views, event ones that don't explicitly
	# support resources. shouln't assume a resourceId on the span or event.
	# `event` can be null.
	getPeerEvents: (span, event) ->
		peerEvents = super

		# if the span (basically the target drop area) has a resource, use its ID.
		# otherwise, assume the the event wants to keep it's existing resource ID.
		newResourceId = span.resourceId or (event and @getEventResourceId(event)) or ''

		filteredPeerEvents = []
		for peerEvent in peerEvents
			peerResourceId = @getEventResourceId(peerEvent) or ''
			if not peerResourceId or peerResourceId == newResourceId
				filteredPeerEvents.push(peerEvent)

		filteredPeerEvents


	buildSelectSpan: (startInput, endInput, resourceId) ->
		span = super
		if resourceId
			span.resourceId = resourceId
		span


	getResourceById: (id) ->
		@resourceManager.getResourceById(id)


	# NOTE: views pair *segments* to resources. that's why there's no code reuse
	getResourceEvents: (idOrResource) ->
		resource =
			if typeof idOrResource == 'object'
				idOrResource
			else
				@getResourceById(idOrResource)
		if resource
			eventResourceField = @resourceManager.getEventResourceField()
			@clientEvents (event) -> # return value
				event[eventResourceField] == resource.id
		else
			[]


	getEventResource: (idOrEvent) ->
		event =
			if typeof idOrEvent == 'object'
				idOrEvent
			else
				@clientEvents(idOrEvent)[0]
		if event
			resourceId = @resourceManager.getEventResourceId(event)
			return @getResourceById(resourceId)
		return null


Calendar.prototype = CalendarExtension.prototype # nothing subclasses Calendar, so this is okay
