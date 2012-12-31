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
	NSAttributedString *attString = [[AshtonUIKit sharedInstance] intermediateRepresentationWithTargetRepresentation:self];
#else
	NSAttributedString *attString = [[AshtonAppKit sharedInstance] intermediateRepresentationWithTargetRepresentation:self];
#endif
	return [[AshtonHTMLWriter sharedInstance] HTMLStringFromAttributedString:attString];
}

- (id)mn_initWithHTMLString:(NSString *)htmlString
{
	NSAttributedString *attString = [[AshtonHTMLReader sharedInstance] attributedStringFromHTMLString:htmlString];
#if TARGET_OS_IPHONE
	attString = [[AshtonUIKit sharedInstance] targetRepresentationWithIntermediateRepresentation:attString];
#else
	attString = [[AshtonAppKit sharedInstance] targetRepresentationWithIntermediateRepresentation:attString];
#endif
    return [self initWithAttributedString:attString];
}


- (NSString *)mn_HTMLRepresentationFromCoreTextAttributes
{
	NSAttributedString *attString = [[AshtonCoreText sharedInstance] intermediateRepresentationWithTargetRepresentation:self];
	return [[AshtonHTMLWriter sharedInstance] HTMLStringFromAttributedString:attString];
}

- (id)mn_initWithCoreTextAttributesFromHTMLString:(NSString *)htmlString
{
	NSAttributedString *attString = [[AshtonHTMLReader sharedInstance] attributedStringFromHTMLString:htmlString];
	return [[AshtonCoreText sharedInstance] targetRepresentationWithIntermediateRepresentation:attString];
}

@end
