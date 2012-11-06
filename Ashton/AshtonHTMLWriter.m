#import "AshtonHTMLWriter.h"
#import "AshtonUtils.h"

@implementation AshtonHTMLWriter

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static AshtonHTMLWriter *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AshtonHTMLWriter alloc] init];
    });
    return sharedInstance;
}


- (NSString *)HTMLStringFromAttributedString:(NSAttributedString *)input {
    NSMutableString *output = [NSMutableString string];

    for (NSAttributedString *paragraph in [self paragraphsForAttributedString:input]) {
        [paragraph enumerateAttributesInRange:NSMakeRange(0, paragraph.length) options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
            [output appendString:[self openingTagForAttributes:attrs]];
            NSString *subString = [paragraph.string substringWithRange:range];
            subString = [subString stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
            subString = [subString stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
            subString = [subString stringByReplacingOccurrencesOfString:@"\n" withString:@"<br />"];
            [output appendString:subString];
            [output appendString:[self closingTagWithAttributes:attrs]];
        }];
    };

    return output;
}

- (NSArray *)paragraphsForAttributedString:(NSAttributedString *)input {
    NSMutableArray *paragraphs = [NSMutableArray array];

    NSUInteger length = [input length];
    NSUInteger paraStart = 0, paraEnd = 0, contentsEnd = 0;
    NSRange currentRange;
    while (paraEnd < length) {
        [input.string getParagraphStart:&paraStart end:&paraEnd
                           contentsEnd:&contentsEnd forRange:NSMakeRange(paraEnd, 0)];
        currentRange = NSMakeRange(paraStart, contentsEnd - paraStart);
        if (currentRange.length > 0)
            [paragraphs addObject:[input attributedSubstringFromRange:currentRange]];
    }

    return paragraphs;
}

- (NSString *)openingTagForAttributes:(NSDictionary *)attrs {
    NSMutableString *tag = [NSMutableString string];
    [tag appendString:@"<"];
    [tag appendString:[self tagNameForAttributes:attrs]];

    NSDictionary *styles = [self stylesForAttributes:attrs];
    if ([styles count] > 0) {
        [tag appendString:@" style='"];
        [styles enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [tag appendString:key];
            [tag appendString:@": "];
            if ([obj respondsToSelector:@selector(stringValue)]) obj = [obj stringValue];
            [tag appendString:obj];
            [tag appendString:@"; "];
        }];
        [tag appendString:@"'"];
    }

    [tag appendString:@">"];

    NSString *href = attrs[@"link"];
    if (href) {
        [tag appendString:@"<a href='"];
        [tag appendString:href]; // TODO: Escape '
        [tag appendString:@"'>"];
    }

    return tag;
}

- (NSString *)closingTagWithAttributes:(NSDictionary *)attrs {
    NSMutableString *tag = [NSMutableString string];

    if (attrs[@"link"]) {
        [tag appendString:@"</a>"];
    }

    [tag appendString:@"</"];
    [tag appendString:[self tagNameForAttributes:attrs]];
    [tag appendString:@">"];

    return tag;
}

- (NSString *)tagNameForAttributes:(NSDictionary *)attrs {
    if (attrs[@"paragraph"]) {
        return @"p";
    }
    return @"span";
}

- (NSDictionary *)stylesForAttributes:(NSDictionary *)attrs {
    NSMutableDictionary *styles = [NSMutableDictionary dictionary];
    for (id key in attrs) {
        [styles addEntriesFromDictionary:[self stylesForAttribute:attrs[key] withName:key]];
    }
    return styles;
}

- (NSDictionary *)stylesForAttribute:(id)attr withName:(NSString *)attrName {
    NSMutableDictionary *styles = [NSMutableDictionary dictionary];

    if ([attrName isEqual:@"paragraph"]) {
        NSDictionary *attrDict = attr;
        if ([attrDict[@"textAlignment"] isEqual:@"left"]) styles[@"text-align"] = @"left";
        if ([attrDict[@"textAlignment"] isEqual:@"right"]) styles[@"text-align"] = @"right";
        if ([attrDict[@"textAlignment"] isEqual:@"center"]) styles[@"text-align"] = @"center";
    }
    if ([attrName isEqual:@"font"]) {
        NSDictionary *attrDict = attr;
        // see https://developer.mozilla.org/en-US/docs/CSS/font
        NSMutableArray *fontStyle = [NSMutableArray array];

        if ([attrDict[@"traitBold"] isEqual:@(YES)]) [fontStyle addObject:@"bold"];
        if ([attrDict[@"traitItalic"] isEqual:@(YES)]) [fontStyle addObject:@"italic"];

        [fontStyle addObject:[NSString stringWithFormat:@"%gpt", [attrDict[@"pointSize"] floatValue]]];
        [fontStyle addObject:[NSString stringWithFormat:@"\"%@\"", attrDict[@"familyName"]]];
        styles[@"font"] = [fontStyle componentsJoinedByString:@" "];
    }
    if ([attrName isEqual:@"underline"]) {
        styles[@"text-decoration"] = @"underline";

        if ([attr isEqual:@"single"]) styles[@"-cocoa-underline"] = @"underline";
        if ([attr isEqual:@"thick"]) styles[@"-cocoa-underline"] = @"thick";
        if ([attr isEqual:@"double"]) {
            styles[@"-cocoa-underline"] = @"double";
            styles[@"text-decoration-style"] = @"double"; // CSS 3 attribute, not yet recognized
        }
    }
    if ([attrName isEqual:@"underlineColor"]) {
        styles[@"text-decoration-color"] = [self CSSColor:attr];
        styles[@"-cocoa-underline-color"] = [self CSSColor:attr];
    }
    if ([attrName isEqual:@"color"]) {
        styles[@"color"] = [self CSSColor:attr];
    }

    if ([attrName isEqual:@"strikethrough"]) {
        styles[@"text-decoration"] = @"line-through";

        if ([attr isEqual:@"single"]) styles[@"-cocoa-strikethrough"] = @"underline";
        if ([attr isEqual:@"thick"]) styles[@"-cocoa-strikethrough"] = @"thick";
        if ([attr isEqual:@"double"]) styles[@"-cocoa-strikethrough"] = @"double";
    }
    if ([attrName isEqual:@"strikethroughColor"]) {
        styles[@"-cocoa-strikethrough-color"] = [self CSSColor:attr];
    }
    
    return styles;
}

- (NSString *)CSSColor:(NSArray *)color {
    return [NSString stringWithFormat:@"rgba(%i, %i, %i, %f)", (int)([color[0] doubleValue] * 255), (int)([color[1] doubleValue] * 255), (int)([color[2] doubleValue] * 255), [color[3] doubleValue]];
}

@end
