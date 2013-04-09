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
	void hyp_on_connect( const char *socketId );
	void hyp_on_subscribed( const char *channel );
	void hyp_on_disconnect( );
	void hyp_on_message( const char *event, const char *data, const char *channel );
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
/*		[[NSNotificationCenter defaultCenter]
  		removeObserver:self name:PTPusherEventReceivedNotification object:self.pusher];*/
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
		client.reconnectDelay	= 10;
		client.delegate      	= self;

/*		[[NSNotificationCenter defaultCenter]
			addObserver:self
			selector:@selector(handlePusherEvent:)
			name:PTPusherEventReceivedNotification
			object:self.pusher
		];*/

	  	return client;
	}


	#pragma mark - PTPusherDelegate methods

	- (void)pusher:(PTPusher *)pusher connectionDidConnect:(PTPusherConnection *)connection {
	    pusher.reconnectAutomatically = YES;

		NSLog(@"[pusher-%@] Pusher client connected", connection.socketID);

		hyp_on_connect( [connection.socketID UTF8String] );
	}

	- (void)pusher:(PTPusher *)pusher connection:(PTPusherConnection *)connection failedWithError:(NSError *)error {
		NSLog(@"[pusher-%@] Pusher Connection failed, error: %@", pusher.connection.socketID, error);
	}

	- (void)pusher:(PTPusher *)pusher connectionWillReconnect:(PTPusherConnection *)connection afterDelay:(NSTimeInterval)delay {
		NSLog(@"[pusher-%@] Reconnecting after %d seconds...", pusher.connection.socketID, (int)delay);
	}

	- (void)pusher:(PTPusher *)pusher didSubscribeToChannel:(PTPusherChannel *)channel {
		NSLog(@"[pusher-%@] Subscribed to channel %@", pusher.connection.socketID, channel);
		hyp_on_subscribed( [channel.name UTF8String] );
	}

	- (void)pusher:(PTPusher *)pusher didFailToSubscribeToChannel:(PTPusherChannel *)channel withError:(NSError *)error {
		NSLog(@"[pusher-%@] Authorization failed for channel %@", pusher.connection.socketID, channel);
		if (pusher != self.pusher) {
			[pusher disconnect];
		}
	}

	- (void)pusher:(PTPusher *)pusher didReceiveErrorEvent:(PTPusherErrorEvent *)errorEvent {
		NSLog(@"[pusher-%@] Received error event %@", pusher.connection.socketID, errorEvent);
	}

	- (void)pusher:(PTPusher *)pusher willAuthorizeChannelWithRequest:(NSMutableURLRequest *)request {
		NSLog(@"[pusher-%@] Authorizing channel access...", pusher.connection.socketID);

		if( _token != (NSString *)[NSNull null] ){
			NSMutableData *data = (NSMutableData *)[request HTTPBody];
			[data appendData:[_token dataUsingEncoding:NSUTF8StringEncoding]];
			if( _user_id != (NSString *)[NSNull null] ) {
				[data appendData:[_user_id dataUsingEncoding:NSUTF8StringEncoding]];
			}
			[request setHTTPBody:data];
		}
	}

	@end

namespace hyperfiction {

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

	void unbindEvent( const char *event ) {
		NSString *eventString	= [NSString stringWithUTF8String:event];
		[hp.pusher removeBinding:[bindings objectForKey:eventString]];
		[bindings removeObjectForKey:eventString];

	}

	void bindEvent( const char *event ) {
		NSString *eventString = [NSString stringWithUTF8String:event];
		PTPusherEventBinding *evtBind = [hp.pusher bindToEventNamed:eventString handleWithBlock:^(PTPusherEvent *event) {
			@try{
				NSString *data = [[[PTJSON JSONParser] JSONStringFromObject:event.data] copy];
				hyp_on_message( [event.name UTF8String], [data UTF8String], [event.channel UTF8String] );
				[data release];
			} @catch( NSException* e ) {
				NSLog (@"invalid json data in message...");
			}
		}];
		[bindings setObject:evtBind forKey:eventString];
	}

	void unbindEventOnChannel( const char *event, const char *channel ) {
		// TODO
		NSLog (@"unbindEventOnChannel is not implemented yet on iOS");
	}

	void bindEventOnChannel( const char *event, const char *channel ) {
		// TODO
		NSLog (@"bindEventOnChannel is not implemented yet on iOS");
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
		[channel unsubscribe];
		NSLog (@"unsubscribe from %s ",channel_name);
	}

}