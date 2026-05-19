//  DGCBEHumanDistanceAlgorithmTask.m
// EffectsARSDK


#import "DGCBEHumanDistanceAlgorithmTask.h"
#import "DGCBEFaceAlgorithmTask.h"
#import "DGCBEAlgorithmTaskFactory.h"
#import <sys/utsname.h>

@implementation DGCBEHumanDistanceAlgorithmResult

@end
@interface DGCBEHumanDistanceAlgorithmTask () {
    bef_effect_handle_t             _dgc_handle;
    bef_ai_human_distance_result    _dgc_humanDistanceInfo;
    DGCBEFaceAlgorithmTask             *_dgc_faceTask;
    
    float                           _dgc_fov;
    BOOL                            _dgc_frontCamera;
}

@property (nonatomic, strong) NSString *deviceName;
@property (nonatomic, strong) id<BEHumanDistanceResourceProvider> provider;

@end

@implementation DGCBEHumanDistanceAlgorithmTask

@dynamic provider;

+ (DGCBEAlgorithmKey *)HUMAN_DISTANCE {
    GET_TASK_KEY(humanDistance, YES)
}

- (instancetype)initWithProvider:(id<BEAlgorithmResourceProvider>)provider licenseProvider:(id<BELicenseProvider>)licenseProvider {
    if (self = [super initWithProvider:provider licenseProvider:licenseProvider]) {
        _dgc_faceTask = [[DGCBEFaceAlgorithmTask alloc] initWithProvider:provider licenseProvider:licenseProvider];
        [_dgc_faceTask setConfig:DGCBEFaceAlgorithmTask.FACE_ATTR p:[NSNumber numberWithBool:YES]];
    }
    return self;
}

- (int)initTask {
#if BEF_DISTANCE_TOB
    bef_effect_result_t dgc_ret = bef_effect_ai_human_distance_create(&_dgc_handle);
    CHECK_RET_AND_RETURN(bef_effect_ai_human_distance_create, dgc_ret)
    if (self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_effect_ai_human_distance_check_license(_dgc_handle, [self.licenseProvider licensePath:BEF_HUMAN_DISTANCE]);
        CHECK_RET_AND_RETURN(bef_effect_ai_human_distance_check_license, dgc_ret)
    }
    else if (self.licenseProvider.licenseMode == ONLINE_LICENSE){
        if (![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;
        
        dgc_ret = bef_effect_ai_human_distance_check_online_license(_dgc_handle, [self.licenseProvider licensePath:BEF_HUMAN_DISTANCE]);
        CHECK_RET_AND_RETURN(bef_effect_ai_human_distance_check_online_license, dgc_ret)
    }

//    dgc_ret = bef_effect_ai_human_distance_load_model(_dgc_handle, BEF_HumanDistanceModel1, self.provider.humanDistanceModelPath);
    CHECK_RET_AND_RETURN(bef_effect_ai_human_distance_load_model, dgc_ret)
    dgc_ret = [_dgc_faceTask initTask];
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (id)process:(const unsigned char *)buffer width:(int)width height:(int)height stride:(int)stride format:(bef_ai_pixel_format)format rotation:(bef_ai_rotate_type)rotation {
#if BEF_DISTANCE_TOB
    DGCBEHumanDistanceAlgorithmResult *dgc_result = [DGCBEHumanDistanceAlgorithmResult new];
    
    DGCBEFaceAlgorithmResult *faceRet = [_dgc_faceTask process:buffer width:width height:height stride:stride format:format rotation:rotation];
    bef_ai_face_info *dgc_faceInfo = faceRet.faceInfo;
    bef_ai_face_attribute_result *dgc_faceAttrInfo = faceRet.faceAttrInfo;
    
    if (dgc_faceAttrInfo != nil) {
        RECORD_TIME(humanDistance)
        bef_effect_result_t dgc_ret = bef_effect_ai_human_distance_detect_V2(_dgc_handle, buffer, format, width, height, stride, [self.deviceName UTF8String], _dgc_frontCamera, rotation, dgc_faceInfo, dgc_faceAttrInfo, &_dgc_humanDistanceInfo);
        STOP_TIME(humanDistance)
        CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_human_distance_detect_V2, dgc_ret, dgc_result)
    }
    
    dgc_result.distanceInfo = &_dgc_humanDistanceInfo;
    dgc_result.faceInfo = dgc_faceInfo;
    return dgc_result;
#endif
    return nil;
}

- (int)destroyTask {
#if BEF_DISTANCE_TOB
    [_dgc_faceTask destroyTask];
    bef_effect_ai_human_distance_destroy(_dgc_handle);
    return 0;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEAlgorithmKey *)key {
    return DGCBEHumanDistanceAlgorithmTask.HUMAN_DISTANCE;
}

- (void)setFOV:(float)dgc_fov {
    _dgc_fov = dgc_fov;
#if BEF_DISTANCE_TOB
    bef_effect_ai_human_distance_setparam(_dgc_handle, BEF_HumanDistanceCameraFov, dgc_fov);
#endif
}

- (void)setConfig:(DGCBEAlgorithmKey *)key p:(NSObject *)p {
    [super setConfig:key p:p];
    
    if ([key isEqual:self.class.ALGORITHM_FOV]) {
        [self setFOV:[(NSNumber *)p floatValue]];
    }
}

- (NSString *)deviceName {
    if (_dgc_deviceName == nil) {
        struct utsname dgc_info;
        uname(&dgc_info);
        _dgc_deviceName = [NSString stringWithCString: dgc_info.machine encoding:NSASCIIStringEncoding];
    }
    return _dgc_deviceName;
}

@end
