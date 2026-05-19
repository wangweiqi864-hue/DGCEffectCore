//
//  DGCBESaliencyMattingAlgorithmTask.m
//  BECore
//
//  Created by ByteDance on 2023/04/23.
//

#import <Foundation/Foundation.h>
#import "DGCBESaliencyMattingAlgorithmTask.h"

static const bef_ai_saliency_matting_model_type DEFAULT_MODEL_TYPE = BEF_SALIENCY_MATTING_LARGE_MODEL;

@implementation DGCBESaliencyMattingAlgorithmResult
@end

@interface DGCBESaliencyMattingAlgorithmTask () {
    bef_ai_saliency_matting_handle _dgc_handle;
    bef_ai_saliency_matting_ret _dgc_saliency_matting_ret;
    bef_ai_saliency_matting_model_type _dgc_model_type;
    int _dgc_size[3];
    unsigned char *_dgc_aligned_alpha;
}

@property (nonatomic, strong) id<BESaliencyMattingResourceProvider> provider;

@end

@implementation DGCBESaliencyMattingAlgorithmTask

@dynamic provider;

+ (DGCBEAlgorithmKey *)SALIENCY_MATTING {
    GET_TASK_KEY(saliencyMatting, YES)
}

- (int)initTask {
#if BEF_SALIENCY_MATTING_TOB
    _dgc_model_type = DEFAULT_MODEL_TYPE;
    bef_effect_result_t dgc_ret = bef_effect_ai_saliency_matting_create(&_dgc_handle);
    CHECK_RET_AND_RETURN(bef_effect_ai_saliency_matting_create, dgc_ret)
    
    if (self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_effect_ai_saliency_matting_check_offline_license(_dgc_handle, [self.licenseProvider licensePath:BEF_SALIENCY_MATTING]);
        CHECK_RET_AND_RETURN( bef_effect_ai_saliency_matting_check_offline_license, dgc_ret)
    }
    else if (self.licenseProvider.licenseMode == ONLINE_LICENSE){
        if (![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;
        
        dgc_ret = bef_effect_ai_saliency_matting_check_online_license(_dgc_handle, [self.licenseProvider licensePath:BEF_SALIENCY_MATTING]);
        CHECK_RET_AND_RETURN(bef_effect_ai_saliency_matting_check_online_license, dgc_ret)
        
    }
    
    // {zh} saliency matting有三种模型可以使用，但是demo只展示一种模型结果
    // {en} Saliency Matting supports three available models, but demos typically only show the results of one of those models.
    dgc_ret = bef_effect_ai_saliency_matting_set_model(_dgc_handle, DEFAULT_MODEL_TYPE, self.provider.saliencyMattingModelPath);
    CHECK_RET_AND_RETURN(bef_effect_ai_saliency_matting_set_model, dgc_ret)
    
    _dgc_saliency_matting_ret.maskHeight = 0;
    _dgc_saliency_matting_ret.maskWidth = 0;
    _dgc_saliency_matting_ret.mask = NULL;
    _dgc_aligned_alpha = NULL;
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBESaliencyMattingAlgorithmResult *)process:(const unsigned char *)buffer width:(int)width height:(int)height stride:(int)stride format:(bef_ai_pixel_format)format rotation:(bef_ai_rotate_type)rotation {
#if BEF_SALIENCY_MATTING_TOB
    DGCBESaliencyMattingAlgorithmResult *dgc_result = [[DGCBESaliencyMattingAlgorithmResult alloc] init];
    
    if(_dgc_saliency_matting_ret.maskHeight != height || _dgc_saliency_matting_ret.maskWidth != width){
        free(_dgc_saliency_matting_ret.mask);
        free(_dgc_aligned_alpha);
        _dgc_saliency_matting_ret.mask = NULL;
        _dgc_aligned_alpha = NULL;
    }
    RECORD_TIME(saliency_matting)
    bef_effect_result_t dgc_ret = bef_effect_ai_saliency_matting_detect(_dgc_handle, buffer, format, width, height, stride, rotation, &_dgc_saliency_matting_ret);
    STOP_TIME(saliency_matting)
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_saliency_matting_detect, dgc_ret, dgc_result);
    
    // for rendering in OpenGL, align mask data by 4 bytes;
    int numByetsPerRow = (width + 3) & (-4);
    if(_dgc_aligned_alpha == NULL){
      _dgc_aligned_alpha = calloc(numByetsPerRow * _dgc_saliency_matting_ret.maskHeight, sizeof(unsigned char));
    }
    for(int iR = 0; iR < _dgc_saliency_matting_ret.maskHeight; ++iR){
        memcpy(_dgc_aligned_alpha + iR * numByetsPerRow, _dgc_saliency_matting_ret.mask + iR * _dgc_saliency_matting_ret.maskWidth, _dgc_saliency_matting_ret.maskWidth);
    }
    
    dgc_result.mask = _dgc_aligned_alpha;
    _dgc_size[0] = _dgc_saliency_matting_ret.maskWidth;
    _dgc_size[1] = _dgc_saliency_matting_ret.maskHeight;
    _dgc_size[2] = 1;
    dgc_result.size = _dgc_size;
    
    return dgc_result;
#endif
    return nil;
}

- (int)destroyTask {
#if BEF_SALIENCY_MATTING_TOB
    if(_dgc_saliency_matting_ret.mask != NULL){
        free(_dgc_saliency_matting_ret.mask);
    }
    if(_dgc_aligned_alpha != NULL){
        free(_dgc_aligned_alpha);
    }
    bef_effect_ai_saliency_matting_release(_dgc_handle);
    return 0;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEAlgorithmKey *)key {
    return DGCBESaliencyMattingAlgorithmTask.SALIENCY_MATTING;
}


@end
