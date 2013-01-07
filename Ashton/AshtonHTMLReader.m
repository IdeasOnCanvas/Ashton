#import "AshtonHTMLReader.h"

@interface AshtonHTMLReader ()
@property (nonatomic, strong) NSXMLParser *parser;
@property (nonatomic, strong) NSMutableAttributedString *output;
@property (nonatomic, strong) NSMutableArray *styleStack;
@end

@implementation AshtonHTMLReader

+ (instancetype)sharedInstance {
    return [[AshtonHTMLReader alloc] init];
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
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];

    if (href) {
        attrs[@"link"] = href;
    }

    if (styleString) {
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
                NSMutableDictionary *paragraphAttrs = attrs[@"paragraph"];
                if (!paragraphAttrs) paragraphAttrs = attrs[@"paragraph"] = [NSMutableDictionary dictionary];

                if ([value isEqualToString:@"left"]) paragraphAttrs[@"textAlignment"] = @"left";
                if ([value isEqualToString:@"right"]) paragraphAttrs[@"textAlignment"] = @"right";
                if ([value isEqualToString:@"center"]) paragraphAttrs[@"textAlignment"] = @"center";
            }
            if ([key isEqualToString:@"font"]) {
                // produces: font
                NSScanner *scanner = [NSScanner scannerWithString:value];
                BOOL traitBold = [scanner scanString:@"bold " intoString:NULL];
                BOOL traitItalic = [scanner scanString:@"italic " intoString:NULL];
                NSInteger pointSize; [scanner scanInteger:&pointSize];
                [scanner scanString:@"px " intoString:NULL];
                [scanner scanString:@"\"" intoString:NULL];
                NSString *familyName; [scanner scanUpToString:@"\"" intoString:&familyName];

                attrs[@"font"] = @{ @"traitBold": @(traitBold), @"traitItalic": @(traitItalic), @"familyName": familyName, @"pointSize": @(pointSize), @"features": @[] };
            }
            if ([key isEqualToString:@"-cocoa-font-features"]) {
                // We expect -cocoa-font-features to only happen after font
                NSMutableArray *features = [NSMutableArray array];

                NSMutableDictionary *font = [attrs[@"font"] mutableCopy];
                for (NSString *feature in [value componentsSeparatedByString:@" "]) {
                    NSArray *values = [feature componentsSeparatedByString:@"/"];
                    [features addObject:@[@([values[0] intValue]), @([values[1] intValue])]];
                }

                font[@"features"] = features;
                attrs[@"font"] = font;
            }

            if ([key isEqualToString:@"-cocoa-underline"]) {
                // produces: underline
                if ([value isEqualToString:@"single"]) attrs[@"underline"] = @"single";
                if ([value isEqualToString:@"thick"]) attrs[@"underline"] = @"thick";
                if ([value isEqualToString:@"double"]) attrs[@"underline"] = @"double";
            }
            if ([key isEqualToString:@"-cocoa-underline-color"]) {
                // produces: underlineColor
                attrs[@"underlineColor"] = [self colorForCSS:value];
            }
            if ([key isEqualToString:@"color"]) {
                // produces: color
                attrs[@"color"] = [self colorForCSS:value];
            }
            if ([key isEqualToString:@"-cocoa-strikethrough"]) {
                // produces: strikethrough
                if ([value isEqualToString:@"single"]) attrs[@"strikethrough"] = @"single";
                if ([value isEqualToString:@"thick"]) attrs[@"strikethrough"] = @"thick";
                if ([value isEqualToString:@"double"]) attrs[@"strikethrough"] = @"double";
            }
            if ([key isEqualToString:@"-cocoa-strikethrough-color"]) {
                // produces: strikethroughColor
                attrs[@"strikethroughColor"] = [self colorForCSS:value];
            }
        }
    }

    return attrs;
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
        if ([elementName isEqualToString:@"p"]) [self.output appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
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
    NSMutableAttributedString *fragment = [[NSMutableAttributedString alloc] initWithString:string attributes:[self currentAttributes]];
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
