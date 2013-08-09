package fr.hyperfiction;

import flash.Lib;
import flash.events.TimerEvent;
import flash.events.Event;

import flash.utils.Timer;
import org.shoebox.utils.system.Signal;
import org.shoebox.utils.system.Signal1;
import org.shoebox.utils.system.Signal2;
import org.shoebox.utils.system.Signal3;


/**
*	HypPusher, NME native extension for pusher service.
*	See <a href="http://pusher.com/docs">pusher documentation</a>
*
*	Use <a href="https://github.com/jmschultz/JavaPusherClient">JavaPusherClient</a> for Android
*	Use <a href="https://github.com/lukeredpath/libPusher">LibPusher</a> for iOS
*
* 	Default is to use wss://, on port 443 as it works better on mobile connection
*
* 	In order to use private channel, you need to provide an end point url to authenticate
*
*	Limitations : only one channel at a time for now, no presence
*	TODO : better handling of connection / reconnectionchannel
*
* @author louisbl
*/
@:build( ShortCuts.mirrors() )
class HypPusher {

	public var onConnect                    	: Signal1<String>;
	public var onConnectError               	: Signal1<String>;
	public var onDisconnect                 	: Signal;
	public var onSubscribed                 	: Signal1<String>;
	public var onSubscribeError             	: Signal2<String,String>;
	public var onMessage                    	: Signal3<String, Dynamic, String >;
	public var onChannelMessage             	: Signal3<String, Dynamic, String >;
	public var is_connected( default, null )	: Bool;
	public var socket_id                    	: String;

	var _channels      	: Map<String,Bool>;
	var _events        	: Map<String,Array<String>>;
	var _auth_end_point	: String;
	var _auth_token    	: String;
	var _auth_user_id  	: String;
	var _connect_timer 	: Timer;
	var _connecting    	: Bool;

	#if android
		var _pusher_auth 	: HypPusherAuth;
		var _instance    	: Dynamic;
		var _all_chan_evt	: Map<String,Bool>;
	#end

	// -------o constructor

		/**
		 * Constructor, instantiate a pusher client, wihtout autoconnect.
		 * @see connectToServer to connect to the pusher server
		 *
		 * @param apiKey        : String Pusher API Key
		 * @param ?authEndPoint : String url used to authenticate private/presence channel
		 * @param ?token        : String a token used to authenticate with the authEndPoint for private/presence channel
		 * @param ?userId       : String userID used to authenticate with the authEndPoint for presence channel
		 * @return Void
		 */
		public function new( apiKey : String, ?authEndPoint : String, ?token : String, ?userId : String ) : Void {
			onConnect       	= new Signal1<String>();
			onConnectError  	= new Signal1<String>();
			onDisconnect    	= new Signal();
			onSubscribed    	= new Signal1<String>();
			onSubscribeError	= new Signal2<String,String>();
			onMessage       	= new Signal3<String, Dynamic, String>();
			onChannelMessage	= new Signal3<String, Dynamic, String>();
			is_connected    	= false;
			_connecting     	= false;
			_channels       	= new Map<String, Bool>( );
			_events         	= new Map<String, Array<String>>( );

			trace( "token:"+token);
			trace("userId:"+userId);

			_auth_end_point	= authEndPoint;
			_auth_token    	= token;
			_auth_user_id  	= userId;
			_connect_timer 	= new Timer( 6000, 1);

			#if ( android || ios )
				hyppusher_cb_connect( _onConnect );
				hyppusher_cb_connect_error( _onConnectError );
				hyppusher_cb_disconnect( _onDisconnect );
				hyppusher_cb_message( _onMessage );
				hyppusher_cb_channel_message( _onChannelMessage );
				hyppusher_cb_subscribed( _onSubscribed );
				hyppusher_cb_subscribe_error( _onSubscribeError );
			#end
			#if android
				_instance = create( apiKey );
				_all_chan_evt	= new Map<String,Bool>( );
				_pusher_auth 	= new HypPusherAuth( );
				_pusher_auth.sgAuthSuccessful.connect( _on_auth_success );
				_pusher_auth.sgAuthFailed.connect( _onSubscribeError );
				_pusher_auth.sgAuthError.connect( _onSubscribeError );
			#end
			#if ios
				hyppusher_create( apiKey );
				if( _auth_end_point != null && _auth_token != null ) {
					hyppusher_set_authurl( _auth_end_point, _auth_token, _auth_user_id );
				}
			#end
		}


