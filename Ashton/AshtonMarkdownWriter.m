#import "AshtonMarkdownWriter.h"
#import "AshtonIntermediate.h"

@implementation AshtonMarkdownWriter

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static AshtonMarkdownWriter *sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AshtonMarkdownWriter alloc] init];
    });
    return sharedInstance;
}

- (NSString *)markdownStringFromAttributedString:(NSAttributedString *)input {
    NSString *inputString = input.string;
    NSMutableString *output = [NSMutableString stringWithCapacity:input.length*1.5];
    NSUInteger length = [input length];
    NSUInteger paraStart = 0, paraEnd = 0, contentsEnd = 0;
    NSRange paragraphRange;
    while (paraEnd < length) {
        [inputString getParagraphStart:&paraStart end:&paraEnd
                            contentsEnd:&contentsEnd forRange:NSMakeRange(paraEnd, 0)];
        paragraphRange = NSMakeRange(paraStart, contentsEnd - paraStart);
        __block BOOL outputIsBold = NO;
        __block BOOL outputIsItalic = NO;
        __block BOOL outputIsStrikethrough = NO;
        __block NSString *previousSuffix = nil;
        [inputString enumerateSubstringsInRange:paragraphRange options:NSStringEnumerationByWords usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
            NSDictionary *attrs = [input attributesAtIndex:substringRange.location effectiveRange:NULL];
            BOOL isBold = [attrs[AshtonAttrFont][AshtonFontAttrTraitBold] boolValue];
            BOOL isItalic = [attrs[AshtonAttrFont][AshtonFontAttrTraitItalic] boolValue];
            BOOL isStrikethrough = (attrs[AshtonAttrStrikethrough] != nil);

            NSUInteger prefixLocation = enclosingRange.location;
            NSUInteger prefixLength = enclosingRange.location - substringRange.location;
            NSUInteger suffixLocation = substringRange.location + substringRange.length;
            NSUInteger suffixLength = (enclosingRange.location + enclosingRange.length) - suffixLocation;
            NSString *suffix = nil, *prefix = nil;
            if (suffixLength > 0) suffix = [inputString substringWithRange:NSMakeRange(suffixLocation, suffixLength)];
            if (prefixLength > 0) prefix = [inputString substringWithRange:NSMakeRange(prefixLocation, prefixLength)];

            if (outputIsBold && !isBold) [output appendString:@"**"];
            if (outputIsItalic && !isItalic) [output appendString:@"*"];
            if (outputIsStrikethrough && !isStrikethrough) [output appendString:@"~~"];

            if (previousSuffix) [output appendString:previousSuffix];
            if (prefix) [output appendString:prefix];

            if (!outputIsStrikethrough && isStrikethrough) [output appendString:@"~~"];
            if (!outputIsBold && isBold) [output appendString:@"**"];
            if (!outputIsItalic && isItalic) [output appendString:@"*"];

            [output appendString:substring];


            previousSuffix = suffix;
            outputIsBold = isBold;
            outputIsItalic = isItalic;
            outputIsStrikethrough = isStrikethrough;
        }];
        if (outputIsBold) [output appendString:@"**"];
        if (outputIsItalic) [output appendString:@"*"];
        if (outputIsStrikethrough) [output appendString:@"~~"];
        if (previousSuffix) [output appendString:previousSuffix];
        [output appendFormat:@"\n\n"];
    }
    return output;
}

@end