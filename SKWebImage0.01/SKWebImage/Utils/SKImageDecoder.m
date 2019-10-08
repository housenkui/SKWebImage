//
//  SKImageDecoder.m
//  SKWebImage0.01
//
//  Created by 侯森魁 on 2019/9/28.
//  Copyright © 2019 侯森魁. All rights reserved.
//

#import "SKImageDecoder.h"
#define DECOMPRESSED_IMAGE_KEY @"decompressedImage"
#define DECODE_INFO_KEY @"decodeInfo"

#define IMAGE_KEY @"image"
#define DELEGATE_KEY @"delegate"
#define USER_INFO_KEY @"userInfo"

@implementation SKImageDecoder

- (void)notifyDelegateOnMainThreadWithInfo:(NSDictionary *)dict
{
    NSDictionary *decodeInfo = [dict objectForKey:DECODE_INFO_KEY];
    UIImage *decodeImage = [dict objectForKey:DECOMPRESSED_IMAGE_KEY];
    
    id <SKWebImageDecoderDelegate> delegate = [decodeInfo objectForKey:DELEGATE_KEY];
    NSDictionary *userInfo = [decodeInfo objectForKey:USER_INFO_KEY];
    [delegate imageDecoder:self didFinishDecodingImage:decodeImage userInfo:userInfo];
}
- (void)decodeImageWithInfo:(NSDictionary *)decodeInfo
{
    UIImage *image = [decodeInfo objectForKey:IMAGE_KEY];
    
    UIImage *decompressedImage = [UIImage decodedImageWithImage:image];
    if (!decompressedImage) {
        decompressedImage = image;
    }
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          decompressedImage,DECOMPRESSED_IMAGE_KEY,
                          decodeInfo,DECODE_INFO_KEY, nil];
    [self performSelectorOnMainThread:@selector(notifyDelegateOnMainThreadWithInfo:) withObject:dict waitUntilDone:NO];
}

- (instancetype)init
{
    if (self = [super init]) {
        
        //Initialization code here.
        imageDecodingQueue = [[NSOperationQueue alloc]init];
    }
    return self;
}

- (void)decodeImage:(UIImage *)image withDelegate:(id<SKWebImageDecoderDelegate>)delegate userInfo:(nullable NSDictionary *)userInfo
{
    NSDictionary *decodeInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                image,IMAGE_KEY,
                                delegate,DELEGATE_KEY,
                                userInfo,USER_INFO_KEY,nil];
    NSOperation *operation = [[NSInvocationOperation alloc]initWithTarget:self selector:@selector(decodeImageWithInfo:) object:decodeInfo];
    [imageDecodingQueue addOperation:operation];
}

+ (SKImageDecoder *)sharedImageDecoder
{
    static SKImageDecoder * sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SKImageDecoder alloc]init];
    });
    return sharedInstance;
}
@end

@implementation UIImage (ForceDecode)
+ (UIImage *)decodedImageWithImage:(UIImage *)image
{
    //一张10M的图片在子线程解码的时间 134.863us(毫秒)
    NSLog(@"decodedImageWithImage start %@",[NSThread currentThread]);
    NSLog(@"-----%@---- %@-",[NSThread currentThread], [[NSRunLoop currentRunLoop] currentMode]);

    CGImageRef imageRef =  image.CGImage;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 CGImageGetWidth(imageRef),
                                                 CGImageGetHeight(imageRef),
                                                 8,
                                                 // Just always return width * 4 will be enough
                                                 CGImageGetWidth(imageRef) * 4,
                                                 //System only supports RGB,set explicitly
                                                 colorSpace,
                                                 //Make system don't need to do extra conversion when displayed.
                                                 // NOTE: here we remove the alpha channel for performance. Most of the time, images loaded
                                                 //       from the network are jpeg with no alpha channel. As a TODO, finding a way to detect
                                                 //       if alpha channel is necessary would be nice.

                                                 alphaInfo | kCGBitmapByteOrder32Little);
    CGColorSpaceRelease(colorSpace);
    if (!context) {
        return nil;
    }
    CGRect rect = (CGRect) {CGPointZero,{CGImageGetWidth(imageRef),CGImageGetHeight(imageRef)}};
    CGContextDrawImage(context, rect, imageRef);
    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    UIImage *decompressedImage = [[UIImage alloc]initWithCGImage:decompressedImageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(decompressedImageRef);
    NSLog(@"decodedImageWithImage end %@",[NSThread currentThread]);

    return decompressedImage;
}


@end
