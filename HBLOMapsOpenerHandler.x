@import MapKit;
#import "Global.h"
#import "HBLOMapsOpenerHandler.h"
#import <MobileCoreServices/LSApplicationWorkspace.h>
#import <MobileCoreServices/NSURL+LSAdditions.h>
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
	// the mapsURL method will translate a maps.apple.com url into a maps: uri, or return nil
	url = url.mapsURL ?: url;

	// maps: the simplest of all, used most of the time when the address is only
	// known as a string. less commonly used these days but still used for
	// auto detected links in text/web views
	//
	// mapitem://, x-maps-mapitemhandles://: used when there is already an
	// MKMapItem, and it is serialised into a URL to be viewed in the maps app
	//
	// google urls: we try to pick up when the google maps site is being opened,
	// so we can direct to the app instead
	if ([url.scheme isEqualToString:@"maps"]) {
		// grab the query string from a url of format maps:address=blah. with
		// iOS 9, ContactsUI now uses maps:?address=blah, for whatever reason
		NSString *queryString = [url.absoluteString substringFromIndex:5];

		if ([queryString hasPrefix:@"?"]) {
			queryString = [queryString substringFromIndex:1];
		}

		NSDictionary *query = queryString.queryKeysAndValues;

		// ios_addr, address: used in iOS 6 calendar/contacts/etc when the query is
		// almost definitely an address
		// q: still used in some places on iOS 6, and probably various apps/sites
		// ll: longitude,latitude
		// saddr, daddr: start and destination addresses
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
		// load our hooks dylib for this to work
		dlopen("/Library/MobileSubstrate/DynamicLibraries/MapsOpenerHooks.dylib", RTLD_LAZY);

		// turn the url back into an array of MKMapItems, then back to a url, so
		// our hook on urlForMapItems:options: is executed
		NSArray <MKMapItem *> *items = [MKMapItem mapItemsFromURL:url options:nil];
		NSURL *url = [MKMapItem urlForMapItems:items options:nil];

		// if, for some reason, we failed, don't use the new url which may have
		// missing data
		return [url.host isEqualToString:@"mapitem"] ? nil : url;
	} else if ([url.scheme isEqualToString:@"x-maps-mapitemhandles"]) {
		// load our hooks dylib for this to work
		dlopen("/Library/MobileSubstrate/DynamicLibraries/MapsOpenerHooks.dylib", RTLD_LAZY);

		// i’m convinced apple added this because they hate me. we do basically the
		// same thing as mapitem://, because this type of url serves the exact same
		// purpose, but now the api is async! what joy
		// make a semaphore so we can do the fun task of hanging the main thread
		dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
		__block NSURL *newURL = nil;

		[MKMapItem _mapItemsFromHandleURL:url completionHandler:^(NSArray <MKMapItem *> *items) {
			// i kinda really don’t care, just use the old method
			newURL = [MKMapItem urlForMapItems:items options:nil];

			// signal that we’re done
			dispatch_semaphore_signal(semaphore);
		}];

		// wait for the semaphore, with a 1 sec timeout
		dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC));

		// do the same return thing as above
		return url && [url.host isEqualToString:@"mapitem"] ? nil : url;
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
			// fall back to the undocumented comgooglemaps://?mapsurl=, because
			// gmaps dropped support for iOS 6 long before comgooglemapsurl://
			// was introduced
			return [NSURL URLWithString:[@"comgooglemaps://?mapsurl=" stringByAppendingString:PERCENT_ENCODE(url.absoluteString)]];
		}
	}

	return nil;
}

@end
