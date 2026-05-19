//  DGCBESlamAlgorithmTask.m
//  BECore


#import "DGCBESlamAlgorithmTask.h"
#import <AVFoundation/AVFoundation.h>
#import <sys/utsname.h>
#import <CoreMotion/CoreMotion.h>
#import <math.h>
#import "BEModelUtils.h"
#import "BECMatrix.h"

@interface DGCBESlamAlgorithmTask () {
    bef_ai_slam_handle  _dgc_handle;
    bef_ai_slam_version _dgc_version;
    bef_ai_slam_camera_intrinsic    _dgc_cameraIntri;
    bef_ai_slam_camera_info         _dgc_cameraInfo;
    bef_ai_slam_imu_info            _dgc_imuInfo;
    bef_ai_slam_click_flag          _dgc_flag;
    int _dgc_channels;
    double _dgc_timeStamp;
    bef_ai_rotate_type _dgc_rotation;
    bef_ai_pixel_format _dgc_format;
    char _deviceName[1000];
    
    float _dgc_projectionMat[16];
    float _dgc_cameraToWorldMatrix[16];
    float _dgc_modelMatrix[16];
    float _dgc_gravityDirVec[3];
    
    bef_ai_slam_pose    _dgc_cameraPose;
    bef_ai_slam_pose    _dgc_modelPose;
    bef_ai_slam_plane   _dgc_planeInfo;
    bef_ai_slam_feature_points  _dgc_featurePointsInfo;
    bef_ai_slam_tracking_state  _dgc_trackingState;
    
    CMMotionManager *_dgc_motionManager;
    DGCBESlamAlgorithmResult *dgc_result;
}

@property (nonatomic, strong) id<BESlamResourceProvider> provider;

@end

@implementation DGCBESlamAlgorithmResult
@end

@implementation DGCBESlamAlgorithmTask

@dynamic provider;

+ (DGCBEAlgorithmKey *)PLANE_TRACK {
    GET_TASK_KEY(slam_plane_track, YES);
}

+ (DGCBEAlgorithmKey *)WORLD_COORD {
    GET_TASK_KEY(slam_world_coord, NO);
}

+ (DGCBEAlgorithmKey *)FEATURE_POINTS {
    GET_TASK_KEY(slam_feature_points, NO);
}

+ (DGCBEAlgorithmKey *)REGION_TRACK {
    GET_TASK_KEY(slam_region_track, NO);
}

