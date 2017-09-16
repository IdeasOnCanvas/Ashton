#import "AshtonMarkdownWriter.h"
#import "AshtonIntermediate.h"
#if TARGET_OS_IPHONE
#import "AshtonUIKit.h"
#else
#import "AshtonAppKit.h"
#endif

static void writeMarkdownFragment(NSAttributedString *input, NSString *inputString, NSRange range, NSMutableString *output) {
    __block BOOL outputIsBold = NO;
    __block BOOL outputIsItalic = NO;
    __block BOOL outputIsStrikethrough = NO;
    __block BOOL outputIsLink = NO;
    __block NSString *outputLink; // current link
    __block NSString *previousSuffix = nil;

    __block BOOL didParseWord = NO;
    void(^parseBlock)(NSString *, NSRange, NSRange, BOOL *) = ^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        NSDictionary *attrs = [input attributesAtIndex:substringRange.location effectiveRange:NULL];
        BOOL isBold = [attrs[AshtonAttrFont][AshtonFontAttrTraitBold] boolValue];
        BOOL isItalic = [attrs[AshtonAttrFont][AshtonFontAttrTraitItalic] boolValue];
        BOOL isStrikethrough = (attrs[AshtonAttrStrikethrough] != nil);
        BOOL isLink = (attrs[AshtonAttrLink] != nil);

        NSUInteger prefixLocation = enclosingRange.location;
        NSUInteger prefixLength = substringRange.location - enclosingRange.location;
        NSUInteger suffixLocation = substringRange.location + substringRange.length;
        NSUInteger suffixLength = (enclosingRange.location + enclosingRange.length) - suffixLocation;
        NSString *suffix = nil, *prefix = nil;
        if (suffixLength > 0) suffix = [inputString substringWithRange:NSMakeRange(suffixLocation, suffixLength)];
        if (prefixLength > 0) prefix = [inputString substringWithRange:NSMakeRange(prefixLocation, prefixLength)];

        if (outputIsLink && !isLink) {
            if (outputIsBold) [output appendString:@"**"];
            if (outputIsItalic) [output appendString:@"*"];
            if (outputIsStrikethrough) [output appendString:@"~~"];
            [output appendFormat:@"](%@)", outputLink];
            if (outputIsBold && isBold) [output appendString:@"**"];
            if (outputIsItalic && isItalic) [output appendString:@"*"];
            if (outputIsStrikethrough && isStrikethrough) [output appendString:@"~~"];
            outputLink = nil;
        } else {
            if (outputIsBold && !isBold) [output appendString:@"**"];
            if (outputIsItalic && !isItalic) [output appendString:@"*"];
            if (outputIsStrikethrough && !isStrikethrough) [output appendString:@"~~"];
        }

        if (!outputIsLink && isLink) {
            outputLink = attrs[AshtonAttrLink];
            if (outputIsStrikethrough) [output appendString:@"~~"];
            if (outputIsBold) [output appendString:@"**"];
            if (outputIsItalic) [output appendString:@"*"];
            if (previousSuffix) [output appendString:previousSuffix];
            if (prefix) [output appendString:prefix];
            [output appendString:@"["];
            if (isStrikethrough) [output appendString:@"~~"];
            if (isBold) [output appendString:@"**"];
            if (isItalic) [output appendString:@"*"];
        } else {
            if (previousSuffix) [output appendString:previousSuffix];
            if (prefix) [output appendString:prefix];
            if (!outputIsStrikethrough && isStrikethrough) [output appendString:@"~~"];
            if (!outputIsBold && isBold) [output appendString:@"**"];
            if (!outputIsItalic && isItalic) [output appendString:@"*"];
        }
        [output appendString:substring];


        previousSuffix = suffix;
        outputIsBold = isBold;
        outputIsItalic = isItalic;
        outputIsStrikethrough = isStrikethrough;
        outputIsLink = isLink;

        didParseWord = YES;
    };

    [inputString enumerateSubstringsInRange:range options:NSStringEnumerationByWords usingBlock:parseBlock];
    // parse surrogate pairs instead
    if (!didParseWord) {
        [inputString enumerateSubstringsInRange:range options:NSStringEnumerationByComposedCharacterSequences usingBlock:parseBlock];
    }

    if (outputIsBold) [output appendString:@"**"];
    if (outputIsItalic) [output appendString:@"*"];
    if (outputIsStrikethrough) [output appendString:@"~~"];
    if (previousSuffix) [output appendString:previousSuffix];
    if (outputIsLink) [output appendFormat:@"](%@)", outputLink];
}

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
    if (input.length == 0) {
        return @"";
    }

#if TARGET_OS_IPHONE
    input = [[AshtonUIKit sharedInstance] intermediateRepresentationWithTargetRepresentation:input];
#else
    input = [[AshtonAppKit sharedInstance] intermediateRepresentationWithTargetRepresentation:input];
#endif

    NSString *inputString = input.string;
    NSMutableString *output = [NSMutableString stringWithCapacity:input.length*1.5];
    NSUInteger length = [input length];
    NSUInteger paraStart = 0, paraEnd = 0, contentsEnd = 0;
    NSRange paragraphRange;

    while (paraEnd < length) {
        [inputString getParagraphStart:&paraStart end:&paraEnd
                           contentsEnd:&contentsEnd forRange:NSMakeRange(paraEnd, 0)];
        paragraphRange = NSMakeRange(paraStart, contentsEnd - paraStart);
        writeMarkdownFragment(input, inputString, paragraphRange, output);
        if (paraEnd < length) {
            [output appendFormat:@"  \n"];
        }
    }
    return output;
}

@end
