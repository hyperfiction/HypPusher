#ifndef IPHONE
#define IMPLEMENT_API
#endif

#include <hx/CFFI.h>
#include <stdio.h>
#include <hxcpp.h>
#include "HypPusher.h"

#ifdef ANDROID
#include <jni.h>
#include <android/log.h>
#endif

using namespace hyppusher;

#ifdef ANDROID
	extern JNIEnv *GetEnv();
	enum JNIType{
	   jniUnknown,
	   jniVoid,
	   jniObjectString,
	   jniObjectArray,
	   jniObject,
	   jniBoolean,
	   jniByte,
	   jniChar,
	   jniShort,
	   jniInt,
	   jniLong,
	   jniFloat,
	   jniDouble,
	};
#endif

AutoGCRoot *_on_connect        	= 0;
AutoGCRoot *_on_connect_error  	= 0;
AutoGCRoot *_on_disconnect     	= 0;
AutoGCRoot *_on_message        	= 0;
AutoGCRoot *_on_channel_message	= 0;
AutoGCRoot *_on_subscribed     	= 0;
AutoGCRoot *_on_subscribe_error	= 0;

extern "C" {

	int hyppusher_register_prims( ) {
		printf("HypPusher ::: register_prims() \n");
		return 0;
	}

// Android -------------------------------------------------------------------------------------------------------------

	#ifdef ANDROID

		JNIEXPORT void JNICALL Java_fr_hyperfiction_HypPusher_onConnect(JNIEnv * env, jobject  obj, jstring socketId ) {
			const char *socketIdString = env->GetStringUTFChars(socketId, 0);
	        val_call1( _on_connect -> get( ), alloc_string( socketIdString )  );
			env->ReleaseStringUTFChars( socketId, socketIdString );
	    }

		JNIEXPORT void JNICALL Java_fr_hyperfiction_HypPusher_onConnectError(JNIEnv * env, jobject  obj, jstring error ) {
			const char *errorString = env->GetStringUTFChars(error, 0);
	        val_call1( _on_connect_error -> get( ), alloc_string( errorString )  );
			env->ReleaseStringUTFChars( error, errorString );
	    }

	    JNIEXPORT void JNICALL Java_fr_hyperfiction_HypPusher_onDisconnect(JNIEnv * env, jobject  obj ) {
	        val_call0( _on_disconnect -> get( ) );
	    }

		JNIEXPORT void JNICALL Java_fr_hyperfiction_HypPusher_onMessage(
		                                                                JNIEnv * env,
		                                                                jobject  obj,
		                                                                jstring event,
		                                                                jstring data,
		                                                                jstring channel
		                                                                ) {
			 const char *eventString = env->GetStringUTFChars(event, 0);
			 const char *dataString = env->GetStringUTFChars(data, 0);
			 const char *channelString = env->GetStringUTFChars(channel, 0);

			 val_call3( _on_message -> get( ),
			           alloc_string( eventString ),
			           alloc_string( dataString ),
			           alloc_string( channelString )
			           );

			 env->ReleaseStringUTFChars( event, eventString );
			 env->ReleaseStringUTFChars( data, dataString );
			 env->ReleaseStringUTFChars( channel, channelString );
	    }

		JNIEXPORT void JNICALL Java_fr_hyperfiction_HypPusher_onChannelMessage(
		                                                                JNIEnv * env,
		                                                                jobject  obj,
		                                                                jstring event,
		                                                                jstring data,
		                                                                jstring channel
		                                                                ) {
			 const char *eventString = env->GetStringUTFChars(event, 0);
			 const char *dataString = env->GetStringUTFChars(data, 0);
			 const char *channelString = env->GetStringUTFChars(channel, 0);

			 val_call3( _on_channel_message -> get( ),
			           alloc_string( eventString ),
			           alloc_string( dataString ),
			           alloc_string( channelString )
			           );

			 env->ReleaseStringUTFChars( event, eventString );
			 env->ReleaseStringUTFChars( data, dataString );
			 env->ReleaseStringUTFChars( channel, channelString );
	    }

	    JNIEXPORT void JNICALL Java_fr_hyperfiction_HypPusher_onSubscribed(
	                                                                       JNIEnv * env,
	                                                                       jobject obj,
	                                                                       jstring channel
	                                                                       ) {
			const char *channelString = env->GetStringUTFChars(channel, 0);
	        val_call1( _on_subscribed -> get( ), alloc_string( channelString )  );
			env->ReleaseStringUTFChars( channel, channelString );
	    }

	    JNIEXPORT void JNICALL Java_fr_hyperfiction_HypPusher_onSubscribeError(
	                                                                       JNIEnv * env,
	                                                                       jobject obj,
	                                                                       jstring channel,
	                                                                       jstring error
	                                                                       ) {
			const char *channelString = env->GetStringUTFChars(channel, 0);
			const char *errorString = env->GetStringUTFChars(error, 0);
	        val_call2( _on_subscribe_error -> get( ), alloc_string( channelString ), alloc_string( errorString )  );
			env->ReleaseStringUTFChars( channel, channelString );
			env->ReleaseStringUTFChars( error, errorString );
	    }
	#endif

// iOS -----------------------------------------------------------------------------------------------------------------

	#ifdef IPHONE

		void hyppusher_on_connect( const char *socketId ) {
			val_call1( _on_connect -> get( ), alloc_string( socketId ) );
		}

		void hyppusher_on_connect_error( const char *error ) {
			val_call1( _on_connect_error -> get( ), alloc_string( error ) );
		}

		void hyppusher_on_subscribed( const char *channel ) {
			val_call1( _on_subscribed-> get( ), alloc_string( channel ) );
		}

		void hyppusher_on_subscribe_error( const char *channel, const char *error ) {
			val_call2( _on_subscribe_error-> get( ), alloc_string( channel ), alloc_string( error ) );
		}

		void hyppusher_on_disconnect( ) {
			val_call0( _on_disconnect -> get( ) );
		}

		void hyppusher_on_message( const char *event, const char *data, const char *channel ) {
			printf("hyppusher_on_message ::: %s ::: %s ::: %s \n",event,data,channel );
			val_call3( _on_message -> get( ), alloc_string( event ), alloc_string( data ), alloc_string( channel ) );
		}

		void hyppusher_on_channel_message( const char *event, const char *data, const char *channel ) {
			printf("hyppusher_on_channel_message ::: %s ::: %s ::: %s \n",event,data,channel );
			val_call3( _on_channel_message -> get( ), alloc_string( event ), alloc_string( data ), alloc_string( channel ) );
		}

	#endif

// iOS -----------------------------------------------------------------------------------------------------------------

	#ifdef IPHONE

		void hyppusher_bind_event( value event, value channel ) {
			bindEvent( val_string(event), val_string( channel ) );
		}
		DEFINE_PRIM( hyppusher_bind_event, 2);

		void hyppusher_unbind_event( value event, value channel ) {
			unbindEvent( val_string(event), val_string( channel ) );
		}
		DEFINE_PRIM( hyppusher_unbind_event, 2);

		void hyppusher_send_event( value event, value data, value channel ) {
			sendEvent( val_string(event), val_string(data), val_string(channel) );
		}
		DEFINE_PRIM( hyppusher_send_event, 3);

		void hyppusher_create( value apiKey ) {
			createClient( val_string( apiKey ) );
		}
		DEFINE_PRIM( hyppusher_create, 1 );

		void hyppusher_set_authurl( value url, value token, value user_id ) {
			setAuthEndPoint( val_string( url ), val_string( token ), val_string( user_id ) );
		}
		DEFINE_PRIM( hyppusher_set_authurl, 3 );

		void hyppusher_subscribe( value channel ) {
			subscribe( val_string( channel ) );
		}
		DEFINE_PRIM( hyppusher_subscribe, 1 );

		void hyppusher_unsubscribe( value channel ) {
			unsubscribe( val_string( channel ) );
		}
		DEFINE_PRIM( hyppusher_unsubscribe, 1 );

		void hyppusher_connect( ) {
			connect( );
		}
		DEFINE_PRIM( hyppusher_connect, 0 );

		void hyppusher_disconnect( ) {
			disconnect( );
		}
		DEFINE_PRIM( hyppusher_disconnect, 0 );

	#endif




// Callbacks -----------------------------------------------------------------------------------------------------------

	static value hyppusher_cb_connect( value onCall ) {
		_on_connect = new AutoGCRoot( onCall );
	    return alloc_bool(true);
	}
	DEFINE_PRIM(hyppusher_cb_connect,1);

	static value hyppusher_cb_connect_error( value onCall ) {
		_on_connect_error = new AutoGCRoot( onCall );
	    return alloc_bool(true);
	}
	DEFINE_PRIM(hyppusher_cb_connect_error,1);

	static value hyppusher_cb_disconnect( value onCall ) {
		_on_disconnect = new AutoGCRoot( onCall );
	    return alloc_bool(true);
	}
	DEFINE_PRIM(hyppusher_cb_disconnect,1);

	static value hyppusher_cb_message( value onCall ) {
		_on_message = new AutoGCRoot( onCall );
	    return alloc_bool(true);
	}
	DEFINE_PRIM(hyppusher_cb_message,1);

	static value hyppusher_cb_channel_message( value onCall ) {
		_on_channel_message = new AutoGCRoot( onCall );
	    return alloc_bool(true);
	}
	DEFINE_PRIM(hyppusher_cb_channel_message,1);

	static value hyppusher_cb_subscribed( value onCall ) {
		_on_subscribed = new AutoGCRoot( onCall );
	    return alloc_bool(true);
	}
	DEFINE_PRIM(hyppusher_cb_subscribed,1);

	static value hyppusher_cb_subscribe_error( value onCall ) {
		_on_subscribe_error = new AutoGCRoot( onCall );
	    return alloc_bool(true);
	}
	DEFINE_PRIM(hyppusher_cb_subscribe_error,1);
}