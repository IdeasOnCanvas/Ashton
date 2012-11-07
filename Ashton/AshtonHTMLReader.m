#import "AshtonHTMLReader.h"

@interface AshtonHTMLReader ()
@property (nonatomic, strong) NSXMLParser *parser;
@end

@implementation AshtonHTMLReader

+ (instancetype)HTMLReader {
    return [[AshtonHTMLReader alloc] init];
}

- (NSAttributedString *)attributedStringFromHTMLString:(NSString *)htmlString {
    NSMutableString *stringToParse = [NSMutableString stringWithCapacity:(htmlString.length + 13)];
    [stringToParse appendString:@"<html>"];
    [stringToParse appendString:htmlString];
    [stringToParse appendString:@"</html>"];
    NSLog(@"%@", stringToParse);
    self.parser = [[NSXMLParser alloc] initWithData:[stringToParse dataUsingEncoding:NSUTF8StringEncoding]];
    self.parser.delegate = self;
    [self.parser parse];
    return nil;
}

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    NSLog(@"start");
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    NSLog(@"end");
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    NSLog(@"<%@>", elementName);
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    NSLog(@"</%@>", elementName);
}

- (void)parser:(NSXMLParser *)parser foundElementDeclarationWithName:(NSString *)elementName model:(NSString *)model {
    NSLog(@"e");
}

- (void)parser:(NSXMLParser *)parser foundUnparsedEntityDeclarationWithName:(NSString *)name publicID:(NSString *)publicID systemID:(NSString *)systemID notationName:(NSString *)notationName {
    NSLog(@"un");
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    NSLog(@"%li, %li", self.parser.lineNumber, self.parser.columnNumber);
    NSLog(@"error %@", parseError);
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    NSLog(@"%@", string);
}

@end
