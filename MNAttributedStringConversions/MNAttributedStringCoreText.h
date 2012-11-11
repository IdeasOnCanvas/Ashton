#import "MNAttributedStringConverter.h"

@interface MNAttributedStringCoreText : NSObject < MNAttributedStringConverter >

+ (instancetype)shared;

- (NSAttributedString *)intermediateRepresentationWithTargetRepresentation:(NSAttributedString *)input;
- (NSAttributedString *)targetRepresentationWithIntermediateRepresentation:(NSAttributedString *)input;

@end
