#import "AshtonConverter.h"

@interface AshtonAppKit : NSObject < AshtonConverter >

+ (instancetype)sharedInstance;

- (NSAttributedString *)intermediateRepresentationWithTargetRepresentation:(NSAttributedString *)input;
- (NSAttributedString *)targetRepresentationWithIntermediateRepresentation:(NSAttributedString *)input;

@end
