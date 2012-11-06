#import "AshtonTransformer.h"

@interface AshtonCoreText : NSObject < AshtonTransformer >

+ (instancetype)shared;

- (NSAttributedString *)intermediateRepresentationWithTargetRepresentation:(NSAttributedString *)input;
- (NSAttributedString *)targetRepresentationWithIntermediateRepresentation:(NSAttributedString *)input;

@end
