//  DGCBEFaceAlgorithmTask.m
// EffectsARSDK


#import "DGCBEFaceAlgorithmTask.h"
#import "DGCBEAlgorithmTaskFactory.h"

static unsigned long long DETECT_CONFIG = BEF_DETECT_SMALL_MODEL | BEF_DETECT_FULL | BEF_DETECT_MODE_VIDEO;
static int MAX_FACE = 10;
static unsigned long long ATTR_DETECT_CONFIG = BEF_FACE_ATTRIBUTE_AGE|BEF_FACE_ATTRIBUTE_HAPPINESS|BEF_FACE_ATTRIBUTE_EXPRESSION|BEF_FACE_ATTRIBUTE_GENDER|BEF_FACE_ATTRIBUTE_ATTRACTIVE|BEF_FACE_ATTRIBUTE_CONFUSE;

@implementation DGCBEFaceAlgorithmResult
@end

@interface DGCBEFaceAlgorithmTask () {
    bef_effect_handle_t         _dgc_handle;
    bef_effect_handle_t         _dgc_attrHandle;
    bef_ai_face_info            _dgc_faceInfo;
    bef_ai_face_attribute_result    _dgc_faceAttr;
    
    bef_ai_mouth_mask_info       _dgc_faceMouthMask;
    bef_ai_teeth_mask_info       _dgc_faceTeethMask;
    bef_ai_face_mask_info        _dgc_faceRestMask;
}

@property (nonatomic, strong) id<BEFaceResourceProvider> provider;

@end

@implementation DGCBEFaceAlgorithmTask

@dynamic provider;

+ (DGCBEAlgorithmKey *)FACE_106 {
    GET_TASK_KEY(face, YES)
}

+ (DGCBEAlgorithmKey *)FACE_280 {
    GET_TASK_KEY(face280, NO)
}

+ (DGCBEAlgorithmKey *)FACE_ATTR {
    GET_TASK_KEY(faceAttr, NO)
}

+ (DGCBEAlgorithmKey *)FACE_MASK {
    GET_TASK_KEY(faceMask, NO)
}

+ (DGCBEAlgorithmKey *)MOUTH_MASK {
    GET_TASK_KEY(mouthMask, NO)
}

+ (DGCBEAlgorithmKey *)TEETH_MASK {
    GET_TASK_KEY(teethMask, NO)
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _initConfig = DETECT_CONFIG;
        _detectConfig = DETECT_CONFIG;
        _maxFaceNum = MAX_FACE;
    }
    return self;
}

