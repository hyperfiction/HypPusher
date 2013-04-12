HypPusher
========
A native extension to add Pusher to your NME application
---------------------------------------------------------

See the <a href="http://pusher.com/docs">pusher documentation</a>.

Use <a href="https://github.com/jmschultz/JavaPusherClient">JavaPusherClient</a> for Android.

Use <a href="https://github.com/lukeredpath/libPusher">LibPusher</a> for iOS.

Default is to use wss://, on port 443 as it works better on mobile connection
In order to use private channel, you need to provide an end point url to authenticate

Limitations
-----------
No presence channel and no tests for multiple channels (it may work).

Installation
------------
There is an [include.nmml](https://github.com/hyperfiction/HypPusher/blob/master/include.nmml) file and [ndll](https://github.com/hyperfiction/HypPusher/tree/master/ndll) are compiled for:
* ios armv6
* ios armv7
* ios simulator
* android armv6


Usage
-----
Initialize a pusher client, without autoconnect. It needs your api key and for private channel channel your third party server url with an optional token and optional userid for authentication.

	hp = new HypPusher( api_key, server_url, user_id );

This extension uses signals:

	public var onConnect       	: Signal1<String>;
	public var onConnectError  	: Signal;
	public var onDisconnect    	: Signal;
	public var onSubscribed    	: Signal1<String>;
	public var onSubscribeError	: Signal2<String,String>;
	public var onMessage       	: Signal3<String, Dynamic, String >;
	public var onChannelMessage	: Signal3<String, Dynamic, String >;

To connect to the pusher server and get a socket id:

	hp.onConnect.connect( _onConnect );
	hp.onConnectError.connect( _onConnectError );
	hp.connectToServer( );

	function _onConnect( socket_id : String ){
		trace( "pusher connected with socket id: "+socket_id );
		trace( "pusher is connected? "+hp.is_connected );
		trace( "pusher socket id: "+hp.socket_id );
	}

	function _onConnectError( ) {
		trace( "cannot connect to pusher!" );
	}

To connect to a public/private channel:
If it's a private channel it trigger the authentication mecanism.

	hp.onSubscribed.connect( _onSubscribed );
	hp.setChannel( "channel_name" );
	// hp.setChannel( "private-channel_name" );

	function _onSubscribed( channel_name : String ) {
		trace( 'connected to channel: '+channel_name );
	}

By default the android version listens to events on all channels. For iOS you should use:

	hp.onMessage.connect( _onMessage );
	hp.bind( "event_name" );

	function _onMessage( event_name : String, data : Dynamic, channel_name : String ) {
		trace( Std.format( "on message: $event_name,
					data: $data, channel_name: $channel_name" ) );
	}

To subscribe to message on a specific channel:

	hp.onChannelMessage.connect( _onChannelMessage );
	hp.bindOnChannel( "event_name", "channel_name" );

	function _onChannelMessage( event_name : String, data : Dynamic, channel_name : String ) {
		trace( Std.format( "on channel message: $event_name,
					data: $data, channel_name: $channel_name" ) );
	}

Once you're subscribed to a private channel, you can send message:

	hp.send( "event-name", {"optional":"json data"}, "channel_name" );

To unbind and unsubscribe:

	hp.unbind( "event_name" );
	hp.unbindOnChannel( "event_name", "channel_name" );
	hp.unsetChannel( "channel_name" );


Made at [Hyperfiction](http://hyperfiction.fr)
----------------------------------------------
Developed by :
- [Louis Beltramo](https://github.com/louisbl) [@louisbl](https://twitter.com/louisbl)

License
-------
This work is under BSD simplified License.