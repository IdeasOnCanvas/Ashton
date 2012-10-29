#import "MSASSUtils.h"

@implementation MSASSUtils

+ (void)diffDictionary:(NSDictionary *)prev to:(NSDictionary *)current created:(NSDictionary **)created removed:(NSDictionary **)removed {
    NSMutableDictionary *_removed = [NSMutableDictionary dictionary];
    NSMutableDictionary *_created = [NSMutableDictionary dictionary];

    NSMutableSet *keys = [NSMutableSet setWithArray:[prev allKeys]];
    [keys unionSet:[NSSet setWithArray:[current allKeys]]];

    for (id key in keys) {
        id previousVal = prev[key];
        id currentVal = current[key];
        if (![previousVal isEqual: currentVal]) {
            if (previousVal) _removed[key] = previousVal;
            if (currentVal) _created[key] = currentVal;
        }
    }

    *created = _created;
    *removed = _removed;
}

@end