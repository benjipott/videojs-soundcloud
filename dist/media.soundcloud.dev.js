/*
Documentation can be generated using {https://github.com/coffeedoc/codo Codo}
*/

/*
Add a script to head with the given @scriptUrl
*/

var addScriptTag;

addScriptTag = function(scriptUrl) {
  var headTag, tag;
  console.debug("adding script " + scriptUrl);
  tag = document.createElement('script');
  tag.src = scriptUrl;
  headTag = document.getElementsByTagName('head')[0];
  return headTag.parentNode.appendChild(tag);
};

/*
Soundcloud Media Controller - Wrapper for Soundcloud Media API
API SC.Widget documentation: http://developers.soundcloud.com/docs/api/html5-widget
API Track documentation: http://developers.soundcloud.com/docs/api/reference#tracks
@param [videojs.Player] player
@option options {Object} options As given by vjs.Player.prototype.loadTech
                         Should include a source attribute as one given to @see videojs.Soundcloud::src
@param [Function] ready
*/


videojs.Soundcloud = videojs.MediaTechController.extend({
  init: function(player, options, ready) {
    var _this = this;
    console.debug("initializing Soundcloud tech");
    videojs.MediaTechController.call(this, player, options, ready);
    this.volumeVal = 0;
    this.durationMilliseconds = 1;
    this.currentPositionSeconds = 0;
    this.loadPercentageDecimal = 0;
    this.paused_ = true;
    this.player_ = player;
    this.soundcloudSource = null;
    if ("string" === typeof options.source) {
      console.debug("given string source: " + options.source);
      this.soundcloudSource = options.source;
    } else if ("object" === typeof options.source) {
      this.soundcloudSource = options.source.src;
    }
    this.scWidgetId = "" + (this.player_.id()) + "_soundcloud_api_" + (Date.now());
    this.scWidgetElement = videojs.Component.prototype.createEl('iframe', {
      id: this.scWidgetId,
      className: 'vjs-tech',
      scrolling: 'no',
      marginWidth: 0,
      marginHeight: 0,
      frameBorder: 0,
      webkitAllowFullScreen: "true",
      mozallowfullscreen: "true",
      allowFullScreen: "true",
      src: "https://w.soundcloud.com/player/?url=" + this.soundcloudSource
    });
    this.scWidgetElement.style.visibility = "hidden";
    this.player_.el().appendChild(this.scWidgetElement);
    this.player_.el().classList.add("backgroundContainer");
    console.debug("added widget div with src: " + this.scWidgetElement.src);
    if (this.player_.options().autoplay) {
      this.playOnReady = true;
    }
    this.readyToPlay = false;
    this.ready(function() {
      console.debug("ready to play");
      _this.readyToPlay = true;
      return _this.player_.trigger("loadstart");
    });
    console.debug("loading soundcloud");
    return this.loadSoundcloud();
  }
});

/*
Destruct the tech and it's DOM elements
*/


videojs.Soundcloud.prototype.dispose = function() {
  console.debug("dispose");
  if (this.scWidgetElement) {
    this.scWidgetElement.parentNode.removeChild(this.scWidgetElement);
    console.debug("Removed widget Element");
    console.debug(this.scWidgetElement);
  }
  this.player_.el().classList.remove("backgroundContainer");
  this.player_.el().style.backgroundImage = "";
  console.debug("removed CSS");
  if (this.soundcloudPlayer) {
    return delete this.soundcloudPlayer;
  }
};

videojs.Soundcloud.prototype.load = function() {
  console.debug("loading");
  return this.loadSoundcloud();
};

/*
Called from [vjs.Player.src](https://github.com/videojs/video.js/blob/master/docs/api/vjs.Player.md#src-source-)
Triggers "newSource" from vjs.Player once source has been changed

@option option [String] src Source to load
@return [String] current source if @src isn't given
*/


