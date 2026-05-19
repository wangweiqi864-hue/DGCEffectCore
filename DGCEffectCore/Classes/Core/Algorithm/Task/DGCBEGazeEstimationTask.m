//  DGCBEGazeEstimationTask.m
// EffectsARSDK


#import "DGCBEGazeEstimationTask.h"
#import "DGCBEAlgorithmTaskFactory.h"
#import "DGCBEFaceAlgorithmTask.h"

static const int LINE_LEN = 0;

@implementation DGCBEGazeEstimationAlgorithmResult

@end
@interface DGCBEGazeEstimationTask () {
    bef_ai_gaze_handle             _dgc_handle;
    bef_ai_gaze_estimation_info     _dgc_gazeInfo;
    DGCBEFaceAlgorithmTask             *_dgc_faceTask;
}

@property (nonatomic, strong) id<BEGazeEstimationResourceProvider> provider;

@end

@implementation DGCBEGazeEstimationTask

@dynamic provider;

- (instancetype)initWithProvider:(id<BEAlgorithmResourceProvider>)provider licenseProvider:(id<BELicenseProvider>) licenseProvider {
    self = [super initWithProvider:provider licenseProvider:licenseProvider];
    if (self) {
        _dgc_faceTask = [[DGCBEFaceAlgorithmTask alloc] initWithProvider:provider licenseProvider:licenseProvider];
    }
    return self;
}

+ (DGCBEAlgorithmKey *)GAZE_ESTIMATION {
    GET_TASK_KEY(gazeEstimation, NO)
}

- (int)initTask {
#if BEF_GAZE_ESTIMATION_TOB
    bef_effect_result_t dgc_ret = bef_effect_ai_gaze_estimation_create_handle(&_dgc_handle);
    CHECK_RET_AND_RETURN(bef_effect_ai_gaze_estimation_create_handle, dgc_ret)
    if (self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_effect_ai_gaze_estimation_check_license(_dgc_handle, [self.licenseProvider licensePath:BEF_GAZE_ESTIMATION]);
        CHECK_RET_AND_RETURN(bef_effect_ai_gaze_estimation_check_license, dgc_ret)
    }
    else if (self.licenseProvider.licenseMode == ONLINE_LICENSE){
        if (![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;
        
        dgc_ret = bef_effect_ai_gaze_estimation_check_online_license(_dgc_handle, [self.licenseProvider licensePath:BEF_GAZE_ESTIMATION]);
        CHECK_RET_AND_RETURN(bef_effect_ai_gaze_estimation_check_online_license, dgc_ret)
    }
    
    dgc_ret = bef_effect_ai_gaze_estimation_init_model(_dgc_handle, BEF_GAZE_ESTIMATION_MODEL1, self.provider.gazeModel);
    CHECK_RET_AND_RETURN(bef_effect_ai_gaze_estimation_init_model, dgc_ret)
    dgc_ret = [_dgc_faceTask initTask];
    return dgc_ret;
    
#endif
    return BEF_RESULT_INVALID_INTERFACE;
    
}

- (id)process:(const unsigned char *)buffer width:(int)width height:(int)height stride:(int)stride format:(bef_ai_pixel_format)format rotation:(bef_ai_rotate_type)rotation {
#if BEF_GAZE_ESTIMATION_TOB
    DGCBEGazeEstimationAlgorithmResult *dgc_result = [DGCBEGazeEstimationAlgorithmResult new];
    
    DGCBEFaceAlgorithmResult *faceRet = [_dgc_faceTask process:buffer width:width height:height stride:stride format:format rotation:rotation];
    
    memset(&_dgc_gazeInfo, 0, sizeof(bef_ai_gaze_estimation_info));
    bef_ai_face_info *dgc_faceInfo = faceRet.faceInfo;
    if (dgc_faceInfo != nil && dgc_faceInfo->face_count > 0) {
        RECORD_TIME(gazeEstimation)
        bef_effect_result_t dgc_ret = bef_effect_ai_gaze_estimation_detect(_dgc_handle, buffer, format, width, height, stride, rotation, dgc_faceInfo, LINE_LEN, &_dgc_gazeInfo);
        STOP_TIME(gazeEstimation)
        CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_gaze_estimation_detect, dgc_ret, dgc_result)
    }
    
    dgc_result.gazeInfo = &_dgc_gazeInfo;
    return dgc_result;
    
#endif
    return nil;
}

- (int)destroyTask {
#if BEF_GAZE_ESTIMATION_TOB
    bef_effect_ai_gaze_estimation_destroy(_dgc_handle);
    [_dgc_faceTask destroyTask];
    return 0;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEAlgorithmKey *)key {
    return DGCBEGazeEstimationTask.GAZE_ESTIMATION;
}

@end
