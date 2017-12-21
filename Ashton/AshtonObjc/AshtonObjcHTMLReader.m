//
//  AshtonObjcHTMLReader.m
//  Ashton
//
//  Created by Michael Schwarz on 20.12.17.
//  Copyright © 2017 Michael Schwarz. All rights reserved.
//

#import "AshtonObjcHTMLReader.h"
#import "TBXML.h"
#import "AshtonEnvironment.h"


@interface AshtonObjcHTMLReader()

@property (nonatomic, strong) NSMutableAttributedString *output;
@property (nonatomic, strong) NSMutableDictionary *currentAttributes;

@end


@implementation AshtonObjcHTMLReader

+ (NSMutableDictionary *)fontsCache
{
    static NSMutableDictionary *cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [NSMutableDictionary new];
    });
    return cache;
}

- (NSAttributedString *)decodeAttributedStringFromHTML:(NSString *)html
{
    self.currentAttributes = [NSMutableDictionary new];
    NSMutableString *stringToParse = [NSMutableString stringWithCapacity:(html.length + 13)];
    [stringToParse appendString:@"<html>"];
    [stringToParse appendString:html];
    [stringToParse appendString:@"</html>"];
    self.output = [NSMutableAttributedString new];
    TBXML *tbxml = [[TBXML alloc] initWithXMLString:stringToParse error:nil];
    [self parseElement:tbxml.rootXMLElement];

    return self.output;
}

- (void)parseElement:(TBXMLElement *)element
{
    NSDictionary *attributesBeforeElement = self.currentAttributes.copy;
    TBXMLAttribute *attribute = element->firstAttribute;
    if (attribute != nil) {
        [self parseAttribute:attribute];
    }

    NSString *text = [TBXML textForElement:element];
    if (text != nil) {
        [self appendString:[self convertHTMLEntities:text]];
    }

    TBXMLElement *firstChild = element->firstChild;
    if (firstChild != nil) {
        [self parseElement:firstChild];
    }

    TBXMLElement *nextSibling = element->nextSibling;
    if (nextSibling != nil) {
        NSString *elementName = [TBXML elementName:element];
        if ([elementName isEqualToString:@"p"]) {
            [self appendString:@"\n"];
        }

        self.currentAttributes = [attributesBeforeElement mutableCopy];

        [self parseElement:nextSibling];
    }
}

- (void)appendString:(NSString *)string
{
    NSAttributedString *stringToAppend;
    if (self.currentAttributes.count == 0) {
        stringToAppend = [[NSAttributedString alloc] initWithString:string];
    } else {
        stringToAppend = [[NSAttributedString alloc] initWithString:string attributes:self.currentAttributes];
    }
    [self.output appendAttributedString:stringToAppend];
}


- (void)parseAttribute:(TBXMLAttribute *)attribute
{
    NSString *name = [[NSString alloc] initWithCString:attribute->name encoding:NSUTF8StringEncoding];
    NSString *value = [[NSString alloc] initWithCString:attribute->value encoding:NSUTF8StringEncoding];

    if ([name isEqualToString:@"style"]) {
        [self parseStyleString:value];
    } else if ([name isEqualToString:@"href"]) {
        [self parseLink:value];
    } else {
        NSLog(@"unhandeled attribute");
    }

    TBXMLAttribute *nextAttribute = attribute->next;
    if (nextAttribute != nil) {
        [self parseAttribute:nextAttribute];
    }
}

