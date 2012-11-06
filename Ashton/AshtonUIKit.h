#import "AshtonTransformer.h"

@interface AshtonUIKit : NSObject < AshtonTransformer >

+ (instancetype)shared;

- (NSAttributedString *)intermediateRepresentationWithTargetRepresentation:(NSAttributedString *)input;
- (NSAttributedString *)targetRepresentationWithIntermediateRepresentation:(NSAttributedString *)input;

@end
