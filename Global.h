// percent encoding macro. iOS 9 of course made this more interesting, finally
// adding an actual api for this, but we support way older than that here…
#define PERCENT_ENCODE(string) [string respondsToSelector:@selector(stringByAddingPercentEncodingWithAllowedCharacters:)] \
	? [(string) stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] \
	: [(NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)(string), NULL, CFSTR(":/=,!$& '()*+;[]@#?"), kCFStringEncodingUTF8) autorelease]

static NSString *const kHBMOHandlerIdentifier = @"MapsOpener";
