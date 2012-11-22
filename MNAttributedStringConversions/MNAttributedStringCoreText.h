#import "MNAttributedStringConverter.h"

@interface MNAttributedStringCoreText : NSObject < MNAttributedStringConverter >

+ (instancetype)sharedInstance;

- (NSAttributedString *)intermediateRepresentationWithTargetRepresentation:(NSAttributedString *)input;
- (NSAttributedString *)targetRepresentationWithIntermediateRepresentation:(NSAttributedString *)input;

@end
