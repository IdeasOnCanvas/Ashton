#import "MSASSAppKit.h"

@implementation MSASSAppKit

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static MSASSAppKit *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MSASSAppKit alloc] init];
    });
    return sharedInstance;
}

- (NSAttributedString *)intermediateRepresentationWithTargetRepresentation:(NSAttributedString *)input {
    NSMutableAttributedString *output = [input mutableCopy];
    NSRange totalRange = NSMakeRange (0, input.length);
    [input enumerateAttributesInRange:totalRange options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        NSMutableDictionary *newAttrs = [NSMutableDictionary dictionaryWithCapacity:[attrs count]];
        for (NSString *attrName in attrs) {
            id attr = attrs[attrName];
            if ([attrName isEqual:NSParagraphStyleAttributeName]) {
                NSParagraphStyle *paragraphStyle = (NSParagraphStyle *)attr;

                newAttrs[@"kind"] = @"paragraph";

                if ([paragraphStyle alignment] == NSLeftTextAlignment) newAttrs[@"textAlignment"] = @"left";
                if ([paragraphStyle alignment] == NSRightTextAlignment) newAttrs[@"textAlignment"] = @"right";
                if ([paragraphStyle alignment] == NSCenterTextAlignment) newAttrs[@"textAlignment"] = @"center";
            }
            if ([attrName isEqual:NSFontAttributeName]) {
                NSFont *font = (NSFont *)attr;
                NSFontSymbolicTraits symbolicTraits = [[font fontDescriptor] symbolicTraits];
                if ((symbolicTraits & NSFontBoldTrait) == NSFontBoldTrait) newAttrs[@"fontTraitBold"] = @(YES);
                if ((symbolicTraits & NSFontItalicTrait) == NSFontItalicTrait) newAttrs[@"fontTraitItalic"] = @(YES);

                newAttrs[@"fontPointSize"] = @(font.pointSize);
                newAttrs[@"fontFamilyName"] = font.familyName;
            }
            if ([attrName isEqual:NSUnderlineStyleAttributeName]) {
                if ([attr isEqual:@(NSUnderlineStyleSingle)]) newAttrs[@"underline"] = @"single";
                if ([attr isEqual:@(NSUnderlineStyleThick)]) newAttrs[@"underline"] = @"thick";
                if ([attr isEqual:@(NSUnderlineStyleDouble)]) newAttrs[@"underline"] = @"double";
            }
            if ([attrName isEqual:NSUnderlineColorAttributeName]) {
                newAttrs[@"underlineColor"] = [self hexColor:attr];
            }
            if ([attrName isEqual:NSForegroundColorAttributeName] || [attrName isEqual:NSStrokeColorAttributeName]) {
                newAttrs[@"color"] = [self hexColor:attr];
            }

            if ([attrName isEqual:NSStrikethroughStyleAttributeName]) {
                if ([attr isEqual:@(NSUnderlineStyleSingle)]) newAttrs[@"strikethrough"] = @"single";
                if ([attr isEqual:@(NSUnderlineStyleThick)]) newAttrs[@"strikethrough"] = @"thick";
                if ([attr isEqual:@(NSUnderlineStyleDouble)]) newAttrs[@"strikethrough"] = @"double";
            }
            if ([attrName isEqual:NSStrikethroughColorAttributeName]) {
                newAttrs[@"strikethroughColor"] = [self hexColor:attr];
            }
        }
        [output setAttributes:newAttrs range:range];
    }];

    return output;
}

