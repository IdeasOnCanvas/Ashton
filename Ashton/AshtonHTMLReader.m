#import "AshtonHTMLReader.h"

@interface AshtonHTMLReader ()
@property (nonatomic, strong) NSXMLParser *parser;
@property (nonatomic, strong) NSMutableAttributedString *output;
@property (nonatomic, strong) NSMutableArray *styleStack;
@end

@implementation AshtonHTMLReader

+ (instancetype)HTMLReader {
    return [[AshtonHTMLReader alloc] init];
}

- (NSAttributedString *)attributedStringFromHTMLString:(NSString *)htmlString {
    self.output = [[NSMutableAttributedString alloc] init];
    self.styleStack = [NSMutableArray array];
    NSMutableString *stringToParse = [NSMutableString stringWithCapacity:(htmlString.length + 13)];
    [stringToParse appendString:@"<html>"];
    [stringToParse appendString:htmlString];
    [stringToParse appendString:@"</html>"];
    NSLog(@"%@", stringToParse);
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

            if ([key isEqual:@"-cocoa-underline"]) {
                // produces: underline
                if ([value isEqual:@"single"]) attrs[@"underline"] = @"single";
                if ([value isEqual:@"thick"]) attrs[@"underline"] = @"thick";
                if ([value isEqual:@"double"]) attrs[@"underline"] = @"double";
            }
            if ([key isEqual:@"-cocoa-underline-color"]) {
                // produces: underlineColor
                attrs[@"underlineColor"] = [self colorForCSS:value];
            }
            if ([key isEqual:@"color"]) {
                // produces: color
                attrs[@"color"] = [self colorForCSS:value];
            }
            if ([key isEqual:@"-cocoa-strikethrough"]) {
                // produces: strikethrough
                if ([value isEqual:@"single"]) attrs[@"strikethrough"] = @"single";
                if ([value isEqual:@"thick"]) attrs[@"strikethrough"] = @"thick";
                if ([value isEqual:@"double"]) attrs[@"strikethrough"] = @"double";
            }
            if ([key isEqual:@"-cocoa-strikethrough-color"]) {
                // produces: strikethroughColor
                attrs[@"strikethroughColor"] = [self colorForCSS:value];
            }
            NSLog(@"%@: %@", key, value);
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
    if ([elementName isEqual:@"html"]) return;
    [self.styleStack addObject:[self attributesForStyleString:attributeDict[@"style"] href:attributeDict[@"href"]]];
    NSLog(@"<%@ %@>", elementName, attributeDict[@"style"]);
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if ([elementName isEqual:@"html"]) return;
    if ([elementName isEqual:@"p"]) [self.output appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    [self.styleStack removeLastObject];
    NSLog(@"</%@>", elementName);
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
