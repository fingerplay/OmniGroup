// Copyright 2011-2013 The Omni Group. All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniAppKit/OATextAttachmentCell.h>
#import <OmniFoundation/OFXMLDocument.h>

#if defined(TARGET_OS_IPHONE) && TARGET_OS_IPHONE

#import <CoreGraphics/CoreGraphics.h>
#import <OmniBase/OBUtilities.h>
#import <OmniBase/rcsid.h>

RCS_ID("$Id$");

@implementation OATextAttachmentCell

@synthesize attachment = _nonretained_attachment;

- (void)drawWithFrame:(CGRect)cellFrame inView:(UIView *)controlView characterIndex:(NSUInteger)charIndex layoutManager:(NSLayoutManager *)layoutManager;
{
    OBRequestConcreteImplementation(self, _cmd);
}

- (CGSize)cellSize;
{
    OBRequestConcreteImplementation(self, _cmd);
    return CGSizeZero;
}

- (CGPoint)cellBaselineOffset
{
    return CGPointZero;
}

- (void)appendXMLForNonDefaultCellInformation:(OFXMLDocument *)doc;
{
    // Nothing; subclasses should override this to write any extra attributes
}

@end

#endif

@implementation OATextAttachmentCell (OATextAttachmentCellXML)

+ (void)appendXMLForNonDefaultCellInformation:(OFXMLDocument *)doc image:(id)image;
{
    if (image) {
#if defined(TARGET_OS_IPHONE) && TARGET_OS_IPHONE
        CGImageRef imageRef = (CGImageRef)image;
        CGSize size = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
#else
        CGSize size = [(NSImage *)image size];
#endif
        OBASSERT(size.width >= FLT_MIN && size.width <= FLT_MAX);
        OBASSERT(size.height >= FLT_MIN && size.height <= FLT_MAX);
        [doc setAttribute:@"width" real:(float)size.width];
        [doc setAttribute:@"height" real:(float)size.height];
    }
}

@end
