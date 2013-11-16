debug = window.console.debug
###
Documentation can be generated using {https://github.com/coffeedoc/codo Codo}
###


###
Add a script to head with the given @scriptUrl
###
addScriptTag = (scriptUrl)->
	tag = document.createElement 'script'
	tag.src = scriptUrl
	firstScriptTag = document.getElementsByTagName('script')[0]
	firstScriptTag.parentNode.insertBefore tag, firstScriptTag

###
Soundcloud Media Controller - Wrapper for Soundcloud Media API
API SC.Widget documentation: http://developers.soundcloud.com/docs/api/html5-widget
API Track documentation: http://developers.soundcloud.com/docs/api/reference#tracks
@param [videojs.Player] player
@param [Object] options soundcloudClientId is mandatory!
@param [Function] ready
###
videojs.Soundcloud = videojs.MediaTechController.extend
	init: (player, options, ready)->
		videojs.MediaTechController.call(@, player, options, ready)

		# Define which features we provide
		@features.fullscreenResize = true
		@features.volumeControl = true

		@player_ = player
		@player_el_ = document.getElementById @player_.id()

		# Copy the Javascript options if they exist
		if typeof options.source != 'undefined'
			for key in options.source
				@player_.options()[key] = options.source[key]
		@clientId = @player_.options().soundcloudClientId
		@soundcloudSource = @player_.options().src || ""

		# Create the iframe for the soundcloud API
		@scWidgetId = @player_.id() + '_soundcloud_api'
		@scWidgetElement = videojs.Component.prototype.createEl 'iframe',
			id: @scWidgetId
			className: 'vjs-tech'
			scrolling: 'no'
			marginWidth: 0
			marginHeight: 0
			frameBorder: 0
			webkitAllowFullScreen: "true"
			mozallowfullscreen: "true"
			allowFullScreen: "true"
			style: "visibility: hidden;"
			src: "https://w.soundcloud.com/player/?url=#{@soundcloudSource}"

		@player_el_.appendChild @scWidgetElement
		@player_el_.classList.add "backgroundContainer"
		debug "added widget div"

		# Make autoplay work for iOS
		if @player_.options().autoplay
			@playOnReady = true

		# Load Soundcloud API
		if videojs.Soundcloud.apiReady
			@loadSoundcloud()
		else
			# Load the Soundcloud API if it is the first Soundcloud video
			if not videojs.Soundcloud.apiLoading
				###
				Initiate the soundcloud tech once the API is ready
				###
				checkSoundcloudApiReady = =>
					if typeof window.SC != "undefined"
						videojs.Soundcloud.apiReady = true
						@onApiReady()
						clearInterval videojs.Soundcloud.intervalId
				addScriptTag "https://w.soundcloud.com/player/api.js"
				addScriptTag "http://connect.soundcloud.com/sdk.js"
				videojs.Soundcloud.apiLoading = true
				videojs.Soundcloud.intervalId = setInterval checkSoundcloudApiReady, 500

###
Set up everything to use soundcloud's streaming API
###
videojs.Soundcloud.prototype.onApiReady = ->
	SC.initialize client_id: @clientId

	# Get all the information we need from the soundcloud src
	SC.get "/resolve", url: @player_.options().src, (item) =>
		if item.errors
			debug item.errors # TODO we have an error... wat do?
		else if item.kind == "track"
			# Add artwork if nothing isn't being used yet
			if not @player_.poster() and item.artwork_url
				@player_.poster(item.artwork_url)

			# We will embed the player => streaming API always uses 128 kb stream
			@scWidgetElement.src = "https://w.soundcloud.com/player/?url=#{item.permalink_url}"
			@loadSoundcloud()

		else if item.kind == "playlist"
			debug "It's a playlist ladies and gentlemen" # TODO how do we create a playlist with videojs?

###
Destruct the tech and it's DOM elements
###
videojs.Soundcloud.prototype.dispose = ->
	debug "dispose"
	if @scWidgetElement
		@scWidgetElement.remove()
		debug "Removed widget Element"
		debug @scWidgetElement
	@player_.el().classList.remove "backgroundContainer"
	@player_.el().style.backgroundImage = ""
	debug "removed CSS"
	delete @soundcloudPlayer if @soundcloudPlayer
	@isReady_ = false


videojs.Soundcloud.prototype.src = (src)->
	@soundcloudPlayer.load src, {}

videojs.Soundcloud.prototype.play = ->
	if @isReady_
		debug "play"
		@soundcloudPlayer.play()
	else
		debug "to play on ready"
		# We will play it when the API will be ready
		@playOnReady = true

###
Toggle the playstate between playing and paused
###
videojs.Soundcloud.prototype.toggle = ->
	debug "toggle"
	# We used @player_ to trigger events for changing the display
	if @player_.paused()
		@player_.play()
	else
		@player_.pause()

videojs.Soundcloud.prototype.pause = ->
	@soundcloudPlayer.pause()
videojs.Soundcloud.prototype.paused = ->
	@paused_

###
@return track time in seconds
###
videojs.Soundcloud.prototype.currentTime = ->
	debug "currentTime #{@durationMilliseconds * @playPercentageDecimal / 1000}"
	@durationMilliseconds * @playPercentageDecimal / 1000

videojs.Soundcloud.prototype.setCurrentTime = (seconds)->
	debug "setCurrentTime"
	@soundcloudPlayer.seekTo(seconds*1000)
	@player_.trigger('timeupdate')

###
@return total length of track in seconds
###
videojs.Soundcloud.prototype.duration = ->
	#debug "duration: #{@durationMilliseconds / 1000}"
	@durationMilliseconds / 1000

# TODO Fix buffer-range calculations
videojs.Soundcloud.prototype.buffered = ->
	timePassed = @duration() * @loadPercentageDecimal
	videojs.createTimeRange 0, timePassed

videojs.Soundcloud.prototype.volume = ->
	debug "volume: #{@volumeVal}"
	@volumeVal

videojs.Soundcloud.prototype.setVolume = (percentAsDecimal)->
	debug "setVolume(#{percentAsDecimal})"
	if percentAsDecimal != @volumeVal
		@volumeVal = percentAsDecimal
		@soundcloudPlayer.setVolume(@volumeVal * 100)
		@player_.trigger('volumechange')

videojs.Soundcloud.prototype.muted = ->
	debug "muted: #{@volumeVal == 0}"
	@volumeVal == 0

###
Soundcloud doesn't do muting so we need to handle that.

A possible pitfall is when this is called with true and the volume has been changed elsewhere.
We will use @unmutedVolumeVal

@param {Boolean}
###
videojs.Soundcloud.prototype.setMuted = (muted)->
	debug "setMuted(#{muted})"
	if muted
		@unmuteVolume = @volumeVal
		@setVolume 0
	else
		@setVolume @unmuteVolume


###
Take a wild guess ;)
###
videojs.Soundcloud.isSupported = ->
	debug "isSupported: #{true}"
	return true