	// -------o public


		/**
		* connectToServer try to connect to the pusher server
		* default uses secure connection over 443 port.
		*
		* @public
		* @return	Void
		*/
		public function connectToServer( ) : Void {
			_connecting = true;
			_connect_timer.addEventListener( TimerEvent.TIMER, _onConnectTimer );
			_connect_timer.reset( );
			_connect_timer.start( );
			#if android
				connectToPusher( _instance );
			#end
			#if ios
				hyppusher_connect( );
			#end
		}

		/**
		* disconnectFromServer
		*
		* @public
		* @return	Void
		*/
		public function disconnectFromServer( ) : Void {
			_connect_timer.removeEventListener( TimerEvent.TIMER, _onConnectTimer );
			_connect_timer.reset( );
			#if android
				disconnect( _instance );
			#end
			#if ios
				hyppusher_disconnect( );
			#end
		}

		public function reset( ) : Void {
			_channels = new Map<String,Bool>( );
		}

		/**
		 * Check if pusher is connected before subscribing
		 * to a channel. if the name
		 * start with "private-", subscribe to a private channel.
		 * start with "presence-", subscribe to a presence channel.
		 * otherwise a public one.
		 *
		 * @public
		 * @param channel_name the name of the channel to subscribe to.
		 * @return	Void
		 */
		public function setChannel( channel_name : String ) : Void {
			if( _channels.exists( channel_name ) ){
				trace( "[HypPusher] Warning ::: I've already subscribed to this channel" );
				return;
			} else {
				trace( "[HypPusher] I've not subscribe to this channel, let's do it." );
				_channels.set( channel_name, false );
				#if ios
					hyppusher_subscribe( channel_name );
				#end
			}
			if( !is_connected && !_connecting ){
				trace( "[HypPusher] Error ::: I need to be connected to subscribe to a channel. Let's do it.");
				connectToServer( );
			} else {
				#if android
					_subscribeOnceConnected( );
				#end
			}
		}

		public function unsetChannel( channel_name : String ) : Void {
			if( _channels.exists( channel_name ) ){
				_channels.remove( channel_name );
				#if android
					unsubscribe( _instance, channel_name );
				#end
				#if ios
					hyppusher_unsubscribe( channel_name );
				#end
			} else {
				trace( "[HypPusher] I'm not subscribed to this channel." );
			}
		}

		/**
		 * bind an event on a channel. All notif are received
		 * through onChannelMessage signal.
		 *
		 * @param  event   : String
		 * @param  channel : String
		 * @return Void
		 */
		public function bindOnChannel( event : String, channel : String ) : Void {
			#if android
				if ( _channels.get( channel ) )  {
					var evts = _events.get( channel );
					if( evts == null ) {
						evts = new Array<String>( );
						_events.set( channel, evts );
					}
					evts.push( event );
					bindToEvent( _instance, event, channel );
				}
			#end
			#if ios
				hyppusher_bind_event( event, channel );
			#end
		}

		/**
		 * unbind an event on a channel
		 * @param  event   : String
		 * @param  channel : String
		 * @return Void
		 */
		public function unbindOnChannel( event : String, channel : String ) : Void {
			#if android
				var evts = _events.get( channel );
				if( evts != null ) {
					evts.remove( event );
				}
				unbindEvent( _instance, event, channel );
			#end
			#if ios
				hyppusher_unbind_event( event, channel );
			#end
		}

		/**
		* sendEvent send a client event to Pusher, with optional json data.
		* only allowed when subscribed to a private channel.
		*
		* @public
		* @param event the name of the event
		* @param data optional data, json object
		* @return	Void
		*/
		public function send( event : String, data : Dynamic, channel_name : String ) : Void {
			if( ! _channels.get( channel_name ) ){
				trace( "[HypPusher] Error ::: cannot send " + event + " without subscribing to " + channel_name );
				return;
			}

			try{
				data = haxe.Json.stringify( data );
			} catch ( e : Dynamic ){
				trace( "[HypPusher] Error ::: malformed Json data ::: "+e);
			}

			#if android
				sendEvent( _instance, event, data, channel_name );
			#end
			#if ios
				hyppusher_send_event( event, data, channel_name );
			#end
		}


