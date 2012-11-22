@interface NSAttributedString (MNAttributedStringConversions)

// Attributed String with UIKit or AppKit Attributes
- (NSString *)mn_HTMLRepresentation;
- (id)mn_initWithHTMLString:(NSString *)htmlString;

// Attributed String with CT Attributes
- (NSString *)mn_HTMLRepresentationFromCoreTextAttributes;
- (id)mn_initWithCoreTextAttributesFromHTMLString:(NSString *)htmlString;

@end