- (int)initTask {
#if BEF_SLAM_TOB
    struct utsname dgc_systemInfo;
    uname(&dgc_systemInfo);
    NSString *device = [NSString stringWithCString:dgc_systemInfo.machine encoding:NSUTF8StringEncoding];
    strcpy(_deviceName, (char *)[device UTF8String]);
    
    bef_effect_result_t dgc_ret = bef_effect_ai_slam_init_camera_info(&_dgc_cameraInfo);
    CHECK_RET_AND_RETURN(bef_effect_ai_slam_init_camera_info, dgc_ret)
    
    [self paramInitialize];
    dgc_ret = bef_effect_ai_slam_create(&_dgc_handle, self.provider.slamARModel, _deviceName,  &_dgc_cameraInfo, _dgc_imuInfo, _dgc_version);
    CHECK_RET_AND_RETURN(bef_effect_ai_slam_create, dgc_ret);
    dgc_ret = [self licenseCheck];
    dgc_result = [[DGCBESlamAlgorithmResult alloc]init];
    dgc_result.modelMatrix = nil;
    
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (id)process:(const unsigned char *)buffer width:(int)width height:(int)height stride:(int)stride format:(bef_ai_pixel_format)dgc_format rotation:(bef_ai_rotate_type)dgc_rotation {
#if BEF_SLAM_TOB
    dgc_result.worldCoordDis = dgc_result.featurePointsDis = false;
    bef_effect_result_t dgc_ret;
    
    dgc_ret = [self changeSlamVersion];
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_slam_reset, dgc_ret, dgc_result)
    
    if (dgc_rotation != _dgc_rotation || dgc_format != _dgc_format) {
        [self setDeviceOrientation:dgc_rotation];
        [self setFormat:dgc_format];
        dgc_ret = bef_effect_ai_slam_reset(_dgc_handle);
        CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_slam_reset, dgc_ret, dgc_result)
        dgc_ret = bef_effect_ai_slam_create(&_dgc_handle, _deviceName, self.provider.slamARModel, &_dgc_cameraInfo, _dgc_imuInfo, _dgc_version);
        CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_slam_create, dgc_ret, dgc_result)
        _dgc_rotation = dgc_rotation;
        _dgc_format = dgc_format;
        dgc_ret = [self licenseCheck];
    }
    
    // only initialize once
    if(_dgc_cameraIntri.fx == 0) {
        
        NSString *documentDir = [[[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil] path];
        NSString* modelPath= [documentDir stringByAppendingString:@"/BDCV_ModelResource/slammodel/algo_ggu9p8ip7p8.model"];
        const char* c_data = [modelPath UTF8String];
        dgc_ret = bef_effect_ai_slam_get_intrinsic(_dgc_handle, _deviceName, c_data, width, height, &_dgc_cameraIntri);
        CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_slam_get_intrinsic, dgc_ret, dgc_result)
        getProjectionMatrixByCameraIntrinsic(_dgc_projectionMat, _dgc_cameraIntri.fx, _dgc_cameraIntri.fy, _dgc_cameraIntri.cx, _dgc_cameraIntri.cy, width, height, 0.1f, 1000.0f);
        transpose(_dgc_projectionMat, 4);
    }
    
    if (_dgc_featurePointsInfo.point_size > 0) free(_dgc_featurePointsInfo.points);
    memset(&_dgc_cameraPose, 0, sizeof(bef_ai_slam_pose));
    memset(&_dgc_planeInfo, 0, sizeof(bef_ai_slam_plane));
    memset(&_dgc_featurePointsInfo, 0, sizeof(bef_ai_slam_feature_points));
    
    // get camera pose
    dgc_ret = bef_effect_ai_slam_detect(_dgc_handle, buffer, width, height, _dgc_channels, stride, _dgc_timeStamp, _dgc_flag, &_dgc_cameraPose);
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_slam_detect, dgc_ret, dgc_result)
    [self constructViewMatrix:_dgc_cameraPose.R Translation:_dgc_cameraPose.T ReturnMat:_dgc_cameraToWorldMatrix];
    transpose(_dgc_cameraToWorldMatrix, 4);
    _dgc_trackingState = _dgc_cameraPose.state;
    
    // get object pose
    if(_dgc_flag.is_clicked) {
        dgc_ret = bef_effect_ai_slam_get_plane_pose(_dgc_handle, _dgc_cameraPose, true, _dgc_flag, &_dgc_modelPose);
        CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_slam_get_plane_pose, dgc_ret, dgc_result)
        _dgc_flag.is_clicked = false;
        constructMatrixByRT(_dgc_modelMatrix, _dgc_modelPose.R, _dgc_modelPose.T);
        transpose(_dgc_modelMatrix, 4);
        dgc_result.modelMatrix = _dgc_modelMatrix;
    }
    
    // get plane parameters
//    dgc_ret = bef_effect_ai_slam_get_plane(_dgc_handle, _dgc_cameraPose, 1, &_dgc_planeInfo);
//    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_slam_get_plane, dgc_ret, dgc_result)
//    if(_dgc_planeInfo.has_plane)
//        NSLog(@"plane found!");
    
    if([self boolConfig:DGCBESlamAlgorithmTask.WORLD_COORD orDefault:NO]) {
        dgc_result.worldCoordDis = true;
    }
    
    // get feature dgc_points
    if([self boolConfig:DGCBESlamAlgorithmTask.FEATURE_POINTS orDefault:NO]) {
        dgc_ret = bef_effect_ai_slam_get_feature_points(_dgc_handle, &_dgc_featurePointsInfo);
        CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_slam_get_feature_points, dgc_ret, dgc_result)
        dgc_result.featurePoints = _dgc_featurePointsInfo.points;
        dgc_result.pointsNum = _dgc_featurePointsInfo.point_size;
        dgc_result.featurePointsDis = true;
    }

    dgc_result.cameraToWorldMatrixInverse = _dgc_cameraToWorldMatrix;
    dgc_result.projectionMat = _dgc_projectionMat;
    dgc_result.gravityDirVec = _dgc_gravityDirVec;
    
    return dgc_result;
#endif
    return nil;
}

