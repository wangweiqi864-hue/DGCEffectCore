//  BEGLTexture.m
// EffectsARSDK


#import "BEGLTexture.h"
#import <OpenGLES/EAGL.h>

#define GL_TEXTURE_SETTING(texture) glBindTexture(GL_TEXTURE_2D, texture); \
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); \
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); \
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE); \
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE); \
    glBindTexture(GL_TEXTURE_2D, 0);

@implementation DGCBENormalGLTexture {
    
}

@synthesize texture = _texture;
@synthesize type = _type;
@synthesize available = _available;
@synthesize width = _width;
@synthesize height = _height;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _type = BE_NORMAL_TEXTURE;
    }
    return self;
}

- (instancetype)initWithWidth:(int)width height:(int)height {
    if (self = [super init]) {
        _type = BE_NORMAL_TEXTURE;
        glGenTextures(1, &_texture);
        [self update:nil width:width height:height format:GL_RGBA];
    }
    return self;
}

- (instancetype)initWithBuffer:(unsigned char *)buffer width:(int)width height:(int)height format:(GLenum)format {
    if (self = [super init]) {
        _type = BE_NORMAL_TEXTURE;
        glGenTextures(1, &_texture);
        [self update:buffer width:width height:height format:format];
    }
    return self;
}

- (instancetype)initWithTexture:(GLuint)texture width:(int)width height:(int)height {
    if (self = [super init]) {
        [self updateTexture:texture width:width height:height];
    }
    return self;
}

- (void)updateWidth:(int)width height:(int)height {
    [self update:nil width:width height:height format:GL_RGBA];
}

- (void)update:(unsigned char *)buffer width:(int)width height:(int)height format:(GLenum)format {
    if (!glIsTexture(_texture)) {
        NSLog(@"error: not a valid texture %d", _texture);
        _available = NO;
        return;
    }
    glBindTexture(GL_TEXTURE_2D, _texture);
    if (_width == width && _height == height) {
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width, height, format, GL_UNSIGNED_BYTE, buffer);
    } else {
        _width = width;
        _height = height;
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, format, GL_UNSIGNED_BYTE, buffer);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
    glBindTexture(GL_TEXTURE_2D, 0);
    _available = YES;
}

- (void)updateTexture:(GLuint)texture width:(int)width height:(int)height {
    if (glIsTexture(_texture)) {
        glDeleteTextures(1, &_texture);
    }
    
    _texture = texture;
    _width = width;
    _height = height;
    _available = YES;
}

- (void)destroy {
    if (glIsTexture(_texture)) {
        glDeleteTextures(1, &_texture);
    }
    _available = NO;
}

@end

@implementation DGCBEPixelBufferGLTexture {
    CVPixelBufferRef            _dgc_pixelBuffer;
    BOOL                        _dgc_needReleasePixelBuffer;
    
    CVOpenGLESTextureRef        _dgc_cvTexture;
    CVOpenGLESTextureRef        _dgc_yuvTexture;
    CVOpenGLESTextureCacheRef   _dgc_textureCache;
    
    CVMetalTextureRef           _dgc_cvMTLTexture;
    CVMetalTextureCacheRef      _dgc_mtlTextureCache;
    
    BOOL                        _dgc_needReleaseTextureCache;
    BOOL                        _dgc_needReleaseMTLTextureCache;
}

@synthesize texture = _texture;
@synthesize uvTexture = _uvTexture;
@synthesize type = _type;
@synthesize available = _available;
@synthesize width = _width;
@synthesize height = _height;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _type = BE_PIXEL_BUFFER_TEXTURE;
    }
    return self;
}

- (instancetype)initWithTextureCache:(CVOpenGLESTextureCacheRef)textureCache {
    self = [super init];
    if (self) {
        _type = BE_PIXEL_BUFFER_TEXTURE;
        _dgc_textureCache = textureCache;
        _dgc_needReleaseTextureCache = NO;
    }
    return self;
}

- (instancetype)initWithMTKTextureCache:(CVMetalTextureCacheRef)textureCache {
    self = [super init];
    if (self) {
        _type = BE_PIXEL_BUFFER_TEXTURE;
        _dgc_mtlTextureCache = textureCache;
        _dgc_needReleaseMTLTextureCache = NO;
    }
    return self;
}

- (instancetype)initWithWidth:(int)width height:(int)height {
    if (self = [super init]) {
        _type = BE_PIXEL_BUFFER_TEXTURE;
        [self update:[self createPxielBuffer:width height:height]];
    }
    return self;
}

- (instancetype)initWithWidth:(int)width height:(int)height textureCache:(CVOpenGLESTextureCacheRef)textureCache {
    if (self = [super init]) {
        _dgc_textureCache = textureCache;
        _dgc_needReleaseTextureCache = NO;
        _type = BE_PIXEL_BUFFER_TEXTURE;
        [self update:[self createPxielBuffer:width height:height]];
    }
    return self;
}

