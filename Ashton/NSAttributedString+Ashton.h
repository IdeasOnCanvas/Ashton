@interface NSAttributedString (Ashton)

// See http://objcolumnist.com/2011/11/03/keeping-the-static-analyzer-happy-prefixed-initializers/ for an explanation of
// NS_RETURNS_RETAINED and __attribute__((ns_consumes_self))

// Attributed String with UIKit or AppKit Attributes
- (NSString *)mn_HTMLRepresentation;
- (instancetype)mn_initWithHTMLString:(NSString *)htmlString NS_RETURNS_RETAINED __attribute__((ns_consumes_self));

// Attributed String with CT Attributes
- (NSString *)mn_HTMLRepresentationFromCoreTextAttributes;
- (instancetype)mn_initWithCoreTextAttributesFromHTMLString:(NSString *)htmlString NS_RETURNS_RETAINED __attribute__((ns_consumes_self));

@end
