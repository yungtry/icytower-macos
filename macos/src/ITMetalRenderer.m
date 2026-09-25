#import "ITMetalRenderer.h"
#import <MetalKit/MetalKit.h>

#define NUM_FRAME_BUFFERS 3
#define VERTEX_BUFFER_CAPACITY (4 * 1024 * 1024) // 4 MB per frame buffer
#define BATCH_VERTEX_LIMIT 4096

typedef struct {
    matrix_float4x4 projectionMatrix;
} ITUniforms;

@interface ITMetalRenderer () {
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    id<MTLRenderPipelineState> _pipelineState;
    id<MTLSamplerState> _samplerState;
    
    id<MTLBuffer> _vertexBuffers[NUM_FRAME_BUFFERS];
    NSUInteger _currentBufferIndex;
    NSUInteger _bufferOffset;
    dispatch_semaphore_t _frameSemaphore;
    
    id<MTLTexture> _whiteTexture;
    
    id<MTLCommandBuffer> _currentCommandBuffer;
    id<MTLRenderCommandEncoder> _currentEncoder;
    id<MTLTexture> _currentTexture;
    
    ITVertex _vertexArray[BATCH_VERTEX_LIMIT];
    NSUInteger _vertexCount;
    ITUniforms _uniforms;
}
@end

@implementation ITMetalRenderer

+ (instancetype)sharedRenderer {
    static ITMetalRenderer *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[ITMetalRenderer alloc] init];
    });
    return shared;
}

- (id<MTLDevice>)device {
    return _device;
}

- (id<MTLCommandQueue>)commandQueue {
    return _commandQueue;
}

- (BOOL)setupWithDevice:(id<MTLDevice>)device pixelFormat:(MTLPixelFormat)pixelFormat {
    _device = device;
    _commandQueue = [_device newCommandQueue];
    _frameSemaphore = dispatch_semaphore_create(NUM_FRAME_BUFFERS);
    
    NSError *error = nil;
    id<MTLLibrary> library = [_device newDefaultLibrary];
    if (!library) {
        NSString *shaderSource = @""
        "#include <metal_stdlib>\n"
        "using namespace metal;\n"
        "struct ITVertex { float2 position [[attribute(0)]]; float2 texCoord [[attribute(1)]]; float4 color [[attribute(2)]]; };\n"
        "struct ITUniforms { float4x4 projectionMatrix; };\n"
        "struct RasterizerData { float4 position [[position]]; float2 texCoord; float4 color; };\n"
        "vertex RasterizerData it_vertex_shader(uint vertexID [[vertex_id]], constant ITVertex *vertices [[buffer(0)]], constant ITUniforms &uniforms [[buffer(1)]]) {\n"
        "    RasterizerData out;\n"
        "    out.position = uniforms.projectionMatrix * float4(vertices[vertexID].position, 0.0, 1.0);\n"
        "    out.texCoord = vertices[vertexID].texCoord;\n"
        "    out.color = vertices[vertexID].color;\n"
        "    return out;\n"
        "}\n"
        "fragment float4 it_fragment_shader(RasterizerData in [[stage_in]], texture2d<float> colorTexture [[texture(0)]], sampler textureSampler [[sampler(0)]]) {\n"
        "    float4 tex = colorTexture.sample(textureSampler, in.texCoord);\n"
        "    return tex * in.color;\n"
        "}\n";
        library = [_device newLibraryWithSource:shaderSource options:nil error:&error];
        if (!library) {
            NSLog(@"Failed to create shader library: %@", error);
            return NO;
        }
    }
    
    id<MTLFunction> vertexFunc = [library newFunctionWithName:@"it_vertex_shader"];
    id<MTLFunction> fragmentFunc = [library newFunctionWithName:@"it_fragment_shader"];
    
    MTLRenderPipelineDescriptor *pDesc = [[MTLRenderPipelineDescriptor alloc] init];
    pDesc.vertexFunction = vertexFunc;
    pDesc.fragmentFunction = fragmentFunc;
    pDesc.colorAttachments[0].pixelFormat = pixelFormat;
    
    pDesc.colorAttachments[0].blendingEnabled = YES;
    pDesc.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    pDesc.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
    pDesc.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    pDesc.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    pDesc.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorOne;
    pDesc.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pDesc error:&error];
    if (!_pipelineState) {
        NSLog(@"Failed to create pipeline state: %@", error);
        return NO;
    }
    
    MTLSamplerDescriptor *sDesc = [[MTLSamplerDescriptor alloc] init];
    sDesc.minFilter = MTLSamplerMinMagFilterNearest;
    sDesc.magFilter = MTLSamplerMinMagFilterNearest;
    sDesc.sAddressMode = MTLSamplerAddressModeClampToEdge;
    sDesc.tAddressMode = MTLSamplerAddressModeClampToEdge;
    _samplerState = [_device newSamplerStateWithDescriptor:sDesc];
    
    for (int i = 0; i < NUM_FRAME_BUFFERS; i++) {
        _vertexBuffers[i] = [_device newBufferWithLength:VERTEX_BUFFER_CAPACITY
                                                 options:MTLResourceStorageModeShared];
    }
    _currentBufferIndex = 0;
    _bufferOffset = 0;
    
    // 1x1 white texture
    MTLTextureDescriptor *tDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                     width:1
                                                                                    height:1
                                                                                 mipmapped:NO];
    _whiteTexture = [_device newTextureWithDescriptor:tDesc];
    uint32_t whitePixel = 0xFFFFFFFF;
    [_whiteTexture replaceRegion:MTLRegionMake2D(0, 0, 1, 1) mipmapLevel:0 withBytes:&whitePixel bytesPerRow:4];
    
    // Ortho matrix for 640x480 virtual canvas
    float left = 0.0f, right = 640.0f;
    float top = 0.0f, bottom = 480.0f;
    float near = -1.0f, far = 1.0f;
    
    _uniforms.projectionMatrix = (matrix_float4x4){
        .columns[0] = { 2.0f / (right - left), 0.0f, 0.0f, 0.0f },
        .columns[1] = { 0.0f, 2.0f / (top - bottom), 0.0f, 0.0f },
        .columns[2] = { 0.0f, 0.0f, 1.0f / (far - near), 0.0f },
        .columns[3] = { -(right + left) / (right - left), -(top + bottom) / (top - bottom), -near / (far - near), 1.0f }
    };
    
    return YES;
}

