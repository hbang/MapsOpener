static inline NSString *urlQueryEncode(NSString *string) {
	return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, NULL, CFSTR(":/=,!$& '()*+;[]@#?"), kCFStringEncodingUTF8));
}

NSString *queryStringFromDictionary(NSDictionary <NSString *, NSString *> *dictionary) {
	// NSURLComponents will do this in a more "right" way, but NSURLQueryItem was only introduced in
	// iOS 8. if we're on an older iOS version, fall back to manually constructing the query string
	if (%c(NSURLQueryItem)) {
		NSURLComponents *components = [[%c(NSURLComponents) alloc] init];
		NSMutableArray <NSURLQueryItem *> *queryItems = [NSMutableArray array];

		for (NSString *key in dictionary.allKeys) {
			[queryItems addObject:[%c(NSURLQueryItem) queryItemWithName:key value:dictionary[key]]];
		}

		components.queryItems = queryItems;
		return components.URL.query;
	} else {
		NSMutableArray <NSString *> *queryItems = [NSMutableArray array];

		for (NSString *key in dictionary.allKeys) {
			[queryItems addObject:[NSString stringWithFormat:@"%@=%@", urlQueryEncode(key), urlQueryEncode(dictionary[key])]];
		}

		return [queryItems componentsJoinedByString:@"&"];
	}
}