###
Fullscreen of audio is just enlarging making the container fullscreen and using it's poster as a placeholder.
###
videojs.Soundcloud.prototype.supportsFullScreen = ()->
	debug "we support fullscreen!"
	return true

###
Fullscreen of audio is just enlarging making the container fullscreen and using it's poster as a placeholder.
###
videojs.Soundcloud.prototype.enterFullScreen = ()->
	debug "enterfullscreen"
	@scWidgetElement.webkitEnterFullScreen()

###
We return the player's container to it's normal (non-fullscreen) state.
###
videojs.Soundcloud.prototype.exitFullScreen = ->
	debug "EXITfullscreen"
	@scWidgetElement.webkitExitFullScreen()

###
Simple URI host check of the given url to see if it's really a soundcloud url
@param url {String}
###
videojs.Soundcloud.prototype.isSoundcloudUrl = (url)->
	uri = new URI url

	switch uri.host
		when "www.soundcloud.com"
		when "soundcloud.com"
			debug "Can play '#{url}'"
			return true
		else
			return false

###
We expect "audio/soundcloud" or a src containing soundcloud
###
videojs.Soundcloud.prototype.canPlaySource = videojs.Soundcloud.canPlaySource = (source)->
	if typeof source == "string"
		return videojs.Soundcloud::isSoundcloudUrl source
	else
		debug "Can play source?"
		debug source
		ret = (source.type == 'audio/soundcloud') or videojs.Soundcloud::isSoundcloudUrl(source.src)
		debug ret
		return ret


