#import <Foundation/Foundation.h>
#import <Foundation/Foundation.h>

@protocol AshtonConverter

- (NSAttributedString *)intermediateRepresentationWithTargetRepresentation:(NSAttributedString *)input;
- (NSAttributedString *)targetRepresentationWithIntermediateRepresentation:(NSAttributedString *)input;

@end