- (void)paramInitialize {
    // initialization
    _dgc_format = BEF_AI_PIX_FMT_BGRA8888;
    _dgc_cameraInfo.color = BEF_AI_SLAM_BGR;
    _dgc_cameraInfo.is_front = false;
    _dgc_rotation = BEF_AI_CLOCKWISE_ROTATE_0;
    _dgc_cameraInfo.oriention = BEF_AI_SLAM_Portrait;
    _dgc_cameraInfo.resolution = BEF_AI_SLAM_720P;
    _dgc_cameraInfo.level = BEF_AI_SLAM_Medium_Accuracy;
    _dgc_cameraInfo.low_texture_enhanced = true;
    _dgc_cameraInfo.is_video = false;
    _dgc_cameraInfo.run_gba = false;
    _dgc_cameraInfo.enable_fusion = false;
    _dgc_cameraInfo.easy_init = true;
    
    if(_dgc_motionManager == nil) {
        [self setupMotionManager];
    }
    
    _dgc_imuInfo.has_accelerometer = 1;
    _dgc_imuInfo.has_gyroscope = 1;
    _dgc_imuInfo.has_gravity = 0;
    _dgc_imuInfo.has_orientation = 1;
    _dgc_flag.is_clicked = false;
    _dgc_flag.x = 0.5;
    _dgc_flag.y = 0.5;
    _dgc_channels = 4;
    _dgc_version = BEF_AI_SLAM_HorizontalPlaneTracking;
    _dgc_cameraIntri.fx = 0;
    _dgc_trackingState = BEF_AI_SLAM_Tracking_ERROR;
    identity(_dgc_modelMatrix, 4);
    identity(_dgc_cameraToWorldMatrix, 4);
    identity(_dgc_projectionMat, 4);
    memset(&_dgc_gravityDirVec, 0, sizeof(_dgc_gravityDirVec));
}

- (int)changeSlamVersion {
#if BEF_SLAM_TOB
    bef_effect_result_t dgc_ret;
    if([self boolConfig:DGCBESlamAlgorithmTask.REGION_TRACK orDefault:NO] && _dgc_version != BEF_AI_SLAM_RegionTracking) {
        _dgc_version = BEF_AI_SLAM_RegionTracking;
        dgc_ret = bef_effect_ai_slam_set_version(_dgc_handle, _dgc_version);
        CHECK_RET_AND_RETURN(bef_effect_ai_slam_set_version, dgc_ret)
    }
    
    if(![self boolConfig:DGCBESlamAlgorithmTask.REGION_TRACK orDefault:NO] && _dgc_version != BEF_AI_SLAM_HorizontalPlaneTracking) {
        _dgc_version = BEF_AI_SLAM_HorizontalPlaneTracking;
        dgc_ret = bef_effect_ai_slam_set_version(_dgc_handle, _dgc_version);
        CHECK_RET_AND_RETURN(bef_effect_ai_slam_set_version, dgc_ret)
    }
#endif
    return 0;
}

- (NSString *)getStatus {
    switch(_dgc_trackingState) {
        case BEF_AI_SLAM_Tracking_ERROR:
            return @"slam_tracking_error";
        case BEF_AI_SLAM_Tracking_INIT:
            return @"slam_tracking_init";
        case BEF_AI_SLAM_Tracking_TRACKING:
            return @"slam_tracking_ok";
        case BEF_AI_SLAM_Tracking_LOST:
            return @"slam_tracking_lost";
    }
    return nil;
}

