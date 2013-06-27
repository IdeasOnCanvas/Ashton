#import "OSXCoreTextView.h"
#import <CoreText/CoreText.h>

@implementation OSXCoreTextView

- (void)setAttributedString:(NSAttributedString *)attributedString {
    _attributedString = attributedString;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    if (self.attributedString == nil) return;
    
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	CGContextSetTextMatrix(context, CGAffineTransformIdentity);

    // Initialize a rectangular path.
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.bounds);

    CFAttributedStringRef cfString = CFBridgingRetain(self.attributedString);
    // Create the framesetter with the attributed string.
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(cfString);

    // Create the frame and draw it into the graphics context
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter,
                                                CFRangeMake(0, 0), path, NULL);

    CTFrameDraw(frame, context);
    CFRelease(frame);
    CFRelease(cfString);
    CFRelease(framesetter);
    CFRelease(path);
}

@end
