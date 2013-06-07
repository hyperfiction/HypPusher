#ifndef Device
#define Device

namespace hyppusher {

	void createClient( const char *apiKey );
	void connect( );
	void setAuthEndPoint( const char *url, const char *token, const char *user_id );
	void disconnect( );
	void subscribe( const char *channel );
	void unsubscribe( const char *channel );
	void sendEvent( const char *event, const char *data, const char *channel );
	void bindEvent( const char *event, const char *channel );
	void unbindEvent( const char *event, const char *channel );
}

#endif