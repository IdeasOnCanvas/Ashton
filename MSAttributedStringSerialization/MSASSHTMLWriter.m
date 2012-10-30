#import "MSASSHTMLWriter.h"
#import "MSASSUtils.h"

@interface MSASSHTMLWriter ()
@property (nonatomic, assign) MSHTMLWritingOptions options;
@property (nonatomic, strong) NSAttributedString *input;
@property (nonatomic, strong) NSString *output;
@end

@implementation MSASSHTMLWriter

- (id)initWithAttributedString:(NSAttributedString *)attributedString options:(MSHTMLWritingOptions)options {
    if (self = [super init]) {
        self.input = [attributedString copy];
        self.options = options;
    }
    return self;
}

- (NSString *)HTMLString {
    if (!self.output) [self createHTMLString];
    return self.output;
}

- (void)createHTMLString {
}

@end
