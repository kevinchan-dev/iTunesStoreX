#pragma once
#import <Foundation/Foundation.h>

// Authentication URL correction identified by Pod in NewerStoreLoginFix:
// https://github.com/Epixx512/NewerStoreLoginFix
// Keep the slash in the path, before any query or fragment.
static NSURL *ITXAuthenticationURL(NSURL *url) {
    if (url == nil) return nil;
    NSURLComponents *parts = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    NSString *host = url.host.lowercaseString;
    BOOL appleHost = [host isEqualToString:@"itunes.apple.com"] ||
        [host hasSuffix:@".itunes.apple.com"];
    if (!appleHost || ![parts.percentEncodedPath isEqualToString:@"/WebObjects/MZFinance.woa/wa/authenticate"]) {
        return url;
    }
    parts.percentEncodedPath = [parts.percentEncodedPath stringByAppendingString:@"/"];
    NSLog(@"[iTunesStoreX] corrected authentication URL path");
    return parts.URL ?: url;
}

static NSURL *ITXStoreURL(NSURL *url) {
    NSString *host = url.host.lowercaseString;
    BOOL legacyHost = [host isEqualToString:@"ax.init.itunes.apple.com"] ||
        [host isEqualToString:@"phobos.apple.com"];
    BOOL bagPath = [url.path isEqualToString:@"/bag.xml"] ||
        [url.path hasPrefix:@"/WebObjects/MZInit.woa/"];
    if (legacyHost && bagPath) {
        NSURLComponents *parts = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        parts.host = @"init.itunes.apple.com";
        NSLog(@"[iTunesStoreX] corrected legacy URL bag host");
        return parts.URL ?: url;
    }
    return ITXAuthenticationURL(url);
}

static id ITXBagValue(NSString *key, id value) {
    if (![key isEqualToString:@"authenticateAccount"]) return value;
    if ([value isKindOfClass:[NSURL class]]) return ITXAuthenticationURL(value);
    if ([value isKindOfClass:[NSString class]]) {
        NSURL *url = [NSURL URLWithString:value];
        NSURL *rewritten = ITXAuthenticationURL(url);
        return rewritten != url ? rewritten.absoluteString : value;
    }
    return value;
}

