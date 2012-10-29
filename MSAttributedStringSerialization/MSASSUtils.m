#import "MSASSUtils.h"

@implementation MSASSUtils

#if TARGET_OS_IPHONE
+ (BOOL)NSASHasUIKitAdditions {
    return ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options: NSNumericSearch] != NSOrderedAscending);
}
#endif

@end