#import "MSASSHTMLWriter.h"
#import "MSASSUtils.h"

@interface MSASSHTMLWriter ()
@property (nonatomic, strong) NSAttributedString *input;
@property (nonatomic, strong) NSString *output;
@end

@implementation MSASSHTMLWriter

- (id)initWithAttributedString:(NSAttributedString *)attributedString {
    if (self = [super init]) {
        self.input = [attributedString copy];
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
