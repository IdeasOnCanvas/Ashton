#import "NSAttributedString+Ashton.h"
#import "AshtonCoreText.h"
#import "AshtonHTMLWriter.h"
#import "AshtonHTMLReader.h"
#if TARGET_OS_IPHONE
#import "AshtonUIKit.h"
#else
#import "AshtonAppKit.h"
#endif

@implementation NSAttributedString (Ashton)

- (NSString *)mn_HTMLRepresentation
{
#if TARGET_OS_IPHONE
	NSAttributedString *attString = [[[AshtonUIKit alloc] init] intermediateRepresentationWithTargetRepresentation:self];
#else
	NSAttributedString *attString = [[AshtonAppKit alloc] init] intermediateRepresentationWithTargetRepresentation:self];
#endif
	return [[[AshtonHTMLWriter alloc] init] HTMLStringFromAttributedString:attString];
}

- (instancetype)initWithHTMLString:(NSString *)htmlString
{
    NSAttributedString *attributedString = [[[AshtonHTMLReader alloc] init] attributedStringFromHTMLString:htmlString];
#if TARGET_OS_IPHONE
	attributedString = [[[AshtonUIKit alloc] init] targetRepresentationWithIntermediateRepresentation:attributedString];
#else
    attributedString = [[[AshtonAppKit alloc] init] targetRepresentationWithIntermediateRepresentation:attributedString];
#endif
    return [self initWithAttributedString:attributedString];
}


- (NSString *)mn_HTMLRepresentationFromCoreTextAttributes
{
	NSAttributedString *attString = [[AshtonCoreText sharedInstance] intermediateRepresentationWithTargetRepresentation:self];
	return [[AshtonHTMLWriter sharedInstance] HTMLStringFromAttributedString:attString];
}

- (instancetype)mn_initWithCoreTextAttributesFromHTMLString:(NSString *)htmlString
{
	NSAttributedString *attString = [[AshtonHTMLReader HTMLReader] attributedStringFromHTMLString:htmlString];
	attString = [[AshtonCoreText sharedInstance] targetRepresentationWithIntermediateRepresentation:attString];
    return [self initWithAttributedString:attString];
}

@end
