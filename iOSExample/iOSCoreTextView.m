#import "iOSCoreTextView.h"
#import <CoreText/CoreText.h>

@implementation iOSCoreTextView

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _attributedString = [[NSAttributedString alloc] init];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _attributedString = [[NSAttributedString alloc] init];
    }
    return self;
}

- (void)setAttributedString:(NSAttributedString *)attributedString {
    _attributedString = [attributedString copy];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();

	// flip the coordinate system
	CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	CGContextTranslateCTM(context, 0, self.bounds.size.height);
	CGContextScaleCTM(context, 1.0, -1.0);

    // Initialize a rectangular path.
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.bounds);

    // Create the framesetter with the attributed string.
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)(self.attributedString));

    // Create the frame and draw it into the graphics context
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter,
                                                CFRangeMake(0, 0), path, NULL);
    CTFrameDraw(frame, context);
    CFRelease(framesetter);
    CFRelease(path);
    CFRelease(frame);
}

@end
