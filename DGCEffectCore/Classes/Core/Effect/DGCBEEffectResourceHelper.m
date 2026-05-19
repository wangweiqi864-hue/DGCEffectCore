//  DGCBEEffectResourceHelper.m
//  Effect


#import "DGCBEEffectResourceHelper.h"
#import "DGCBELicenseHelper.h"

static NSString *LICENSE_PATH = @"LicenseBag";
static NSString *COMPOSER_PATH = @"ComposeMakeup";
static NSString *FILTER_PATH = @"FilterResource";
static NSString *STICKER_PATH = @"StickerResource";
static NSString *MODEL_PATH = @"ModelResource";
static NSString *VIDEOSR_PATH = @"videovrsr";

static NSString *BUNDLE = @"bundle";

@interface DGCBEEffectResourceHelper () {
    NSString            *_dgc_licensePrefix;
    NSString            *_dgc_composerPrefix;
    NSString            *_dgc_filterPrefix;
    NSString            *_dgc_stickerPrefix;
}

@end

@implementation DGCBEEffectResourceHelper

- (NSString *)composerNodePath:(NSString *)nodeName
{
    if(!_dgc_composerPrefix)
    {
        NSString *documentDir = [[[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil] path];
        documentDir = [documentDir stringByAppendingString:@"/BDCV_Resource/ComposeMakeup/"];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:documentDir]) {
            documentDir = [[[NSBundle mainBundle] pathForResource:COMPOSER_PATH ofType:BUNDLE] stringByAppendingFormat:@"/ComposeMakeup/"];
        }
        
        _dgc_composerPrefix = documentDir;
    }
    return [_dgc_composerPrefix stringByAppendingString:nodeName];
}

- (NSString *)filterPath:(NSString *)filterName
{
    if (!_dgc_filterPrefix)
    {
        NSString *documentDir = [[[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil] path];
        documentDir = [documentDir stringByAppendingString:@"/BDCV_Resource/Filter/"];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:documentDir]) {
            documentDir = [[[NSBundle mainBundle] pathForResource:FILTER_PATH ofType:BUNDLE] stringByAppendingFormat:@"/Filter/"];
        }
        
        _dgc_filterPrefix = documentDir;
    }
    return [_dgc_filterPrefix stringByAppendingString:filterName];
}

- (NSString *)stickerPath:(NSString *)stickerName
{
    if(!_dgc_stickerPrefix)
    {
        NSString *documentDir = [[[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil] path];
        documentDir = [documentDir stringByAppendingString:@"/BDCV_Resource/"];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:documentDir]) {
            documentDir = [[[NSBundle mainBundle] pathForResource:STICKER_PATH ofType:BUNDLE] stringByAppendingFormat:@"/stickers/"];
        }
        
        _dgc_stickerPrefix = documentDir;
    }
    
    return [_dgc_stickerPrefix stringByAppendingString:stickerName];
}

- (const char *)modelDirPath
{
    NSString *documentDir = [[[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil] path];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[documentDir stringByAppendingString:@"/BDCV_ModelResource"]]) {
        return [[[NSBundle mainBundle] pathForResource:MODEL_PATH ofType:BUNDLE] UTF8String];
    }
    
    return [[documentDir stringByAppendingString:@"/BDCV_ModelResource"] UTF8String];
}

- (NSString *)videoSRModelPath
{
    return [[NSBundle mainBundle] pathForResource:VIDEOSR_PATH ofType:BUNDLE];
}

@end
