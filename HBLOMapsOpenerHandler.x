#import "Global.h"
#import "HBLOMapsOpenerHandler.h"
#import <UIKit/NSString+UIKitAdditions.h>
#include <dlfcn.h>

@import MapKit;

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

	if ([url.scheme isEqualToString:@"maps"]) {
		NSDictionary *query = [url.absoluteString substringFromIndex:5].queryKeysAndValues;

		if (query[@"ios_addr"]) {
			return [NSURL URLWithString:[@"comgooglemaps://?q=" stringByAppendingString:PERCENT_ENCODE(query[@"ios_addr"])]];
		} else if (query[@"address"]) {
			return [NSURL URLWithString:[@"comgooglemaps://?q=" stringByAppendingString:PERCENT_ENCODE(query[@"address"])]];
		} else if (query[@"saddr"] && query[@"daddr"]) {
			return [NSURL URLWithString:[NSString stringWithFormat:@"comgooglemaps://?saddr=%@&daddr=%@", PERCENT_ENCODE(query[@"saddr"]), PERCENT_ENCODE(query[@"daddr"])]];
		} else {
			HBLogError(@"failed to handle unknown maps: url: %@", url);
			return nil;
		}
	} else if ([url.scheme isEqualToString:@"mapitem"]) {
		dlopen("/Library/MobileSubstrate/DynamicLibraries/MapsOpenerHooks.dylib", RTLD_LAZY);

		NSArray *items = [MKMapItem mapItemsFromURL:url options:nil];
		NSURL *url = [MKMapItem urlForMapItems:items options:nil];

		/*
		 if, for some reason, we failed, don't use the new url which may have
		 missing data
		*/
		return [url.host isEqualToString:@"mapitem"] ? nil : url;
	} else if ([url.host hasPrefix:@"maps.google."] || (([url.host hasPrefix:@"google."] || [url.host hasPrefix:@"www.google."] || [url.host isEqualToString:@"goo.gl"]) && url.pathComponents.count > 2 && [url.pathComponents[1] isEqualToString:@"maps"])) {
		/*
		 matches the regex from the docs:

		 (http(s?)://)?
		 ((maps\.google\.{TLD}/)|
		  ((www\.)?google\.{TLD}/maps/)|
		  (goo.gl/maps/))
		 .*
		*/

		return [NSURL URLWithString:[@"comgooglemapsurl:" stringByAppendingString:[url.absoluteString substringFromIndex:url.scheme.length]]];
	}

	return nil;
}

@end