- (void)beginFrameWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                 renderPassDescriptor:(MTLRenderPassDescriptor *)renderPassDescriptor
                         drawableSize:(CGSize)drawableSize {
    dispatch_semaphore_wait(_frameSemaphore, DISPATCH_TIME_FOREVER);
    dispatch_semaphore_t sem = _frameSemaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> cb) {
        dispatch_semaphore_signal(sem);
    }];
    
    _currentCommandBuffer = commandBuffer;
    _currentBufferIndex = (_currentBufferIndex + 1) % NUM_FRAME_BUFFERS;
    _bufferOffset = 0;
    _vertexCount = 0;
    _currentTexture = nil;
    
    _currentEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [_currentEncoder setRenderPipelineState:_pipelineState];
    [_currentEncoder setFragmentSamplerState:_samplerState atIndex:0];
    [_currentEncoder setVertexBytes:&_uniforms length:sizeof(ITUniforms) atIndex:1];
    
    float scale = MIN(drawableSize.width / 640.0f, drawableSize.height / 480.0f);
    float vpW = floorf(640.0f * scale);
    float vpH = floorf(480.0f * scale);
    float vpX = floorf((drawableSize.width - vpW) * 0.5f);
    float vpY = floorf((drawableSize.height - vpH) * 0.5f);
    
    MTLViewport vp = { vpX, vpY, vpW, vpH, 0.0, 1.0 };
    [_currentEncoder setViewport:vp];
    
    MTLScissorRect scissor = { (NSUInteger)MAX(0.0f, vpX), (NSUInteger)MAX(0.0f, vpY), (NSUInteger)MAX(1.0f, vpW), (NSUInteger)MAX(1.0f, vpH) };
    [_currentEncoder setScissorRect:scissor];
}

- (void)flush {
    if (_vertexCount == 0 || !_currentEncoder || !_currentTexture) {
        return;
    }
    
    NSUInteger bytesToCopy = _vertexCount * sizeof(ITVertex);
    // Align to 256 bytes for Metal setVertexBuffer offset requirement
    NSUInteger alignedOffset = (_bufferOffset + 255) & ~255;
    
    if (alignedOffset + bytesToCopy > VERTEX_BUFFER_CAPACITY) {
        alignedOffset = 0; // Wrap around if capacity exceeded
    }
    
    id<MTLBuffer> curBuffer = _vertexBuffers[_currentBufferIndex];
    memcpy((uint8_t *)curBuffer.contents + alignedOffset, _vertexArray, bytesToCopy);
    
    [_currentEncoder setVertexBuffer:curBuffer offset:alignedOffset atIndex:0];
    [_currentEncoder setFragmentTexture:_currentTexture atIndex:0];
    [_currentEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_vertexCount];
    
    _bufferOffset = alignedOffset + bytesToCopy;
    _vertexCount = 0;
}

- (void)endFrame {
    [self flush];
    [_currentEncoder endEncoding];
    _currentEncoder = nil;
    _currentCommandBuffer = nil;
    _currentTexture = nil;
}

