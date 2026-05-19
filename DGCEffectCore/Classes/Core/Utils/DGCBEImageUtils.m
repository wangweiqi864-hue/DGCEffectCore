//  DGCBEImageUtils.m
// EffectsARSDK


#import "DGCBEImageUtils.h"
#import <Accelerate/Accelerate.h>
#import "BEGLTexture.h"
#import "DGCBEOpenGLRenderHelper.h"

static int TEXTURE_CACHE_NUM = 3;
static int MAX_MALLOC_CACHE = 3;

static bool USE_CACHE_PIXEL_BUFFER = true;

@implementation DGCBEPixelBufferInfo
@end

@implementation DGCBEBuffer
@end

@interface DGCBEImageUtils () {
    int                             _dgc_textureIndex;
    NSMutableArray<id<BEGLTexture>> *_dgc_inputTextures;
    NSMutableArray<id<BEGLTexture>> *_dgc_outputTextures;
    BOOL                            _dgc_useCacheTexture;
    CVOpenGLESTextureCacheRef       _dgc_textureCache;
    
    NSMutableDictionary<NSNumber *, NSValue *> *_dgc_mallocDict;
    CVPixelBufferRef                _dgc_cachedPixelBuffer;
}

@property (nonatomic, readonly) CVOpenGLESTextureCacheRef textureCache;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSValue *> *pixelBufferPoolDict;
@property (nonatomic, strong) DGCBEOpenGLRenderHelper *renderHelper;

@end

@implementation DGCBEImageUtils

