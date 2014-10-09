videojs-soundcloud
==================

A [videojs/video-js](https://github.com/videojs/video.js) plugin to support soundcloud links e.g https://soundcloud.com/vaughan-1-1/this-is-what-crazy-looks-like

It depends on [jwagener/uri.js](https://github.com/jwagener/uri.js) for checking URIs.

How to use (with coffeescript)
==============================
The project uses coffeescript, which is a language that compiles into javascript locally or in the browser using ```<script type="text/coffeescript">``` as described [here](http://coffeescript.org/#scripts).

```html
<head>
  <!-- Mandatory videojs include! -->
  <script src="http://vjs.zencdn.net/4.2.2/video.js"></script>
  <link href="http://vjs.zencdn.net/4.2.2/video-js.css" rel="stylesheet">
  <script type="text/javascript" src="http://coffeescript.org/extras/coffee-script.js"></script>
  <script type="text/coffeescript" src="src/media.soundcloud.coffee"></script>
</head>
<body>
  <video
    id="myStuff"
    class="video-js vjs-default-skin"
    controls
    preload="auto"
    width="100%"
    height="360"
    data-setup=''
    ></video>
    <!--
      Dynamic include
      coffeescript is compiled in the onload cycle
    -->
    <script type="text/coffeescript">
      videojs "myStuff", {
          "techOrder": ["soundcloud"]
          "source": ["https://soundcloud.com/vaughan-1-1/this-is-what-crazy-looks-like"]
          }, ->
    </script>
</body>
```

More information is in the example below.


How it works
============
We create an iframe (with a soundcloud-embed URL) in the player-element and, using the soundcloud [Widget API](http://developers.soundcloud.com/docs/api/html5-widget] we initialize a widget that will give us the control methods, getters and setters we need.

More in detail notes
--------------------
> [**Getters**](http://developers.soundcloud.com/docs/api/html5-widget#methods)

> Since communication between the parent page and the widget's iframe is implemented through [window.postMessage](https://developer.mozilla.org/en/DOM/window.postMessage), it's not possible to return the value synchronously. Because of this, every getter method accepts a callback function as a parameter which, when called, will be given the return value of the getter method.

Due to this we have quite a few state variables when using the widget API.

Documentation
-------------
Is generated with [Codo](https://github.com/coffeedoc/codo) and hosted on [coffeedoc.info](http://coffeedoc.info/github/LoveIsGrief/videojs-soundcloud/master/). Props to them :)

Example
-------
[JsFiddle with single source](http://jsfiddle.net/x7FDL/27/)