- (void)parseStyleString:(NSString *)styleString
{
    if (styleString == nil) { return; }

    NSScanner *scanner = [[NSScanner alloc] initWithString:styleString];
    NSString *propertyName = nil;
    NSString *value = nil;

    // font properties
    NSString *fontFamily = nil;
    NSString *postScriptname = nil;
    BOOL isBold = NO;
    BOOL isItalic = NO;
    int pointSize = 0;

    NSCharacterSet *charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@": ;"];
    [scanner setCharactersToBeSkipped:charactersToBeSkipped];

    while ([scanner scanUpToString:@":" intoString:&propertyName] && [scanner scanUpToString:@";" intoString:&value]) {
        if ([propertyName isEqualToString:@"background-color"]) {
            ASHColor *color = [self parseCSSColor:value];
            if (color == nil) { continue; }

            self.currentAttributes[NSBackgroundColorAttributeName] = color;
        } else if ([propertyName isEqualToString:@"color"]) {
            ASHColor *color = [self parseCSSColor:value];
            if (color == nil) { continue; }

            self.currentAttributes[NSForegroundColorAttributeName] = color;
        } else if ([propertyName isEqualToString:@"-cocoa-strikethrough-color"]) {
            ASHColor *color = [self parseCSSColor:value];
            if (color == nil) { continue; }

            self.currentAttributes[NSStrikethroughColorAttributeName] = color;
        } else if ([propertyName isEqualToString:@"-cocoa-underline-color"]) {
            ASHColor *color = [self parseCSSColor:value];
            if (color == nil) { continue; }

            self.currentAttributes[NSUnderlineColorAttributeName] = color;
        } else if ([propertyName isEqualToString:@"text-decoration"]) {
            static NSDictionary* textDecoration = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                textDecoration = @{
                                   @"underline": NSUnderlineStyleAttributeName,
                                   @"line-through": NSStrikethroughStyleAttributeName
                                   };
            });
            NSString *textDecorationStyle = textDecoration[value];
            if (textDecorationStyle == nil) { continue; }

            self.currentAttributes[textDecorationStyle] = @(NSUnderlineStyleSingle);
        } else if ([propertyName isEqualToString:@"-cocoa-underline"] || ([propertyName isEqualToString:@"-cocoa-strikethrough"])) {
            static NSDictionary* underlineMapping = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                underlineMapping = @{
                                 @"single": @(NSUnderlineStyleSingle),
                                 @"double": @(NSUnderlineStyleDouble),
                                 @"thick": @(NSUnderlineStyleThick)
                                 };
            });
            NSNumber *style = underlineMapping[value];
            if (style == nil) { continue; }

            if ([propertyName isEqualToString:@"-cocoa-underline"]) {
                self.currentAttributes[NSUnderlineStyleAttributeName] = style;
            } else {
                self.currentAttributes[NSStrikethroughStyleAttributeName] = style;
            }
        } else if ([propertyName isEqualToString:@"font"]) {
            NSCharacterSet *skippedCharacters = [NSCharacterSet characterSetWithCharactersInString:@", "];
            NSScanner *scanner = [NSScanner scannerWithString:value];
            [scanner setCharactersToBeSkipped:skippedCharacters];

            isBold = [scanner scanString:@"bold" intoString:nil];
            isItalic = [scanner scanString:@"italic" intoString:nil];

            if ([scanner scanInt:&pointSize] == NO) { continue; }

            [scanner scanString:@"px" intoString:nil];
            [scanner scanString:@"\"" intoString:nil];

            if ([scanner scanUpToString:@"\"" intoString:&fontFamily] == NO) { continue; }
        } else if ([propertyName isEqualToString:@"-cocoa-font-postscriptname"]) {
            NSScanner *scanner = [NSScanner scannerWithString:value];
            [scanner scanString:@"\"" intoString:nil];
            if ([scanner scanUpToString:@"\"" intoString:&postScriptname] == NO) { continue; }

        } else if ([propertyName isEqualToString:@"text-align"]) {
            static NSDictionary* textAlignMapping = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                textAlignMapping = @{
                                     @"left": @(NSTextAlignmentLeft),
                                     @"center": @(NSTextAlignmentCenter),
                                     @"right": @(NSTextAlignmentRight),
                                     @"justify": @(NSTextAlignmentJustified)
                                     };
            });
            NSNumber *alignment = textAlignMapping[value];
            if (alignment == nil) { continue; }

            NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
            paragraphStyle.alignment = alignment.integerValue;
            self.currentAttributes[NSParagraphStyleAttributeName] = paragraphStyle;
        } else if ([propertyName isEqualToString:@"-cocoa-baseline-offset"]) {
            self.currentAttributes[NSBaselineOffsetAttributeName] = @(value.floatValue);
        } else if ([propertyName isEqualToString:@"-cocoa-vertical-align"]) {
            self.currentAttributes[@"NSSuperScript"] = @(value.floatValue);
        } else if ([propertyName isEqualToString:@"vertical-align"]) {
            // skip, if we assigned already via -cocoa-vertical-align
            if (self.currentAttributes[@"NSSuperScript"] != nil) { continue; }

            if ([value isEqualToString:@"super"]) {
                self.currentAttributes[@"NSSuperScript"] = @(1);
            } else if ([value isEqualToString:@"sub"]) {
                self.currentAttributes[@"NSSuperScript"] = @(-1);
            }
        }
    }

    if ((fontFamily != nil || postScriptname != nil) && pointSize > 0) {
        NSMutableDictionary *fontCache = [AshtonObjcHTMLReader fontsCache];
        NSString *fontName = postScriptname != nil ? postScriptname : fontFamily;

        NSString *cacheKey = [NSString stringWithFormat:@"%@%zd%d%d", fontName, pointSize, isBold, isItalic];
        ASHFont *cachedFont = (ASHFont *)[fontCache objectForKey:cacheKey];
        if (cachedFont != nil) {
            self.currentAttributes[NSFontAttributeName] = cachedFont;
            return;
        }

        ASHFontDescriptor *descriptor = [ASHFontDescriptor fontDescriptorWithFontAttributes:@{ASHFontDescriptorNameAttribute: fontName}];

        if (postScriptname == nil) {
            ASHFontDescriptorSymbolicTraits traits = descriptor.symbolicTraits;
            if (isBold) {
                traits |= ASHFontDescriptorTraitBold;
            }
            if (isItalic) {
                traits |= ASHFontDescriptorTraitItalic;
            }
            descriptor = [descriptor fontDescriptorWithSymbolicTraits:traits];
        }

        ASHFont *font = [ASHFont fontWithDescriptor:descriptor size:pointSize];
        [fontCache setObject:font forKey:cacheKey];
        self.currentAttributes[NSFontAttributeName] = font;
    }
}