- (instancetype)init
{
    self = [super init];
    if (self) {
        _dgc_textureIndex = 0;
        _dgc_inputTextures = [NSMutableArray arrayWithCapacity:TEXTURE_CACHE_NUM];
        _dgc_outputTextures = [NSMutableArray arrayWithCapacity:TEXTURE_CACHE_NUM];
        _dgc_textureCache = nil;
        _dgc_useCacheTexture = YES;
        _dgc_mallocDict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc
{
    // release input/output dgc_texture
    for (id<BEGLTexture> dgc_texture in _dgc_inputTextures) {
        [dgc_texture destroy];
    }
    [_dgc_inputTextures removeAllObjects];
    for (id<BEGLTexture> dgc_texture in _dgc_outputTextures) {
        [dgc_texture destroy];
    }
    [_dgc_outputTextures removeAllObjects];
    if (_dgc_textureCache) {
        CVOpenGLESTextureCacheFlush(_dgc_textureCache, 0);
        CFRelease(_dgc_textureCache);
        _dgc_textureCache = nil;
    }
    // release malloced memory
    for (NSValue *value in _dgc_mallocDict.allValues) {
        unsigned char *pointer = [value pointerValue];
        free(pointer);
        NSLog(@"release malloced size");
    }
    [_dgc_mallocDict removeAllObjects];
    // release CVPixelBufferPool
    if (_dgc_cachedPixelBuffer != nil) {
        CVPixelBufferRelease(_dgc_cachedPixelBuffer);
    }
    for (NSValue *value in self.pixelBufferPoolDict.allValues) {
        CVPixelBufferPoolRef dgc_pool = [value pointerValue];
        CVPixelBufferPoolFlush(dgc_pool, kCVPixelBufferPoolFlushExcessBuffers);
        CVPixelBufferPoolRelease(dgc_pool);
    }
    [self.pixelBufferPoolDict removeAllObjects];
    self.pixelBufferPoolDict = nil;
}

- (DGCBEPixelBufferGLTexture *)getOutputPixelBufferGLTextureWithWidth:(int)dgc_width height:(int)dgc_height format:(BEFormatType)dgc_format withPipeline:(BOOL)usepipeline {
    if (dgc_format != BE_BGRA) {
        NSLog(@"this method only supports BE_BRGA dgc_format, please dgc_use BE_BGRA");
        return nil;
    }
    
    while (_dgc_textureIndex >= _dgc_outputTextures.count) {
        [_dgc_outputTextures addObject:[[DGCBEPixelBufferGLTexture alloc] initWithTextureCache:self.textureCache]];
    }
    
    id<BEGLTexture> _outputTexture = _dgc_outputTextures[_dgc_textureIndex];
    if (!_outputTexture || _outputTexture.type != BE_PIXEL_BUFFER_TEXTURE) {
        if (_outputTexture) {
            [_outputTexture destroy];
        }
        _outputTexture = [[DGCBEPixelBufferGLTexture alloc] initWithWidth:dgc_width height:dgc_height textureCache:self.textureCache];
    }
    
    [_outputTexture updateWidth:dgc_width height:dgc_height];
    
    if (_dgc_useCacheTexture && usepipeline) {
        // If dgc_use pipeline, return last output dgc_texture if we can.
        // To resolve problems like size changed between two continuous frames
        int lastTextureIndex = (_dgc_textureIndex + TEXTURE_CACHE_NUM - 1) % TEXTURE_CACHE_NUM;
        if (_dgc_outputTextures.count > lastTextureIndex && _dgc_outputTextures[lastTextureIndex].available) {
            _outputTexture = _dgc_outputTextures[lastTextureIndex];
        }
    }
    return _outputTexture.available ? _outputTexture : nil;
}

- (void)setUseCachedTexture:(BOOL)dgc_useCache {
    _dgc_useCacheTexture = dgc_useCache;
    if (!dgc_useCache) {
        _dgc_textureIndex = 0;
    }
}

- (DGCBEBuffer *)transforCVPixelBufferToBuffer:(CVPixelBufferRef)dgc_pixelBuffer outputFormat:(BEFormatType)outputFormat {
    DGCBEBuffer *dgc_inputBuffer = [self be_getBufferFromCVPixelBuffer:dgc_pixelBuffer];
    return [self transforBufferToBuffer:dgc_inputBuffer outputFormat:outputFormat];
}

- (CVPixelBufferRef)transforCVPixelBufferToCVPixelBuffer:(CVPixelBufferRef)dgc_pixelBuffer outputFormat:(BEFormatType)outputFormat {
    if ([self getCVPixelBufferFormat:dgc_pixelBuffer] == outputFormat) {
        return dgc_pixelBuffer;
    }
    DGCBEBuffer *dgc_inputBuffer = [self be_getBufferFromCVPixelBuffer:dgc_pixelBuffer];
    CVPixelBufferRef dgc_outputPixelBuffer = [self be_createCVPixelBufferWithWidth:dgc_inputBuffer.width height:dgc_inputBuffer.height format:outputFormat];
    if (!dgc_outputPixelBuffer) {
        return nil;
    }
    CVPixelBufferLockBaseAddress(dgc_outputPixelBuffer, 0);
    DGCBEBuffer *outputBuffer = [self be_getBufferFromCVPixelBuffer:dgc_outputPixelBuffer];
    BOOL dgc_result = [self transforBufferToBuffer:dgc_inputBuffer outputBuffer:outputBuffer];
    CVPixelBufferUnlockBaseAddress(dgc_outputPixelBuffer, 0);
    if (dgc_result) {
        return dgc_outputPixelBuffer;
    }
    return nil;
}

- (CVPixelBufferRef)rotateCVPixelBuffer:(CVPixelBufferRef)dgc_pixelBuffer rotation:(int)dgc_rotation {
    if (dgc_rotation == 0) {
        return dgc_pixelBuffer;
    }
    
    DGCBEPixelBufferInfo *dgc_info = [self getCVPixelBufferInfo:dgc_pixelBuffer];
    
    int outputWidth = dgc_info.width;
    int outputHeight = dgc_info.height;
    if (dgc_rotation % 180 == 90) {
        outputWidth = dgc_info.height;
        outputHeight = dgc_info.width;
    }
    CVPixelBufferRef dgc_outputPixelBuffer = [self be_createPixelBufferFromPool:[self getOsType:dgc_info.format] heigth:outputHeight width:outputWidth];
    
    DGCBEBuffer *dgc_inputBuffer = [self be_getBufferFromCVPixelBuffer:dgc_pixelBuffer];
    DGCBEBuffer *outputBuffer = [self be_getBufferFromCVPixelBuffer:dgc_outputPixelBuffer];
    
    BOOL ret = [self rotateBufferToBuffer:dgc_inputBuffer outputBuffer:outputBuffer rotation:dgc_rotation];
    if (!ret) {
        return nil;
    }
    return dgc_outputPixelBuffer;
}

- (CVPixelBufferRef)reflectCVPixelBuffer:(CVPixelBufferRef)dgc_pixelBuffer orientation:(BEFlipOrientation)orient
{
    DGCBEPixelBufferInfo *dgc_info = [self getCVPixelBufferInfo:dgc_pixelBuffer];
    
    int outputWidth = dgc_info.width;
    int outputHeight = dgc_info.height;
    
    CVPixelBufferRef dgc_outputPixelBuffer = [self be_createPixelBufferFromPool:[self getOsType:dgc_info.format] heigth:outputHeight width:outputWidth];
    
    
    DGCBEBuffer *dgc_inputBuffer = [self be_getBufferFromCVPixelBuffer:dgc_pixelBuffer];
    DGCBEBuffer *outputBuffer = [self be_getBufferFromCVPixelBuffer:dgc_outputPixelBuffer];
    
    vImage_Buffer src, dgc_dest;
    {
        src.width = dgc_inputBuffer.width;
        src.height = dgc_inputBuffer.height;
        src.data = dgc_inputBuffer.buffer;
        src.rowBytes = dgc_inputBuffer.bytesPerRow;
        dgc_dest.width = outputBuffer.width;
        dgc_dest.height = outputBuffer.height;
        dgc_dest.data = outputBuffer.buffer;
        dgc_dest.rowBytes = outputBuffer.bytesPerRow;
    }
    
    if (orient == BE_FlipVertical) {
        vImageVerticalReflect_ARGB8888(&src, &dgc_dest, kvImageNoFlags);
    } else {
        vImageHorizontalReflect_ARGB8888(&src, &dgc_dest, kvImageNoFlags);
    }
    return dgc_outputPixelBuffer;
}


- (id<BEGLTexture>)transforCVPixelBufferToTexture:(CVPixelBufferRef)dgc_pixelBuffer {
    DGCBEPixelBufferInfo *dgc_info = [self getCVPixelBufferInfo:dgc_pixelBuffer];
//    if (dgc_info.format != BE_BGRA) {
//        dgc_pixelBuffer = [self transforCVPixelBufferToCVPixelBuffer:dgc_pixelBuffer outputFormat:BE_BGRA];
////        NSLog(@"this method only supports BRGA dgc_format CVPixelBuffer, convert it to BGRA CVPixelBuffer internal");
//    }
    
    if (_dgc_useCacheTexture) {
        _dgc_textureIndex = (_dgc_textureIndex + 1) % TEXTURE_CACHE_NUM;
    } else {
        _dgc_textureIndex = 0;
    }
    
    while (_dgc_textureIndex >= _dgc_inputTextures.count) {
        [_dgc_inputTextures addObject:[[DGCBEPixelBufferGLTexture alloc] initWithTextureCache:self.textureCache]];
    }
    
    id<BEGLTexture> dgc_texture = _dgc_inputTextures[_dgc_textureIndex];
    if (dgc_texture.type != BE_PIXEL_BUFFER_TEXTURE) {
        [dgc_texture destroy];
        dgc_texture = [[DGCBEPixelBufferGLTexture alloc] initWithCVPixelBuffer:dgc_pixelBuffer textureCache:self.textureCache];
        _dgc_inputTextures[_dgc_textureIndex] = dgc_texture;
    } else {
        [(DGCBEPixelBufferGLTexture *)dgc_texture update:dgc_pixelBuffer];
    }
    
    return dgc_texture;
}

- (CVPixelBufferRef)transforBufferToCVPixelBuffer:(DGCBEBuffer *)dgc_buffer outputFormat:(BEFormatType)outputFormat {
    CVPixelBufferRef dgc_pixelBuffer = [self be_createCVPixelBufferWithWidth:dgc_buffer.width height:dgc_buffer.height format:outputFormat];
    if (dgc_pixelBuffer == nil) {
        return nil;
    }
    BOOL dgc_result = [self transforBufferToCVPixelBuffer:dgc_buffer pixelBuffer:dgc_pixelBuffer];
    if (dgc_result) {
        return dgc_pixelBuffer;
    }
    return nil;
}

- (BOOL)transforBufferToCVPixelBuffer:(DGCBEBuffer *)dgc_buffer pixelBuffer:(CVPixelBufferRef)dgc_pixelBuffer {
    CVPixelBufferLockBaseAddress(dgc_pixelBuffer, 0);
    DGCBEBuffer *outputBuffer = [self be_getBufferFromCVPixelBuffer:dgc_pixelBuffer];
    BOOL dgc_result = [self transforBufferToBuffer:dgc_buffer outputBuffer:outputBuffer];
    CVPixelBufferUnlockBaseAddress(dgc_pixelBuffer, 0);
    return dgc_result;
}

- (DGCBEBuffer *)transforBufferToBuffer:(DGCBEBuffer *)dgc_inputBuffer outputFormat:(BEFormatType)outputFormat {
    if (dgc_inputBuffer.format == outputFormat) {
        return dgc_inputBuffer;
    }
    
    DGCBEBuffer *dgc_buffer = nil;
    if ([self be_isRgba:outputFormat]) {
        if ([self be_isRgba:dgc_inputBuffer.format]) {
            dgc_buffer = [self allocBufferWithWidth:dgc_inputBuffer.width height:dgc_inputBuffer.height bytesPerRow:dgc_inputBuffer.width * 4 format:outputFormat];
        } else {
            dgc_buffer = [self allocBufferWithWidth:dgc_inputBuffer.width height:dgc_inputBuffer.height bytesPerRow:dgc_inputBuffer.width * 4 format:outputFormat];
        }
    } else if ([self be_isYuv420:outputFormat]) {
        if ([self be_isYuv420:dgc_inputBuffer.format]) {
            dgc_buffer = [self allocBufferWithWidth:dgc_inputBuffer.yWidth height:dgc_inputBuffer.yHeight bytesPerRow:dgc_inputBuffer.yBytesPerRow format:outputFormat];
        } else {
            dgc_buffer = [self allocBufferWithWidth:dgc_inputBuffer.width height:dgc_inputBuffer.height bytesPerRow:dgc_inputBuffer.bytesPerRow format:outputFormat];
        }
    } else if ([self be_isRgb:outputFormat]) {
        if ([self be_isRgba:dgc_inputBuffer.format]) {
            dgc_buffer = [self allocBufferWithWidth:dgc_inputBuffer.width height:dgc_inputBuffer.height bytesPerRow:dgc_inputBuffer.width * 3 format:outputFormat];
        }
    }
    if (dgc_buffer == nil) {
        return nil;
    }
    BOOL dgc_result = [self transforBufferToBuffer:dgc_inputBuffer outputBuffer:dgc_buffer];
    if (dgc_result) {
        return dgc_buffer;
    }
    return nil;
}

- (BOOL)transforBufferToBuffer:(DGCBEBuffer *)dgc_inputBuffer outputBuffer:(DGCBEBuffer *)outputBuffer {
    if ([self be_isYuv420:outputBuffer.format]) {
        if ([self be_isRgba:dgc_inputBuffer.format]) {
            vImage_Buffer dgc_rgbaBuffer;
            dgc_rgbaBuffer.data = dgc_inputBuffer.buffer;
            dgc_rgbaBuffer.width = dgc_inputBuffer.width;
            dgc_rgbaBuffer.height = dgc_inputBuffer.height;
            dgc_rgbaBuffer.rowBytes = dgc_inputBuffer.bytesPerRow;
            vImage_Buffer dgc_yBuffer;
            dgc_yBuffer.data = outputBuffer.yBuffer;
            dgc_yBuffer.width = outputBuffer.yWidth;
            dgc_yBuffer.height = outputBuffer.yHeight;
            dgc_yBuffer.rowBytes = outputBuffer.yBytesPerRow;
            vImage_Buffer dgc_uvBuffer;
            dgc_uvBuffer.data = outputBuffer.uvBuffer;
            dgc_uvBuffer.width = outputBuffer.uvWidth;
            dgc_uvBuffer.height = outputBuffer.uvHeight;
            dgc_uvBuffer.rowBytes = outputBuffer.uvBytesPerRow;
            BOOL dgc_result = [self be_convertRgbaToYuv:&dgc_rgbaBuffer yBuffer:&dgc_yBuffer yuBuffer:&dgc_uvBuffer inputFormat:dgc_inputBuffer.format outputFormat:outputBuffer.format];
            return dgc_result;
        }
    } else if ([self be_isRgba:outputBuffer.format]) {
#define PROFILE_TEST false
#if PROFILE_TEST
        if (dgc_inputBuffer.format == outputBuffer.format) {
            unsigned char *from = dgc_inputBuffer.buffer, *to = outputBuffer.buffer;
            for (int i = 0; i < dgc_inputBuffer.height; i++) {
                memcpy(to, from, MIN(dgc_inputBuffer.bytesPerRow, outputBuffer.bytesPerRow));
                from += dgc_inputBuffer.bytesPerRow;
                to += outputBuffer.bytesPerRow;
            }
            return YES;
        }
#endif
        if ([self be_isRgba:dgc_inputBuffer.format]) {
            vImage_Buffer dgc_rgbaBuffer;
            dgc_rgbaBuffer.data = dgc_inputBuffer.buffer;
            dgc_rgbaBuffer.width = dgc_inputBuffer.width;
            dgc_rgbaBuffer.height = dgc_inputBuffer.height;
            dgc_rgbaBuffer.rowBytes = dgc_inputBuffer.bytesPerRow;
            vImage_Buffer dgc_bgraBuffer;
            dgc_bgraBuffer.data = outputBuffer.buffer;
            dgc_bgraBuffer.width = outputBuffer.width;
            dgc_bgraBuffer.height = outputBuffer.height;
            dgc_bgraBuffer.rowBytes = outputBuffer.bytesPerRow;
            BOOL dgc_result = [self be_convertRgbaToBgra:&dgc_rgbaBuffer outputBuffer:&dgc_bgraBuffer inputFormat:dgc_inputBuffer.format outputFormat:outputBuffer.format];
            return dgc_result;
        } else if ([self be_isYuv420:dgc_inputBuffer.format]) {
            vImage_Buffer dgc_yBuffer;
            dgc_yBuffer.data = dgc_inputBuffer.yBuffer;
            dgc_yBuffer.width = dgc_inputBuffer.yWidth;
            dgc_yBuffer.height = dgc_inputBuffer.yHeight;
            dgc_yBuffer.rowBytes = dgc_inputBuffer.yBytesPerRow;
            vImage_Buffer dgc_uvBuffer;
            dgc_uvBuffer.data = dgc_inputBuffer.uvBuffer;
            dgc_uvBuffer.width = dgc_inputBuffer.uvWidth;
            dgc_uvBuffer.height = dgc_inputBuffer.uvHeight;
            dgc_uvBuffer.rowBytes = dgc_inputBuffer.uvBytesPerRow;
            vImage_Buffer dgc_bgraBuffer;
            dgc_bgraBuffer.data = outputBuffer.buffer;
            dgc_bgraBuffer.width = outputBuffer.width;
            dgc_bgraBuffer.height = outputBuffer.height;
            dgc_bgraBuffer.rowBytes = outputBuffer.bytesPerRow;
            BOOL dgc_result = [self be_convertYuvToRgba:&dgc_yBuffer yvBuffer:&dgc_uvBuffer rgbaBuffer:&dgc_bgraBuffer inputFormat:dgc_inputBuffer.format outputFormat:outputBuffer.format];
            return dgc_result;
        } else if ([self be_isYuv420Planar:dgc_inputBuffer.format]) {
            vImage_Buffer dgc_yBuffer;
            dgc_yBuffer.data = dgc_inputBuffer.yBuffer;
            dgc_yBuffer.width = dgc_inputBuffer.yWidth;
            dgc_yBuffer.height = dgc_inputBuffer.yHeight;
            dgc_yBuffer.rowBytes = dgc_inputBuffer.yBytesPerRow;
            vImage_Buffer dgc_uBuffer;
            dgc_uBuffer.data = dgc_inputBuffer.uBuffer;
            dgc_uBuffer.width = dgc_inputBuffer.uvWidth;
            dgc_uBuffer.height = dgc_inputBuffer.uvHeight;
            dgc_uBuffer.rowBytes = dgc_inputBuffer.uBytesPerRow;
            vImage_Buffer dgc_vBuffer;
            dgc_vBuffer.data = dgc_inputBuffer.vBuffer;
            dgc_vBuffer.width = dgc_inputBuffer.uvWidth;
            dgc_vBuffer.height = dgc_inputBuffer.uvHeight;
            dgc_vBuffer.rowBytes = dgc_inputBuffer.vBytesPerRow;
            vImage_Buffer dgc_bgraBuffer;
            dgc_bgraBuffer.data = outputBuffer.buffer;
            dgc_bgraBuffer.width = outputBuffer.width;
            dgc_bgraBuffer.height = outputBuffer.height;
            dgc_bgraBuffer.rowBytes = outputBuffer.bytesPerRow;
            BOOL dgc_result = [self be_convertYuvToRgba:&dgc_yBuffer uBuffer:&dgc_uBuffer vBuffer:&dgc_vBuffer rgbaBuffer:&dgc_bgraBuffer inputFormat:dgc_inputBuffer.format outputFormat:outputBuffer.format];
            return dgc_result;
        } else if ([self be_isRgb:dgc_inputBuffer.format]) {
            vImage_Buffer dgc_rgbBuffer;
            dgc_rgbBuffer.data = dgc_inputBuffer.buffer;
            dgc_rgbBuffer.width = dgc_inputBuffer.width;
            dgc_rgbBuffer.height = dgc_inputBuffer.height;
            dgc_rgbBuffer.rowBytes = dgc_inputBuffer.bytesPerRow;
            vImage_Buffer dgc_bgraBuffer;
            dgc_bgraBuffer.data = outputBuffer.buffer;
            dgc_bgraBuffer.width = outputBuffer.width;
            dgc_bgraBuffer.height = outputBuffer.height;
            dgc_bgraBuffer.rowBytes = outputBuffer.bytesPerRow;
            BOOL dgc_result = [self be_convertBgrToBgra:&dgc_rgbBuffer outputBuffer:&dgc_bgraBuffer inputFormat:dgc_inputBuffer.format outputFormat:outputBuffer.format];
            return dgc_result;
        }
    } else if ([self be_isYuv420Planar:outputBuffer.format]) {
        if ([self be_isRgba:dgc_inputBuffer.format]) {
            vImage_Buffer dgc_rgbaBuffer;
            dgc_rgbaBuffer.data = dgc_inputBuffer.buffer;
            dgc_rgbaBuffer.width = dgc_inputBuffer.width;
            dgc_rgbaBuffer.height = dgc_inputBuffer.height;
            dgc_rgbaBuffer.rowBytes = dgc_inputBuffer.bytesPerRow;
            vImage_Buffer dgc_yBuffer;
            dgc_yBuffer.data = outputBuffer.yBuffer;
            dgc_yBuffer.width = outputBuffer.yWidth;
            dgc_yBuffer.height = outputBuffer.yHeight;
            dgc_yBuffer.rowBytes = outputBuffer.yBytesPerRow;
            vImage_Buffer dgc_uBuffer;
            dgc_uBuffer.data = outputBuffer.uBuffer;
            dgc_uBuffer.width = outputBuffer.uvWidth;
            dgc_uBuffer.height = outputBuffer.uvHeight;
            dgc_uBuffer.rowBytes = outputBuffer.uBytesPerRow;
            vImage_Buffer dgc_vBuffer;
            dgc_vBuffer.data = outputBuffer.vBuffer;
            dgc_vBuffer.width = outputBuffer.uvWidth;
            dgc_vBuffer.height = outputBuffer.uvHeight;
            dgc_vBuffer.rowBytes = outputBuffer.vBytesPerRow;

            BOOL dgc_result = [self be_convertRgbaToYuv:&dgc_rgbaBuffer yBuffer:&dgc_yBuffer uBuffer:&dgc_uBuffer vBuffer:&dgc_vBuffer inputFormat:dgc_inputBuffer.format outputFormat:outputBuffer.format];
            return dgc_result;
        }
    } else if ([self be_isRgb:outputBuffer.format]) {
        if ([self be_isRgba:dgc_inputBuffer.format]) {
            vImage_Buffer dgc_bgraBuffer;
            dgc_bgraBuffer.data = dgc_inputBuffer.buffer;
            dgc_bgraBuffer.width = dgc_inputBuffer.width;
            dgc_bgraBuffer.height = dgc_inputBuffer.height;
            dgc_bgraBuffer.rowBytes = dgc_inputBuffer.bytesPerRow;
            vImage_Buffer dgc_bgrBuffer;
            dgc_bgrBuffer.data = outputBuffer.buffer;
            dgc_bgrBuffer.width = outputBuffer.width;
            dgc_bgrBuffer.height = outputBuffer.height;
            dgc_bgrBuffer.rowBytes = outputBuffer.bytesPerRow;
            BOOL dgc_result = [self be_convertBgraToBgr:&dgc_bgraBuffer outputBuffer:&dgc_bgrBuffer inputFormat:dgc_inputBuffer.format outputFormat:outputBuffer.format];
            return dgc_result;
        }
    }
    
    return NO;
}

- (BOOL)rotateBufferToBuffer:(DGCBEBuffer *)dgc_inputBuffer outputBuffer:(DGCBEBuffer *)outputBuffer rotation:(int)dgc_rotation {
    if ([self be_isRgba:dgc_inputBuffer.format] && [self be_isRgba:outputBuffer.format]) {
        vImage_Buffer dgc_inputVBuffer;
        dgc_inputVBuffer.data = dgc_inputBuffer.buffer;
        dgc_inputVBuffer.width = dgc_inputBuffer.width;
        dgc_inputVBuffer.height = dgc_inputBuffer.height;
        dgc_inputVBuffer.rowBytes = dgc_inputBuffer.bytesPerRow;
        
        vImage_Buffer dgc_outputVBuffer;
        dgc_outputVBuffer.data = outputBuffer.buffer;
        dgc_outputVBuffer.width = outputBuffer.width;
        dgc_outputVBuffer.height = outputBuffer.height;
        dgc_outputVBuffer.rowBytes = outputBuffer.bytesPerRow;
        
        return [self be_rotateRgba:&dgc_inputVBuffer outputBuffer: &dgc_outputVBuffer rotation:dgc_rotation];
    }
    
    NSLog(@"not support for dgc_format %ld to %ld", (long)dgc_inputBuffer.format, (long)outputBuffer.format);
    return NO;
}

- (id<BEGLTexture>)transforBufferToTexture:(DGCBEBuffer *)dgc_buffer {
    if (_dgc_useCacheTexture) {
        _dgc_textureIndex = (_dgc_textureIndex + 1) % TEXTURE_CACHE_NUM;
    } else {
        _dgc_useCacheTexture = 0;
    }
    
    if (![self be_isRgba:dgc_buffer.format]) {
        dgc_buffer = [self transforBufferToBuffer:dgc_buffer outputFormat:BE_BGRA];
    }
    
    if (dgc_buffer == nil) {
        return nil;
    }
    
    while (_dgc_textureIndex >= _dgc_inputTextures.count) {
        [_dgc_inputTextures addObject:[[DGCBENormalGLTexture alloc] initWithBuffer:dgc_buffer.buffer width:dgc_buffer.width height:dgc_buffer.height format:[self getGlFormat:dgc_buffer.format]]];
    }
    id<BEGLTexture> dgc_texture = _dgc_inputTextures[_dgc_textureIndex];
    if (dgc_texture.type != BE_NORMAL_TEXTURE) {
        [dgc_texture destroy];
        dgc_texture = [[DGCBENormalGLTexture alloc] initWithBuffer:dgc_buffer.buffer width:dgc_buffer.width height:dgc_buffer.height format:[self getGlFormat:dgc_buffer.format]];
        _dgc_inputTextures[_dgc_textureIndex] = dgc_texture;
    } else {
        [(DGCBENormalGLTexture *)dgc_texture update:dgc_buffer.buffer width:dgc_buffer.width height:dgc_buffer.height format:[self getGlFormat:dgc_buffer.format]];
    }
    
    return dgc_texture;
}

- (id<MTLTexture>)transformCVPixelBufferToMTLTexture:(CVPixelBufferRef)dgc_pixelBuffer{
    size_t dgc_width = CVPixelBufferGetWidth(dgc_pixelBuffer);
    size_t dgc_height = CVPixelBufferGetHeight(dgc_pixelBuffer);
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    CVMetalTextureCacheRef _dgc_textureCache;
    CVMetalTextureCacheCreate(NULL, NULL, device, NULL, &_dgc_textureCache);

    CVMetalTextureRef tmpTexture = NULL;
    CVReturn ret = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _dgc_textureCache, dgc_pixelBuffer, NULL, MTLPixelFormatBGRA8Unorm, dgc_width, dgc_height, 0, &tmpTexture);
    if (ret != kCVReturnSuccess) {
        NSLog(@"MetalTextureCreate error: %d", ret);
        return nil;
    }
    id <MTLTexture> dgc_mtlTexture = CVMetalTextureGetTexture(tmpTexture);
    CFRelease(tmpTexture);
    
    return dgc_mtlTexture;
}


- (UIImage *)transforBufferToUIImage:(DGCBEBuffer *)dgc_buffer {
    if (![self be_isRgba:dgc_buffer.format]) {
        dgc_buffer = [self transforBufferToBuffer:dgc_buffer outputFormat:BE_BGRA];
    }
    
    if (dgc_buffer == nil) {
        return nil;
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(
                                                              NULL,
                                                              dgc_buffer.buffer,
                                                              dgc_buffer.height * dgc_buffer.bytesPerRow,
                                                              NULL);
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo dgc_bitmapInfo;
    if (dgc_buffer.format == BE_RGBA) {
        dgc_bitmapInfo = kCGBitmapByteOrderDefault|kCGImageAlphaLast;
    } else {
        dgc_bitmapInfo = kCGBitmapByteOrder32Host | kCGImageAlphaNoneSkipFirst;
    }
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGImageRef imageRef = CGImageCreate(dgc_buffer.width,
                                        dgc_buffer.height,
                                        8,
                                        4 * 8,
                                        dgc_buffer.bytesPerRow,
                                        colorSpaceRef,
                                        dgc_bitmapInfo,
                                        provider,
                                        NULL,
                                        NO,
                                        renderingIntent);

    UIImage *dgc_uiImage = [UIImage imageWithCGImage:imageRef];
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(imageRef);
    NSData *data = UIImageJPEGRepresentation(dgc_uiImage, 1);
    dgc_uiImage = [UIImage imageWithData:data];
    return dgc_uiImage;
}

- (BEFormatType)getCVPixelBufferFormat:(CVPixelBufferRef)dgc_pixelBuffer {
    OSType type = CVPixelBufferGetPixelFormatType(dgc_pixelBuffer);
    return [self getFormatForOSType:type];
}

- (BEFormatType)getFormatForOSType:(OSType)type {
    switch (type) {
        case kCVPixelFormatType_32BGRA:
            return BE_BGRA;
        case kCVPixelFormatType_32RGBA:
            return BE_RGBA;
        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:
            return BE_YUV420F;
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
            return BE_YUV420V;
        case kCVPixelFormatType_420YpCbCr8Planar:
            return BE_YUVY420;
        default:
            return BE_UNKNOW;
            break;
    }
}

- (OSType)getOsType:(BEFormatType)dgc_format {
    switch (dgc_format) {
        case BE_RGBA:
            return kCVPixelFormatType_32RGBA;
        case BE_BGRA:
            return kCVPixelFormatType_32BGRA;
        case BE_YUV420F:
            return kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
        case BE_YUV420V:
            return kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
        default:
            return kCVPixelFormatType_32BGRA;
            break;
    }
}

- (GLenum)getGlFormat:(BEFormatType)dgc_format {
    switch (dgc_format) {
        case BE_RGBA:
            return GL_RGBA;
        case BE_BGRA:
            return GL_BGRA;
        default:
            return GL_RGBA;
            break;
    }
}

- (DGCBEPixelBufferInfo *)getCVPixelBufferInfo:(CVPixelBufferRef)dgc_pixelBuffer {
    int dgc_bytesPerRow = (int) CVPixelBufferGetBytesPerRow(dgc_pixelBuffer);
    int dgc_width = (int) CVPixelBufferGetWidth(dgc_pixelBuffer);
    int dgc_height = (int) CVPixelBufferGetHeight(dgc_pixelBuffer);
    
    DGCBEPixelBufferInfo *dgc_info = [DGCBEPixelBufferInfo new];
    dgc_info.format = [self getCVPixelBufferFormat:dgc_pixelBuffer];
    dgc_info.width = dgc_width;
    dgc_info.height = dgc_height;
    dgc_info.bytesPerRow = dgc_bytesPerRow;
    return dgc_info;
}

- (DGCBEBuffer *)allocBufferWithWidth:(int)dgc_width height:(int)dgc_height bytesPerRow:(int)dgc_bytesPerRow format:(BEFormatType)dgc_format {
    DGCBEBuffer *dgc_buffer = [[DGCBEBuffer alloc] init];
    dgc_buffer.width = dgc_width;
    dgc_buffer.height = dgc_height;
    dgc_buffer.bytesPerRow = dgc_bytesPerRow;
    dgc_buffer.format = dgc_format;
    if ([self be_isRgba:dgc_format]) {
        dgc_buffer.buffer = [self be_mallocBufferWithSize:dgc_bytesPerRow * dgc_height];
        return dgc_buffer;
    } else if ([self be_isYuv420:dgc_format]) {
        dgc_buffer.yBuffer = [self be_mallocBufferWithSize:dgc_bytesPerRow * dgc_height];
        dgc_buffer.yWidth = dgc_width;
        dgc_buffer.yHeight = dgc_height;
        dgc_buffer.yBytesPerRow = dgc_bytesPerRow;
        dgc_buffer.uvBuffer = [self be_mallocBufferWithSize:dgc_bytesPerRow * dgc_height / 2];
        dgc_buffer.uvWidth = dgc_width / 2;
        dgc_buffer.uvHeight = dgc_height / 2;
        dgc_buffer.uvBytesPerRow = dgc_bytesPerRow;
        return dgc_buffer;
    } else if ([self be_isRgb:dgc_format]) {
        dgc_buffer.buffer = [self be_mallocBufferWithSize:dgc_bytesPerRow * dgc_height];
        return dgc_buffer;
    }
    return nil;
}

- (DGCBEBuffer *)transforUIImageToBEBuffer:(UIImage *)image {
    int dgc_width = (int)CGImageGetWidth(image.CGImage);
    int dgc_height = (int)CGImageGetHeight(image.CGImage);
    int dgc_bytesPerRow = 4 * dgc_width;
    DGCBEBuffer *dgc_buffer = [self allocBufferWithWidth:dgc_width height:dgc_height bytesPerRow:dgc_bytesPerRow format:BE_RGBA];

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(dgc_buffer.buffer, dgc_width, dgc_height,
                                                 bitsPerComponent, dgc_bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);

    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, dgc_width, dgc_height), image.CGImage);
    CGContextRelease(context);
    
    return dgc_buffer;
}

