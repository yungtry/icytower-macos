#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <simd/simd.h>

#include "allegro5/allegro.h"

NS_ASSUME_NONNULL_BEGIN

typedef struct {
    vector_float2 position;
    vector_float2 texCoord;
    vector_float4 color;
} ITVertex;

@interface ITMetalRenderer : NSObject

@property (nonatomic, strong, readonly) id<MTLDevice> device;
@property (nonatomic, strong, readonly) id<MTLCommandQueue> commandQueue;

+ (instancetype)sharedRenderer;

- (BOOL)setupWithDevice:(id<MTLDevice>)device pixelFormat:(MTLPixelFormat)pixelFormat;

- (void)beginFrameWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                 renderPassDescriptor:(MTLRenderPassDescriptor *)renderPassDescriptor
                         drawableSize:(CGSize)drawableSize;

- (void)endFrame;

// 2D Draw Commands
- (void)drawBitmap:(ALLEGRO_BITMAP *)bitmap
                dx:(float)dx
                dy:(float)dy
             flags:(int)flags;

- (void)drawBitmapRegion:(ALLEGRO_BITMAP *)bitmap
                      sx:(float)sx
                      sy:(float)sy
                      sw:(float)sw
                      sh:(float)sh
                      dx:(float)dx
                      dy:(float)dy
                   flags:(int)flags;

- (void)drawScaledBitmap:(ALLEGRO_BITMAP *)bitmap
                      sx:(float)sx
                      sy:(float)sy
                      sw:(float)sw
                      sh:(float)sh
                      dx:(float)dx
                      dy:(float)dy
                      dw:(float)dw
                      dh:(float)dh
                   flags:(int)flags;

- (void)drawRotatedBitmap:(ALLEGRO_BITMAP *)bitmap
                       cx:(float)cx
                       cy:(float)cy
                       dx:(float)dx
                       dy:(float)dy
                    angle:(float)angle
                    flags:(int)flags;

- (void)drawScaledRotatedBitmap:(ALLEGRO_BITMAP *)bitmap
                             cx:(float)cx
                             cy:(float)cy
                             dx:(float)dx
                             dy:(float)dy
                         xscale:(float)xscale
                         yscale:(float)yscale
                          angle:(float)angle
                          flags:(int)flags;

- (void)drawFilledRectangleX1:(float)x1 y1:(float)y1 x2:(float)x2 y2:(float)y2 color:(ALLEGRO_COLOR)color;
- (void)drawLineX1:(float)x1 y1:(float)y1 x2:(float)x2 y2:(float)y2 color:(ALLEGRO_COLOR)color thickness:(float)thickness;

// Texture management
- (id<MTLTexture>)getOrCreateTextureForBitmap:(ALLEGRO_BITMAP *)bitmap;

@end

NS_ASSUME_NONNULL_END
