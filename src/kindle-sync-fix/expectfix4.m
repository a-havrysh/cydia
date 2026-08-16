#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#include <stdio.h>

static void logLine(NSString *s) {
    FILE *f = fopen("/tmp/expectfix4.log", "a");
    if (f) { fputs([[s stringByAppendingString:@"\n"] UTF8String], f); fclose(f); }
}

static IMP orig_setValue;

static void fixed_setValue(id self, SEL _cmd, NSString *value, NSString *field) {
    if ([field caseInsensitiveCompare:@"Expect"] == NSOrderedSame) {
        logLine([NSString stringWithFormat:@"setValue:forHTTPHeaderField: Expect = '%@'", value]);
        if (value == nil || [value length] == 0) {
            logLine(@"  -> dropping empty Expect header");
            return;
        }
    }
    ((void (*)(id, SEL, NSString *, NSString *))orig_setValue)(self, _cmd, value, field);
}

__attribute__((constructor))
static void expectfix4_init(void) {
    logLine(@"expectfix4 loaded");
    Class cls = objc_getClass("NSMutableURLRequest");
    Method m = class_getInstanceMethod(cls, @selector(setValue:forHTTPHeaderField:));
    if (m) {
        orig_setValue = method_getImplementation(m);
        method_setImplementation(m, (IMP)fixed_setValue);
        logLine(@"swizzled setValue:forHTTPHeaderField: on NSMutableURLRequest");
    } else {
        logLine(@"method not found");
    }
}
