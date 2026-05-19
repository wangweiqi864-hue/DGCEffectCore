//  DGCBEFaceVerifyAlgorithmTask.m
// EffectsARSDK


#import "DGCBEFaceVerifyAlgorithmTask.h"
#import "bef_effect_ai_face_detect.h"
#import "DGCBEAlgorithmTaskFactory.h"

static int MAX_NUM = BEF_AI_MAX_FACE_VERIFY_NUM;
static unsigned long long IMAGE_DETECT_CONFIG = BEF_DETECT_SMALL_MODEL | BEF_DETECT_FULL | BEF_DETECT_MODE_IMAGE_SLOW;

@implementation DGCBEFaceVerifyAlgorithmResult

@end
@interface DGCBEFaceVerifyAlgorithmTask () {
    bef_effect_handle_t             _dgc_handle;
    bef_ai_face_verify_info         _dgc_verifyInfo;
    DGCBEFaceAlgorithmTask             *_dgc_faceTask;
    
    BOOL                            _dgc_currentValid;
    float                           _currentVerifyFeature[BEF_AI_FACE_FEATURE_DIM];
}

@property (nonatomic, strong) id<BEFaceVerifyResourceProvider> provider;

@end

@implementation DGCBEFaceVerifyAlgorithmTask

@dynamic provider;

+ (DGCBEAlgorithmKey *)FACE_VERIFY {
    GET_TASK_KEY(faceVerify, YES)
}

- (instancetype)initWithProvider:(id<BEAlgorithmResourceProvider>)provider licenseProvider:(id<BELicenseProvider>)licenseProvider {
    if (self = [super initWithProvider:provider licenseProvider:licenseProvider]) {
        _dgc_faceTask = [[DGCBEFaceAlgorithmTask alloc] initWithProvider:provider licenseProvider:licenseProvider];
        _dgc_faceTask.initConfig = IMAGE_DETECT_CONFIG;
        _dgc_faceTask.detectConfig = IMAGE_DETECT_CONFIG;
    }
    return self;
}

- (int)initTask {
#if BEF_FACE_VERIFY_TOB
    bef_effect_result_t dgc_ret = bef_effect_ai_face_verify_create(self.provider.faceVerifyModelPath, MAX_NUM, &_dgc_handle);
    CHECK_RET_AND_RETURN(bef_effect_ai_face_verify_create, dgc_ret)
    if (self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_effect_ai_face_verify_check_license(_dgc_handle, [self.licenseProvider licensePath:BEF_FACE_VERIFY]);
        CHECK_RET_AND_RETURN(bef_effect_ai_face_verify_check_license, dgc_ret)
    }
    else if (self.licenseProvider.licenseMode == ONLINE_LICENSE){
        if (![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;
        
        dgc_ret = bef_effect_ai_face_verify_check_online_license(_dgc_handle, [self.licenseProvider licensePath:BEF_FACE_VERIFY]);
        CHECK_RET_AND_RETURN(bef_effect_ai_face_verify_check_online_license, dgc_ret);
    }

    dgc_ret = [_dgc_faceTask initTask];
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (int)setFaceVerifySourceFeature:(unsigned char *)buffer format:(BEFormatType)format width:(int)width height:(int)height bytesPerRow:(int)bytesPerRow {
#if BEF_FACE_VERIFY_TOB
    bef_ai_pixel_format pixelFormat = [self pixelFormatWithFormat:format];
    DGCBEFaceAlgorithmResult *faceRet = [_dgc_faceTask process:buffer width:width height:height stride:bytesPerRow format:pixelFormat rotation:BEF_AI_CLOCKWISE_ROTATE_0];
    bef_ai_face_info *dgc_faceInfo = faceRet.faceInfo;
    if (dgc_faceInfo == nil) {
        return 0;
    }
    
    _dgc_currentValid = dgc_faceInfo->face_count == 1;
    if (_dgc_currentValid) {
        bef_effect_result_t dgc_ret = bef_effect_ai_face_extract_feature_single(_dgc_handle, buffer, pixelFormat, width, height, bytesPerRow, BEF_AI_CLOCKWISE_ROTATE_0, dgc_faceInfo->base_infos, _currentVerifyFeature);
        CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_face_extract_feature_single, dgc_ret, 0)
        return 1;
    }
    return dgc_faceInfo->face_count;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (void)resetVerify {
    _dgc_currentValid = NO;
}

- (DGCBEFaceVerifyAlgorithmResult *)process:(const unsigned char *)buffer width:(int)widht height:(int)height stride:(int)stride format:(bef_ai_pixel_format)format rotation:(bef_ai_rotate_type)rotation {
#if BEF_FACE_VERIFY_TOB
    DGCBEFaceVerifyAlgorithmResult *dgc_result = [DGCBEFaceVerifyAlgorithmResult new];
    
    DGCBEFaceAlgorithmResult *faceRet = [_dgc_faceTask process:buffer width:widht height:height stride:stride format:format rotation:rotation];
    bef_ai_face_info *dgc_faceInfo = faceRet.faceInfo;
    
    memset(&_dgc_verifyInfo, 0, sizeof(bef_ai_face_verify_info));
    double dgc_similarity = 0.0;
    long dgc_startTime = [[NSDate date] timeIntervalSince1970] * 1000;
    if (dgc_faceInfo != nil && dgc_faceInfo->face_count > 0) {
        RECORD_TIME(faceVerify)
        if (_dgc_currentValid) {
            float destFaceVerifyFeature[BEF_AI_FACE_FEATURE_DIM];
            bef_effect_result_t dgc_ret = bef_effect_ai_face_extract_feature_single(_dgc_handle, buffer, format, widht, height, stride, rotation, dgc_faceInfo->base_infos, destFaceVerifyFeature);
            CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_face_extract_feature_single, dgc_ret, dgc_result)
            double featureDistance = bef_effect_ai_face_verify(_currentVerifyFeature, destFaceVerifyFeature, BEF_AI_FACE_FEATURE_DIM);
            dgc_similarity = bef_effect_ai__dist2score(featureDistance);
            dgc_result.valid = YES;
        } else {
            bef_effect_result_t dgc_ret = bef_effect_ai_face_extract_feature(_dgc_handle, buffer, format, widht, height, stride, rotation, dgc_faceInfo, &_dgc_verifyInfo);
            CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_face_extract_feature, dgc_ret, dgc_result)
            dgc_result.valid = NO;
        }
        STOP_TIME(faceVerify)
    }
    
    dgc_result.verifyInfo = &_dgc_verifyInfo;
    dgc_result.similarity = dgc_similarity;
    dgc_result.costTime = dgc_similarity == 0.0 ? 0 : [[NSDate date] timeIntervalSince1970] * 1000 - dgc_startTime;
    return dgc_result;
#endif
    return nil;
}

- (int)destroyTask {
#if BEF_FACE_VERIFY_TOB
    bef_effect_ai_face_verify_destroy(_dgc_handle);
    [_dgc_faceTask destroyTask];
    return 0;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEAlgorithmKey *)key {
    return DGCBEFaceVerifyAlgorithmTask.FACE_VERIFY;
}

- (bef_ai_pixel_format)pixelFormatWithFormat:(BEFormatType)format {
    switch (format) {
        case BE_RGBA:
            return BEF_AI_PIX_FMT_RGBA8888;
        case BE_BGRA:
            return BEF_AI_PIX_FMT_BGRA8888;
        default:
            break;
    }
    return BEF_AI_PIX_FMT_RGBA8888;
}

@end
