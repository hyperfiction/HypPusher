package fr.hyperfiction;

import nme.Lib;
import nme.net.URLLoader;
import nme.net.URLRequest;
import nme.net.URLRequestMethod;
import nme.net.URLVariables;

import nme.events.Event;
import nme.events.SecurityErrorEvent;
import nme.events.IOErrorEvent;

import org.shoebox.utils.system.Signal2;
import org.shoebox.utils.system.Signal3;

import haxe.Http;

#if cpp
import cpp.vm.Thread;
#end

class HypPusherAuth {

	public var sgAuthSuccessful	: Signal3<String, String, Bool>;
	public var sgAuthFailed    	: Signal2<String, String>;
	public var sgAuthError     	: Signal2<String, String>;

	var _socket_id   	: String;
	var _end_point   	: String;
	var _channel_name	: String;
	var _token       	: String;
	var _user_id     	: String;
	var _result      	: String;
	var _error       	: String;
	var _is_presence 	: Bool;

	var _channels_auth	: Hash<String>;

	public function new() {
		sgAuthSuccessful	= new Signal3<String, String, Bool>();
		sgAuthFailed    	= new Signal2<String, String>();
		sgAuthError     	= new Signal2<String, String>();
		_channels_auth  	= new Hash<String>( );
	}

	public function reset( ) : Void {
		_channels_auth	= new Hash<String>( );
	}

	public function getAuth( channel_name : String ) : String {
		return _channels_auth.get( channel_name );
	}

	public function authenticate( socket_id : String, end_point : String, channel_name : String, token : String, ?userId : String ) : Void {
		trace( " auth endpoint ::: "+end_point );
		if( userId == null ) {
			_is_presence = false;
		} else {
			_is_presence = true;
		}
		var auth : String = getAuth( channel_name );
		if( auth != null ){
			sgAuthSuccessful.emit( channel_name, auth, _is_presence );
			return;
		}

		#if cpp
			var thread_load : Thread;

			thread_load = Thread.create( _callHttp );

			thread_load.sendMessage( Thread.current( ) );
			thread_load.sendMessage( end_point );
			thread_load.sendMessage( socket_id );
			thread_load.sendMessage( channel_name );
			thread_load.sendMessage( token );
			thread_load.sendMessage( userId );

			Lib.current.stage.addEventListener( Event.ENTER_FRAME, watchThread );

		#else
			_socket_id   	= socket_id;
			_end_point   	= end_point;
			_channel_name	= channel_name;
			_token       	= token;
			_user_id     	= userId;

			_callHttp( );
		#end
	}

	function _callHttp( ) : Void {
		#if cpp
		var main_thread	: Thread;
		main_thread    	= Thread.readMessage( true );

		_end_point   	= Thread.readMessage( true );
		_socket_id   	= Thread.readMessage( true );
		_channel_name	= Thread.readMessage( true );
		_token       	= Thread.readMessage( true );
		_user_id     	= Thread.readMessage( true );
		#end

		var http : Http = new Http( _end_point );

		http.setParameter( "socket_id", _socket_id );
		http.setParameter( "channel_name", _channel_name );
		http.setParameter( "token", _token );
		http.setParameter( "user_id", _user_id );

		http.onData		= function( res : String ) {
			#if cpp
			main_thread.sendMessage( res );
			#else
			_result = res;
			watchThread( null );
			#end
		}

		http.onError	= function( msg : String ) {
			#if cpp
			main_thread.sendMessage( "error" );
			main_thread.sendMessage( msg );
			#else
			_error = msg;
			watchThread( null );
			#end
		}

		http.request( true );

	}

	function watchThread( _ ) : Void {
		#if cpp
		_error 	= null;
		_result	= Thread.readMessage( false );

		if( _result != null ) {
			Lib.current.stage.addEventListener( Event.ENTER_FRAME, watchThread );
			if( _result == "error" ) {
				_error = Thread.readMessage( true );
			}
		}
		#end

		if( _error != null ) {
			trace('error! (' + _error + ')');
			sgAuthError.emit( _channel_name, _error );

		} else if( _result != null ) {
			trace( "result ::: "+ _result );
			var decodedData : Dynamic;

			try {
				decodedData = haxe.Json.parse( _result );
			} catch ( e : Dynamic ){
				sgAuthFailed.emit( _channel_name, 'authentication failed! Property "data" not found in response data.' );
				return;
			}

			if( Reflect.hasField( decodedData, 'auth' ) ) {
				var authString:String = decodedData.auth;
				_channels_auth.set( _channel_name, authString );
				sgAuthSuccessful.emit( _channel_name, authString, _is_presence );
			} else {
				sgAuthFailed.emit( _channel_name, 'authentication failed! Property "auth" not found in response data.' );
			}
		}
	}
}