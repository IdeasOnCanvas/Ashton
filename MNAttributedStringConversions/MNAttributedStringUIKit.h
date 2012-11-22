#import "MNAttributedStringConverter.h"

@interface MNAttributedStringUIKit : NSObject < MNAttributedStringConverter >

+ (instancetype)sharedInstance;

- (NSAttributedString *)intermediateRepresentationWithTargetRepresentation:(NSAttributedString *)input;
- (NSAttributedString *)targetRepresentationWithIntermediateRepresentation:(NSAttributedString *)input;

@end
