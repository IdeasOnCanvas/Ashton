#import "AshtonHTMLWriter.h"

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
        NSRange paragraphRange = NSMakeRange(0, paragraph.length);
        NSMutableString *paragraphOutput = [NSMutableString string];
        NSMutableDictionary *paragraphAttrs = [NSMutableDictionary dictionary];
        id paragraphStyle = [paragraph attribute:@"paragraph" atIndex:0 effectiveRange:NULL];
        if (paragraphStyle) paragraphAttrs[@"paragraph"] = paragraphStyle;

        [paragraph enumerateAttributesInRange:paragraphRange options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
            NSString *content = [self HTMLEscapeString:[paragraph.string substringWithRange:range]];
            if (NSEqualRanges(range, paragraphRange)) {
                [paragraphAttrs addEntriesFromDictionary:attrs];
                if (attrs[@"link"]) [paragraphOutput appendFormat:@"<a href='%@'>", attrs[@"link"]];
                [paragraphOutput appendString:content];
                if (attrs[@"link"]) [paragraphOutput appendString:@"</a>"];
            } else {
                [paragraphOutput appendString:[self openingTagForAttributes:attrs skipParagraphStyles:YES]];
                [paragraphOutput appendString:content];
                [paragraphOutput appendString:[self closingTagWithAttributes:attrs]];
            }
        }];

        [output appendString:@"<p"];
        [output appendString:[self styleStringForAttributes:paragraphAttrs skipParagraphStyles:NO]];
        [output appendString:@">"];
        [output appendString:paragraphOutput];
        [output appendString:@"</p>"];
    };

    return output;
}

- (NSString *)HTMLEscapeString:(NSString *)input {
    input = [input stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    input = [input stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    input = [input stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    input = [input stringByReplacingOccurrencesOfString:@"\n" withString:@"<br />"];
    return input;
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

- (NSString *)openingTagForAttributes:(NSDictionary *)attrs skipParagraphStyles:(BOOL)skipParagraphStyles {
    NSMutableString *tag = [NSMutableString string];
    [tag appendString:@"<"];
    [tag appendString:[self tagNameForAttributes:attrs]];
    [tag appendString:[self styleStringForAttributes:attrs skipParagraphStyles:skipParagraphStyles]];
    [tag appendString:@">"];
    return tag;
}

- (NSString *)styleStringForAttributes:(NSDictionary *)attrs skipParagraphStyles:(BOOL)skipParagraphStyles {
    NSDictionary *styles = [self stylesForAttributes:attrs skipParagraphStyles:skipParagraphStyles];
    NSMutableString *styleString = [NSMutableString string];
    if ([styles count] > 0) {
        [styleString appendString:@" style='"];
        [styles enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [styleString appendString:key];
            [styleString appendString:@": "];
            if ([obj respondsToSelector:@selector(stringValue)]) obj = [obj stringValue];
            [styleString appendString:obj];
            [styleString appendString:@"; "];
        }];
        [styleString appendString:@"'"];
    }

    if(skipParagraphStyles && attrs[@"link"]) [styleString appendFormat:@" href='%@'", attrs[@"link"]];

    return styleString;
}

- (NSString *)closingTagWithAttributes:(NSDictionary *)attrs {
    NSMutableString *tag = [NSMutableString string];
    [tag appendString:@"</"];
    [tag appendString:[self tagNameForAttributes:attrs]];
    [tag appendString:@">"];
    return tag;
}

- (NSString *)tagNameForAttributes:(NSDictionary *)attrs {
    if (attrs[@"link"]) {
        return @"a";
    }
    return @"span";
}

- (NSDictionary *)stylesForAttributes:(NSDictionary *)attrs skipParagraphStyles:(BOOL)skipParagraphStyles {
    NSMutableDictionary *styles = [NSMutableDictionary dictionary];
    for (id key in attrs) {
        if(skipParagraphStyles && [key isEqual:@"paragraph"]) continue;
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

        [fontStyle addObject:[NSString stringWithFormat:@"%gpx", [attrDict[@"pointSize"] floatValue]]];
        [fontStyle addObject:[NSString stringWithFormat:@"\"%@\"", attrDict[@"familyName"]]];
        styles[@"font"] = [fontStyle componentsJoinedByString:@" "];
    }
    if ([attrName isEqual:@"underline"]) {
        styles[@"text-decoration"] = @"underline";

        if ([attr isEqual:@"single"]) styles[@"-cocoa-underline"] = @"single";
        if ([attr isEqual:@"thick"]) styles[@"-cocoa-underline"] = @"thick";
        if ([attr isEqual:@"double"]) styles[@"-cocoa-underline"] = @"double";
    }
    if ([attrName isEqual:@"underlineColor"]) {
        styles[@"-cocoa-underline-color"] = [self CSSColor:attr];
    }
    if ([attrName isEqual:@"color"]) {
        styles[@"color"] = [self CSSColor:attr];
    }

    if ([attrName isEqual:@"strikethrough"]) {
        styles[@"text-decoration"] = @"line-through";

        if ([attr isEqual:@"single"]) styles[@"-cocoa-strikethrough"] = @"single";
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
