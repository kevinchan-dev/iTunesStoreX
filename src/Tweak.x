#import "StoreURLs.h"
#import "CustomURLProtocol.h"

%hook ISURLOperation
- (BOOL)_runRequestWithURL:(NSURL *)url dataConnectionServiceType:(CFStringRef)serviceType {
    return %orig(ITXStoreURL(url), serviceType);
}
%end

%hook ISURLBag
- (id)valueForKey:(NSString *)key {
    return ITXBagValue(key, %orig);
}
- (NSURL *)urlForKey:(NSString *)key {
    return ITXBagValue(key, %orig);
}
%end

%ctor {
    %init;
    // Exclude the expired bag certificate and unconditional signature bypass.
    [NSURLProtocol registerClass:[CustomURLProtocol class]];
    NSLog(@"[iTunesStoreX] iOS 8 compatibility loaded in %@", [[NSProcessInfo processInfo] processName]);
}
