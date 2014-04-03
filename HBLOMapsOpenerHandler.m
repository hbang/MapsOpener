#import "Global.h"
#import "HBLOMapsOpenerHandler.h"

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

	static NSArray *SupportedPaths = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		SupportedPaths = [@[ @"", @"place", @"search", @"dir" ] retain];
	});

	if ([url.scheme isEqualToString:@"maps"]) {
		return [NSURL URLWithString:[@"comgooglemaps://?" stringByAppendingString:[[url.absoluteString
			stringByReplacingOccurrencesOfString:@"maps:address=" withString:@"maps:q="]
			stringByReplacingOccurrencesOfString:@"maps:" withString:@""]]];
	} else if (([url.host hasPrefix:@"maps.google."] && [url.path isEqualToString:@"/maps"])
		|| (([url.host hasPrefix:@"google."] || [url.host hasPrefix:@"www.google."]) && [url.pathComponents[1] isEqualToString:@"maps"] && [SupportedPaths containsObject:url.pathComponents.count > 1 ? url.pathComponents[2] : @""])) {
		return [NSURL URLWithString:[@"comgooglemaps://?mapsurl=" stringByAppendingString:PERCENT_ENCODE(url.absoluteString)]];
	}

	return nil;
}

@end
