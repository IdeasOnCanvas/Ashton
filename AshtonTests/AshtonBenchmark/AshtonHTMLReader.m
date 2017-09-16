#import "AshtonHTMLReader.h"
#import "AshtonIntermediate.h"

@interface AshtonHTMLReader ()
@property (nonatomic, strong) NSXMLParser *parser;
@property (nonatomic, strong) NSMutableAttributedString *output;
@property (nonatomic, strong) NSMutableArray *styleStack;
@end

@implementation AshtonHTMLReader

+ (instancetype)HTMLReader {
    return [[AshtonHTMLReader alloc] init];
}

+ (NSMutableDictionary *)stylesCache
{
    static NSMutableDictionary *stylesCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        stylesCache = [NSMutableDictionary dictionary];
    });
    return stylesCache;
}

+ (void)clearStylesCache
{
    [[self stylesCache] removeAllObjects];
}

- (NSAttributedString *)attributedStringFromHTMLString:(NSString *)htmlString {
    self.output = [[NSMutableAttributedString alloc] init];
    self.styleStack = [NSMutableArray array];
    NSMutableString *stringToParse = [NSMutableString stringWithCapacity:(htmlString.length + 13)];
    [stringToParse appendString:@"<html>"];
    [stringToParse appendString:htmlString];
    [stringToParse appendString:@"</html>"];
    self.parser = [[NSXMLParser alloc] initWithData:[stringToParse dataUsingEncoding:NSUTF8StringEncoding]];
    self.parser.delegate = self;
    [self.parser parse];
    return self.output;
}