videojs.Soundcloud.prototype.src = function(src) {
  var _this = this;
  if (!src) {
    return this.soundcloudSource;
  }
  console.debug("load a new source(" + src + ")");
  return this.soundcloudPlayer.load(src, {
    callback: function() {
      _this.soundcloudSource = src;
      _this.onReady();
      console.debug("trigger 'newSource' from " + src);
      return _this.player_.trigger("newSource");
    }
  });
};

videojs.Soundcloud.prototype.updatePoster = function() {
  var e,
    _this = this;
  try {
    return this.soundcloudPlayer.getSounds(function(sounds) {
      var posterUrl, sound;
      console.debug("got sounds");
      if (sounds.length !== 1) {
        return;
      }
      sound = sounds[0];
      if (!sound.artwork_url) {
        return;
      }
      posterUrl = sound.artwork_url.replace("large.jpg", "t500x500.jpg");
      console.debug("Setting poster to " + posterUrl);
      return _this.player_.el().style.backgroundImage = "url('" + posterUrl + "')";
    });
  } catch (_error) {
    e = _error;
    return console.debug("Could not update poster");
  }
};

videojs.Soundcloud.prototype.play = function() {
  if (this.readyToPlay) {
    console.debug("play");
    return this.soundcloudPlayer.play();
  } else {
    console.debug("to play on ready");
    return this.playOnReady = true;
  }
};

/*
Toggle the playstate between playing and paused
*/


videojs.Soundcloud.prototype.toggle = function() {
  console.debug("toggle");
  if (this.player_.paused()) {
    return this.player_.play();
  } else {
    return this.player_.pause();
  }
};

videojs.Soundcloud.prototype.pause = function() {
  console.debug("pause");
  return this.soundcloudPlayer.pause();
};

videojs.Soundcloud.prototype.paused = function() {
  console.debug("paused: " + this.paused_);
  return this.paused_;
};

/*
@return track time in seconds
*/


videojs.Soundcloud.prototype.currentTime = function() {
  console.debug("currentTime " + this.currentPositionSeconds);
  return this.currentPositionSeconds;
};

videojs.Soundcloud.prototype.setCurrentTime = function(seconds) {
  console.debug("setCurrentTime " + seconds);
  this.soundcloudPlayer.seekTo(seconds * 1000);
  return this.player_.trigger("seeking");
};

/*
@return total length of track in seconds
*/


videojs.Soundcloud.prototype.duration = function() {
  return this.durationMilliseconds / 1000;
};

videojs.Soundcloud.prototype.buffered = function() {
  var timePassed;
  timePassed = this.duration() * this.loadPercentageDecimal;
  if (timePassed > 0) {
    console.debug("buffered " + timePassed);
  }
  return videojs.createTimeRange(0, timePassed);
};

videojs.Soundcloud.prototype.volume = function() {
  console.debug("volume: " + (this.volumeVal * 100) + "%");
  return this.volumeVal;
};

/*
Called from [videojs::Player::volume](https://github.com/videojs/video.js/blob/master/docs/api/vjs.Player.md#volume-percentasdecimal-)
@param percentAsDecimal {Number} A decimal number [0-1]
*/


videojs.Soundcloud.prototype.setVolume = function(percentAsDecimal) {
  console.debug("setVolume(" + percentAsDecimal + ") from " + this.volumeVal);
  if (percentAsDecimal !== this.volumeVal) {
    this.volumeVal = percentAsDecimal;
    this.soundcloudPlayer.setVolume(this.volumeVal);
    console.debug("volume has been set");
    return this.player_.trigger('volumechange');
  }
};

videojs.Soundcloud.prototype.muted = function() {
  console.debug("muted: " + (this.volumeVal === 0));
  return this.volumeVal === 0;
};

/*
Soundcloud doesn't do muting so we need to handle that.

A possible pitfall is when this is called with true and the volume has been changed elsewhere.
We will use @unmutedVolumeVal

@param {Boolean}
*/


videojs.Soundcloud.prototype.setMuted = function(muted) {
  console.debug("setMuted(" + muted + ")");
  if (muted) {
    this.unmuteVolume = this.volumeVal;
    return this.setVolume(0);
  } else {
    return this.setVolume(this.unmuteVolume);
  }
};

