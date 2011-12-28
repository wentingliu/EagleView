#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <ApplicationServices/ApplicationServices.h>
#import <Cocoa/Cocoa.h>

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    // To complete your generator please implement the function GeneratePreviewForURL in GeneratePreviewForURL.c
    @autoreleasepool {
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:(__bridge NSURL *)url];
        if (!image) {
            return noErr;
        }
        
        NSBitmapImageRep *firstRep = [[image representations] objectAtIndex:0];
        
        if ([firstRep colorSpace] == [NSColorSpace deviceRGBColorSpace]) {
            ColorSyncProfileRef profile = ColorSyncProfileCreateWithName(kColorSyncSRGBProfile);
            CFErrorRef error;
            NSData *profileData = (__bridge NSData *)ColorSyncProfileCopyData (profile, &error);
            
            // Set the ColorSync profile for the object
            [firstRep setProperty:NSImageColorSyncProfileData withValue:profileData];
        }
        
        // TODO: limit canvasSize to fit screen size        
        NSSize canvasSize = image.size;
        
        NSRect rect;
        rect.origin = CGPointMake(0, 0);
        rect.size = canvasSize;
        CGContextRef cgContext = QLPreviewRequestCreateContext(preview, *(CGSize *)&canvasSize, TRUE, NULL);
        if (cgContext) {
            NSGraphicsContext* context = [NSGraphicsContext graphicsContextWithGraphicsPort:(void *)cgContext flipped:YES];
            if(context) {
                //These two lines of code are just good safe programming...
                [NSGraphicsContext setCurrentContext:context];                
                [NSGraphicsContext saveGraphicsState];


                [firstRep drawInRect:rect];
//                [@"QuickLook is using EagleView" drawInRect:rect withAttributes:nil];
                
                //This line sets the context back to what it was when we're done
                [NSGraphicsContext restoreGraphicsState];
            }
            
            // When we are done with our drawing code QLPreviewRequestFlushContext() is called to flush the context
            QLPreviewRequestFlushContext(preview, cgContext);
            
            CFRelease(cgContext);
        }        
    }

    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}
