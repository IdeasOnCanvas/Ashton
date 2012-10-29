@interface MSASSUtils : NSObject

+ (void)diffDictionary:(NSDictionary *)prev to:(NSDictionary *)current created:(NSDictionary **)created removed:(NSDictionary **)removed;

@end
