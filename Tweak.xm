#import "Global.h"
#import <libopener/HBLibOpener.h>
#import <MapKit/MKMapItem.h>
#import <MapKit/MKPlacemark.h>

NSString *HBMOMakeQuery(MKMapItem *mapItem) {
	if (mapItem.isCurrentLocation) {
		return @"";
	} else {
		NSDictionary *info = mapItem.placemark.addressDictionary;
		return PERCENT_ENCODE(([[NSString stringWithFormat:@"%@ %@ %@ %@ %@", info[@"Street"] ?: @"", info[@"City"] ?: @"", info[@"State"] ?: @"", info[@"ZIP"] ?: @"", info[@"CountryCode"] ?: @""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]));
	}
}

#pragma mark - MapKit hooks

%group HBMOMapKit
%hook MKMapItem

+ (NSURL *)urlForMapItems:(NSArray *)items options:(id)options {
	if (![[HBLibOpener sharedInstance] handlerIsEnabled:kHBMOHandlerIdentifier] || items.count < 1 || ![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
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
	return [[HBLibOpener sharedInstance] handlerIsEnabled:kHBMOHandlerIdentifier]
		? [NSURL URLWithString:[NSString stringWithFormat:@"comgooglemaps://?saddr=%@&daddr=%@", PERCENT_ENCODE(source), PERCENT_ENCODE(destination)]]
		: %orig;
}

+ (NSURL *)mapsURLWithAddress:(NSString *)address {
	return [[HBLibOpener sharedInstance] handlerIsEnabled:kHBMOHandlerIdentifier]
		? [NSURL URLWithString:[@"comgooglemaps://?q=" stringByAppendingString:PERCENT_ENCODE(address)]]
		: %orig;
}

+ (NSURL *)mapsURLWithQuery:(NSString *)query {
	return [[HBLibOpener sharedInstance] handlerIsEnabled:kHBMOHandlerIdentifier]
		? [NSURL URLWithString:[@"comgooglemaps://?q=" stringByAppendingString:PERCENT_ENCODE(query)]]
		: %orig;
}

%end

#pragma mark - Constructor

%ctor {
	%init;

	if (%c(MKMapItem)) {
		%init(HBMOMapKit);
	}
}
