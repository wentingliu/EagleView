//
//  GenerateThumbnailForURL.h
//  EagleView
//
//  Created by Wenting Liu on 12/28/11.
//  Copyright (c) 2011 D&O. All rights reserved.
//


#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <ApplicationServices/ApplicationServices.h>
#import <Cocoa/Cocoa.h>

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
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
        
        NSSize canvasSize = NSMakeSize([firstRep pixelsWide], [firstRep pixelsHigh]);
        
        NSRect rect;
        rect.origin = CGPointMake(0, 0);
        rect.size = canvasSize;
        CGContextRef cgContext = QLPreviewRequestCreateContext(preview, *(CGSize *)&canvasSize, TRUE, NULL);
        if (cgContext) {
            NSGraphicsContext* context = [NSGraphicsContext graphicsContextWithGraphicsPort:(void *)cgContext flipped:YES];
            if(context) {
                [NSGraphicsContext saveGraphicsState];
                [NSGraphicsContext setCurrentContext:context];

                [firstRep drawInRect:rect];
                
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