- (void)setTexture:(id<MTLTexture>)texture {
    if (_currentTexture != texture) {
        [self flush];
        _currentTexture = texture;
    }
}

- (id<MTLTexture>)getOrCreateTextureForBitmap:(ALLEGRO_BITMAP *)bitmap {
    if (!bitmap) return _whiteTexture;
    
    if (bitmap->metal_texture && !bitmap->is_texture_dirty) {
        return (__bridge id<MTLTexture>)bitmap->metal_texture;
    }
    
    if (bitmap->w <= 0 || bitmap->h <= 0 || !bitmap->pixels) {
        return _whiteTexture;
    }
    
    id<MTLTexture> texture = (__bridge id<MTLTexture>)bitmap->metal_texture;
    if (!texture || texture.width != bitmap->w || texture.height != bitmap->h) {
        MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                        width:bitmap->w
                                                                                       height:bitmap->h
                                                                                    mipmapped:NO];
        texture = [_device newTextureWithDescriptor:desc];
        bitmap->metal_texture = (void *)CFBridgingRetain(texture);
    }
    
    [texture replaceRegion:MTLRegionMake2D(0, 0, bitmap->w, bitmap->h)
               mipmapLevel:0
                 withBytes:bitmap->pixels
               bytesPerRow:bitmap->w * 4];
    
    bitmap->is_texture_dirty = false;
    return texture;
}

- (void)addQuadP0:(vector_float2)p0 uv0:(vector_float2)uv0
               p1:(vector_float2)p1 uv1:(vector_float2)uv1
               p2:(vector_float2)p2 uv2:(vector_float2)uv2
               p3:(vector_float2)p3 uv3:(vector_float2)uv3
            color:(vector_float4)color {
    if (_vertexCount + 6 > BATCH_VERTEX_LIMIT) {
        [self flush];
    }
    
    // Triangle 1: p0, p1, p2
    _vertexArray[_vertexCount++] = (ITVertex){ p0, uv0, color };
    _vertexArray[_vertexCount++] = (ITVertex){ p1, uv1, color };
    _vertexArray[_vertexCount++] = (ITVertex){ p2, uv2, color };
    
    // Triangle 2: p1, p3, p2
    _vertexArray[_vertexCount++] = (ITVertex){ p1, uv1, color };
    _vertexArray[_vertexCount++] = (ITVertex){ p3, uv3, color };
    _vertexArray[_vertexCount++] = (ITVertex){ p2, uv2, color };
}

- (void)drawBitmap:(ALLEGRO_BITMAP *)bitmap dx:(float)dx dy:(float)dy flags:(int)flags {
    if (!bitmap) return;
    [self drawScaledBitmap:bitmap sx:0 sy:0 sw:bitmap->w sh:bitmap->h dx:dx dy:dy dw:bitmap->w dh:bitmap->h flags:flags];
}

- (void)drawBitmapRegion:(ALLEGRO_BITMAP *)bitmap sx:(float)sx sy:(float)sy sw:(float)sw sh:(float)sh dx:(float)dx dy:(float)dy flags:(int)flags {
    [self drawScaledBitmap:bitmap sx:sx sy:sy sw:sw sh:sh dx:dx dy:dy dw:sw dh:sh flags:flags];
}

- (void)drawScaledBitmap:(ALLEGRO_BITMAP *)bitmap sx:(float)sx sy:(float)sy sw:(float)sw sh:(float)sh dx:(float)dx dy:(float)dy dw:(float)dw dh:(float)dh flags:(int)flags {
    if (!bitmap || bitmap->w <= 0 || bitmap->h <= 0) return;
    
    id<MTLTexture> tex = [self getOrCreateTextureForBitmap:bitmap];
    [self setTexture:tex];
    
    float u0 = sx / (float)bitmap->w;
    float v0 = sy / (float)bitmap->h;
    float u1 = (sx + sw) / (float)bitmap->w;
    float v1 = (sy + sh) / (float)bitmap->h;
    
    if (flags & ALLEGRO_FLIP_HORIZONTAL) {
        float tmp = u0; u0 = u1; u1 = tmp;
    }
    if (flags & ALLEGRO_FLIP_VERTICAL) {
        float tmp = v0; v0 = v1; v1 = tmp;
    }
    
    vector_float2 p0 = { dx, dy };
    vector_float2 p1 = { dx + dw, dy };
    vector_float2 p2 = { dx, dy + dh };
    vector_float2 p3 = { dx + dw, dy + dh };
    
    vector_float2 uv0 = { u0, v0 };
    vector_float2 uv1 = { u1, v0 };
    vector_float2 uv2 = { u0, v1 };
    vector_float2 uv3 = { u1, v1 };
    
    vector_float4 col = { 1.0f, 1.0f, 1.0f, 1.0f };
    [self addQuadP0:p0 uv0:uv0 p1:p1 uv1:uv1 p2:p2 uv2:uv2 p3:p3 uv3:uv3 color:col];
}

