#import "HypPusher.h"
#import "PTJSON.h"
#import "PTPusher.h"
#import "PTPusherEvent.h"
#import "PTPusherChannel.h"
#import "PTPusherDelegate.h"

#define kLOG_ALL_EVENTS
#define kUSE_ENCRYPTED_CHANNELS YES


// Externs

extern "C" {
	void hyppusher_on_connect( const char *socketId );
	void hyppusher_on_subscribed( const char *channel );
	void hyppusher_on_subscribe_error( const char *channel, const char *error );
	void hyppusher_on_disconnect( );
	void hyppusher_on_message( const char *event, const char *data, const char *channel );
	void hyppusher_on_channel_message( const char *event, const char *data, const char *channel );
}


// Interfaces

	@class PTPusher;

	@interface HypPusherDelegate : NSObject <PTPusherDelegate>
	{}
	@property (nonatomic, strong) PTPusher *pusher;
	@property (nonatomic, strong) NSString *token;
	@property (nonatomic, strong) NSString *user_id;

	- (PTPusher *)createInstance:(NSString*)apiKey;

	@end


// Implementations

@implementation HypPusherDelegate

	@synthesize pusher = _pusher;


	- (void)dealloc {
		// [[NSNotificationCenter defaultCenter]
		//	removeObserver:self name:PTPusherEventReceivedNotification object:self.pusher];
		[super dealloc];
	}

	#pragma mark - Event notifications

	- (void)handlePusherEvent:(NSNotification *)note {
	#ifdef kLOG_ALL_EVENTS
		PTPusherEvent *event = [note.userInfo objectForKey:PTPusherEventUserInfoKey];
	#endif
	}

	#pragma mark - Client creation

	- (PTPusher *)createInstance:(NSString*)apiKey {
		PTPusher *client     	= [PTPusher pusherWithKey:apiKey connectAutomatically:NO encrypted:kUSE_ENCRYPTED_CHANNELS];
		client.reconnectDelay	= 5;
		client.delegate      	= self;

		// [[NSNotificationCenter defaultCenter]
		//	addObserver:self
		//	selector:@selector(didReceiveEventNotification:)
		//	name:PTPusherEventReceivedNotification
		//	object:client
		// ];

		return client;
	}

	- (void)didReceiveEventNotification:(NSNotification *)note {
		PTPusherEvent *event = [note.userInfo objectForKey:PTPusherEventUserInfoKey];
		@try{
			NSString *data = [[[PTJSON JSONParser] JSONStringFromObject:event.data] copy];
			NSLog (@"json data: %@",data);
			hyppusher_on_message( [event.name UTF8String], [data UTF8String], [event.channel UTF8String] );
			[data release];
		} @catch( NSException* e ) {
			NSLog (@"invalid json data in message...");
		}
	}


	#pragma mark - PTPusherDelegate methods

	- (void)pusher:(PTPusher *)pusher connectionDidConnect:(PTPusherConnection *)connection {
	    pusher.reconnectAutomatically = YES;

		NSLog(@"[pusher-%@] Pusher client connected", connection.socketID);

		hyppusher_on_connect( [connection.socketID UTF8String] );
	}

	- (void)pusher:(PTPusher *)pusher connection:(PTPusherConnection *)connection didDisconnectWithError:(NSError *)error {
		NSLog(@"[pusher-%@] Pusher Connection failed, error: %@", pusher.connection.socketID, error);
		hyppusher_on_disconnect( );
	}

	- (void)pusher:(PTPusher *)pusher connection:(PTPusherConnection *)connection failedWithError:(NSError *)error {
		NSLog(@"[pusher-%@] Pusher Connection failed, error: %@", pusher.connection.socketID, error);
	}

	- (void)pusher:(PTPusher *)pusher connectionWillReconnect:(PTPusherConnection *)connection afterDelay:(NSTimeInterval)delay {
		NSLog(@"[pusher-%@] Reconnecting after %d seconds...", pusher.connection.socketID, (int)delay);
	}

	- (void)pusher:(PTPusher *)pusher didSubscribeToChannel:(PTPusherChannel *)channel {
		NSLog(@"[pusher-%@] Subscribed to channel %@", pusher.connection.socketID, channel);
		hyppusher_on_subscribed( [channel.name UTF8String] );
	}

	- (void)pusher:(PTPusher *)pusher didFailToSubscribeToChannel:(PTPusherChannel *)channel withError:(NSError *)error {
		NSLog(@"[pusher-%@] Authorization failed for channel %@", pusher.connection.socketID, channel);
		if (pusher != self.pusher) {
			[pusher disconnect];
		}
		hyppusher_on_subscribe_error( [channel.name UTF8String], [[error localizedDescription]UTF8String] );
	}

	- (void)pusher:(PTPusher *)pusher didReceiveErrorEvent:(PTPusherErrorEvent *)errorEvent {
		NSLog(@"[pusher-%@] Received error event %@", pusher.connection.socketID, errorEvent);
	}

	- (void)pusher:(PTPusher *)pusher willAuthorizeChannelWithRequest:(NSMutableURLRequest *)request {
		NSLog(@"[pusher-%@] Authorizing channel access...", pusher.connection.socketID);

		NSMutableData *data = (NSMutableData *)[request HTTPBody];
		if( _token != (NSString *)[NSNull null] ){
			[data appendData:[_token dataUsingEncoding:NSUTF8StringEncoding]];
		}
		if( _user_id != (NSString *)[NSNull null] ) {
			[data appendData:[_user_id dataUsingEncoding:NSUTF8StringEncoding]];
		}
		[request setHTTPBody:data];
	}

	@end