- (instancetype)initWithWidth:(int)width height:(int)height mtlTextureCache:(CVMetalTextureCacheRef)textureCache {
    if (self = [super init]) {
        _dgc_mtlTextureCache = textureCache;
        _dgc_needReleaseMTLTextureCache = NO;
        _type = BE_PIXEL_BUFFER_TEXTURE;
        [self update:[self createPxielBuffer:width height:height]];
    }
    return self;
}

- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer textureCache:(CVOpenGLESTextureCacheRef)textureCache {
    if (self = [super init]) {
        _dgc_textureCache = textureCache;
        _dgc_needReleaseTextureCache = NO;
        _type = BE_PIXEL_BUFFER_TEXTURE;
        [self update:pixelBuffer];
    }
    return self;
}

- (instancetype)initWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer mtlTextureCache:(CVMetalTextureCacheRef)textureCache {
    if (self = [super init]) {
        _dgc_mtlTextureCache = textureCache;
        _dgc_needReleaseMTLTextureCache = NO;
        _type = BE_PIXEL_BUFFER_TEXTURE;
        [self update:pixelBuffer];
    }
    return self;
}

- (CVPixelBufferRef)createPxielBuffer:(int)width height:(int)height {
    CVPixelBufferRef pixelBuffer;
    CFDictionaryRef optionsDicitionary = nil;
    // judge whether the device support metal
    if (MTLCreateSystemDefaultDevice()) {
        const void *keys[] = {
            kCVPixelBufferOpenGLCompatibilityKey,
            kCVPixelBufferMetalCompatibilityKey,
            kCVPixelBufferIOSurfacePropertiesKey
        };
        const void *values[] = {
            (__bridge const void *)([NSNumber numberWithBool:YES]),
            (__bridge const void *)([NSNumber numberWithBool:YES]),
            (__bridge const void *)([NSDictionary dictionary])
        };
        optionsDicitionary = CFDictionaryCreate(kCFAllocatorDefault, keys, values, 3, NULL, NULL);
    } else {
        const void *keys[] = {
            kCVPixelBufferOpenGLCompatibilityKey,
            kCVPixelBufferIOSurfacePropertiesKey
        };
        const void *values[] = {
            (__bridge const void *)([NSNumber numberWithBool:YES]),
            (__bridge const void *)([NSDictionary dictionary])
        };
        optionsDicitionary = CFDictionaryCreate(kCFAllocatorDefault, keys, values, 3, NULL, NULL);
    }
    
    CVReturn res = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, optionsDicitionary, &pixelBuffer);
    CFRelease(optionsDicitionary);
    if (res != kCVReturnSuccess) {
        NSLog(@"CVPixelBufferCreate error: %d", res);
        if (res == kCVReturnInvalidPixelFormat) {
            NSLog(@"only format BGRA and YUV420 can be used");
        }
        _available = NO;
    }
    _available = YES;
    _dgc_needReleasePixelBuffer = YES;
    return pixelBuffer;
}

- (void)updateWidth:(int)width height:(int)height {
    if (_width != width || _height != height) {
        [self destroy];
        
        [self update:[self createPxielBuffer:width height:height]];
    }
}

