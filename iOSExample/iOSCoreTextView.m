#import "iOSCoreTextView.h"
#import <CoreText/CoreText.h>

@implementation iOSCoreTextView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    NSAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"asdqwe"];
	CGContextRef context = UIGraphicsGetCurrentContext();

	// flip the coordinate system
	CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	CGContextTranslateCTM(context, 0, self.bounds.size.height);
	CGContextScaleCTM(context, 1.0, -1.0);

	// draw
	CTLineRef line = CTLineCreateWithAttributedString(CFBridgingRetain(string));
	CGContextSetTextPosition(context, 10.0, 10.0);
	CTLineDraw(line, context);
    
	// clean up
	CFRelease(line);
}

@end
