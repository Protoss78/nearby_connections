#import "NearbyConnectionsPlugin.h"
#import <nearby_connections/nearby_connections-Swift.h>

@implementation NearbyConnectionsPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftNearbyConnectionsPlugin registerWithRegistrar:registrar];
}
@end
