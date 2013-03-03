/**
 * MapsOpener - open Google Maps links in the new app
 *
 * By HASHBANG Productions <http://hbang.ws>
 * Licensed under the GPL license <http://www.gnu.org/copyleft/gpl.html>
 *
 * The comgooglemaps:// URL scheme is documented on Google Developers:
 * <https://developers.google.com/maps/documentation/ios/urlscheme>
 */

#import "HBLibOpener.h"
#import <version.h>
#import <MapKit/MKMapItem.h>

#define PERCENT_ENCODE(string) [(NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)(string), NULL, CFSTR(":/=,!$& '()*+;[]@#?"), kCFStringEncodingUTF8) autorelease]

%group HBMOiOS6
static NSString *HBMOMakeQuery(MKMapItem *mapItem) {
	if (mapItem.isCurrentLocation) {
		return @"";
	} else {
		NSDictionary *info = mapItem.placemark.addressDictionary;

		return [NSString stringWithFormat:@"%@%@%@%@%@",
			PERCENT_ENCODE([info objectForKey:@"Street"] ? [[info objectForKey:@"Street"] stringByAppendingString:@" "] : @""),
			PERCENT_ENCODE([info objectForKey:@"City"] ? [[info objectForKey:@"City"] stringByAppendingString:@" "] : @""),
			PERCENT_ENCODE([info objectForKey:@"State"] ? [[info objectForKey:@"State"] stringByAppendingString:@" "] : @""),
			PERCENT_ENCODE([info objectForKey:@"ZIP"] ? [[info objectForKey:@"ZIP"] stringByAppendingString:@" "] : @""),
			PERCENT_ENCODE([info objectForKey:@"CountryCode"] ?: @"")
		];
	}
}

%hook MKMapItem
+(NSURL *)urlForMapItems:(NSArray *)items options:(id)options {
	if (items.count < 1) {
		return %orig;
	} else if (items.count == 1) {
		return [NSURL URLWithString:[@"comgooglemaps://?q=" stringByAppendingString:HBMOMakeQuery([items objectAtIndex:0])]];
	} else {
		return [NSURL URLWithString:[NSString stringWithFormat:@"comgooglemaps://?saddr=%@&daddr=%@", HBMOMakeQuery([items objectAtIndex:0]), HBMOMakeQuery([items objectAtIndex:1])]];
	}
}
%end
%end

%ctor {
	if (IS_IOS_OR_NEWER(iOS_6_0)) {
		%init(HBMOiOS6);
	}

	if (![[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
		return;
	}

	[[HBLibOpener sharedInstance] registerHandlerWithName:@"MapsOpener" block:^(NSURL *url) {
		if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlemaps://"]]) {
			return (id)nil;
		} else if ([url.scheme isEqualToString:@"maps"]) {
			return [NSURL URLWithString:[@"comgooglemaps://?" stringByAppendingString:[[url.absoluteString stringByReplacingOccurrencesOfString:@"maps:address=" withString:@"maps:q="] stringByReplacingOccurrencesOfString:@"maps:" withString:@""]]];
		} else if ([url.host hasPrefix:@"maps.google.co"] && [url.path isEqualToString:@"/maps"]) {
			return [NSURL URLWithString:[@"comgooglemaps://?" stringByAppendingString:url.query]];
		}

		return (id)nil;
	}];
}
