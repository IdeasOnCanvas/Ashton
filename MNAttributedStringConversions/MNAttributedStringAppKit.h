#import "MNAttributedStringConverter.h"

@interface MNAttributedStringAppKit : NSObject < MNAttributedStringConverter >

+ (instancetype)sharedInstance;

- (NSAttributedString *)intermediateRepresentationWithTargetRepresentation:(NSAttributedString *)input;
- (NSAttributedString *)targetRepresentationWithIntermediateRepresentation:(NSAttributedString *)input;

@end
