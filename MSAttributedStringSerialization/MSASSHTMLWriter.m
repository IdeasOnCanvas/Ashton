#import "MSASSHTMLWriter.h"

@implementation MSASSHTMLWriter {
    NSAttributedString *_input;
    NSString *_output;
}

- (id)initWithAttributedString:(NSAttributedString *)attributedString {
    if (self == [super init]) {
        _input = [attributedString copy];
    }
    return self;
}

- (NSString *)HTMLString {
    if (!_output) [self createHTMLString];
    return _output;
}

- (void)createHTMLString {

}

@end