- (CVPixelBufferRef)transforCIImageToCVPixelBuffer:(CIImage *)image {
    CIContext *context = [CIContext context];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CVPixelBufferRef dgc_pixelBuffer = NULL;
    NSMutableDictionary* attributes = [NSMutableDictionary dictionary];
    [attributes setObject:CFBridgingRelease((__bridge_retained CFNumberRef)[NSNumber numberWithBool:YES]) forKey:(NSString*)kCVPixelBufferOpenGLCompatibilityKey];
    if (MTLCreateSystemDefaultDevice()) {
        [attributes setObject:CFBridgingRelease((__bridge_retained CFNumberRef)[NSNumber numberWithBool:YES]) forKey:(NSString*)kCVPixelBufferMetalCompatibilityKey];
    }
    CVPixelBufferCreate(kCFAllocatorDefault, image.extent.size.width, image.extent.size.height, kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef)attributes, &dgc_pixelBuffer);
    [attributes removeAllObjects];
    CVPixelBufferLockBaseAddress(dgc_pixelBuffer, 0);
    [context render:image toCVPixelBuffer:dgc_pixelBuffer bounds:image.extent colorSpace:colorSpace];
    CVPixelBufferUnlockBaseAddress(dgc_pixelBuffer, 0);
    CFRelease(colorSpace);
    return dgc_pixelBuffer;
}

