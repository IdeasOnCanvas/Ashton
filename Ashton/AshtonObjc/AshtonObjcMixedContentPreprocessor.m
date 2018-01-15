//
//  AshtonObjcMixedContentPreprocessor.m
//  Ashton
//
//  Created by Michael Schwarz on 15.01.18.
//  Copyright © 2018 Michael Schwarz. All rights reserved.
//

#import "AshtonObjcMixedContentPreprocessor.h"


@interface AshtonObjcMixedContentPreprocessor() <NSXMLParserDelegate>

@property (nonatomic, strong) NSMutableString *output;

@end


@implementation AshtonObjcMixedContentPreprocessor

- (NSString *)preprocessHTMLString:(NSString *)htmlString
{
    self.output = [[NSMutableString alloc] initWithCapacity:htmlString.length];
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[htmlString dataUsingEncoding:NSUTF8StringEncoding]];
    parser.delegate = self;
    [parser parse];

    NSLog(@"%@", self.output);
    return self.output;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    if (attributeDict.count > 0) {
        NSMutableString *attributesString = [NSMutableString new];
        for (NSString *key in attributeDict.allKeys) {
            [attributesString appendFormat:@" %@='%@'", key, attributeDict[key]];
        }
        [self.output appendFormat:@"<%@%@>", elementName, attributesString];
    } else {
        [self.output appendFormat:@"<%@>", elementName];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    [self.output appendFormat:@"</%@>",elementName];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    [self.output appendFormat:@"<wrapped>%@</wrapped>", string];
}

@end