###
Take care of loading the Soundcloud API
###
videojs.Soundcloud.prototype.loadSoundcloud = ->
	debug "loadSoundcloud"
	@soundcloudPlayer = SC.Widget @scWidgetElement
	@soundcloudPlayer.bind SC.Widget.Events.READY, =>
		@onReady()

	@soundcloudPlayer.bind SC.Widget.Events.PLAY_PROGRESS, (eventData)=>
		@onPlayProgress eventData.relativePosition

	@soundcloudPlayer.bind SC.Widget.Events.LOAD_PROGRESS, (eventData) =>
		@onLoadProgress eventData.loadedProgress

	@soundcloudPlayer.bind SC.Widget.Events.ERROR, (error)=>
		@onError error

	@soundcloudPlayer.bind SC.Widget.Events.PLAY, =>
		@onPlay()

	@soundcloudPlayer.bind SC.Widget.Events.PAUSE, =>
		@onPause()

	@soundcloudPlayer.bind SC.Widget.Events.FINISH, =>
		@onFinished()

	@soundcloudPlayer.vjsTech = @

###
Callback for soundcloud's READY event.
###
videojs.Soundcloud.prototype.onReady = ->
	debug "onReady"

	@volumeVal = 0
	@durationMilliseconds = 0
	@loadPercentageDecimal = 0
	@playPercentageDecimal = 0
	@paused_ = true

	# Preparing to handle muting
	@soundcloudPlayer.getVolume (volume) =>
		@unmuteVolume = volume / 100
		@setVolume @unmuteVolume

	# It's async and won't change so let's do this now
	@soundcloudPlayer.getDuration (duration) =>
		@durationMilliseconds = duration
		@player_.trigger 'durationchange'

	# Trigger buffering
	@soundcloudPlayer.play()
	@soundcloudPlayer.pause()

	@triggerReady();
	@isReady_ = true
	@player_.trigger 'techready'
	# Play right away if we clicked before ready
	@soundcloudPlayer.play() if @playOnReady

###
Callback for Soundcloud's PLAY_PROGRESS event
It should keep track of how much has been played.
@param {Decimal= playPercentageDecimal} [0...1] How much has been played  of the sound in decimal from [0...1]
###
videojs.Soundcloud.prototype.onPlayProgress = (@playPercentageDecimal)->
	debug "onPlayProgress"
	@player_.trigger "playing"

###
Callback for Soundcloud's LOAD_PROGRESS event.
It should keep track of how much has been buffered/loaded.
@param {Decimal= loadPercentageDecimal} How much has been buffered/loaded of the sound in decimal from [0...1]
###
videojs.Soundcloud.prototype.onLoadProgress = (@loadPercentageDecimal)->
	debug "onLoadProgress: #{@loadPercentageDecimal}"
	@player_.trigger "timeupdate"

###
Callback for Soundcloud's PLAY event.
It should keep track of the player's paused and playing status.
###
videojs.Soundcloud.prototype.onPlay = ->
	debug "onPlay"
	@paused_ = false
	@playing = not @paused_
	@player_.trigger "play"

###
Callback for Soundcloud's PAUSE event.
It should keep track of the player's paused and playing status.
###
videojs.Soundcloud.prototype.onPause = ->
	debug "onPause"
	@paused_ = true
	@playing = not @paused_
	@player_.trigger "pause"

###
Callback for Soundcloud's FINISHED event.
It should keep track of the player's paused and playing status.
###
videojs.Soundcloud.prototype.onFinished = ->
	@paused_ = false # TODO what does videojs expect here?
	@playing = not @paused_
	@player_.trigger "ended"

###
Callback for Soundcloud's ERROR event.
Sadly soundlcoud doesn't send any information on what happened when using the widget API --> no error message.
###
videojs.Soundcloud.prototype.onError = ->
	@player_.error = "Soundcloud error"
	@player_.trigger('error')