- (void)drawRotatedBitmap:(ALLEGRO_BITMAP *)bitmap cx:(float)cx cy:(float)cy dx:(float)dx dy:(float)dy angle:(float)angle flags:(int)flags {
    if (!bitmap) return;
    [self drawScaledRotatedBitmap:bitmap cx:cx cy:cy dx:dx dy:dy xscale:1.0f yscale:1.0f angle:angle flags:flags];
}

- (void)drawScaledRotatedBitmap:(ALLEGRO_BITMAP *)bitmap cx:(float)cx cy:(float)cy dx:(float)dx dy:(float)dy xscale:(float)xscale yscale:(float)yscale angle:(float)angle flags:(int)flags {
    if (!bitmap || bitmap->w <= 0 || bitmap->h <= 0) return;
    
    id<MTLTexture> tex = [self getOrCreateTextureForBitmap:bitmap];
    [self setTexture:tex];
    
    float w = bitmap->w * xscale;
    float h = bitmap->h * yscale;
    
    float cosA = cosf(angle);
    float sinA = sinf(angle);
    
    float x0 = -cx * xscale;
    float y0 = -cy * yscale;
    float x1 = x0 + w;
    float y1 = y0 + h;
    
    vector_float2 p0 = { dx + x0 * cosA - y0 * sinA, dy + x0 * sinA + y0 * cosA };
    vector_float2 p1 = { dx + x1 * cosA - y0 * sinA, dy + x1 * sinA + y0 * cosA };
    vector_float2 p2 = { dx + x0 * cosA - y1 * sinA, dy + x0 * sinA + y1 * cosA };
    vector_float2 p3 = { dx + x1 * cosA - y1 * sinA, dy + x1 * sinA + y1 * cosA };
    
    float u0 = 0.0f, v0 = 0.0f, u1 = 1.0f, v1 = 1.0f;
    if (flags & ALLEGRO_FLIP_HORIZONTAL) {
        float tmp = u0; u0 = u1; u1 = tmp;
    }
    if (flags & ALLEGRO_FLIP_VERTICAL) {
        float tmp = v0; v0 = v1; v1 = tmp;
    }
    
    vector_float2 uv0 = { u0, v0 };
    vector_float2 uv1 = { u1, v0 };
    vector_float2 uv2 = { u0, v1 };
    vector_float2 uv3 = { u1, v1 };
    
    vector_float4 col = { 1.0f, 1.0f, 1.0f, 1.0f };
    [self addQuadP0:p0 uv0:uv0 p1:p1 uv1:uv1 p2:p2 uv2:uv2 p3:p3 uv3:uv3 color:col];
}

- (void)drawFilledRectangleX1:(float)x1 y1:(float)y1 x2:(float)x2 y2:(float)y2 color:(ALLEGRO_COLOR)color {
    [self setTexture:_whiteTexture];
    
    vector_float2 p0 = { x1, y1 };
    vector_float2 p1 = { x2, y1 };
    vector_float2 p2 = { x1, y2 };
    vector_float2 p3 = { x2, y2 };
    
    vector_float2 uv0 = { 0, 0 }, uv1 = { 1, 0 }, uv2 = { 0, 1 }, uv3 = { 1, 1 };
    vector_float4 col = { color.r, color.g, color.b, color.a };
    
    [self addQuadP0:p0 uv0:uv0 p1:p1 uv1:uv1 p2:p2 uv2:uv2 p3:p3 uv3:uv3 color:col];
}

- (void)drawLineX1:(float)x1 y1:(float)y1 x2:(float)x2 y2:(float)y2 color:(ALLEGRO_COLOR)color thickness:(float)thickness {
    float dx = x2 - x1;
    float dy = y2 - y1;
    float len = sqrtf(dx * dx + dy * dy);
    if (len < 0.0001f) return;
    
    float nx = -dy / len * (thickness * 0.5f);
    float ny = dx / len * (thickness * 0.5f);
    
    [self setTexture:_whiteTexture];
    
    vector_float2 p0 = { x1 + nx, y1 + ny };
    vector_float2 p1 = { x2 + nx, y2 + ny };
    vector_float2 p2 = { x1 - nx, y1 - ny };
    vector_float2 p3 = { x2 - nx, y2 - ny };
    
    vector_float2 uv0 = { 0, 0 }, uv1 = { 1, 0 }, uv2 = { 0, 1 }, uv3 = { 1, 1 };
    vector_float4 col = { color.r, color.g, color.b, color.a };
    
    [self addQuadP0:p0 uv0:uv0 p1:p1 uv1:uv1 p2:p2 uv2:uv2 p3:p3 uv3:uv3 color:col];
}

@end