	// -------o protected

		#if android
			function _subscribeOnceConnected( ) : Void {
				if( !is_connected ){
					trace( "[HypPusher] Error ::: I thought I was connected. I'm not subscribing to all channels.");
				} else {
					for ( channel_name in _channels.keys( ) ) {
						trace( "re/connect to: "+channel_name );
						if( _channels.get( channel_name ) ) {
							continue;
						}
						var chanIsPrivate : Bool;
						chanIsPrivate = false;
						var chanIsPresence : Bool;
						chanIsPresence = false;
						if( StringTools.startsWith( channel_name, "private-" ) ){
							if( _auth_end_point == null || _auth_token == null ){
								trace("[HypPusher] Error ::: authEndPoint or token not set before subscribing to private channel");
								return;
							}else{
								chanIsPrivate = true;
							}
						} else if ( StringTools.startsWith( channel_name, "presence-" ) ) {
							if( _auth_end_point == null || _auth_token == null || _auth_user_id == null ){
								trace("[HypPusher] Error ::: authEndPoint or token or userId not set before subscribing to presence channel");
								return;
							}else{
								chanIsPresence = true;
							}
						}
						_connect_timer.addEventListener( TimerEvent.TIMER, _onConnectTimer );
						_connect_timer.reset( );
						_connect_timer.start( );
						if( chanIsPrivate ){
							_pusher_auth.authenticate( socket_id, _auth_end_point, channel_name, _auth_token, _auth_user_id );
						} else if ( chanIsPresence ) {
							_pusher_auth.authenticate( socket_id, _auth_end_point, channel_name, _auth_token, _auth_user_id, true );
						} else {
							subscribeToPublic( _instance, channel_name );
						}
					}
				}
			}
		#end

		function _on_auth_success( channel_name : String, auth : String, is_presence : Bool ) : Void {
			#if android
				if( is_presence ) {
						subscribeToPresence( _instance, channel_name, auth, _auth_user_id );
					} else {
						subscribeToPrivate( _instance, channel_name, auth );
					}
			#end
		}

		function _onConnectTimer( _ ) : Void {
			_connecting	= false;
			_connect_timer.removeEventListener( TimerEvent.TIMER, _onConnectTimer );
			_connect_timer.reset( );
			onConnectError.emit( "[HypPusher] Error ::: connection timed out" );
		}

		function _onConnect( socketId : String ) : Void {
			_connect_timer.removeEventListener( TimerEvent.TIMER, _onConnectTimer );
			_connect_timer.reset( );
			socket_id   	= socketId;
			is_connected	= true;
			_connecting 	= false;
			onConnect.emit( socketId );
			#if android
			_pusher_auth.reset( );
			_subscribeOnceConnected( );
			#end
		}

		function _onConnectError( error : String ) : Void {
			_connect_timer.removeEventListener( TimerEvent.TIMER, _onConnectTimer );
			_connect_timer.reset( );
			socket_id   	= null;
			is_connected	= false;
			_connecting 	= false;
			onConnectError.emit( error );
		}

		function _onDisconnect( ) : Void {
			socket_id   	= null;
			is_connected	= false;
			_connecting 	= false;
			for ( channel_name in _channels.keys( ) ) {
				_channels.set( channel_name, false );
			}
			onDisconnect.emit();
		}

		function _onChannelMessage( event : String, data : String, channel_name : String ) : Void {
			trace( '[HypPusher] ::: on channel message ::: $event,  data ::: $data, channel_name ::: $channel_name \n' );
			var dataObj : Dynamic = _parseData( data );
			onChannelMessage.emit( event, dataObj, channel_name );
		}

