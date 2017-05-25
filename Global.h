// url query percent encoding macro. iOS 9 of course made this more interesting, finally adding a
// decent api for this, but we support way older than that here
#define URL_QUERY_ENCODE(string) ([NSString instancesRespondToSelector:@selector(stringByAddingPercentEncodingWithAllowedCharacters:)] \
	? [(string) stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]] \
	: (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)(string), NULL, CFSTR(":/=,!$& '()*+;[]@#?"), kCFStringEncodingUTF8)))

static NSString *const kHBMOHandlerIdentifier = @"MapsOpener";

extern NSString *queryStringFromDictionary(NSDictionary <NSString *, NSString *> *dictionary);
