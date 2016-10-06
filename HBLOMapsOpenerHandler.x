@import MapKit;
#import "Global.h"
#import "HBLOMapsOpenerHandler.h"
#import <MobileCoreServices/LSApplicationWorkspace.h>
#import <UIKit/NSString+UIKitAdditions.h>
#import <MapKit/MKMapItem+Private.h>
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
	if ([url.scheme isEqualToString:@"maps"]) {
		// grab the query string from a url of format maps:address=blah. with
		// iOS 9, ContactsUI now uses maps:?address=blah, for whatever reason
		NSString *queryString = [url.absoluteString substringFromIndex:5];

		if ([queryString hasPrefix:@"?"]) {
			queryString = [queryString substringFromIndex:1];
		}

		NSDictionary *query = queryString.queryKeysAndValues;

		if (query[@"ios_addr"]) {
			return [NSURL URLWithString:[@"comgooglemaps://?q=" stringByAppendingString:PERCENT_ENCODE(query[@"ios_addr"])]];
		} else if (query[@"address"]) {
			return [NSURL URLWithString:[@"comgooglemaps://?q=" stringByAppendingString:PERCENT_ENCODE(query[@"address"])]];
		} else if (query[@"q"]) {
			return [NSURL URLWithString:[@"comgooglemaps://?q=" stringByAppendingString:PERCENT_ENCODE(query[@"q"])]];
		} else if (query[@"ll"]) {
			return [NSURL URLWithString:[@"comgooglemaps://?q=" stringByAppendingString:PERCENT_ENCODE(query[@"ll"])]];
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
	} else if (
		([url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"]) && // scheme is https?:, and
		([url.host hasPrefix:@"maps.google."] || // host is maps.google.TLD, or
			(
				([url.host hasPrefix:@"google."] || [url.host hasPrefix:@"www.google."] || [url.host isEqualToString:@"goo.gl"]) // google.TLD or goo.gl, and
				&& url.pathComponents.count > 2 && [url.pathComponents[1] isEqualToString:@"maps"] // we have >2 path components; the first is "maps"
			)
		)) {
		/*
		 matches the regex from the docs:

		 (http(s?)://)?
		 ((maps\.google\.{TLD}/)|
		  ((www\.)?google\.{TLD}/maps/)|
		  (goo.gl/maps/))
		 .*
		*/

		if ([[LSApplicationWorkspace defaultWorkspace] applicationsAvailableForHandlingURLScheme:@"comgooglemapsurl"].count > 0) {
			return [NSURL URLWithString:[@"comgooglemapsurl" stringByAppendingString:[url.absoluteString substringFromIndex:url.scheme.length]]];
		} else {
			/*
			 fall back to the undocumented comgooglemaps://?mapsurl=, because
			 gmaps dropped support for iOS 6 long before comgooglemapsurl://
			 was introduced
			*/

			return [NSURL URLWithString:[@"comgooglemaps://?mapsurl=" stringByAppendingString:PERCENT_ENCODE(url.absoluteString)]];
		}
	}

	return nil;
}

@end