- (NSAttributedString *)targetRepresentationWithIntermediateRepresentation:(NSAttributedString *)input {
    NSMutableAttributedString *output = [input mutableCopy];
    NSRange totalRange = NSMakeRange (0, input.length);
    [input enumerateAttributesInRange:totalRange options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        NSMutableDictionary *newAttrs = [NSMutableDictionary dictionaryWithCapacity:[attrs count]];
        for (NSString *attrName in attrs) {
            id attr = attrs[attrName];
            if ([attrName isEqual:@"kind"] && [attr isEqual:@"paragraph"]) {
                // consumes: kind, textAlignment
                NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];

                if ([attrs[@"textAlignment"] isEqual:@"left"]) paragraphStyle.alignment = NSLeftTextAlignment;
                if ([attrs[@"textAlignment"] isEqual:@"right"]) paragraphStyle.alignment = NSRightTextAlignment;
                if ([attrs[@"textAlignment"] isEqual:@"center"]) paragraphStyle.alignment = NSCenterTextAlignment;

                newAttrs[NSParagraphStyleAttributeName] = [paragraphStyle copy];
            }
            if ([attrName isEqual:@"fontFamilyName"]) {
                // consumes: fontFamilyName, fontTraitBold, fontTraitItalic, fontPointSize

                NSFontDescriptor *fontDescriptor = [NSFontDescriptor fontDescriptorWithFontAttributes:@{ NSFontFamilyAttribute: attrs[@"fontFamilyName"] }];
                NSFontSymbolicTraits symbolicTraits = [fontDescriptor symbolicTraits];
                if ([newAttrs[@"fontTraitBold"] isEqual:@(YES)]) symbolicTraits = symbolicTraits & NSFontBoldTrait;
                if ([newAttrs[@"fontTraitItalic"] isEqual:@(YES)]) symbolicTraits = symbolicTraits & NSFontItalicTrait;

                newAttrs[NSFontAttributeName] = [NSFont fontWithDescriptor:fontDescriptor size:[attrs[@"fontPointSize"] doubleValue]];
            }
            if ([attrName isEqual:@"underline"]) {
                if ([attr isEqual:@"single"]) newAttrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleSingle);
                if ([attr isEqual:@"thick"]) newAttrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleThick);
                if ([attr isEqual:@"double"]) newAttrs[NSUnderlineStyleAttributeName] = @(NSUnderlineStyleDouble);
            }
            if ([attrName isEqual:@"underlineColor"]) {
                newAttrs[NSUnderlineColorAttributeName] = [self colorFromHexRGB:attr];
            }
            if ([attrName isEqual:@"color"]) {
                newAttrs[NSForegroundColorAttributeName] = [self colorFromHexRGB:attr];
            }

            if ([attrName isEqual:@"strikethrough"]) {
                if ([attr isEqual:@"single"]) newAttrs[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleSingle);
                if ([attr isEqual:@"thick"]) newAttrs[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleThick);
                if ([attr isEqual:@"double"]) newAttrs[NSStrikethroughStyleAttributeName] = @(NSUnderlineStyleDouble);
            }
            if ([attrName isEqual:@"strikethroughColor"]) {
                newAttrs[NSStrikethroughColorAttributeName] = [self colorFromHexRGB:attr];
            }
        }
        [output setAttributes:newAttrs range:range];
    }];

    return output;
}


// From https://github.com/Cocoanetics/DTCoreText/blob/master/Core/Source/DTColor%2BHTML.m
- (NSString *)hexColor:(NSColor *)nscolor
{
	CGColorRef color = nscolor.CGColor;
	size_t count = CGColorGetNumberOfComponents(color);
	const CGFloat *components = CGColorGetComponents(color);

	static NSString *stringFormat = @"%02x%02x%02x";

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


// From http://cocoa.karelia.com/Foundation_Categories/NSColor__Instantiat.m
- (NSColor *)colorFromHexRGB:(NSString *) inColorString
{
	NSColor *result = nil;
	unsigned int colorCode = 0;
	unsigned char redByte, greenByte, blueByte;

	if (nil != inColorString)
	{
		NSScanner *scanner = [NSScanner scannerWithString:inColorString];
		(void) [scanner scanHexInt:&colorCode];	// ignore error
	}
	redByte		= (unsigned char) (colorCode >> 16);
	greenByte	= (unsigned char) (colorCode >> 8);
	blueByte	= (unsigned char) (colorCode);	// masks off high bits
	result = [NSColor
              colorWithCalibratedRed:		(float)redByte	/ 0xff
              green:	(float)greenByte/ 0xff
              blue:	(float)blueByte	/ 0xff
              alpha:1.0];
	return result;
}

@end
