HypPusher, NME native extension for pusher service.

HypPusher
========
A native extension to add Pusher to your NME application
---------------------------------------------------------

See <a href="http://pusher.com/docs">pusher documentation</a>
Use <a href="https://github.com/jmschultz/JavaPusherClient">JavaPusherClient</a> for Android
Use <a href="https://github.com/lukeredpath/libPusher">LibPusher</a> for iOS
Default is to use wss://, on port 443 as it works better on mobile connection
In order to use private channel, you need to provide an end point url to authenticate
Limitations : only one channel at a time for now, no presence channel

Installation
------------
There is an [include.nmml](https://github.com/hyperfiction/HypPusher/blob/master/include.nmml) file and [ndll](https://github.com/hyperfiction/HypPusher/tree/master/ndll) are compiled for:
* ios armv6
* ios armv7
* ios simulator
* android armv6


Usage
-----

TODO

Made at [Hyperfiction](http://hyperfiction.fr)
----------------------------------------------
Developed by :
- [Louis Beltramo](https://github.com/louisbl) [@louisbl](https://twitter.com/louisbl)

License
-------
This work is under BSD simplified License.