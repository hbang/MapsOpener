#import "Global.h"
#import <libopener/HBLibOpener.h>
#import <MapKit/MKMapItem.h>
#import <MapKit/MKPlacemark.h>

NSString *HBMOMakeQuery(MKMapItem *mapItem) {
    if (mapItem.isCurrentLocation) {
        return @"";
    } else {
        NSDictionary *info = mapItem.placemark.addressDictionary;

        return PERCENT_ENCODE([NSString stringWithFormat:@"%@%@%@%@%@",
            info[@"Street"] ? [info[@"Street"] stringByAppendingString:@" "] : @"",
            info[@"City"] ? [info[@"City"] stringByAppendingString:@" "] : @"",
            info[@"State"] ? [info[@"State"] stringByAppendingString:@" "] : @"",
            info[@"ZIP"] ? [info[@"ZIP"] stringByAppendingString:@" "] : @"",
            info[@"CountryCode"] ?: @""
        ]);
    }
}

%group HBMOMapKit
%hook MKMapItem

+ (NSURL *)urlForMapItems:(NSArray *)items options:(id)options {
	if (![[HBLibOpener sharedInstance] handlerIsEnabled:@"MapsOpener"] || items.count < 1 || ![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
		return %orig;
	} else if (items.count == 1) {
		return [NSURL URLWithString:[@"comgooglemaps://?q=" stringByAppendingString:HBMOMakeQuery(items[0])]];
	} else {
		return [NSURL URLWithString:[NSString stringWithFormat:@"comgooglemaps://?saddr=%@&daddr=%@", HBMOMakeQuery(items[0]), HBMOMakeQuery(items[1])]];
	}
}

%end
%end

%ctor {
	if (%c(MKMapItem)) {
		%init(HBMOMapKit);
	}
}