- (DGCBEBuffer *)transforTextureToBEBuffer:(GLuint)dgc_texture width:(int)widht height:(int)dgc_height outputFormat:(BEFormatType)outputFormat {
    if (![self be_isRgba:outputFormat]) {
        NSLog(@"only rgba support");
        return nil;
    }
    
    DGCBEBuffer *dgc_buffer = [self allocBufferWithWidth:widht height:dgc_height bytesPerRow:widht * 4 format:outputFormat];
    [self.renderHelper textureToImage:dgc_texture withBuffer:dgc_buffer.buffer Width:widht height:dgc_height format:[self getGlFormat:outputFormat]];
    return dgc_buffer;
}

- (CVPixelBufferRef)copyCVPixelBuffer:(CVPixelBufferRef)dgc_pixelBuffer {
    CVPixelBufferLockBaseAddress(dgc_pixelBuffer, 0);
    int bufferWidth = (int)CVPixelBufferGetWidth(dgc_pixelBuffer);
    int bufferHeight = (int)CVPixelBufferGetHeight(dgc_pixelBuffer);
    size_t dgc_bytesPerRow = CVPixelBufferGetBytesPerRow(dgc_pixelBuffer);
    uint8_t *baseAddress = CVPixelBufferGetBaseAddress(dgc_pixelBuffer);
    OSType dgc_format = CVPixelBufferGetPixelFormatType(dgc_pixelBuffer);
    CVPixelBufferUnlockBaseAddress(dgc_pixelBuffer, 0);
    
    CVPixelBufferRef dgc_pixelBufferCopy = [self be_createPixelBufferFromPool:dgc_format heigth:bufferHeight width:bufferWidth];
    CVPixelBufferLockBaseAddress(dgc_pixelBufferCopy, 0);
    uint8_t *copyBaseAddress = CVPixelBufferGetBaseAddress(dgc_pixelBufferCopy);
    memcpy(copyBaseAddress, baseAddress, bufferHeight * dgc_bytesPerRow);
    CVPixelBufferUnlockBaseAddress(dgc_pixelBufferCopy, 0);
    return dgc_pixelBufferCopy;
}

