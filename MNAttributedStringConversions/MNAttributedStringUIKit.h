#import "MNAttributedStringConverter.h"

@interface MNAttributedStringUIKit : NSObject < MNAttributedStringConverter >

+ (instancetype)shared;

- (NSAttributedString *)intermediateRepresentationWithTargetRepresentation:(NSAttributedString *)input;
- (NSAttributedString *)targetRepresentationWithIntermediateRepresentation:(NSAttributedString *)input;

@end
