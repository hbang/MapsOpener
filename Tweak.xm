#import "Global.h"
#import <Opener/HBLibOpener.h>
#import <version.h>

@import CoreLocation;
@import MapKit;

NSString *HBMOMakeQuery(MKMapItem *mapItem) {
	if (mapItem.isCurrentLocation) {
		/*
		 if the saddr arg is empty, then google maps uses the current location
		*/

		return @"";
	}

	NSString *query = nil;

	if (mapItem.placemark.addressDictionary) {
		NSDictionary *info = mapItem.placemark.addressDictionary;
		query = PERCENT_ENCODE(([[NSString stringWithFormat:@"%@ %@ %@ %@ %@", info[@"Street"] ?: @"", info[@"City"] ?: @"", info[@"State"] ?: @"", info[@"ZIP"] ?: @"", info[@"CountryCode"] ?: @""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]));
	}

	if (!query || [query isEqualToString:@""]) {
		/*
		 if the address dictionary was empty or didn't contain the keys we need,
		 fall back to coordinates
		*/

		if (!mapItem.placemark.location) {
			return nil;
		}

		CLLocationCoordinate2D coord = mapItem.placemark.location.coordinate;
		return PERCENT_ENCODE(([NSString stringWithFormat:@"%f,%f", coord.latitude, coord.longitude]));
	}

	return query;
}

inline BOOL isEnabled() {
	return [[HBLibOpener sharedInstance] handlerIsEnabled:kHBMOHandlerIdentifier] && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]];
}

#pragma mark - MapKit hooks

%group MapKit
%hook MKMapItem

+ (NSURL *)urlForMapItems:(NSArray *)items options:(id)options {
	if (!isEnabled() || items.count < 1) {
		return %orig;
	} else if (items.count == 1) {
		return [NSURL URLWithString:[@"comgooglemaps://?q=" stringByAppendingString:HBMOMakeQuery(items[0])]];
	} else {
		return [NSURL URLWithString:[NSString stringWithFormat:@"comgooglemaps://?saddr=%@&daddr=%@", HBMOMakeQuery(items[0]), HBMOMakeQuery(items[1])]];
	}
}

%end
%end

#pragma mark - NSURL hooks

%hook NSURL

+ (NSURL *)mapsURLWithSourceAddress:(NSString *)source destinationAddress:(NSString *)destination {
	return isEnabled()
		? [NSURL URLWithString:[NSString stringWithFormat:@"comgooglemaps://?saddr=%@&daddr=%@", PERCENT_ENCODE(source), PERCENT_ENCODE(destination)]]
		: %orig;
}

%group PreCue
+ (NSURL *)mapsURLWithAddress:(NSString *)address {
	return isEnabled()
		? [NSURL URLWithString:[@"comgooglemaps://?q=" stringByAppendingString:PERCENT_ENCODE(address)]]
		: %orig;
}
%end

+ (NSURL *)mapsURLWithQuery:(NSString *)query {
	return isEnabled()
		? [NSURL URLWithString:[@"comgooglemaps://?q=" stringByAppendingString:PERCENT_ENCODE(query)]]
		: %orig;
}

%end

#pragma mark - Init function

/*
 to shut up a logos error which complains when there's multiple %inits for
 the same thing
*/

inline void initMapKitHooks() {
	%init(MapKit);
}

%group MapKitLateLoad

// really, this should not be a hook on -[NSBundle load]. but, for reasons i
// still don’t understand, in some apps listening for the notification causes
// the app to freeze…

%hook NSBundle

- (BOOL)load {
	if (!%orig) {
		return NO;
	}

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

	/*
	 if MapKit is loaded into this process, we want to initialise our MapKit
	 hooks. if not, we need to listen for a bundle load notification in case of
	 the chance that the app late loads it
	*/

	if ([NSBundle bundleWithIdentifier:@"com.apple.MapKit"].isLoaded) {
		initMapKitHooks();
	} else if (IS_IOS_OR_NEWER(iOS_7_0)) {
		%init(MapKitLateLoad);
	}
}
