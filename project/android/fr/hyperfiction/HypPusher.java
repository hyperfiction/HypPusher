package fr.hyperfiction;

import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONArray;

import org.haxe.nme.GameActivity;

import android.opengl.GLSurfaceView;
import android.util.Log;

import com.justinschultz.pusherclient.ChannelListener;
import com.justinschultz.pusherclient.Pusher;
import com.justinschultz.pusherclient.Pusher.Channel;
import com.justinschultz.pusherclient.PusherListener;

public class HypPusher extends Pusher {

	public static String TAG = "HypPusher";

	public static native void onConnect( String socketId );
	public static native void onDisconnect( );
	public static native void onMessage( String event, String data, String channel );
	public static native void onChannelMessage( String event, String data, String channel );
	public static native void onSubscribed( String channel );
	public static native void onSubscribeError( String channel, String error );

	public static GLSurfaceView mSurface;

	private PusherListener _eventListener;

	static {
		System.loadLibrary("hyppusher");
	}

	public HypPusher( String apiKey ) {
		super( apiKey );
		mSurface = (GLSurfaceView) GameActivity.getInstance().getCurrentFocus();
		_eventListener = new PusherListener() {
			@Override
			public void onConnect(final String socketId) {
				Log.i(TAG, "[HypPusher] Connected. Socket Id is: " + socketId);
				mSurface.queueEvent(new Runnable() {
					@Override
					public void run() {
						HypPusher.onConnect( socketId );
					}
				});
			}

			@Override
			public void onMessage(JSONObject message) {
				String event;
				String data;
				String channel;
				Boolean is_array;

				event  	= message.optString("event");
				data   	= message.optString("data");
				channel	= message.optString("channel");

				if( event.equals( "pusher_internal:subscription_succeeded" ) ) {
					is_array = true;
				} else {
					is_array = false;
				}
				JSONObject tmp;
				JSONArray tmpa;
				try{
					if( is_array ){
						tmpa = new JSONArray( data );
						tmp = tmpa.getJSONObject(0);
					} else {
						tmp = new JSONObject(data);
					}
				} catch ( JSONException e ){
					e.printStackTrace();
					tmp = new JSONObject( );
					Log.i(TAG, "[HypPusher] invalid json data in message...");
				}

				final String msgEvent  	= event;
				final String msgData   	= tmp.toString( );
				final String msgChannel	= channel;

				mSurface.queueEvent(new Runnable( ) {
					@Override
					public void run() {
						Log.i( TAG, "[HypPusher] Received message : "+msgEvent+" on channel : "+msgChannel+" with data : "+msgData);
						if( msgEvent.equals( "pusher_internal:subscription_succeeded" ) ) {
							HypPusher.onSubscribed( msgChannel );
						} else {
							HypPusher.onMessage(msgEvent, msgData, msgChannel);
						}
					}
				});
			}

			@Override
			public void onDisconnect() {
				Log.i(TAG, "[HypPusher] Disconnected.");
				mSurface.queueEvent(new Runnable( ) {
					@Override
					public void run() {
						HypPusher.onDisconnect();
					}
				});
			}
		};
		setPusherListener(_eventListener);
	}

	public static HypPusher create( String apiKey ) {
		return new HypPusher( apiKey );
	}

	public void connectToPusher( ) {
		Log.i(TAG, "[HypPusher] Connecting...");
	    new Thread(new Runnable() {
			public void run() {
				connect( );
			}
		}).start();
	}

	public void subscribeToPublic( final String channelName ) {
		Log.i(TAG, "[HypPusher] subscribeToPublic : " + channelName);
		new Thread(new Runnable() {
			public void run() {
				if( subscribe( channelName ) == null ) {
					mSurface.queueEvent(new Runnable( ) {
						@Override
						public void run() {
							HypPusher.onSubscribeError( channelName, "cannot subscribe to channel");
						}
					});
				} else {
					mSurface.queueEvent(new Runnable( ) {
						@Override
						public void run() {
							HypPusher.onSubscribed( channelName );
						}
					});
				}
			}
		}).start();
	}

	public void subscribeToPrivate( final String channelName, final String authToken ) {
		Log.i(TAG, "[HypPusher] subscribeToPrivate : " + channelName);
		new Thread(new Runnable() {
			public void run() {
				if( subscribe( channelName, authToken ) == null ){
					mSurface.queueEvent(new Runnable( ) {
						@Override
						public void run() {
							HypPusher.onSubscribeError( channelName, "cannot subscribe to channel");
						}
					});
				} else {
					mSurface.queueEvent(new Runnable( ) {
						@Override
						public void run() {
							HypPusher.onSubscribed( channelName );
						}
					});
				}
			}
		}).start();
	}

	public void subscribeToPresence( final String channelName, final String authToken, final String userId ) {
		Log.i(TAG, "[HypPusher] subscribeToPresence : " + channelName);
		new Thread(new Runnable() {
			public void run() {
				if( subscribe( channelName, authToken, userId ) == null ){
					mSurface.queueEvent(new Runnable( ) {
						@Override
						public void run() {
							HypPusher.onSubscribeError( channelName, "cannot subscribe to channel");
						}
					});
				} else {
					mSurface.queueEvent(new Runnable( ) {
						@Override
						public void run() {
							HypPusher.onSubscribed( channelName );
						}
					});
				}
			}
		}).start();
	}

	public void sendEvent( final String eventName, String data, final String channelName ) {
		final Channel channel;
		final JSONObject obj;
		JSONObject tmp;

		channel	= channel(channelName);

		if (channel != null) {
			try {
				tmp = new JSONObject(data);
			} catch (JSONException e) {
				e.printStackTrace();
				tmp = new JSONObject();
			}

			obj = tmp;
			new Thread(new Runnable() {
				public void run() {
					Log.i( TAG, "[HypPusher] send event : "+eventName+" on channel : "+channelName+" with data : "+obj.toString());
					channel.send(eventName, obj);
				}
			}).start();
		}
	}

	public void bindToEvent( final String eventName, final String channelName ) {
		Channel channel = channel(channelName);
		if (channel != null) {
			Log.i(TAG, "[HypPusher] bind to : "+ eventName + " on channel : "+ channelName );
			channel.bind(eventName, new ChannelListener() {
				@Override
				public void onMessage(JSONObject message) {
					String event;
					String data;

					event	= message.optString("event");
					data 	= message.optString("data");

					JSONObject tmp;
					try{
						tmp = new JSONObject(data);
					} catch ( JSONException e ){
						e.printStackTrace();
						tmp = new JSONObject( );
						Log.i(TAG, "[HypPusher] invalid json data in message...");
					}

					final String msgEvent	= event;
					final String msgData 	= tmp.toString();

					mSurface.queueEvent(new Runnable( ) {
						@Override
						public void run() {
							Log.i( TAG, "[HypPusher] Received channel message : "+eventName+" on channel : "+channelName+" with data : "+msgData);
							HypPusher.onChannelMessage( msgEvent, msgData, channelName );
						}
					});
				}
			});
		}
	}

	public void unbindEvent( final String eventName, final String channelName) {
		Channel channel = channel(channelName);
		if (channel != null) {
			Log.i(TAG, "[HypPusher] unbind : "+ eventName + " on channel : "+ channelName );
			channel.unbind(eventName);
		}
	}
}
