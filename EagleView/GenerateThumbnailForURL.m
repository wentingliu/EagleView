//
//  GenerateThumbnailForURL.m
//  EagleView
//
//  Created by Wenting Liu on 12/28/11.
//  Copyright (c) 2011 D&O. All rights reserved.
//

#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail);

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
    @autoreleasepool {
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:(__bridge NSURL *)url];
        if (!image) {
            return noErr;
        }
        
        // find imageRep which has closed size to maxSize
        __block NSBitmapImageRep *imageRep;
        __block CGFloat closedSize; 
        [[image representations] enumerateObjectsUsingBlock:^(NSBitmapImageRep *obj, NSUInteger idx, BOOL *stop) {
            CGFloat (^getDifferenceOnSize)(NSBitmapImageRep *) = ^(NSBitmapImageRep *rep) {
                CGFloat heightDiff = fabs([rep pixelsHigh] - maxSize.width);
                CGFloat widthDiff = fabs([rep pixelsWide] - maxSize.height);
                CGFloat difference = heightDiff - widthDiff > 0 ? heightDiff : widthDiff;
                return difference;
            };
            if (imageRep == nil) {
                imageRep = obj;
                closedSize = getDifferenceOnSize(obj);
            } else {
                CGFloat diffSize = getDifferenceOnSize(obj);
                if (diffSize < closedSize) {
                    imageRep = obj;
                    closedSize = diffSize;
                }
            }
        }];
        
        if ([imageRep colorSpace] == [NSColorSpace deviceRGBColorSpace]) {
            ColorSyncProfileRef profile = ColorSyncProfileCreateWithName(kColorSyncSRGBProfile);
            CFErrorRef error;
            NSData *profileData = (__bridge NSData *)ColorSyncProfileCopyData (profile, &error);
            
            // Set the ColorSync profile for the object
            [imageRep setProperty:NSImageColorSyncProfileData withValue:profileData];
        }
           
        NSSize canvasSize = image.size;
        
        NSRect rect;
        rect.origin = CGPointMake(0, 0);
        rect.size = canvasSize;
        CGContextRef cgContext = QLThumbnailRequestCreateContext(thumbnail, canvasSize, TRUE, NULL);
        if (cgContext) {
            NSGraphicsContext* context = [NSGraphicsContext graphicsContextWithGraphicsPort:(void *)cgContext flipped:YES];
            if(context) {
                //These two lines of code are just good safe programming...
                [NSGraphicsContext saveGraphicsState];
                [NSGraphicsContext setCurrentContext:context];
                
                [imageRep drawInRect:rect];
//                [@"EagleView" drawInRect:rect withAttributes:nil];
                
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
