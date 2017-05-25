@import CoreLocation;
@import MapKit;
#import <Opener/HBLibOpener.h>
#import <version.h>

// i can’t work out why i have to do this. it’s in the damn public header
@interface MKPlacemark ()

- (CLLocation *)location;

@end

#pragma mark - Helpers

static inline BOOL isEnabled() {
	// we’re enabled if opener says we are, and google maps is installed
	return [[HBLibOpener sharedInstance] handlerIsEnabled:kHBMOHandlerIdentifier] && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]];
}

static inline NSURL *gmapsURLWithQuery(NSDictionary <NSString *, NSString *> *query) {
	return [NSURL URLWithString:[@"comgooglemaps://?" stringByAppendingString:queryStringFromDictionary(query)]];
}

#pragma mark - MapKit hooks

static NSString *queryFromMapItem(MKMapItem *mapItem) {
	if (mapItem.isCurrentLocation) {
		// if the saddr or daddr arg is empty, then google maps uses the current location
		return @"";
	}

	NSString *query = nil;

	// if we have an address dictionary, then we use that
	if (mapItem.placemark.addressDictionary) {
		// construct the query string using as much info as we have, and then trim any extraneous spaces
		NSDictionary *info = mapItem.placemark.addressDictionary;
		query = [[NSString stringWithFormat:@"%@ %@ %@ %@ %@", info[@"Street"] ?: @"", info[@"City"] ?: @"", info[@"State"] ?: @"", info[@"ZIP"] ?: @"", info[@"CountryCode"] ?: @""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	}

	// if the address dictionary was empty or didn't contain the keys we need, fall back to using the
	// coordinates
	if (!query || [query isEqualToString:@""]) {
		if (!mapItem.placemark.location) {
			return nil;
		}

		CLLocationCoordinate2D coord = mapItem.placemark.location.coordinate;
		return [NSString stringWithFormat:@"%.6f,%.6f", coord.latitude, coord.longitude];
	}

	return query;
}

%group MapKit
%hook MKMapItem

+ (NSURL *)urlForMapItems:(NSArray *)items options:(id)options {
	// if we’re disabled or there aren’t any items, just call the original implementation. if there is
	// one item, use it as a search query. if there are two (or more), use item 0 as the source
	// address and item 1 as the destination address
	if (!isEnabled() || items.count == 0) {
		return %orig;
	} else if (items.count == 1) {
		return gmapsURLWithQuery(@{
			@"q": queryFromMapItem(items[0])
		});
	} else {
		return gmapsURLWithQuery(@{
			@"saddr": queryFromMapItem(items[0]),
			@"daddr": queryFromMapItem(items[1])
		});
	}
}

%end
%end

#pragma mark - NSURL hooks

%hook NSURL

+ (NSURL *)mapsURLWithSourceAddress:(NSString *)source destinationAddress:(NSString *)destination {
	return isEnabled()
		? gmapsURLWithQuery(@{
				@"saddr": source,
				@"daddr": destination
			})
		: %orig;
}

%group PreCue
+ (NSURL *)mapsURLWithAddress:(NSString *)address {
	return isEnabled()
		? gmapsURLWithQuery(@{
				@"q": address
			})
		: %orig;
}
%end

+ (NSURL *)mapsURLWithQuery:(NSString *)query {
	return isEnabled()
		? gmapsURLWithQuery(@{
				@"q": query
			})
		: %orig;
}

%end

#pragma mark - Init function

// to shut up a logos error which complains when there’s multiple %inits for the same thing
static inline void initMapKitHooks() {
	%init(MapKit);
}

%group MapKitLateLoad

// really, this should not be a hook on -[NSBundle load]. but, for reasons i still don’t understand,
// in some apps listening for the notification causes the app to freeze…

%hook NSBundle

- (BOOL)load {
	// load the bundle. if it failed, just return NO and do nothing else
	if (!%orig) {
		return NO;
	}

	// if this is MapKit, hook it!
	if ([self.bundleIdentifier isEqualToString:@"com.apple.MapKit"]) {
		initMapKitHooks();
	}

	return YES;
}

%end
%end

#pragma mark - Constructor

%ctor {
	%init;

	// one method was removed in iOS 9
	if (!IS_IOS_OR_NEWER(iOS_9_0)) {
		%init(PreCue);
	}

	// if MapKit is loaded into this process, we want to initialise our MapKit hooks. if not, we need
	// to listen for a bundle load notification in case of the chance that the app late loads it. we
	// only support this on iOS 7+
	if ([NSBundle bundleWithIdentifier:@"com.apple.MapKit"].isLoaded) {
		initMapKitHooks();
	} else if (IS_IOS_OR_NEWER(iOS_7_0)) {
		%init(MapKitLateLoad);
	}
}
