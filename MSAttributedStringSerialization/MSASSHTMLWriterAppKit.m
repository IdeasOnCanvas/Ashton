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
    NSMutableDictionary *styles = [NSMutableDictionary dictionary];

    if ([attrName isEqual:NSParagraphStyleAttributeName]) {
        NSParagraphStyle *paragraphStyle = (NSParagraphStyle *)attr;

        if ([paragraphStyle alignment] == NSLeftTextAlignment) styles[@"text-align"] = @"left";
        if ([paragraphStyle alignment] == NSRightTextAlignment) styles[@"text-align"] = @"right";
        if ([paragraphStyle alignment] == NSCenterTextAlignment) styles[@"text-align"] = @"center";
    }
    if ([attrName isEqual:NSFontAttributeName]) {
        NSFont *font = (NSFont *)attr;
        styles[@"font-family"] = font.familyName;
        styles[@"font-size"] = @(font.pointSize);

        NSFontSymbolicTraits symbolicTraits = [[font fontDescriptor] symbolicTraits];
        if ((symbolicTraits & NSFontBoldTrait) == NSFontBoldTrait) styles[@"font-style"] = @"italic";
        if ((symbolicTraits & NSFontItalicTrait) == NSFontItalicTrait) styles[@"font-weight"] = @"bold";
    }
    if ([attrName isEqual:NSUnderlineStyleAttributeName]) {
        styles[@"text-decoration"] = @"underline";

        if ([attr isEqual:@(NSUnderlineStyleSingle)]) styles[@"-cocoa-underline"] = @"underline";
        if ([attr isEqual:@(NSUnderlineStyleThick)]) styles[@"-cocoa-underline"] = @"thick";
        if ([attr isEqual:@(NSUnderlineStyleDouble)]) {
            styles[@"-cocoa-underline"] = @"double";
            styles[@"text-decoration-style"] = @"double"; // CSS 3 attribute, not yet recognized
        }
    }
    if ([attrName isEqual:NSUnderlineColorAttributeName]) {
        styles[@"text-decoration"] =  @"underline";
        styles[@"text-decoration-color"] = [self htmlHexString:attr];
    }
    if ([attrName isEqual:NSForegroundColorAttributeName] || [attrName isEqual:NSStrokeColorAttributeName]) {
        styles[@"color"] = [self htmlHexString:attr];
    }

    if ([attrName isEqual:NSStrikethroughStyleAttributeName]) {
        styles[@"text-decoration"] = @"line-through";

        if ([attr isEqual:@(NSUnderlineStyleSingle)]) styles[@"-cocoa-strikethrough"] = @"underline";
        if ([attr isEqual:@(NSUnderlineStyleThick)]) styles[@"-cocoa-strikethrough"] = @"thick";
        if ([attr isEqual:@(NSUnderlineStyleDouble)]) styles[@"-cocoa-strikethrough"] = @"double";
    }
    if ([attrName isEqual:NSStrikethroughColorAttributeName]) {
        styles[@"text-decoration"] = @"line-through";
        styles[@"-cocoa-strikethrough-color"] = [self htmlHexString:attr];
    }

    return styles;
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