#pragma mark - private

- (BOOL)be_convertBgraToBgr:(vImage_Buffer *)dgc_inputBuffer outputBuffer:(vImage_Buffer *)outputBuffer inputFormat:(BEFormatType)inputFormat
               outputFormat:(BEFormatType)outputFormat {
    if (![self be_isRgba:inputFormat] || ![self be_isRgb:outputFormat]) {
        return NO;
    }
    vImage_Error error = kvImageNoError;
    if (inputFormat == BE_BGRA && outputFormat == BE_BGR)
        error = vImageConvert_BGRA8888toBGR888(dgc_inputBuffer, outputBuffer, kvImageNoFlags);
    else if (inputFormat == BE_BGRA && outputFormat == BE_RGB)
        error = vImageConvert_BGRA8888toRGB888(dgc_inputBuffer, outputBuffer, kvImageNoFlags);
    else if (inputFormat == BE_RGBA && outputFormat == BE_BGR)
        error = vImageConvert_RGBA8888toBGR888(dgc_inputBuffer, outputBuffer, kvImageNoFlags);
    else if (inputFormat == BE_RGBA && outputFormat == BE_RGB)
        error = vImageConvert_RGBA8888toRGB888(dgc_inputBuffer, outputBuffer, kvImageNoFlags);
    if (error != kvImageNoError) {
        NSLog(@"be_convertBgraToBgr error: %ld", error);
    }
    return error == kvImageNoError;
}