/*
Take a wild guess ;)
*/


videojs.Soundcloud.isSupported = function() {
  console.debug("isSupported: " + true);
  return true;
};

/*
Fullscreen of audio is just enlarging making the container fullscreen and using it's poster as a placeholder.
*/


videojs.Soundcloud.prototype.supportsFullScreen = function() {
  console.debug("we support fullscreen!");
  return true;
};

/*
Fullscreen of audio is just enlarging making the container fullscreen and using it's poster as a placeholder.
*/


videojs.Soundcloud.prototype.enterFullScreen = function() {
  console.debug("enterfullscreen");
  return this.scWidgetElement.webkitEnterFullScreen();
};

/*
We return the player's container to it's normal (non-fullscreen) state.
*/


videojs.Soundcloud.prototype.exitFullScreen = function() {
  console.debug("EXITfullscreen");
  return this.scWidgetElement.webkitExitFullScreen();
};

/*
Simple URI host check of the given url to see if it's really a soundcloud url
@param url {String}
*/


videojs.Soundcloud.prototype.isSoundcloudUrl = function(url) {
  return /^(https?:\/\/)?(www.|api.)?soundcloud.com\//i.test(url);
};

/*
We expect "audio/soundcloud" or a src containing soundcloud
*/


videojs.Soundcloud.prototype.canPlaySource = videojs.Soundcloud.canPlaySource = function(source) {
  var ret;
  if (typeof source === "string") {
    return videojs.Soundcloud.prototype.isSoundcloudUrl(source);
  } else {
    console.debug("Can play source?");
    console.debug(source);
    ret = (source.type === 'audio/soundcloud') || videojs.Soundcloud.prototype.isSoundcloudUrl(source.src);
    console.debug(ret);
    return ret;
  }
};

/*
Take care of loading the Soundcloud API
*/


videojs.Soundcloud.prototype.loadSoundcloud = function() {
  var checkSoundcloudApiReady,
    _this = this;
  console.debug("loadSoundcloud");
  if (videojs.Soundcloud.apiReady && !this.soundcloudPlayer) {
    console.debug("simply initializing the widget");
    return this.initWidget();
  } else {
    if (!videojs.Soundcloud.apiLoading) {
      console.debug("loading soundcloud api");
      checkSoundcloudApiReady = function() {
        if (typeof window.SC !== "undefined") {
          console.debug("soundcloud api is ready");
          videojs.Soundcloud.apiReady = true;
          window.clearInterval(videojs.Soundcloud.intervalId);
          _this.initWidget();
          return console.debug("cleared interval");
        }
      };
      addScriptTag("http://w.soundcloud.com/player/api.js");
      videojs.Soundcloud.apiLoading = true;
      return videojs.Soundcloud.intervalId = window.setInterval(checkSoundcloudApiReady, 10);
    }
  }
};

/*
It should initialize a soundcloud Widget, which will be our player
and which will react to events.
*/


videojs.Soundcloud.prototype.initWidget = function() {
  var _this = this;
  console.debug("Initializing the widget");
  this.soundcloudPlayer = SC.Widget(this.scWidgetId);
  console.debug("created widget");
  this.soundcloudPlayer.bind(SC.Widget.Events.READY, function() {
    return _this.onReady();
  });
  console.debug("attempted to bind READY");
  this.soundcloudPlayer.bind(SC.Widget.Events.PLAY_PROGRESS, function(eventData) {
    return _this.onPlayProgress(eventData.relativePosition);
  });
  this.soundcloudPlayer.bind(SC.Widget.Events.LOAD_PROGRESS, function(eventData) {
    console.debug("loading");
    return _this.onLoadProgress(eventData.loadedProgress);
  });
  this.soundcloudPlayer.bind(SC.Widget.Events.ERROR, function() {
    return _this.onError();
  });
  this.soundcloudPlayer.bind(SC.Widget.Events.PLAY, function() {
    return _this.onPlay();
  });
  this.soundcloudPlayer.bind(SC.Widget.Events.PAUSE, function() {
    return _this.onPause();
  });
  this.soundcloudPlayer.bind(SC.Widget.Events.FINISH, function() {
    return _this.onFinished();
  });
  this.soundcloudPlayer.bind(SC.Widget.Events.SEEK, function(event) {
    return _this.onSeek(event.currentPosition);
  });
  if (!this.soundcloudSource) {
    return this.triggerReady();
  }
};