namespace hyppusher {

	HypPusherDelegate *hp;
	NSMutableDictionary *bindings;

	void createClient( const char *apiKey ) {
		NSString *s	= [NSString stringWithUTF8String:apiKey];
		hp         	= [HypPusherDelegate alloc];
		hp.pusher  	= [hp createInstance:s];
		bindings   	= [[NSMutableDictionary alloc] init];
	}

	void setAuthEndPoint( const char *url, const char *token, const char *user_id ) {
		hp.token	= [NSString stringWithFormat:@"&token=%s", token];
		if( user_id != NULL ) {
			hp.user_id	= [NSString stringWithFormat:@"&user_id=%s", user_id];
		}
		NSString *s               	= [NSString stringWithUTF8String:url];
		NSURL *ns                 	= [[NSURL alloc] initWithString:s];
		hp.pusher.authorizationURL	= ns;
		[ns release];
	}

	void unbindEvent( const char *event, const char *channel_name ) {
		NSString *eventString                	= [NSString stringWithUTF8String:event];
		NSString *s                          	= [NSString stringWithUTF8String:channel_name];
		PTPusherChannel *channel             	= [hp.pusher channelNamed:s];
		NSMutableDictionary *channel_bindings	= [bindings objectForKey:channel];
		[channel removeBinding:[channel_bindings objectForKey:eventString]];
		[channel_bindings removeObjectForKey:eventString];
	}

	void bindEvent( const char *event, const char *channel_name ) {
		NSString *eventString   	= [NSString stringWithUTF8String:event];
		NSString *s             	= [NSString stringWithUTF8String:channel_name];
		PTPusherChannel *channel	= [hp.pusher channelNamed:s];
		PTPusherEventBinding *evtBind = [channel bindToEventNamed:eventString handleWithBlock:^(PTPusherEvent *event) {
			@try{
				NSString *data = [[[PTJSON JSONParser] JSONStringFromObject:event.data] copy];
				hyppusher_on_channel_message( [event.name UTF8String], [data UTF8String], [event.channel UTF8String] );
				[data release];
			} @catch( NSException* e ) {
				NSLog (@"invalid json data in channel message...");
			}
		}];
		NSMutableDictionary *channel_bindings = [bindings objectForKey:channel];
		if( !channel_bindings ) {
			channel_bindings = [[NSMutableDictionary alloc] init];
		}
		[channel_bindings setObject:evtBind forKey:eventString];
	}

	void sendEvent( const char *event, const char *data, const char *channel ) {
		NSString *eventString  	= [NSString stringWithUTF8String:event];
		NSString *dataString   	= [NSString stringWithUTF8String:data];
		NSString *channelString	= [NSString stringWithUTF8String:channel];

		[hp.pusher sendEventNamed: eventString data:dataString channel:channelString];
	}

	void connect( ) {
		[hp.pusher connect];
		NSLog (@"connecting to pusher...");
	}

	void disconnect( ) {
		[hp.pusher disconnect];
		NSLog (@"disconnecting from pusher ! ");
	}

	void subscribe( const char *channel ) {
		NSString *s = [NSString stringWithUTF8String:channel];
		[hp.pusher subscribeToChannelNamed:s];
		NSLog (@"subscribe to %s ",channel);
	}

	void unsubscribe( const char *channel_name ) {
		NSString *s             	= [NSString stringWithUTF8String:channel_name];
		PTPusherChannel *channel	= [hp.pusher channelNamed:s];
		[bindings removeObjectForKey:channel];
		[channel unsubscribe];
		NSLog (@"unsubscribe from %s ",channel_name);
	}

}