#import "AshtonConverter.h"

@interface AshtonCoreText : NSObject < AshtonConverter >

+ (instancetype)sharedInstance;

- (NSAttributedString *)intermediateRepresentationWithTargetRepresentation:(NSAttributedString *)input;
- (NSAttributedString *)targetRepresentationWithIntermediateRepresentation:(NSAttributedString *)input;

@end