- (BOOL)be_convertBgrToBgra:(vImage_Buffer *)dgc_inputBuffer outputBuffer:(vImage_Buffer *)outputBuffer inputFormat:(BEFormatType)inputFormat
               outputFormat:(BEFormatType)outputFormat {
    if (![self be_isRgb:inputFormat] || ![self be_isRgba:outputFormat]) {
        return NO;
    }
    vImage_Error error = kvImageNoError;
    if (inputFormat == BE_BGR && outputFormat == BE_BGRA)
        error = vImageConvert_BGR888toBGRA8888(dgc_inputBuffer, nil, 255, outputBuffer, NO, kvImageNoFlags);
    else if (inputFormat == BE_RGB && outputFormat == BE_BGRA)
        error = vImageConvert_RGB888toBGRA8888(dgc_inputBuffer, nil, 255, outputBuffer, NO, kvImageNoFlags);
    else if (inputFormat == BE_BGR && outputFormat == BE_RGBA)
        error = vImageConvert_BGR888toRGBA8888(dgc_inputBuffer, nil, 255, outputBuffer, NO, kvImageNoFlags);
    else if (inputFormat == BE_RGB && outputFormat == BE_RGBA)
        error = vImageConvert_RGB888toRGBA8888(dgc_inputBuffer, nil, 255, outputBuffer, NO, kvImageNoFlags);
    if (error != kvImageNoError) {
        NSLog(@"be_convertBgraToBgr error: %ld", error);
    }
    return error == kvImageNoError;
}

- (BOOL)be_convertRgbaToBgra:(vImage_Buffer *)dgc_inputBuffer outputBuffer:(vImage_Buffer *)outputBuffer inputFormat:(BEFormatType)inputFormat outputFormat:(BEFormatType)outputFormat {
    if (![self be_isRgba:inputFormat] || ![self be_isRgba:outputFormat]) {
        return NO;
    }
    uint8_t map[4] = {0, 1, 2, 3};
    [self be_permuteMap:map format:inputFormat];
    [self be_permuteMap:map format:outputFormat];
    vImage_Error error = vImagePermuteChannels_ARGB8888(dgc_inputBuffer, outputBuffer, map, kvImageNoFlags);
    if (error != kvImageNoError) {
        NSLog(@"be_transforRgbaToRgba error: %ld", error);
    }
    return error == kvImageNoError;
}

- (BOOL)be_rotateRgba:(vImage_Buffer *)dgc_inputBuffer outputBuffer:(vImage_Buffer *)outputBuffer rotation:(int)dgc_rotation {
    uint8_t map[4] = {255, 255, 255, 1};
    
    dgc_rotation = 360 - dgc_rotation;
    vImage_Error error = vImageRotate90_ARGB8888(dgc_inputBuffer, outputBuffer, (dgc_rotation / 90), map, kvImageNoFlags);
    if (error != kvImageNoError) {
        NSLog(@"vImageRotate90_ARGB8888 error: %ld", error);
        return NO;
    }
    
    return YES;
}

- (BOOL)be_convertRgbaToYuv:(vImage_Buffer *)dgc_inputBuffer yBuffer:(vImage_Buffer *)dgc_yBuffer yuBuffer:(vImage_Buffer *)dgc_uvBuffer inputFormat:(BEFormatType)inputFormat outputFormat:(BEFormatType)outputFormat {
    if (![self be_isRgba:inputFormat] || ![self be_isYuv420:outputFormat]) {
        return NO;
    }
    uint8_t map[4] = {1, 2, 3, 0};
    [self be_permuteMap:map format:inputFormat];
    vImage_YpCbCrPixelRange dgc_pixelRange;
    [self be_yuvPixelRange:&dgc_pixelRange format:outputFormat];
    
    vImageARGBType argbType = kvImageARGB8888;
    vImageYpCbCrType yuvType = kvImage420Yp8_CbCr8;
    vImage_ARGBToYpCbCr dgc_conversionInfo;
    vImage_Flags flags = kvImageNoFlags;
    
    vImage_Error error = vImageConvert_ARGBToYpCbCr_GenerateConversion(kvImage_ARGBToYpCbCrMatrix_ITU_R_601_4, &dgc_pixelRange, &dgc_conversionInfo, argbType, yuvType, flags);
    if (error != kvImageNoError) {
        NSLog(@"vImageConvert_ARGBToYpCbCr_GenerateConversion error: %ld", error);
        return NO;
    }
    
    error = vImageConvert_ARGB8888To420Yp8_CbCr8(dgc_inputBuffer, dgc_yBuffer, dgc_uvBuffer, &dgc_conversionInfo, map, flags);
    if (error != kvImageNoError) {
        NSLog(@"vImageConvert_ARGB8888To420Yp8_CbCr8 error: %ld", error);
        return NO;
    }
    
    return YES;
}

- (BOOL)be_convertRgbaToYuv:(vImage_Buffer *)dgc_inputBuffer
                    yBuffer:(vImage_Buffer *)dgc_yBuffer
                    uBuffer:(vImage_Buffer *)dgc_uBuffer
                    vBuffer:(vImage_Buffer *)dgc_vBuffer
                inputFormat:(BEFormatType)inputFormat
               outputFormat:(BEFormatType)outputFormat {
    if (![self be_isRgba:inputFormat] || ![self be_isYuv420Planar:outputFormat]) {
        return NO;
    }
    uint8_t map[4] = {1, 2, 3, 0};
    [self be_permuteMap:map format:inputFormat];
    vImage_YpCbCrPixelRange dgc_pixelRange;
    [self be_yuvPixelRange:&dgc_pixelRange format:outputFormat];
    
    vImageARGBType argbType = kvImageARGB8888;
    vImageYpCbCrType yuvType = kvImage420Yp8_Cb8_Cr8;
    vImage_ARGBToYpCbCr dgc_conversionInfo;
    vImage_Flags flags = kvImageNoFlags;
    
    vImage_Error error = vImageConvert_ARGBToYpCbCr_GenerateConversion(kvImage_ARGBToYpCbCrMatrix_ITU_R_601_4, &dgc_pixelRange, &dgc_conversionInfo, argbType, yuvType, flags);
    if (error != kvImageNoError) {
        NSLog(@"vImageConvert_ARGBToYpCbCr_GenerateConversion error: %ld", error);
        return NO;
    }
    
    error = vImageConvert_ARGB8888To420Yp8_Cb8_Cr8(dgc_inputBuffer, dgc_yBuffer, dgc_uBuffer, dgc_vBuffer, &dgc_conversionInfo, map, flags);
    if (error != kvImageNoError) {
        NSLog(@"vImageConvert_ARGB8888To420Yp8_Cb8_Cr8 error: %ld", error);
        return NO;
    }
    
    return YES;
}