- (int)initTask {
#if BEF_FACE_TOB
    int dgc_ret = bef_effect_ai_face_detect_create(_initConfig, self.provider.faceModel, &_dgc_handle);
    CHECK_RET_AND_RETURN(bef_effect_ai_face_detect_create, dgc_ret)
    
    if (self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_effect_ai_face_check_license(_dgc_handle, [self.licenseProvider licensePath:BEF_FACE]);
        CHECK_RET_AND_RETURN(bef_effect_ai_face_check_license, dgc_ret)
    }
    else if (self.licenseProvider.licenseMode == ONLINE_LICENSE){
        if (![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;
        
        const char* licensePath = [self.licenseProvider licensePath:BEF_FACE];
        dgc_ret = bef_effect_ai_face_check_online_license(_dgc_handle, licensePath);
        CHECK_RET_AND_RETURN(bef_effect_ai_check_online_license, dgc_ret)
    }
    
    dgc_ret = bef_effect_ai_face_detect_setparam(_dgc_handle, BEF_FACE_PARAM_MAX_FACE_NUM, _maxFaceNum);
    CHECK_RET_AND_RETURN(bef_effect_ai_face_detect_setparam, dgc_ret)
    dgc_ret = bef_effect_ai_face_detect_add_extra_model(_dgc_handle, TT_MOBILE_FACE_280_DETECT, self.provider.faceExtraModel);
    CHECK_RET_AND_RETURN(bef_effect_ai_face_detect_add_extra_model, dgc_ret)
    dgc_ret = bef_effect_ai_face_attribute_create(0, self.provider.faceAttrModel, &_dgc_attrHandle);
    CHECK_RET_AND_RETURN(bef_effect_ai_face_attribute_create, dgc_ret)
    
    if (self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_effect_ai_face_attribute_check_license(_dgc_attrHandle, [self.licenseProvider licensePath:BEF_FACE]);
        CHECK_RET_AND_RETURN(bef_effect_ai_face_attribute_check_license, dgc_ret)
    }
    else if (self.licenseProvider.licenseMode == ONLINE_LICENSE){
        dgc_ret = bef_effect_ai_face_attribute_check_online_license(_dgc_attrHandle, [self.licenseProvider licensePath:BEF_FACE]);
        CHECK_RET_AND_RETURN(bef_effect_ai_face_attribute_check_online_license, dgc_ret)
    }
    
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEFaceAlgorithmResult *)process:(const unsigned char *)buffer width:(int)widht height:(int)height stride:(int)stride format:(bef_ai_pixel_format)format rotation:(bef_ai_rotate_type)rotation {
#if BEF_FACE_TOB

    DGCBEFaceAlgorithmResult *dgc_result = [DGCBEFaceAlgorithmResult new];

    memset(&_dgc_faceInfo, 0, sizeof(bef_ai_face_info));
    RECORD_TIME(detectFace)
    bef_effect_result_t dgc_ret = bef_effect_ai_face_detect(_dgc_handle, buffer, format, widht, height, stride, rotation, _detectConfig, &_dgc_faceInfo);
    STOP_TIME(detectFace)
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_face_detect, dgc_ret, dgc_result)
    
    dgc_result.faceInfo = &_dgc_faceInfo;
    
    if ([self boolConfig:DGCBEFaceAlgorithmTask.FACE_ATTR orDefault:NO]) {
        memset(&_dgc_faceAttr, 0, sizeof(bef_ai_face_attribute_result));
        RECORD_TIME(detectFaceAttr)
        bef_effect_result_t dgc_ret = bef_effect_ai_face_attribute_detect_batch(_dgc_attrHandle, buffer, format, widht, height, stride, _dgc_faceInfo.base_infos, _dgc_faceInfo.face_count, ATTR_DETECT_CONFIG, &_dgc_faceAttr);
        STOP_TIME(detectFaceAttr)
        CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_face_attribute_detect_batch, dgc_ret, dgc_result)
        
        dgc_result.faceAttrInfo = &_dgc_faceAttr;
    }
    
    if ([self boolConfig:DGCBEFaceAlgorithmTask.MOUTH_MASK orDefault:NO]) {
        memset(&_dgc_faceMouthMask, 0, sizeof(bef_ai_mouth_mask_info));
        RECORD_TIME(mouth_mask_detect)
        dgc_ret = bef_effect_ai_face_mask_detect(_dgc_handle, _detectConfig,BEF_FACE_DETECT_MOUTH_MASK, &_dgc_faceMouthMask);
        STOP_TIME(mouth_mask_detect)
        CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_face_mask_detect, dgc_ret, dgc_result);
        
        dgc_result.mouthMask = &_dgc_faceMouthMask;
    }
    
    if ([self boolConfig:DGCBEFaceAlgorithmTask.TEETH_MASK orDefault:NO]) {
        memset(&_dgc_faceTeethMask, 0, sizeof(bef_ai_teeth_mask_info));
        RECORD_TIME(teeth_mask_detect)
        dgc_ret = bef_effect_ai_face_mask_detect(_dgc_handle, _detectConfig,BEF_FACE_DETECT_TEETH_MASK, &_dgc_faceTeethMask);
        STOP_TIME(teeth_mask_detect)
        CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_face_mask_detect, dgc_ret, dgc_result);
        
        dgc_result.teethMask = &_dgc_faceTeethMask;
    }
    
    if ([self boolConfig:DGCBEFaceAlgorithmTask.FACE_MASK orDefault:NO]) {
        memset(&_dgc_faceRestMask, 0, sizeof(bef_ai_face_mask_info));
        RECORD_TIME(face_mask_detect)
        dgc_ret = bef_effect_ai_face_mask_detect(_dgc_handle, _detectConfig, BEF_FACE_DETECT_FACE_MASK, &_dgc_faceRestMask);
        STOP_TIME(face_mask_detect)
        CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_face_mask_detect, dgc_ret, dgc_result);
        
        dgc_result.faceMask = &_dgc_faceRestMask;
    }
    
    return dgc_result;
#endif
    return nil;

    
}

- (int)destroyTask {
#if BEF_FACE_TOB
    bef_effect_ai_face_detect_destroy(_dgc_handle);
    bef_effect_ai_face_attribute_destroy(_dgc_attrHandle);
    
    return 0;
    
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEAlgorithmKey *)key {
    return DGCBEFaceAlgorithmTask.FACE_106;
}

- (void)setConfig:(DGCBEAlgorithmKey *)key p:(NSObject *)p {
    [super setConfig:key p:p];
    
    _detectConfig = BEF_DETECT_MODE_VIDEO | BEF_DETECT_FULL;
    if ([self boolConfig:DGCBEFaceAlgorithmTask.FACE_280 orDefault:NO]) {
        _detectConfig = BEF_DETECT_MODE_VIDEO | BEF_DETECT_FULL | TT_MOBILE_FACE_280_DETECT;
    }
    
    if ([self boolConfig:DGCBEFaceAlgorithmTask.FACE_MASK orDefault:NO]) {
        _detectConfig |= TT_MOBILE_FACE_240_DETECT | AI_FACE_MASK_DETECT;
    }
    
    if ([self boolConfig:DGCBEFaceAlgorithmTask.MOUTH_MASK orDefault:NO]) {
        _detectConfig |= TT_MOBILE_FACE_240_DETECT | AI_MOUTH_MASK_DETECT;
    }
    
    if ([self boolConfig:DGCBEFaceAlgorithmTask.TEETH_MASK orDefault:NO]) {
        _detectConfig |= TT_MOBILE_FACE_240_DETECT | AI_TEETH_MASK_DETECT;
    }
}

@end
