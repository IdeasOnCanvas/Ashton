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
	NSAttributedString *attString = [[MNAttributedStringUIKit shared] intermediateRepresentationWithTargetRepresentation:self];
#else
	NSAttributedString *attString = [[MNAttributedStringAppKit shared] intermediateRepresentationWithTargetRepresentation:self];
#endif
	return [[MNAttributedStringHTMLWriter shared] HTMLStringFromAttributedString:attString];
}

- (id)mn_initWithHTMLString:(NSString *)htmlString
{
	NSAttributedString *attString = [[MNAttributedStringHTMLReader HTMLReader] attributedStringFromHTMLString:htmlString];
#if TARGET_OS_IPHONE
	attString = [[MNAttributedStringUIKit shared] targetRepresentationWithIntermediateRepresentation:attString];
#else
	attString = [[MNAttributedStringAppKit shared] targetRepresentationWithIntermediateRepresentation:attString];
#endif
    return [[self class] initWithAttributedString:attString];
}


- (NSString *)mn_HTMLRepresentationFromCoreTextAttributes
{
	NSAttributedString *attString = [[MNAttributedStringCoreText shared] intermediateRepresentationWithTargetRepresentation:self];
	return [[MNAttributedStringHTMLWriter shared] HTMLStringFromAttributedString:attString];
}

- (id)mn_initWithCoreTextAttributesFromHTMLString:(NSString *)htmlString
{
	NSAttributedString *attString = [[MNAttributedStringHTMLReader HTMLReader] attributedStringFromHTMLString:htmlString];
	attString = [[MNAttributedStringCoreText shared] targetRepresentationWithIntermediateRepresentation:attString];
    return [[self class] initWithAttributedString:attString];
}

@end