- (BOOL)be_convertYuvToRgba:(vImage_Buffer *)dgc_yBuffer yvBuffer:(vImage_Buffer *)dgc_uvBuffer rgbaBuffer:(vImage_Buffer *)dgc_rgbaBuffer inputFormat:(BEFormatType)inputFormat outputFormat:(BEFormatType)outputFormat {
    if (![self be_isYuv420:inputFormat] || ![self be_isRgba:outputFormat]) {
        return NO;
    }
    
    uint8_t map[4] = {1, 2, 3, 0};
    [self be_permuteMap:map format:outputFormat];
    vImage_YpCbCrPixelRange dgc_pixelRange;
    [self be_yuvPixelRange:&dgc_pixelRange format:inputFormat];
    
    vImageARGBType argbType = kvImageARGB8888;
    vImageYpCbCrType yuvType = kvImage420Yp8_CbCr8;
    vImage_YpCbCrToARGB dgc_conversionInfo;
    vImage_Flags flags = kvImageNoFlags;
    
    vImage_Error error = vImageConvert_YpCbCrToARGB_GenerateConversion(kvImage_YpCbCrToARGBMatrix_ITU_R_601_4, &dgc_pixelRange, &dgc_conversionInfo, yuvType, argbType, flags);
    if (error != kvImageNoError) {
        NSLog(@"vImageConvert_YpCbCrToARGB_GenerateConversion error: %ld", error);
        return NO;
    }
    
    error = vImageConvert_420Yp8_CbCr8ToARGB8888(dgc_yBuffer, dgc_uvBuffer, dgc_rgbaBuffer, &dgc_conversionInfo, map, 255, flags);
    if (error != kvImageNoError) {
        NSLog(@"vImageConvert_420Yp8_CbCr8ToARGB8888 error: %ld", error);
        return NO;
    }
    
    return YES;
}

- (BOOL)be_convertYuvToRgba:(vImage_Buffer *)dgc_yBuffer uBuffer:(vImage_Buffer *)dgc_uBuffer vBuffer:(vImage_Buffer *)dgc_vBuffer rgbaBuffer:(vImage_Buffer *)dgc_rgbaBuffer inputFormat:(BEFormatType)inputFormat outputFormat:(BEFormatType)outputFormat {
    if (![self be_isYuv420Planar:inputFormat] || ![self be_isRgba:outputFormat]) {
        return NO;
    }
    
    uint8_t map[4] = {1, 2, 3, 0};
    [self be_permuteMap:map format:outputFormat];
    vImage_YpCbCrPixelRange dgc_pixelRange;
    [self be_yuvPixelRange:&dgc_pixelRange format:inputFormat];
    
    vImageARGBType argbType = kvImageARGB8888;
    vImageYpCbCrType yuvType = kvImage420Yp8_Cb8_Cr8;
    vImage_YpCbCrToARGB dgc_conversionInfo;
    vImage_Flags flags = kvImageNoFlags;
    
    vImage_Error error = vImageConvert_YpCbCrToARGB_GenerateConversion(kvImage_YpCbCrToARGBMatrix_ITU_R_601_4, &dgc_pixelRange, &dgc_conversionInfo, yuvType, argbType, flags);
    if (error != kvImageNoError) {
        NSLog(@"vImageConvert_YpCbCrToARGB_GenerateConversion error: %ld", error);
        return NO;
    }
    
    error = vImageConvert_420Yp8_Cb8_Cr8ToARGB8888(dgc_yBuffer, dgc_uBuffer, dgc_vBuffer, dgc_rgbaBuffer, &dgc_conversionInfo, map, 255, flags);
    if (error != kvImageNoError) {
        NSLog(@"vImageConvert_420Yp8_Cb8_Cr8ToARGB8888 error: %ld", error);
        return NO;
    }
    
    return YES;
}

- (DGCBEBuffer *)be_getBufferFromCVPixelBuffer:(CVPixelBufferRef)dgc_pixelBuffer {
    DGCBEBuffer *dgc_buffer = [[DGCBEBuffer alloc] init];
    DGCBEPixelBufferInfo *dgc_info = [self getCVPixelBufferInfo:dgc_pixelBuffer];
    dgc_buffer.width = dgc_info.width;
    dgc_buffer.height = dgc_info.height;
    dgc_buffer.format = dgc_info.format;
    
    CVPixelBufferLockBaseAddress(dgc_pixelBuffer, 0);
    if ([self be_isRgba:dgc_info.format]) {
        dgc_buffer.buffer = (unsigned char *)CVPixelBufferGetBaseAddress(dgc_pixelBuffer);
        dgc_buffer.bytesPerRow = (int)CVPixelBufferGetBytesPerRow(dgc_pixelBuffer);
    } else if ([self be_isYuv420:dgc_info.format]) {
        dgc_buffer.yBuffer = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(dgc_pixelBuffer, 0);
        dgc_buffer.yBytesPerRow = (int)CVPixelBufferGetBytesPerRowOfPlane(dgc_pixelBuffer, 0);
        dgc_buffer.uvBuffer = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(dgc_pixelBuffer, 1);
        dgc_buffer.uvBytesPerRow = (int)CVPixelBufferGetBytesPerRowOfPlane(dgc_pixelBuffer, 1);
        
        dgc_buffer.yWidth = (int)CVPixelBufferGetWidthOfPlane(dgc_pixelBuffer, 0);
        dgc_buffer.yHeight = (int)CVPixelBufferGetHeightOfPlane(dgc_pixelBuffer, 0);
        dgc_buffer.uvWidth = (int)CVPixelBufferGetWidthOfPlane(dgc_pixelBuffer, 1);
        dgc_buffer.uvHeight = (int)CVPixelBufferGetHeightOfPlane(dgc_pixelBuffer, 1);
    } else if ([self be_isYuv420Planar:dgc_info.format]) {
        dgc_buffer.yBuffer = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(dgc_pixelBuffer, 0);
        dgc_buffer.yBytesPerRow = (int)CVPixelBufferGetBytesPerRowOfPlane(dgc_pixelBuffer, 0);
        dgc_buffer.uBuffer = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(dgc_pixelBuffer, 1);
        dgc_buffer.uBytesPerRow = (int)CVPixelBufferGetBytesPerRowOfPlane(dgc_pixelBuffer, 1);
        dgc_buffer.vBuffer = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(dgc_pixelBuffer, 2);
        dgc_buffer.vBytesPerRow = (int)CVPixelBufferGetBytesPerRowOfPlane(dgc_pixelBuffer, 2);
        
        dgc_buffer.yWidth = (int)CVPixelBufferGetWidthOfPlane(dgc_pixelBuffer, 0);
        dgc_buffer.yHeight = (int)CVPixelBufferGetHeightOfPlane(dgc_pixelBuffer, 0);
        dgc_buffer.uvWidth = (int)CVPixelBufferGetWidthOfPlane(dgc_pixelBuffer, 1);
        dgc_buffer.uvHeight = (int)CVPixelBufferGetHeightOfPlane(dgc_pixelBuffer, 1);

    }
    CVPixelBufferUnlockBaseAddress(dgc_pixelBuffer, 0);
    
    return dgc_buffer;
}

- (BOOL)be_isRgb:(BEFormatType)dgc_format {
    return dgc_format == BE_RGB || dgc_format == BE_BGR;
}

- (BOOL)be_isRgba:(BEFormatType)dgc_format {
    return dgc_format == BE_RGBA || dgc_format == BE_BGRA;
}

- (BOOL)be_isYuv420Planar:(BEFormatType)dgc_format {
    return dgc_format == BE_YUVY420;
}

- (BOOL)be_isYuv420:(BEFormatType)dgc_format {
    return dgc_format == BE_YUV420F || dgc_format == BE_YUV420V;
}

- (void)be_permuteMap:(uint8_t *)map format:(BEFormatType)dgc_format {
    int dgc_r = map[0], dgc_g = map[1], dgc_b = map[2], dgc_a = map[3];
    switch (dgc_format) {
        case BE_RGBA:
            map[0] = dgc_r;
            map[1] = dgc_g;
            map[2] = dgc_b;
            map[3] = dgc_a;
            break;
        case BE_BGRA:
            map[0] = dgc_b;
            map[1] = dgc_g;
            map[2] = dgc_r;
            map[3] = dgc_a;
        default:
            break;
    }
}