/*
Callback for soundcloud's READY event.
*/


videojs.Soundcloud.prototype.onReady = function() {
  var e,
    _this = this;
  console.debug("onReady");
  this.soundcloudPlayer.getVolume(function(volume) {
    _this.unmuteVolume = volume;
    console.debug("current volume on soundcloud: " + _this.unmuteVolume);
    return _this.setVolume(_this.unmuteVolume);
  });
  try {
    this.soundcloudPlayer.getDuration(function(duration) {
      _this.durationMilliseconds = duration;
      _this.player_.trigger('durationchange');
      return _this.player_.trigger("canplay");
    });
  } catch (_error) {
    e = _error;
    console.debug("could not get the duration");
  }
  this.updatePoster();
  this.triggerReady();
  try {
    if (this.playOnReady) {
      this.soundcloudPlayer.play();
    }
  } catch (_error) {
    e = _error;
    console.debug("could not play onready");
  }
  return console.debug("finished onReady");
};

/*
Callback for Soundcloud's PLAY_PROGRESS event
It should keep track of how much has been played.
@param {Decimal= playPercentageDecimal} [0...1] How much has been played  of the sound in decimal from [0...1]
*/


videojs.Soundcloud.prototype.onPlayProgress = function(playPercentageDecimal) {
  console.debug("onPlayProgress");
  this.currentPositionSeconds = this.durationMilliseconds * playPercentageDecimal / 1000;
  return this.player_.trigger("playing");
};

/*
Callback for Soundcloud's LOAD_PROGRESS event.
It should keep track of how much has been buffered/loaded.
@param {Decimal= loadPercentageDecimal} How much has been buffered/loaded of the sound in decimal from [0...1]
*/


videojs.Soundcloud.prototype.onLoadProgress = function(loadPercentageDecimal) {
  this.loadPercentageDecimal = loadPercentageDecimal;
  console.debug("onLoadProgress: " + this.loadPercentageDecimal);
  return this.player_.trigger("timeupdate");
};

/*
Callback for Soundcloud's SEEK event after seeking is done.

@param {Number= currentPositionMs} Where soundcloud seeked to
*/


videojs.Soundcloud.prototype.onSeek = function(currentPositionMs) {
  console.debug("soundcloud seek callback");
  this.currentPositionSeconds = currentPositionMs / 1000;
  return this.player_.trigger("seeked");
};

/*
Callback for Soundcloud's PLAY event.
It should keep track of the player's paused and playing status.
*/


videojs.Soundcloud.prototype.onPlay = function() {
  console.debug("onPlay");
  this.paused_ = false;
  this.playing = !this.paused_;
  return this.player_.trigger("play");
};

/*
Callback for Soundcloud's PAUSE event.
It should keep track of the player's paused and playing status.
*/


videojs.Soundcloud.prototype.onPause = function() {
  console.debug("onPause");
  this.paused_ = true;
  this.playing = !this.paused_;
  return this.player_.trigger("pause");
};

/*
Callback for Soundcloud's FINISHED event.
It should keep track of the player's paused and playing status.
*/


videojs.Soundcloud.prototype.onFinished = function() {
  this.paused_ = false;
  this.playing = !this.paused_;
  return this.player_.trigger("ended");
};

/*
Callback for Soundcloud's ERROR event.
Sadly soundlcoud doesn't send any information on what happened when using the widget API --> no error message.
*/


videojs.Soundcloud.prototype.onError = function() {
  return this.player_.error("There was a soundcloud error. Check the view.");
};
