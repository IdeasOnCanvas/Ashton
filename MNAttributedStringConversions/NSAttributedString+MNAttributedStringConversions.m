#import "NSAttributedString+MNAttributedStringConversions.h"
#import "MNAttributedStringCoreText.h"
#import "MNAttributedStringHTMLWriter.h"
#import "MNAttributedStringHTMLReader.h"
#if TARGET_OS_IPHONE
#import "MNAttributedStringUIKit.h"
#else
#import "MNAttributedStringAppKit.h"
#endif

@implementation NSAttributedString (MNAttributedStringConversions)

- (NSString *)mn_HTMLRepresentation
{
#if TARGET_OS_IPHONE
	NSAttributedString *attString = [[MNAttributedStringUIKit sharedInstance] intermediateRepresentationWithTargetRepresentation:self];
#else
	NSAttributedString *attString = [[MNAttributedStringAppKit sharedInstance] intermediateRepresentationWithTargetRepresentation:self];
#endif
	return [[MNAttributedStringHTMLWriter sharedInstance] HTMLStringFromAttributedString:attString];
}

- (id)mn_initWithHTMLString:(NSString *)htmlString
{
	NSAttributedString *attString = [[MNAttributedStringHTMLReader sharedInstance] attributedStringFromHTMLString:htmlString];
#if TARGET_OS_IPHONE
	attString = [[MNAttributedStringUIKit sharedInstance] targetRepresentationWithIntermediateRepresentation:attString];
#else
	attString = [[MNAttributedStringAppKit sharedInstance] targetRepresentationWithIntermediateRepresentation:attString];
#endif
    return [self initWithAttributedString:attString];
}


- (NSString *)mn_HTMLRepresentationFromCoreTextAttributes
{
	NSAttributedString *attString = [[MNAttributedStringCoreText sharedInstance] intermediateRepresentationWithTargetRepresentation:self];
	return [[MNAttributedStringHTMLWriter sharedInstance] HTMLStringFromAttributedString:attString];
}

- (id)mn_initWithCoreTextAttributesFromHTMLString:(NSString *)htmlString
{
	NSAttributedString *attString = [[MNAttributedStringHTMLReader sharedInstance] attributedStringFromHTMLString:htmlString];
	attString = [[MNAttributedStringCoreText sharedInstance] targetRepresentationWithIntermediateRepresentation:attString];
    return [[self class] initWithAttributedString:attString];
}

@end