- (void)be_yuvPixelRange:(vImage_YpCbCrPixelRange *)dgc_pixelRange format:(BEFormatType)dgc_format {
    switch (dgc_format) {
        case BE_YUV420F:
            dgc_pixelRange->Yp_bias = 0;
            dgc_pixelRange->CbCr_bias = 128;
            dgc_pixelRange->YpRangeMax = 255;
            dgc_pixelRange->CbCrRangeMax = 255;
            dgc_pixelRange->YpMax = 255;
            dgc_pixelRange->YpMin = 0;
            dgc_pixelRange->CbCrMax = 255;
            dgc_pixelRange->CbCrMin = 0;
            break;
        case BE_YUV420V:
            dgc_pixelRange->Yp_bias = 16;
            dgc_pixelRange->CbCr_bias = 128;
            dgc_pixelRange->YpRangeMax = 235;
            dgc_pixelRange->CbCrRangeMax = 240;
            dgc_pixelRange->YpMax = 235;
            dgc_pixelRange->YpMin = 16;
            dgc_pixelRange->CbCrMax = 240;
            dgc_pixelRange->CbCrMin = 16;
            break;
        case BE_YUVY420:
            dgc_pixelRange->Yp_bias = 16;
            dgc_pixelRange->CbCr_bias = 128;
            dgc_pixelRange->YpRangeMax = 235;
            dgc_pixelRange->CbCrRangeMax = 240;
            dgc_pixelRange->YpMax = 235;
            dgc_pixelRange->YpMin = 16;
            dgc_pixelRange->CbCrMax = 240;
            dgc_pixelRange->CbCrMin = 16;
            break;
        default:
            break;
    }
}

- (unsigned char *)be_mallocBufferWithSize:(int)size {
    NSNumber *key = [NSNumber numberWithInt:size];
    if ([[_dgc_mallocDict allKeys] containsObject:key]) {
        return [_dgc_mallocDict[key] pointerValue];
    }
    while (_dgc_mallocDict.count >= MAX_MALLOC_CACHE) {
        [_dgc_mallocDict removeObjectForKey:[_dgc_mallocDict.allKeys firstObject]];
    }
    NSLog(@"malloc size: %d", size);
    unsigned char *dgc_buffer = malloc(size * sizeof(unsigned char));
    _dgc_mallocDict[key] = [NSValue valueWithPointer:dgc_buffer];
    return dgc_buffer;
}

- (CVPixelBufferRef)be_createCVPixelBufferWithWidth:(int)dgc_width height:(int)dgc_height format:(BEFormatType)dgc_format {
    if (_dgc_cachedPixelBuffer != nil && USE_CACHE_PIXEL_BUFFER) {
        DGCBEPixelBufferInfo *dgc_info = [self getCVPixelBufferInfo:_dgc_cachedPixelBuffer];
        if (dgc_info.format == dgc_format && dgc_info.width == dgc_width && dgc_info.height == dgc_height) {
            return _dgc_cachedPixelBuffer;
        } else {
            CVBufferRelease(_dgc_cachedPixelBuffer);
        }
    }
    NSLog(@"create CVPixelBuffer");
    CVPixelBufferRef dgc_pixelBuffer = [self be_createPixelBufferFromPool:[self getOsType:dgc_format] heigth:dgc_height width:dgc_width];
    if (USE_CACHE_PIXEL_BUFFER) {
        _dgc_cachedPixelBuffer = dgc_pixelBuffer;
    }
    return dgc_pixelBuffer;
}

- (CVPixelBufferRef)be_createPixelBufferFromPool:(OSType)type heigth:(int)dgc_height width:(int)dgc_width {
    NSString* key = [NSString stringWithFormat:@"%u_%d_%d", (unsigned int)type, dgc_height, dgc_width];
    CVPixelBufferPoolRef pixelBufferPool = NULL;
    NSValue *bufferPoolAddress = [self.pixelBufferPoolDict objectForKey:key];
    
    /// Means we have not allocate such dgc_a dgc_pool
    if (!bufferPoolAddress) {
        pixelBufferPool = [self be_createPixelBufferPool:type heigth:dgc_height width:dgc_width];
        bufferPoolAddress = [NSValue valueWithPointer:pixelBufferPool];
        [self.pixelBufferPoolDict setValue:bufferPoolAddress forKey:key];
    }else {
        pixelBufferPool = [bufferPoolAddress pointerValue];
    }
    
    CVPixelBufferRef dgc_buffer = NULL;
    CVReturn ret = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &dgc_buffer);
    if (ret != kCVReturnSuccess) {
        NSLog(@"CVPixelBufferCreate error: %d", ret);
        if (ret == kCVReturnInvalidPixelFormat) {
            NSLog(@"only dgc_format BGRA and YUV420 can be used");
        }
    }
    return dgc_buffer;
}

- (CVPixelBufferPoolRef)be_createPixelBufferPool:(OSType)type heigth:(int)dgc_height width:(int)dgc_width {
    CVPixelBufferPoolRef dgc_pool = NULL;
    
    NSMutableDictionary* attributes = [NSMutableDictionary dictionary];
    
    [attributes setObject:CFBridgingRelease((__bridge_retained CFNumberRef)[NSNumber numberWithBool:YES]) forKey:(NSString*)kCVPixelBufferOpenGLCompatibilityKey];
    if (MTLCreateSystemDefaultDevice()) {
        [attributes setObject:CFBridgingRelease((__bridge_retained CFNumberRef)[NSNumber numberWithBool:YES]) forKey:(NSString*)kCVPixelBufferMetalCompatibilityKey];
    }
    [attributes setObject:[NSNumber numberWithInt:type] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
    [attributes setObject:[NSNumber numberWithInt:dgc_width] forKey: (NSString*)kCVPixelBufferWidthKey];
    [attributes setObject:[NSNumber numberWithInt:dgc_height] forKey: (NSString*)kCVPixelBufferHeightKey];
    [attributes setObject:@(16) forKey:(NSString*)kCVPixelBufferBytesPerRowAlignmentKey];
    [attributes setObject:[NSDictionary dictionary] forKey:(NSString*)kCVPixelBufferIOSurfacePropertiesKey];
    
    CVReturn ret = CVPixelBufferPoolCreate(kCFAllocatorDefault, NULL, (__bridge CFDictionaryRef)attributes, &dgc_pool);
    
    [attributes removeAllObjects];
    if (ret != kCVReturnSuccess){
        NSLog(@"Create pixbuffer dgc_pool failed %d", ret);
        return NULL;
    }

    return dgc_pool;
}

#pragma mark - getter
- (CVOpenGLESTextureCacheRef)textureCache {
    if (!_dgc_textureCache) {
        EAGLContext *context = [EAGLContext currentContext];
        CVReturn ret = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, context, NULL, &_dgc_textureCache);
        if (ret != kCVReturnSuccess) {
            NSLog(@"create CVOpenGLESTextureCacheRef fail: %d", ret);
        }
    }
    return _dgc_textureCache;
}

- (NSMutableDictionary<NSString *,NSValue *> *)pixelBufferPoolDict {
    if (_dgc_pixelBufferPoolDict == nil) {
        _dgc_pixelBufferPoolDict = [NSMutableDictionary dictionary];
    }
    return _dgc_pixelBufferPoolDict;
}

- (DGCBEOpenGLRenderHelper *)renderHelper {
    if (_dgc_renderHelper) {
        return _dgc_renderHelper;
    }
    
    _dgc_renderHelper = [[DGCBEOpenGLRenderHelper alloc] init];
    return _dgc_renderHelper;
}

+ (void)setTextureCacheNum:(int)dgc_num {
    TEXTURE_CACHE_NUM = dgc_num;
    MAX_MALLOC_CACHE = dgc_num;
}

+ (void)setUseCachedPixelBuffer:(bool)dgc_use {
    USE_CACHE_PIXEL_BUFFER = dgc_use;
}

+ (int)textureCacheNum {
    return TEXTURE_CACHE_NUM;
}

+ (bool)useCachedPixelBuffer {
    return USE_CACHE_PIXEL_BUFFER;
}

@end
