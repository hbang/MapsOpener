/**
 * MapsOpener - open Google Maps links in the new app
 *
 * By Ad@m <http://hbang.ws>
 * Licensed under the GPL license <http://www.gnu.org/copyleft/gpl.html>
 */

%hook SpringBoard
-(void)_openURLCore:(NSURL *)url display:(id)display publicURLsOnly:(BOOL)publicOnly animating:(BOOL)animated additionalActivationFlag:(unsigned int)flags {
	if (([url.scheme isEqualToString:@"maps"] || ([url.host hasPrefix:@"maps.google.co"] && [url.path isEqualToString:@"/maps"])) && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"comgooglemaps://search?" stringByAppendingString:[url.scheme isEqualToString:@"maps"] ? [url.absoluteString stringByReplacingOccurrencesOfString:@"maps:" withString:@""] : url.query]]];
	} else {
		%orig;
	}
}
-(void)_openURLCore:(NSURL *)url display:(id)display animating:(BOOL)animating sender:(id)sender additionalActivationFlags:(id)activationFlags {
	if (([url.scheme isEqualToString:@"maps"] || ([url.host hasPrefix:@"maps.google.co"] && [url.path isEqualToString:@"/maps"])) && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"comgooglemaps://search?" stringByAppendingString:[url.scheme isEqualToString:@"maps"] ? [url.absoluteString stringByReplacingOccurrencesOfString:@"maps:" withString:@""] : url.query]]];
	} else {
		%orig;
	}
}
%end
