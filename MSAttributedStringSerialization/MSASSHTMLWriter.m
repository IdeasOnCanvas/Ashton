#import "MSASSHTMLWriter.h"
#import "MSASSUtils.h"

@interface MSASSHTMLWriter ()
@property (nonatomic, assign) MSHTMLWritingOptions options;
@property (nonatomic, strong) NSAttributedString *input;
@end

@implementation MSASSHTMLWriter

- (id)initWithAttributedString:(NSAttributedString *)attributedString options:(MSHTMLWritingOptions)options {
    if (self = [super init]) {
        self.input = [attributedString copy];
        self.options = options;
    }
    return self;
}

- (NSString *)createHTMLString {
    NSAttributedString *input = self.input;
    NSString *inputString = [input string];
    NSMutableString *output = [[NSMutableString alloc] initWithCapacity:input.length];
    NSRange totalRange = NSMakeRange (0, input.length);

    __block NSDictionary *previousAttrs = @{};
    [input enumerateAttributesInRange:totalRange options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        NSDictionary *created, *removed;
        [MSASSUtils diffDictionary:previousAttrs to:attrs created:&created removed:&removed];

        for (id key in removed) {
            NSString *tagName = [self tagNameForAttribute:removed[key] withName:key];
            [output appendString:[self closingTagWithName:tagName]];
        }
        for (id key in created) {
            [output appendString:[self openingTagForAttribute:created[key] withName:key]];
        }
        NSString *subString = [inputString substringWithRange:range];
        // TODO: HTML escaping
        subString = [subString stringByReplacingOccurrencesOfString:@"\n" withString:@"<br />\n"];
        [output appendString:subString];
        previousAttrs = attrs;
    }];

    return output;
}

- (NSString *)openingTagForAttribute:(id)attr withName:(NSString *)attrName {
    NSMutableString *tag = [NSMutableString string];
    [tag appendString:@"<"];
    [tag appendString:[self tagNameForAttribute:attr withName:attrName]];

    NSDictionary *styles = [self stylesForAttribute:attr withName:attrName];
    if ([styles count] > 0) {
        [tag appendString:@" style=\""];
        [styles enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [tag appendString:key];
            [tag appendString:@": "];
            if ([obj respondsToSelector:@selector(stringValue)]) obj = [obj stringValue];
            [tag appendString:obj];
            [tag appendString:@"; "];
        }];
        [tag appendString:@"\""];
    }

    NSString *href = [self hrefForAttribute:attr withName:attrName];
    if (href) {
        [tag appendString:@" href=\""];
        [tag appendString:href]; // TODO: Escape "
        [tag appendString:@"\""];
    }

    [tag appendString:@">"];

    return tag;
}

- (NSString *)closingTagWithName:(NSString *)tagName {
    return [NSString stringWithFormat:@"</%@>", tagName];
}


- (NSString *)hrefForAttribute:(id)attr withName:(NSString *)attrName {
    // ABSTRACT
    return nil;
}

- (NSString *)tagNameForAttribute:(id)attr withName:(NSString *)attrName {
    // ABSTRACT
    return nil;
}

- (NSDictionary *)stylesForAttribute:(id)attr withName:(NSString *)attrName {
    // ABSTRACT
    return nil;
}

@end