- (void)parseLink:(NSString *)link
{
    if (link == nil) { return; }

    [self.currentAttributes setObject:[self convertHTMLEntities:link] forKey:NSLinkAttributeName];
}

- (NSString *)convertHTMLEntities:(NSString *)string
{
    if ([string containsString:@"&"] == NO) { return string; }

    string = [string stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    string = [string stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
    string = [string stringByReplacingOccurrencesOfString:@"&apos;" withString:@"'"];
    string = [string stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
    string = [string stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    string = [string stringByReplacingOccurrencesOfString:@"<br />" withString:@"\n<br />"];
    
    return string;
}

- (ASHColor *)parseCSSColor:(NSString *)colorString
{
    if (colorString == nil) { return nil; }

    NSCharacterSet *skippedCharacters = [NSCharacterSet characterSetWithCharactersInString:@", "];
    NSScanner *scanner = [NSScanner scannerWithString:colorString];
    [scanner setCharactersToBeSkipped:skippedCharacters];
    int r, g, b;
    float alpha;
    if ([scanner scanString:@"rgba(" intoString:nil] == NO) { return nil; }
    if ([scanner scanInt:&r] == NO) { return nil; }
    if ([scanner scanInt:&g] == NO) { return nil; }
    if ([scanner scanInt:&b] == NO) { return nil; }
    if ([scanner scanFloat:&alpha] == NO) { return nil; }

    return [ASHColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:alpha];
}


@end