		function _onMessage( event : String, data : String, channel_name : String ) : Void {
			trace( '[HypPusher] ::: on message ::: $event,  data ::: $data, channel_name ::: $channel_name \n' );
			var dataObj : Dynamic = _parseData( data );
			onMessage.emit( event, dataObj, channel_name );
		}

		function _onSubscribed( channel_name : String ) : Void {
			_connect_timer.removeEventListener( TimerEvent.TIMER, _onConnectTimer );
			_connect_timer.reset( );
			_channels.set( channel_name, true );
			#if android
				trace( "events: "+_events );
				var events = _events.get( channel_name );
				if( events != null ) {
					for ( event in events ) {
						bindToEvent( _instance, event, channel_name );
					}
				}
			#end
			onSubscribed.emit( channel_name );
		}

		function _onSubscribeError( channel_name : String, error : String ) : Void {
			_connect_timer.removeEventListener( TimerEvent.TIMER, _onConnectTimer );
			_connect_timer.reset( );
			onSubscribeError.emit( channel_name, error );
		}

		function _parseData( data : String ) : Dynamic {
			var dataObj : Dynamic = {};
			try{
				dataObj	= haxe.Json.parse( data );
			} catch( e : Dynamic ) {
				trace( "[HypPusher] Error ::: "+ e + " parsing Json data ::: "+data );
			}
			if( dataObj == null ) {
				dataObj = {};
			}
			return dataObj;
		}


	// -------o native

		#if android

			@JNI
			static function create( apiKey : String ) : HypPusher {}

			@JNI
			function connectToPusher( instance : Dynamic ) : Void {}

			@JNI
			function disconnect( instance : Dynamic ) : Void {}

			@JNI
			function unsubscribe( instance : Dynamic, chan : String ) : Void {}

			@JNI
			function subscribeToPublic( instance : Dynamic, chan : String ) : Void {}

			@JNI
			function subscribeToPrivate( instance : Dynamic, chan : String, auth : String ) : Void {}

			@JNI
			function subscribeToPresence( instance : Dynamic, chan : String, auth : String, user_id : String ) : Void {}

			@JNI
			function bindToEvent( instance : Dynamic, event : String, chan : String ) : Void {}

			@JNI
			function unbindEvent( instance : Dynamic, event : String, chan : String ) : Void {}

			@JNI
			function sendEvent( instance : Dynamic, event : String, data : String, chan : String ) : Void {}

		#end

		#if cpp

			@CPP("hyppusher")
			function hyppusher_create( apiKey : String ) : Void {}

			@CPP("hyppusher")
			function hyppusher_set_authurl( url : String, token : String, user_id : String ) : Void {}

			@CPP("hyppusher")
			function hyppusher_connect( ) : Void {}

			@CPP("hyppusher")
			function hyppusher_disconnect( ) : Void {}

			@CPP("hyppusher")
			function hyppusher_subscribe( channel : String ) : Void {}

			@CPP("hyppusher")
			function hyppusher_unsubscribe( channel : String ) : Void {}

			@CPP("hyppusher")
			function hyppusher_bind_event( event : String, channel : String ) : Void {}

			@CPP("hyppusher")
			function hyppusher_unbind_event( event : String, channel : String ) : Void {}

			@CPP("hyppusher")
			function hyppusher_send_event( event : String, data : String, chan : String ) : Void {}

			// CPP Callbacks

			@CPP("hyppusher")
			function hyppusher_cb_connect( cb : Dynamic ) : Dynamic {}

			@CPP("hyppusher")
			function hyppusher_cb_connect_error( cb : Dynamic ) : Dynamic {}

			@CPP("hyppusher")
			function hyppusher_cb_disconnect( cb : Dynamic ) : Dynamic {}

			@CPP("hyppusher")
			function hyppusher_cb_message( cb : Dynamic ) : Dynamic {}

			@CPP("hyppusher")
			function hyppusher_cb_channel_message( cb : Dynamic ) : Dynamic {}

			@CPP("hyppusher")
			function hyppusher_cb_subscribed( cb : Dynamic ) : Dynamic {}

			@CPP("hyppusher")
			function hyppusher_cb_subscribe_error( cb : Dynamic ) : Dynamic {}

		#end


	// -------o misc
}