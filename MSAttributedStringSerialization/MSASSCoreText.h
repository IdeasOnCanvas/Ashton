#import "MSASSTransformer.h"

@interface MSASSCoreText : NSObject < MSASSTransformer >

+ (instancetype)shared;

- (NSAttributedString *)intermediateRepresentationWithTargetRepresentation:(NSAttributedString *)input;
- (NSAttributedString *)targetRepresentationWithIntermediateRepresentation:(NSAttributedString *)input;

@end