- (NSDictionary *)attributesForStyleString:(NSString *)styleString href:(NSString *)href {
    NSMutableDictionary *attrs;
    NSMutableDictionary *stylesCache = [AshtonHTMLReader stylesCache];
    if (styleString) {
        NSDictionary *cachedAttr = stylesCache[styleString];
        if (cachedAttr) {
            attrs = [cachedAttr mutableCopy];
        }
        else {
            attrs = [NSMutableDictionary dictionary];
            NSScanner *scanner = [NSScanner scannerWithString:styleString];
            while (![scanner isAtEnd]) {
                NSString *key;
                NSString *value;
                [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
                [scanner scanUpToString:@":" intoString:&key];
                [scanner scanString:@":" intoString:NULL];
                [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
                [scanner scanUpToString:@";" intoString:&value];
                [scanner scanString:@";" intoString:NULL];
                [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
                if ([key isEqualToString:@"text-align"]) {
                    // produces: paragraph.text-align
                    NSMutableDictionary *paragraphAttrs = attrs[AshtonAttrParagraph];
                    if (!paragraphAttrs) paragraphAttrs = attrs[AshtonAttrParagraph] = [NSMutableDictionary dictionary];

                    if ([value isEqualToString:@"left"]) paragraphAttrs[AshtonParagraphAttrTextAlignment] = AshtonParagraphAttrTextAlignmentStyleLeft;
                    if ([value isEqualToString:@"right"]) paragraphAttrs[AshtonParagraphAttrTextAlignment] = AshtonParagraphAttrTextAlignmentStyleRight;
                    if ([value isEqualToString:@"center"]) paragraphAttrs[AshtonParagraphAttrTextAlignment] = AshtonParagraphAttrTextAlignmentStyleCenter;
                    if ([value isEqualToString:@"justify"]) paragraphAttrs[AshtonParagraphAttrTextAlignment] = AshtonParagraphAttrTextAlignmentStyleJustified;
                }
                if ([key isEqualToString:@"vertical-align"]) {
                    // produces verticalAlign
                    // skip if vertical-align was already assigned by -cocoa-vertical-align
                    if (!attrs[AshtonAttrVerticalAlign]) {
                        if ([value isEqualToString:@"sub"]) attrs[AshtonAttrVerticalAlign] = @(-1);
                        if ([value isEqualToString:@"super"]) attrs[AshtonAttrVerticalAlign] = @(+1);
                    }
                }
                if ([key isEqualToString:@"-cocoa-vertical-align"]) {
                    attrs[AshtonAttrVerticalAlign] = @([value integerValue]);
                }
                if ([key isEqualToString:@"-cocoa-baseline-offset"]) {
                    attrs[AshtonAttrBaselineOffset] = @([value floatValue]);
                }
                if ([key isEqualToString:AshtonAttrFont]) {
                    // produces: font
                    NSScanner *scanner = [NSScanner scannerWithString:value];
                    BOOL traitBold = [scanner scanString:@"bold " intoString:NULL];
                    BOOL traitItalic = [scanner scanString:@"italic " intoString:NULL];
                    NSInteger pointSize;
                    [scanner scanInteger:&pointSize];
                    [scanner scanString:@"px " intoString:NULL];
                    [scanner scanString:@"\"" intoString:NULL];

                    NSMutableDictionary *fontAttributes = [@{ AshtonFontAttrTraitBold: @(traitBold), AshtonFontAttrTraitItalic: @(traitItalic), AshtonFontAttrPointSize: @(pointSize), AshtonFontAttrFeatures: @[] } mutableCopy];

                    NSString *familyName = nil;
                    [scanner scanUpToString:@"\"" intoString:&familyName];
                    if (familyName != nil) {
                        fontAttributes[AshtonFontAttrFamilyName] = familyName;
                    }

                    attrs[AshtonAttrFont] = [self mergeFontAttributes:fontAttributes into:attrs[AshtonAttrFont]];
                }
                if ([key isEqualToString:@"-cocoa-font-postscriptname"]) {
                    NSScanner *scanner = [NSScanner scannerWithString:value];
                    [scanner scanString:@"\"" intoString:NULL];
                    NSString *postScriptName; [scanner scanUpToString:@"\"" intoString:&postScriptName];
                    NSDictionary *fontAttrs = @{ AshtonFontAttrPostScriptName:postScriptName };
                    attrs[AshtonAttrFont] = [self mergeFontAttributes:fontAttrs into:attrs[AshtonAttrFont]];
                }
                if ([key isEqualToString:@"-cocoa-font-features"]) {
                    NSMutableArray *features = [NSMutableArray array];
                    for (NSString *feature in [value componentsSeparatedByString:@" "]) {
                        NSArray *values = [feature componentsSeparatedByString:@"/"];
                        [features addObject:@[@([values[0] integerValue]), @([values[1] integerValue])]];
                    }

                    NSDictionary *fontAttrs = @{ AshtonFontAttrFeatures: features };
                    attrs[AshtonAttrFont] = [self mergeFontAttributes:fontAttrs into:attrs[AshtonAttrFont]];
                }

                if ([key isEqualToString:@"-cocoa-underline"]) {
                    // produces: underline
                    if ([value isEqualToString:@"single"]) attrs[AshtonAttrUnderline] = AshtonUnderlineStyleSingle;
                    if ([value isEqualToString:@"thick"]) attrs[AshtonAttrUnderline] = AshtonUnderlineStyleThick;
                    if ([value isEqualToString:@"double"]) attrs[AshtonAttrUnderline] = AshtonUnderlineStyleDouble;
                }
                if ([key isEqualToString:@"-cocoa-underline-color"]) {
                    // produces: underlineColor
                    attrs[AshtonAttrUnderlineColor] = [self colorForCSS:value];
                }
                if ([key isEqualToString:AshtonAttrColor]) {
                    // produces: color
                    attrs[AshtonAttrColor] = [self colorForCSS:value];
                }
                if ([key isEqualToString:@"background-color"]) {
                    // produces backgroundColor
                    attrs[AshtonAttrBackgroundColor] = [self colorForCSS:value];
                }
                if ([key isEqualToString:@"-cocoa-strikethrough"]) {
                    // produces: strikethrough
                    if ([value isEqualToString:@"single"]) attrs[AshtonAttrStrikethrough] = AshtonStrikethroughStyleSingle;
                    if ([value isEqualToString:@"thick"]) attrs[AshtonAttrStrikethrough] = AshtonStrikethroughStyleThick;
                    if ([value isEqualToString:@"double"]) attrs[AshtonAttrStrikethrough] = AshtonStrikethroughStyleDouble;
                }
                if ([key isEqualToString:@"-cocoa-strikethrough-color"]) {
                    // produces: strikethroughColor
                    attrs[AshtonAttrStrikethroughColor] = [self colorForCSS:value];
                }
                stylesCache[styleString] = [attrs copy];
            }
        }
    }

    if (!attrs) {
        attrs = [NSMutableDictionary dictionary];
    }

    if (href) {
        attrs[AshtonAttrLink] = href;
    }

    return [attrs copy];
}

// Merge AshtonAttrFont if it already exists (e.g. if -cocoa-font-features: happened before font:)
- (NSDictionary *)mergeFontAttributes:(NSDictionary *)new into:(NSDictionary *)existing {
    if (existing) {
        NSMutableDictionary *merged = [existing mutableCopy];
        NSArray *mergedFeatures;
        if (existing[AshtonFontAttrFeatures] && new[AshtonFontAttrFeatures]) mergedFeatures = [existing[AshtonFontAttrFeatures] arrayByAddingObjectsFromArray:new[AshtonFontAttrFeatures]];
        [merged addEntriesFromDictionary:new];
        if (mergedFeatures) merged[AshtonFontAttrFeatures] = mergedFeatures;
        return merged;
    } else {
        return new;
    }
}

- (NSDictionary *)currentAttributes {
    NSMutableDictionary *mergedAttrs = [NSMutableDictionary dictionary];
    for (NSDictionary *attrs in self.styleStack) {
        [mergedAttrs addEntriesFromDictionary:attrs];
    }
    return mergedAttrs;
}

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    [self.output beginEditing];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    [self.output endEditing];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"html"]) return;
    if (self.output.length > 0) {
        if ([elementName isEqualToString:@"p"]) [self.output appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:[self.output attributesAtIndex:self.output.length-1 effectiveRange:NULL]]];
    }
    [self.styleStack addObject:[self attributesForStyleString:attributeDict[@"style"] href:attributeDict[@"href"]]];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if ([elementName isEqualToString:@"html"]) return;
    [self.styleStack removeLastObject];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    NSLog(@"error %@", parseError);
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    NSAttributedString *fragment = [[NSAttributedString alloc] initWithString:string attributes:[self currentAttributes]];
    [self.output appendAttributedString:fragment];
}

- (id)colorForCSS:(NSString *)css {
  NSScanner *scanner = [NSScanner scannerWithString:css];
  [scanner scanString:@"rgba(" intoString:NULL];
  int red; [scanner scanInt:&red];
  [scanner scanString:@", " intoString:NULL];
  int green; [scanner scanInt:&green];
  [scanner scanString:@", " intoString:NULL];
  int blue; [scanner scanInt:&blue];
  [scanner scanString:@", " intoString:NULL];
  float alpha; [scanner scanFloat:&alpha];
 
  return @[ @((float)red / 255), @((float)green / 255), @((float)blue / 255), @(alpha) ];
}
@end