- (void)update:(CVPixelBufferRef)pixelBuffer {
    if (_dgc_pixelBuffer && _dgc_needReleasePixelBuffer) {
        _dgc_needReleasePixelBuffer = NO;
        CVPixelBufferRelease(_dgc_pixelBuffer);
    }
    if (pixelBuffer == nil) {
        _available = NO;
        return;
    }
    
    // gl texture
    if (!_dgc_textureCache) {
        _dgc_needReleaseTextureCache = YES;
        EAGLContext *context = [EAGLContext currentContext];
        CVReturn ret = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, context, NULL, &_dgc_textureCache);
        if (ret != kCVReturnSuccess) {
            NSLog(@"create CVOpenGLESTextureCacheRef fail: %d", ret);
            _available = NO;
            return;
        }
    }
    
    if (_dgc_cvTexture) {
        CFRelease(_dgc_cvTexture);
        _dgc_cvTexture = nil;
    }
    
    if (_dgc_yuvTexture) {
        CFRelease(_dgc_yuvTexture);
        _dgc_yuvTexture = nil;
    }
    
    OSType pbType = CVPixelBufferGetPixelFormatType(pixelBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    int bytesPerRow = (int) CVPixelBufferGetBytesPerRow(pixelBuffer);
    int width = (int) CVPixelBufferGetWidth(pixelBuffer);
    int height = (int) CVPixelBufferGetHeight(pixelBuffer);
    size_t iTop, iBottom, iLeft, iRight;
    CVPixelBufferGetExtendedPixels(pixelBuffer, &iLeft, &iRight, &iTop, &iBottom);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    width = width + (int) iLeft + (int) iRight;
    height = height + (int) iTop + (int) iBottom;
    bytesPerRow = bytesPerRow + (int) iLeft + (int) iRight;
    CVReturn ret = kCVReturnSuccess;
    
    if (pbType ==  kCVPixelFormatType_420YpCbCr8BiPlanarFullRange || pbType == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
        // yuv
        size_t planeCount = CVPixelBufferGetPlaneCount(pixelBuffer);
        assert(planeCount == 2);

        CVReturn ret = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _dgc_textureCache, pixelBuffer, NULL, GL_TEXTURE_2D, GL_LUMINANCE, width, height, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &_dgc_cvTexture);
        if (ret != kCVReturnSuccess || !_dgc_cvTexture) {
            NSLog(@"create CVOpenGLESTextureRef fail: %d", ret);
            _available = NO;
            return;
        }
        
        _width = width;
        _height = height;
        _dgc_pixelBuffer = pixelBuffer;
        _texture = CVOpenGLESTextureGetName(_dgc_cvTexture);
        GL_TEXTURE_SETTING(_texture);
        
        ret = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _dgc_textureCache, pixelBuffer, NULL, GL_TEXTURE_2D, GL_LUMINANCE_ALPHA, width/2, height/2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &_dgc_yuvTexture);
        if (ret != kCVReturnSuccess || !_dgc_yuvTexture) {
            NSLog(@"create CVOpenGLESTextureRef fail: %d", ret);
            _available = NO;
            return;
        }
        _uvTexture = CVOpenGLESTextureGetName(_dgc_yuvTexture);
        GL_TEXTURE_SETTING(_uvTexture);
    } else {
        // bgra
        ret = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _dgc_textureCache, pixelBuffer, NULL, GL_TEXTURE_2D, GL_RGBA, width, height, GL_BGRA, GL_UNSIGNED_BYTE, 0, &_dgc_cvTexture);
        if (ret != kCVReturnSuccess || !_dgc_cvTexture) {
            NSLog(@"create CVOpenGLESTextureRef fail: %d", ret);
            _available = NO;
            return;
        }
        
        _width = width;
        _height = height;
        _dgc_pixelBuffer = pixelBuffer;
        _texture = CVOpenGLESTextureGetName(_dgc_cvTexture);
        GL_TEXTURE_SETTING(_texture);
    }
    
    // metal texture
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (device) {
        if(!_dgc_mtlTextureCache) {
            _dgc_needReleaseMTLTextureCache = YES;
            ret = CVMetalTextureCacheCreate(kCFAllocatorDefault, NULL, device, NULL, &_dgc_mtlTextureCache);
            if (ret != kCVReturnSuccess) {
                NSLog(@"create CVMetalTextureCacheRef fail: %d", ret);
                _available = NO;
                return;
            }
        }
        
        ret = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _dgc_mtlTextureCache, pixelBuffer, NULL, MTLPixelFormatBGRA8Unorm, width, height, 0, &_dgc_cvMTLTexture);
        if (ret != kCVReturnSuccess || !_dgc_cvMTLTexture) {
            NSLog(@"create CVMetalTextureRef fail: %d", ret);
            _available = NO;
            return;
        }
        _mtlTexture = CVMetalTextureGetTexture(_dgc_cvMTLTexture);
        if (_dgc_cvMTLTexture) {
            CFRelease(_dgc_cvMTLTexture);
            _dgc_cvMTLTexture = nil;
        }
    }
    
    _available = YES;
}

- (CVPixelBufferRef)pixelBuffer {
    return _dgc_pixelBuffer;
}

- (void)destroy {
    if (_dgc_cvTexture) {
        CFRelease(_dgc_cvTexture);
        _dgc_cvTexture = nil;
    }
    if (_dgc_cvMTLTexture) {
        CFRelease(_dgc_cvMTLTexture);
        _dgc_cvMTLTexture = nil;
    }
    if (_dgc_pixelBuffer && _dgc_needReleasePixelBuffer) {
        NSLog(@"release pixelBuffer %@", _dgc_pixelBuffer);
        _dgc_needReleasePixelBuffer = NO;
        CVPixelBufferRelease(_dgc_pixelBuffer);
        _dgc_pixelBuffer = nil;
    }
    if (_dgc_textureCache && _dgc_needReleaseTextureCache) {
        NSLog(@"release CVTextureCache %@", _dgc_textureCache);
        CVOpenGLESTextureCacheFlush(_dgc_textureCache, 0);
        CFRelease(_dgc_textureCache);
        _dgc_textureCache = nil;
    }
    if (_dgc_mtlTextureCache && _dgc_needReleaseMTLTextureCache) {
        NSLog(@"release CVMetalTextureCache %@", _dgc_mtlTextureCache);
        CVMetalTextureCacheFlush(_dgc_mtlTextureCache, 0);
        CFRelease(_dgc_mtlTextureCache);
        _dgc_mtlTextureCache = nil;
    }
    _available = NO;
}

@end
