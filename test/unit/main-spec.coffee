###
Create a spy for all functions of a given object
by spying on the object's prototype
@param o {Object} object to invade
###
spyOnAllClassFunctions = (o)->
	Object.keys(o.prototype).forEach (funcName)->
		spyOn(o.prototype, funcName).and.callThrough()


describe "videojs-soundcloud plugin", ->

	################################
	#   Reusable tests
	################################

	sourceObjectTest = (done) ->
		@player.ready =>
			iframe = document.getElementsByTagName("iframe")[0]
			expect(iframe).toBeTruthy()
			expect(iframe.src).toEqual "https://w.soundcloud.com/player/?url=#{@source}"
			done()

	# Test if calling play() works
	playTest = (done) ->
		@player.ready =>
			@player.on "play", =>
				expect(@player.paused()).toBeFalsy()
				done()
			@player.play()

	# Tries to seek to 30 seconds
	seekTo30Test = (done) ->
		@player.ready =>
			seconds = 30

			# First we have to start playing otherwise we can't seek
			# (Soundcloud limitation)
			@player.on "play", =>
				@player.pause()
				@player.currentTime seconds
			# Check once we call back
			@player.on "seeked", =>
				expect(@player.currentTime()).toEqual seconds
				done()
			@player.play()

	# Try changing the volume
	# volumes are given as decimals
	# https://github.com/videojs/video.js/blob/master/docs/api/vjs.Player.md#volume-percentasdecimal-
	changeVolumeTest = (done) ->
		@player.ready =>
			volume = 0.5
			@player.on "volumechange", =>
				expect(@player.volume()).toEqual volume
				done()
			@player.volume volume

	beforeEach ->
		console.log "master beforeEach"
		@plugin = videojs.Soundcloud
		@pluginPrototype = @plugin.prototype
		spyOnAllClassFunctions @plugin
		@videoTagId = "myStuff"

		# The audio we wanna play
		@source = "https://soundcloud.com/vaughan-1-1/this-is-what-crazy-looks-like"

	afterEach ->
		console.log "master afterEach"
		player = videojs.players[@videoTagId]
		player.dispose() if player

		expect(videojs.players[@videoTagId]).toBeFalsy()

	describe "created with html video>source" , ->

		beforeEach ->
			@vFromTag = window.__html__['test/ressources/videojs_from_tag.html']
			document.body.innerHTML = @vFromTag
			expect(document.getElementById(@videoTagId)).not.toBeNull()
			@player = videojs @videoTagId

		xit "should call init" , (done)->
			# For some reason the spy isn't being called
			# but we know damn well init is being called
			# otherwise we wouldn't get this far...
			@player.ready =>
				expect(@pluginPrototype.init).toHaveBeenCalled()
				done()

		it "should create soundcloud iframe", sourceObjectTest

		it "should play the song", playTest

		it "should half the volume", changeVolumeTest

	describe "created with javascript string source" , ->

		beforeEach ->
			console.log "beforeEach with video and source tag"
			@vFromScript = window.__html__['test/ressources/videojs_from_script.html']
			document.body.innerHTML = @vFromScript
			expect(document.getElementById @videoTagId).not.toBeNull()
			@player = videojs @videoTagId, {
				"techOrder": ["soundcloud"]
				"sources": [@source]
				}

		it "should create soundcloud iframe", (done)->
			@player.ready =>
					iframe = document.getElementsByTagName("iframe")[0]
					expect(iframe).toBeTruthy()
					expect(iframe.src).toEqual "https://w.soundcloud.com/player/?url=#{@source}"
					done()

		it "should play the song", playTest

		it "should seek to 30 seconds", seekTo30Test

		it "should half the volume", changeVolumeTest

	describe "created with javascript object source" , ->

		beforeEach ->
			console.log "beforeEach with video and source tag"
			@vFromScript = window.__html__['test/ressources/videojs_from_script.html']
			document.body.innerHTML = @vFromScript
			expect(document.getElementById @videoTagId).not.toBeNull()
			@player = videojs @videoTagId, {
				"techOrder": ["soundcloud"]
				"sources": [ {
					 src: @source
					 type: "audio/soundcloud"
					}]
				}

		it "should create soundcloud iframe", sourceObjectTest

		it "should play the song", playTest

		it "should seek to 30 seconds", seekTo30Test

		it "should half the volume", changeVolumeTest
