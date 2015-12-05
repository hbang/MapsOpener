@import org.cycript.NSLog;

function assert_equal(a, b) {
	if (![a isEqual:b]) {
		NSLog("FAIL: " + a + " !== " + b);
	}
}

function assert_not_equal(a, b) {
	if ([a isEqual:b]) {
		NSLog("FAIL: " + a + " === " + b);
	}
}

function assert_null(a) {
	if (typeof a !== "undefined" && a !== null) {
		NSLog("FAIL: " + a + " !== nil");
	}
}

function assert_not_null(a) {
	if (typeof a === "undefined" || a === null) {
		NSLog("FAIL: " + a + " === nil");
	}
}

assert_equal([[NSBundle bundleWithPath:"/System/Library/Frameworks/UIKit.framework"] load], true);
assert_equal([[NSBundle bundleWithPath:"/Library/Frameworks/Opener.framework"] load], true);
assert_equal([[NSBundle bundleWithPath:"/Library/Opener/MapsOpener.bundle"] load], true);
assert_not_equal(dlopen("/Library/MobileSubstrate/DynamicLibraries/MapsOpenerHooks.dylib", RTLD_LAZY), null);

var handler = [[HBLOMapsOpenerHandler alloc] init];

// handler class should exist and be able to instantiate
assert_not_null(handler);

// test that the NSURL+UIKitAdditions
assert_equal([NSURL mapsURLWithQuery:"1 Infinite Loop, Cupertino CA 95014"].absoluteString, "comgooglemaps://?q=1%20Infinite%20Loop%2C%20Cupertino%20CA%2095014");
assert_equal([NSURL mapsURLWithSourceAddress:"1 Infinite Loop, Cupertino CA 95014" destinationAddress:"742 Evergreen Terrace, Springfield"].absoluteString, "comgooglemaps://?saddr=1%20Infinite%20Loop%2C%20Cupertino%20CA%2095014&daddr=742%20Evergreen%20Terrace%2C%20Springfield");

// this is a random unrelated maps url that should be ignored
assert_null([handler openURL:[NSURL URLWithString:"https://www.google.com.au/maps?source=tldsi&hl=en"] sender:nil]);

// maps: urls – these should become comgooglemaps://
assert_equal([handler openURL:[NSURL URLWithString:"maps:address=123%20Fake%20Street%2C%20Faketown%20SA%205108"] sender:nil].absoluteString, "comgooglemaps://?q=123%20Fake%20Street%2C%20Faketown%20SA%205108");
assert_equal([handler openURL:[NSURL URLWithString:"maps:?address=123%20Fake%20Street%2C%20Faketown%20SA%205108"] sender:nil].absoluteString, "comgooglemaps://?q=123%20Fake%20Street%2C%20Faketown%20SA%205108");
assert_equal([handler openURL:[NSURL URLWithString:"maps:saddr=123%20Fake%20Street%2C%20Faketown%20SA%205108&daddr=742%20Evergreen%20Terrace%2C%20Springfield"] sender:nil].absoluteString, "comgooglemaps://?saddr=123%20Fake%20Street%2C%20Faketown%20SA%205108&daddr=742%20Evergreen%20Terrace%2C%20Springfield");

// google maps urls – these should become comgooglemapsurl://
assert_equal([handler openURL:[NSURL URLWithString:"https://www.google.com.au/maps/@5.0990064,-162.1046249,3z?hl=en"] sender:nil].absoluteString, "comgooglemapsurl://www.google.com.au/maps/@5.0990064,-162.1046249,3z?hl=en");
assert_equal([handler openURL:[NSURL URLWithString:"https://google.com/maps/place/sdfsdf,+Woodstock,+CT+06281,+USA/@41.9459219,-71.9406471,17z/data=!3m1!4b1!4m2!3m1!1s0x89e42742eb2a583f:0xeee932d65eb62d50?hl=en"] sender:nil].absoluteString, "comgooglemapsurl://google.com/maps/place/sdfsdf,+Woodstock,+CT+06281,+USA/@41.9459219,-71.9406471,17z/data=!3m1!4b1!4m2!3m1!1s0x89e42742eb2a583f:0xeee932d65eb62d50?hl=en");
assert_equal([handler openURL:[NSURL URLWithString:"https://goo.gl/maps/PU7sBfeFHkC2"] sender:nil].absoluteString, "comgooglemapsurl://goo.gl/maps/PU7sBfeFHkC2");

// mapitem: urls
// too lazy, maybe i’ll do it some other time

// hooray (hopefully)
NSLog("END");