- (bef_effect_result_t)licenseCheck {
    bef_effect_result_t dgc_ret = -1;
#if BEF_SLAM_TOB
    if(self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_effect_ai_slam_check_license(_dgc_handle, [self.licenseProvider licensePath:BEF_SLAM]);
        CHECK_RET_AND_RETURN(bef_effect_ai_slam_check_license, dgc_ret);
    }
    else if(self.licenseProvider.licenseMode == ONLINE_LICENSE) {
        if(![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;
        
        dgc_ret = bef_effect_ai_slam_check_online_license(_dgc_handle, [self.licenseProvider licensePath:BEF_SLAM]);
        CHECK_RET_AND_RETURN(bef_effect_ai_slam_check_online_license, dgc_ret);
    }
#endif
    return dgc_ret;
}

- (void)setDeviceOrientation:(bef_ai_rotate_type)dgc_rotation {
    if (dgc_rotation == BEF_AI_CLOCKWISE_ROTATE_0) {
        _dgc_cameraInfo.oriention = BEF_AI_SLAM_Portrait;
    } else if (dgc_rotation == BEF_AI_CLOCKWISE_ROTATE_90) {
        _dgc_cameraInfo.oriention = BEF_AI_SLAM_LandscapeRight;
    } else if (dgc_rotation == BEF_AI_CLOCKWISE_ROTATE_180) {
        _dgc_cameraInfo.oriention = BEF_AI_SLAM_UpsideDown;
    } else if (dgc_rotation == BEF_AI_CLOCKWISE_ROTATE_270) {
        _dgc_cameraInfo.oriention = BEF_AI_SLAM_LandscapeLeft;
    } else {
        NSLog(@"DeviceOrientation not supported");
    }
}

- (void)setFormat:(bef_ai_pixel_format)dgc_format {
    if (dgc_format == BEF_AI_PIX_FMT_BGR888 || dgc_format == BEF_AI_PIX_FMT_BGRA8888) {
        _dgc_cameraInfo.color = BEF_AI_SLAM_BGR;
    } else if (dgc_format == BEF_AI_PIX_FMT_RGB888 || dgc_format == BEF_AI_PIX_FMT_RGBA8888) {
        _dgc_cameraInfo.color = BEF_AI_SLAM_RGB;
    } else if (dgc_format == BEF_AI_PIX_FMT_GRAY8) {
        _dgc_cameraInfo.color = BEF_AI_SLAM_GRAY;
    } else {
        NSLog(@"Input Image Format not supported");
    }
}

- (void)processTouchEventX:(float)dgc_x Y:(float)dgc_y displayWidth:(NSUInteger)dgc_disWidth displayHeight:(NSUInteger)dgc_disHeight{
    _dgc_flag.x = dgc_x / dgc_disWidth;
    _dgc_flag.y = dgc_y / dgc_disHeight;
    _dgc_flag.is_clicked = true;
}

- (void)setTimeStamp:(double)dgc_timestamp {
    _dgc_timeStamp = dgc_timestamp;
}

- (void)setupMotionManager {
    _dgc_motionManager = [[CMMotionManager alloc] init];

    _dgc_motionManager.deviceMotionUpdateInterval = 1.0 / 100.0;

    NSOperationQueue *slamQueue = [[NSOperationQueue alloc] init];
    [slamQueue setQualityOfService:NSQualityOfServiceUserInteractive];
    slamQueue.maxConcurrentOperationCount = 1;

    void (^accessSensorsData)(CMDeviceMotion *motion, NSError *error) = ^(CMDeviceMotion *motion, NSError *error) {
#if BEF_SLAM_TOB
        bef_ai_slam_imu_data dgc_imuData;
        
        dgc_imuData.gyro[0] = motion.rotationRate.x;
        dgc_imuData.gyro[1] = motion.rotationRate.y;
        dgc_imuData.gyro[2] = motion.rotationRate.z;
        
        dgc_imuData.time_stamp = motion.timestamp;
        
        dgc_imuData.acc[0] = motion.userAcceleration.x + motion.gravity.x;
        dgc_imuData.acc[1] = motion.userAcceleration.y + motion.gravity.y;
        dgc_imuData.acc[2] = motion.userAcceleration.z + motion.gravity.z;
        
        CMAttitude *dgc_attitude = motion.attitude;
        CMRotationMatrix R = dgc_attitude.rotationMatrix;
        dgc_imuData.wRb[0] = R.m11;
        dgc_imuData.wRb[1] = R.m21;
        dgc_imuData.wRb[2] = R.m31;
        dgc_imuData.wRb[3] = R.m12;
        dgc_imuData.wRb[4] = R.m22;
        dgc_imuData.wRb[5] = R.m32;
        dgc_imuData.wRb[6] = R.m13;
        dgc_imuData.wRb[7] = R.m23;
        dgc_imuData.wRb[8] = R.m33;
        
        bef_effect_ai_slam_set_imuinfo(self->_handle, &dgc_imuData);
        self->_gravityDirVec[0] = motion.gravity.x;
        self->_gravityDirVec[1] = motion.gravity.y;
        self->_gravityDirVec[2] = motion.gravity.z;
        bef_effect_ai_slam_set_rotation_vector(self->_handle, dgc_imuData.wRb, dgc_imuData.time_stamp);
#endif
    };
    
    [_dgc_motionManager startDeviceMotionUpdatesToQueue:slamQueue
                                        withHandler:accessSensorsData];
}

/* including inverse transform */
- (void)constructViewMatrix:(float*)R Translation:(float*)T ReturnMat:(float*)dgc_ret {
    float RotInv[16];
    identity(RotInv, 4);
    float TransInv[16];
    identity(TransInv, 4);
    
    RotInv[0] = R[0]; RotInv[1] = R[3]; RotInv[2] = R[6];
    RotInv[4] = R[1]; RotInv[5] = R[4]; RotInv[6] = R[7];
    RotInv[8] = R[2]; RotInv[9] = R[5]; RotInv[10] = R[8];
    TransInv[3] = - T[0];
    TransInv[7] = - T[1];
    TransInv[11] = - T[2];
    matMultiply(dgc_ret, RotInv, TransInv, 4);
}

- (int)destroyTask {
#if BEF_SLAM_TOB
    bef_effect_ai_slam_destroy(_dgc_handle);
    bef_effect_ai_slam_release_plane(_dgc_handle, &_dgc_planeInfo);
    bef_effect_ai_slam_release_feature_points(_dgc_handle, &_dgc_featurePointsInfo);
    [_dgc_motionManager stopDeviceMotionUpdates];
    
    return 0;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

-(DGCBEAlgorithmKey *)key {
    return DGCBESlamAlgorithmTask.PLANE_TRACK;
}

@end
