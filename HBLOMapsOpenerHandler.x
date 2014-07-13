#import "Global.h"
#import "HBLOMapsOpenerHandler.h"
#import <UIKit/NSString+UIKitAdditions.h>
#import <MapKit/MapKit.h>
#include <dlfcn.h>

@implementation HBLOMapsOpenerHandler

- (instancetype)init {
	self = [super init];

	if (self) {
		self.name = @"MapsOpener";
		self.identifier = @"MapsOpener";
	}

	return self;
}

- (NSURL *)openURL:(NSURL *)url sender:(NSString *)sender {
	if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
		return nil;
	}

	static NSArray *GoogleMapsPaths = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		GoogleMapsPaths = [@[ @"", @"place", @"search", @"dir" ] retain];
	});

	if ([url.scheme isEqualToString:@"maps"]) {
		NSDictionary *query = [url.absoluteString substringFromIndex:5].queryKeysAndValues;

		if (query[@"ios_addr"]) {
			return [NSURL URLWithString:[@"comgooglemaps://?q=" stringByAppendingString:PERCENT_ENCODE(query[@"ios_addr"])]];
		} else if (query[@"address"]) {
			return [NSURL URLWithString:[@"comgooglemaps://?q=" stringByAppendingString:PERCENT_ENCODE(query[@"address"])]];
		} else if (query[@"saddr"] && query[@"daddr"]) {
			return [NSURL URLWithString:[NSString stringWithFormat:@"comgooglemaps://?saddr=%@&daddr=%@", PERCENT_ENCODE(query[@"saddr"]), PERCENT_ENCODE(query[@"daddr"])]];
		} else {
			return nil;
		}
	} else if ([url.scheme isEqualToString:@"mapitem"] && %c(MKMapItem)) {
		NSArray *items = [MKMapItem mapItemsFromURL:url options:nil];
		return [MKMapItem urlForMapItems:items options:nil];
	} else if (([url.host hasPrefix:@"maps.google."] && [url.path isEqualToString:@"/maps"])
		|| (([url.host hasPrefix:@"google."] || [url.host hasPrefix:@"www.google."]) && url.pathComponents.count > 2 && [url.pathComponents[1] isEqualToString:@"maps"] && [GoogleMapsPaths containsObject:url.pathComponents[2]])) {
		return [NSURL URLWithString:[@"comgooglemaps://?mapsurl=" stringByAppendingString:PERCENT_ENCODE(url.absoluteString)]];
	}

	return nil;
}

@end
