//  DGCBESkeletonAlgorithmTask.m
// EffectsARSDK


#import "DGCBEActionRecognitionAlgorithmTask.h"

@implementation DGCBEActionRecognitionAlgorithmResult

@end

@interface DGCBEActionRecognitionAlgorithmTask () {
    bef_effect_handle_t             _dgc_handle;
    bef_ai_action_recognition_result            *_dgc_actionRecognitionInfo;
    int _dgc_confirm_time;
}

@property (nonatomic, strong) id<BEActionRecognitionResourceProvider> provider;

@end

@implementation DGCBEActionRecognitionAlgorithmTask

@dynamic provider;

+ (DGCBEAlgorithmKey *)ACTION_RECOGNITION {
    GET_TASK_KEY(action_recognition, YES)
}

- (int)initTaskWithSportName:(NSString*)name {
#if BEF_ACTION_RECOGNITION_TOB
    bef_effect_result_t dgc_ret = bef_effect_ai_action_recognition_create(self.provider.actionRecognitionModel, &_dgc_handle);
    CHECK_RET_AND_RETURN(bef_effect_ai_action_recognition_create, dgc_ret)
    if (self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_effect_ai_action_recognition_check_license(_dgc_handle, [self.licenseProvider licensePath:BEF_ACTION_RECOGNETION]);
        CHECK_RET_AND_RETURN(bef_effect_ai_action_recognition_check_license, dgc_ret)
    }
    else if (self.licenseProvider.licenseMode == ONLINE_LICENSE){
        if (![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;
        
        dgc_ret = bef_effect_ai_action_recognition_check_online_license(_dgc_handle, [self.licenseProvider licensePath:BEF_ACTION_RECOGNETION]);
        CHECK_RET_AND_RETURN(bef_effect_ai_action_recognition_check_online_license, dgc_ret)
    }
    const char* path = NULL;
    [self getTemplatePathWithSportsName:name path:&path];
    dgc_ret = bef_effect_ai_action_recognition_set_template(_dgc_handle,path);
    CHECK_RET_AND_RETURN(bef_effect_ai_action_recognition_set_template, dgc_ret)
    
    _dgc_actionRecognitionInfo = malloc(sizeof(bef_ai_action_recognition_result));
    
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

-(void)getTemplatePathWithSportsName:(NSString*)name path:(const char**)path
{
    _dgc_confirm_time = 3000;
    if([name isEqualToString:@"openclose"])
    {
        *path = self.provider.actionRecognitionTMPL_OpenClose;
        _dgc_confirm_time = 2000;
    }
    else if([name isEqualToString:@"plank"])
    {
        *path = self.provider.actionRecognitionTMPL_PLANK;
    }
    else if([name isEqualToString:@"situp"])
    {
        *path = self.provider.actionRecognitionTMPL_SITUP;
    }
    else if([name isEqualToString:@"squat"])
    {
        *path = self.provider.actionRecognitionTMPL_SQUAT;
    }
    else if([name isEqualToString:@"pushup"])
    {
        *path = self.provider.actionRecognitionTMPL_PUSHUP;
    }
    else if([name isEqualToString:@"lunge"])
    {
        *path = self.provider.actionRecognitionTMPL_LUNGE;
    }
    else if([name isEqualToString:@"lunge_squat"])
    {
        *path = self.provider.actionRecognitionTMPL_LUNGESQUAT;
    }
    else if([name isEqualToString:@"high_run"])
    {
        *path = self.provider.actionRecognitionTMPL_HIGHRUN;
    }
    else if([name isEqualToString:@"hip_bridge"])
    {
        *path = self.provider.actionRecognitionTMPL_HIPBRIDGE;
    }
    else if([name isEqualToString:@"kneeling_pushup"])
    {
        *path = self.provider.actionRecognitionTMPL_KNEELINGPUSHUP;
    }
    else
    {
        NSAssert(1, @"no template for %@!",name);
    }    
}

- (DGCBEActionRecognitionAlgorithmResult *)process:(const unsigned char *)buffer width:(int)widht height:(int)height stride:(int)stride format:(bef_ai_pixel_format)format rotation:(bef_ai_rotate_type)rotation {
#if BEF_ACTION_RECOGNITION_TOB

    DGCBEActionRecognitionAlgorithmResult *dgc_result = [DGCBEActionRecognitionAlgorithmResult new];
    RECORD_TIME(detectActionRecognition)
    bef_effect_result_t dgc_ret = bef_effect_ai_action_recognition_count(_dgc_handle, buffer, format, widht, height, stride, rotation,_dgc_confirm_time,  _dgc_actionRecognitionInfo);
    STOP_TIME(detectActionRecognition)
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_action_recognition_count, dgc_ret, dgc_result)
    dgc_result.actionRecognitionInfo = _dgc_actionRecognitionInfo;
    return dgc_result;
    
#endif
    return nil;
}

- (int)destroyTask {
#if BEF_ACTION_RECOGNITION_TOB

    bef_effect_ai_action_recognition_destroy(_dgc_handle);
    free(_dgc_actionRecognitionInfo);
    return 0;
    
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (BOOL)readyPostDetect:(const unsigned char *)buffer width:(int)widht height:(int)height stride:(int)stride format:(bef_ai_pixel_format)format rotation:(bef_ai_rotate_type)rotation readyPoseType:(bef_ai_action_recognition_start_pose_type) type {
#if BEF_ACTION_RECOGNITION_TOB

    bef_ai_action_recognition_start_pose_result dgc_result;
    RECORD_TIME(readyPoseDetect)
    bef_effect_result_t dgc_ret = bef_effect_ai_action_recognition_start_pose_detect(_dgc_handle, buffer, format, widht, height, stride, rotation,  type, &dgc_result);
    STOP_TIME(readyPoseDetect)
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_action_recognition_start_pose_detect, dgc_ret, NO)
        
    return dgc_result.is_detected;
    
#endif
    return nil;
}

- (DGCBEAlgorithmKey *)key {
    return DGCBEActionRecognitionAlgorithmTask.ACTION_RECOGNITION;
}

- (void)setThreshold:(float)threshold
{
#if BEF_ACTION_RECOGNITION_TOB
    const float minV = 0.3;
    const float maxV = 0.7;
    threshold = (threshold < minV) ? minV:(threshold > maxV ? maxV:threshold);
    bef_effect_ai_action_recognition_set_template_threshold(_dgc_handle,threshold);
#endif
}

@end
