/**
 * MapsOpener - open Google Maps links in the new app
 *
 * By Ad@m <http://hbang.ws>
 * Licensed under the GPL license <http://www.gnu.org/copyleft/gpl.html>
 */

#import "HBLibOpener.h"

%ctor {
	[[HBLibOpener sharedInstance] registerHandlerWithName:@"MapsOpener" block:^(NSURL *url) {
		if (([url.scheme isEqualToString:@"maps"] || ([url.host hasPrefix:@"maps.google.co"] && [url.path isEqualToString:@"/maps"])) && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
			return [NSURL URLWithString:[@"comgooglemaps://search?" stringByAppendingString:[url.scheme isEqualToString:@"maps"] ? [[url.absoluteString stringByReplacingOccurrencesOfString:@"maps:address=" withString:@"maps:q="] stringByReplacingOccurrencesOfString:@"maps:" withString:@""] : url.query]];
		}
		return (id)nil;
	}];
}
