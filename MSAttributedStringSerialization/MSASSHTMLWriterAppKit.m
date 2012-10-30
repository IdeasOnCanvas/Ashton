#import "MSASSHTMLWriterAppKit.h"

@implementation MSASSHTMLWriterAppKit

- (NSString *)tagNameForAttribute:(id)attr withName:(NSString *)attrName {
    if ([attrName isEqual:NSParagraphStyleAttributeName]) {
        return @"p";
    }
    if ([attrName isEqual:NSLinkAttributeName]) {
        return @"a";
    }
    return @"span";
}

- (NSString *)hrefForAttribute:(id)attr withName:(NSString *)attrName {
    if ([attrName isEqual:NSLinkAttributeName]) {
        return [attr absoluteString];
    } else {
        return nil;
    }
}

- (NSDictionary *)stylesForAttribute:(id)attr withName:(NSString *)attrName {
    if ([attrName isEqual:NSParagraphStyleAttributeName]) {
        NSParagraphStyle *paragraphStyle = (NSParagraphStyle *)attr;

        NSString *textAlignment = @"";
        if ([paragraphStyle alignment] == NSLeftTextAlignment) {
            textAlignment = @"left";
        } else if ([paragraphStyle alignment] == NSRightTextAlignment) {
            textAlignment = @"right";
        } else if ([paragraphStyle alignment] == NSCenterTextAlignment) {
            textAlignment = @"center";
        }

        return @{ @"text-alignment": textAlignment };
    }
    if ([attrName isEqual:NSFontAttributeName]) {
        NSFont *font = (NSFont *)attr;
        NSMutableDictionary *styles = [@{ @"font-family": font.familyName, @"font-size": @(font.pointSize) } mutableCopy];

        NSFontSymbolicTraits symbolicTraits = [[font fontDescriptor] symbolicTraits];
        if ((symbolicTraits & NSFontBoldTrait) == NSFontBoldTrait) styles[@"font-style"] = @"italic";
        if ((symbolicTraits & NSFontItalicTrait) == NSFontItalicTrait) styles[@"font-weight"] = @"bold";

        return styles;
    }
    if ([attrName isEqual:NSLinkAttributeName]) {
        return nil;
    }
    if ([attrName isEqual:NSUnderlineStyleAttributeName]) {
        NSMutableDictionary *styles = [@{ @"text-decoration": @"underline" } mutableCopy];

        if ([attr isEqual:@(NSUnderlineStyleSingle)]) styles[@"-cocoa-underline"] = @"underline";
        if ([attr isEqual:@(NSUnderlineStyleThick)]) styles[@"-cocoa-underline"] = @"thick";
        if ([attr isEqual:@(NSUnderlineStyleDouble)]) {
            styles[@"-cocoa-underline"] = @"double";
            styles[@"text-decoration-style"] = @"double"; // CSS 3 attribute, not yet recognized
        }

        return styles;
    }
    if ([attrName isEqual:NSUnderlineColorAttributeName]) {
        return @{ @"text-decoration": @"underline", @"text-decoration-color": [self htmlHexString:attr] };
    }
    if ([attrName isEqual:NSForegroundColorAttributeName] || [attrName isEqual:NSStrokeColorAttributeName]) {
        return @{ @"color": [self htmlHexString:attr] };
    }

    if ([attrName isEqual:NSStrikethroughStyleAttributeName]) {
        NSMutableDictionary *styles = [@{ @"text-decoration": @"line-through" } mutableCopy];

        if ([attr isEqual:@(NSUnderlineStyleSingle)]) styles[@"-cocoa-strikethrough"] = @"underline";
        if ([attr isEqual:@(NSUnderlineStyleThick)]) styles[@"-cocoa-strikethrough"] = @"thick";
        if ([attr isEqual:@(NSUnderlineStyleDouble)]) styles[@"-cocoa-strikethrough"] = @"double";

        return styles;
    }
    if ([attrName isEqual:NSStrikethroughColorAttributeName]) {
        return @{ @"text-decoration": @"line-through", @"-cocoa-strikethrough-color": [self htmlHexString:attr] };
    }

    return nil;
}

// From https://github.com/Cocoanetics/DTCoreText/blob/master/Core/Source/DTColor%2BHTML.m
- (NSString *)htmlHexString:(NSColor *)nscolor
{
	CGColorRef color = nscolor.CGColor;
	size_t count = CGColorGetNumberOfComponents(color);
	const CGFloat *components = CGColorGetComponents(color);

	static NSString *stringFormat = @"#%02x%02x%02x";

	// Grayscale
	if (count == 2)
	{
		NSUInteger white = (NSUInteger)(components[0] * (CGFloat)255);
		return [NSString stringWithFormat:stringFormat, white, white, white];
	}

	// RGB
	else if (count == 4)
	{
		return [NSString stringWithFormat:stringFormat, (NSUInteger)(components[0] * (CGFloat)255),
				(NSUInteger)(components[1] * (CGFloat)255), (NSUInteger)(components[2] * (CGFloat)255)];
	}

	// Unsupported color space
	return nil;
}

@end
