#import "AshtonUIKit.h"

@implementation AshtonUIKit

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static AshtonUIKit *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AshtonUIKit alloc] init];
    });
    return sharedInstance;
}

- (NSAttributedString *)intermediateRepresentationWithTargetRepresentation:(NSAttributedString *)input {
    return nil;
}

- (NSAttributedString *)targetRepresentationWithIntermediateRepresentation:(NSAttributedString *)input {
    return nil;
}

@end
