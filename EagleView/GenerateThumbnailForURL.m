#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail);

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
    // To complete your generator please implement the function GenerateThumbnailForURL in GenerateThumbnailForURL.c
    @autoreleasepool {
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:(__bridge NSURL *)url];
        if (!image) {
            return noErr;
        }
        
        // TODO: should choose approiate rep according maxSize
        NSBitmapImageRep *firstRep = [[image representations] objectAtIndex:0];
        
        if ([firstRep colorSpace] == [NSColorSpace deviceRGBColorSpace]) {
            ColorSyncProfileRef profile = ColorSyncProfileCreateWithName(kColorSyncSRGBProfile);
            CFErrorRef error;
            NSData *profileData = (__bridge NSData *)ColorSyncProfileCopyData (profile, &error);
            
            // Set the ColorSync profile for the object
            [firstRep setProperty:NSImageColorSyncProfileData withValue:profileData];
        }
        
        // TODO: limit canvasSize to fit max size        
        NSSize canvasSize = image.size;
        
        NSRect rect;
        rect.origin = CGPointMake(0, 0);
        rect.size = canvasSize;
        CGContextRef cgContext = QLThumbnailRequestCreateContext(thumbnail, canvasSize, TRUE, NULL);
        if (cgContext) {
            NSGraphicsContext* context = [NSGraphicsContext graphicsContextWithGraphicsPort:(void *)cgContext flipped:YES];
            if(context) {
                //These two lines of code are just good safe programming...
                [NSGraphicsContext setCurrentContext:context];                
                [NSGraphicsContext saveGraphicsState];
                
                
                [firstRep drawInRect:rect];
                //                [@"QuickLook is using QLForWideGamut" drawInRect:rect withAttributes:nil];
                
                //This line sets the context back to what it was when we're done
                [NSGraphicsContext restoreGraphicsState];
            }
            
            // When we are done with our drawing code QLPreviewRequestFlushContext() is called to flush the context
            QLThumbnailRequestFlushContext(thumbnail, cgContext);
            
            CFRelease(cgContext);
        }        
    }
    
    return noErr;
}

void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail)
{
    // Implement only if supported
}
