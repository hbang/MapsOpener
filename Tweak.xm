#import "Global.h"
#import <libopener/HBLibOpener.h>
#import <MapKit/MKMapItem.h>
#import <MapKit/MKPlacemark.h>

NSString *HBMOMakeQuery(MKMapItem *mapItem) {
    if (mapItem.isCurrentLocation) {
        return @"";
    } else {
        NSDictionary *info = mapItem.placemark.addressDictionary;

        return [NSString stringWithFormat:@"%@%@%@%@%@",
            PERCENT_ENCODE(info[@"Street"] ? [info[@"Street"] stringByAppendingString:@" "] : @""),
            PERCENT_ENCODE(info[@"City"] ? [info[@"City"] stringByAppendingString:@" "] : @""),
            PERCENT_ENCODE(info[@"State"] ? [info[@"State"] stringByAppendingString:@" "] : @""),
            PERCENT_ENCODE(info[@"ZIP"] ? [info[@"ZIP"] stringByAppendingString:@" "] : @""),
            PERCENT_ENCODE(info[@"CountryCode"] ?: @"")
        ];
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
