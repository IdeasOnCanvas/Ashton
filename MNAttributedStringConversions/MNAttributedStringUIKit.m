#import "MNAttributedStringUIKit.h"

@implementation MNAttributedStringUIKit

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static MNAttributedStringUIKit *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MNAttributedStringUIKit alloc] init];
    });
    return sharedInstance;
}

- (NSAttributedString *)intermediateRepresentationWithTargetRepresentation:(NSAttributedString *)input {
    return [[NSAttributedString alloc] init];
}

- (NSAttributedString *)targetRepresentationWithIntermediateRepresentation:(NSAttributedString *)input {
    return [[NSAttributedString alloc] init];
}

@end
