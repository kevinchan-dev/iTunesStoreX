#import <Foundation/Foundation.h>
#import <asl.h>
#include <time.h>

int main(void) {
    @autoreleasepool {
        for (NSString *sender in @[@"AppStore", @"itunesstored", @"Preferences", @"accountsd", @"storeaccountd"]) {
            aslmsg query = asl_new(ASL_TYPE_QUERY);
            char since[32]; snprintf(since, sizeof(since), "%ld", (long)time(NULL)-1800);
            asl_set_query(query, ASL_KEY_TIME, since, ASL_QUERY_OP_GREATER_EQUAL|ASL_QUERY_OP_NUMERIC);
            asl_set_query(query, ASL_KEY_SENDER, sender.UTF8String, ASL_QUERY_OP_EQUAL);
            aslresponse results = asl_search(NULL, query);
            aslmsg message; unsigned count = 0;
            NSRegularExpression *errors = [NSRegularExpression regularExpressionWithPattern:@"(?:Error Domain=|error domain: ?)([A-Za-z0-9_.-]+)(?: Code=| code: ?)(-?[0-9]+)" options:NSRegularExpressionCaseInsensitive error:NULL];
            NSRegularExpression *urls = [NSRegularExpression regularExpressionWithPattern:@"https?://[^\\s<>\\\"']+" options:0 error:NULL];
            while (results && (message = asl_next(results))) {
                const char *raw = asl_get(message, ASL_KEY_MSG);
                if (!raw) continue;
                NSString *msg = [NSString stringWithUTF8String:raw];
                NSMutableArray *facts = [NSMutableArray array];
                if ([msg hasPrefix:@"[iTunesStoreX]"]) [facts addObject:msg];
                for (NSTextCheckingResult *match in [errors matchesInString:msg options:0 range:NSMakeRange(0,msg.length)])
                    [facts addObject:[NSString stringWithFormat:@"error=%@/%@", [msg substringWithRange:[match rangeAtIndex:1]], [msg substringWithRange:[match rangeAtIndex:2]]]];
                for (NSString *marker in @[@"SSL", @"certificate", @"signature", @"URL bag", @"URLBag", @"authenticate", @"Cannot connect", @"timed out", @"connection failed", @"unsupported", @"HTTP status", @"503", @"403", @"404"]) {
                    if ([msg rangeOfString:marker options:NSCaseInsensitiveSearch].location != NSNotFound) [facts addObject:[@"marker=" stringByAppendingString:marker]];
                }
                if (facts.count) {
                    for (NSTextCheckingResult *match in [urls matchesInString:msg options:0 range:NSMakeRange(0,msg.length)]) {
                        NSURL *url = [NSURL URLWithString:[msg substringWithRange:match.range]];
                        if (url.host) [facts addObject:[@"host=" stringByAppendingString:url.host]];
                    }
                    printf("%s %s %s\n", asl_get(message, ASL_KEY_TIME) ?: "?", sender.UTF8String, [facts componentsJoinedByString:@" "].UTF8String);
                    ++count;
                }
            }
            printf("MATCHES %s %u\n", sender.UTF8String, count);
            if (results) asl_release(results);
            asl_free(query);
        }
    }
    return 0;
}
