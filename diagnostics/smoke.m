#import "../src/StoreURLs.h"
#import "../src/CustomURLProtocol.h"
#import <dlfcn.h>
#import <objc/runtime.h>
#include <assert.h>

int main(int argc, char **argv) {
    @autoreleasepool {
        NSArray *cases = @[
            @[@"https://p01-buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/authenticate", @"https://p01-buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/authenticate/"],
            @[@"https://p01-buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/authenticate?q=a%2Fb#fragment", @"https://p01-buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/authenticate/?q=a%2Fb#fragment"],
            @[@"https://p01-buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/authenticate/", @"https://p01-buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/authenticate/"],
            @[@"https://example.com/WebObjects/MZFinance.woa/wa/authenticate", @"https://example.com/WebObjects/MZFinance.woa/wa/authenticate"],
            @[@"https://fakeitunes.apple.com/WebObjects/MZFinance.woa/wa/authenticate", @"https://fakeitunes.apple.com/WebObjects/MZFinance.woa/wa/authenticate"],
            @[@"https://ax.init.itunes.apple.com/bag.xml?ix=4", @"https://init.itunes.apple.com/bag.xml?ix=4"],
            @[@"https://phobos.apple.com/WebObjects/MZInit.woa/wa/bag", @"https://init.itunes.apple.com/WebObjects/MZInit.woa/wa/bag"],
            @[@"https://phobos.apple.com/unrelated", @"https://phobos.apple.com/unrelated"]
        ];
        for (NSArray *pair in cases) {
            assert([ITXStoreURL([NSURL URLWithString:pair[0]]).absoluteString isEqual:pair[1]]);
        }
        assert(ITXStoreURL(nil) == nil);
        assert(ITXBagValue(@"authenticateAccount", nil) == nil);
        assert([ITXBagValue(@"other", cases[0][0]) isEqual:cases[0][0]]);
        assert([ITXBagValue(@"authenticateAccount", cases[0][0]) isEqual:cases[0][1]]);
        assert([ITXBagValue(@"authenticateAccount", [NSURL URLWithString:cases[0][0]]) isEqual:[NSURL URLWithString:cases[0][1]]]);
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://itunes.apple.com/htmlResources/dv6-storefront-p6bootstrap.js"]];
        assert([CustomURLProtocol canInitWithRequest:request]);
        [NSURLProtocol setProperty:@YES forKey:@"URLProtocolHandledKey" inRequest:request];
        assert(![CustomURLProtocol canInitWithRequest:request]);
        for (NSString *host in @[@"search.itunes.apple.com", @"example.com", @"fakeitunes.apple.com"]) {
            request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/dv6-storefront-p6bootstrap.js", host]]];
            assert(![CustomURLProtocol canInitWithRequest:request]);
        }
        puts("PASS: URL rewrites, query preservation, bag types, host scope, protocol loop guard");
        if (argc > 1) {
            assert(dlopen("/System/Library/PrivateFrameworks/iTunesStore.framework/iTunesStore", RTLD_NOW));
            Class cls = NSClassFromString(@"ISURLOperation");
            for (NSString *name in @[@"ISURLOperation", @"ISStoreURLOperation"]) {
                Class operation = NSClassFromString(name);
                unsigned count = 0;
                Method *methods = class_copyMethodList(operation, &count);
                printf("CLASS %s present=%d\n", name.UTF8String, operation != Nil);
                for (unsigned i = 0; i < count; ++i) {
                    const char *selector = sel_getName(method_getName(methods[i]));
                    if (strstr(selector, "URL") || strstr(selector, "Request"))
                        printf("METHOD %s encoding=%s\n", selector, method_getTypeEncoding(methods[i]));
                }
                free(methods);
            }
            cls = NSClassFromString(@"ISURLBag");
            assert(class_getInstanceMethod(cls, sel_registerName("valueForKey:")));
            assert(class_getInstanceMethod(cls, sel_registerName("urlForKey:")));
            Method hooks[] = {
                class_getInstanceMethod(NSClassFromString(@"ISURLOperation"), sel_registerName("_runRequestWithURL:dataConnectionServiceType:")),
                class_getInstanceMethod(cls, sel_registerName("valueForKey:")),
                class_getInstanceMethod(cls, sel_registerName("urlForKey:"))
            };
            IMP before[3];
            for (unsigned i = 0; i < 3; ++i) { assert(hooks[i]); before[i] = method_getImplementation(hooks[i]); }
            void *handle = dlopen(argv[1], RTLD_NOW);
            if (!handle) { fprintf(stderr, "LOAD FAILED: %s\n", dlerror()); return 1; }
            for (unsigned i = 0; i < 3; ++i) assert(before[i] != method_getImplementation(hooks[i]));
            puts("PASS: device Store selectors, signed armv7 dylib loading, all three hooks installed");
        }
    }
    return 0;
}
