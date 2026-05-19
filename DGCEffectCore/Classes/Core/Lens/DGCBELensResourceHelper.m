//  DGCBELensResourceHelper.m
//  Lens


#import "DGCBELensResourceHelper.h"
#import "macro.h"

static NSString *LICENSE_PATH = @"LicenseBag";
//static NSString *MODEL_PATH = @"ModelResource";
static NSString *BUNDLE = @"bundle";
static NSString *SKIN_SEGMENTATION_MODEL = @"/skin_seg/algo_gglus5cluha_v5.0.model";
static NSString *FACE_MODEL = @"/lensVida/algo_r5vpl1pqhl8tvh9.bytenn";
static NSString *AES_MODEL = @"/lensVida/algo_r5vplphul8tvh9.bytenn";
static NSString *CLARITY_MODEL = @"/lensVida/algo_9hrh9ylqik.bytenn";
static NSString *VIDEO_HDR_LITE = @"vhdr.bundle";
static NSString *VIDEO_HDR_LITE_LUT_PATH = @"lens_vhdr_image_lut_rgb";
static NSString *VIDEO_DEFLICKER_LIB_PATH = @"videodeflicker.bundle";
static NSString *VIDEO_DEFLICKER_LIB_NAME = @"deflicker";

@interface DGCBELensResourceHelper () {
    NSString            *_dgc_licensePrefix;
}

@end

@implementation DGCBELensResourceHelper

- (NSString *)licensePath {
    NSString *licenseName = [NSString stringWithFormat:@"/%s", LICENSE_NAME];
    if (!_dgc_licensePrefix) {
        _dgc_licensePrefix = [[NSBundle mainBundle] pathForResource:LICENSE_PATH ofType:BUNDLE];
    }
    return [_dgc_licensePrefix stringByAppendingString:licenseName];
}

- (NSString *)videoSRModelPath {
    return nil;
}

- (const char *)aesModelPath {
    return [self modelPath:AES_MODEL];
}

- (const char *)clarityModelPath {
    return [self modelPath:CLARITY_MODEL];
}

- (const char *)faceModelPath {
    return [self modelPath:FACE_MODEL];
}

-(const char*)skinSegPath {
    return [self modelPath:SKIN_SEGMENTATION_MODEL];
}

- (const char *)modelPath:(NSString *)model {
    return [[[self modelDirPath] stringByAppendingString:model] UTF8String];
}

- (const char *)videoHdrLiteHdrPath {
    NSString *path = [NSString stringWithFormat:@"vhdr.bundle/%@", VIDEO_HDR_LITE_LUT_PATH];
    NSString *ret=  [[NSBundle mainBundle] pathForResource:path ofType:@"bin"];
    return [ret UTF8String];
}

- (const char *)videoDeflickerLibPath {
    NSString *path = [[[[NSString alloc] init] stringByAppendingPathComponent:VIDEO_DEFLICKER_LIB_PATH] stringByAppendingPathComponent:VIDEO_DEFLICKER_LIB_NAME];
    NSString *ret = [[NSBundle mainBundle] pathForResource:path ofType:@"metallib"];
    return [ret UTF8String];
}

- (NSString *)modelDirPath
{
    NSString *documentDir = [[[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil] path];
    return [documentDir stringByAppendingString:@"/BDCV_ModelResource"];
}



@end
