//
//  DGCBEObjectTrackingAlgorithmTask.m
//  BECore
//
//  Created by wufanfan on 2022/12/29.
//

#import <Foundation/Foundation.h>
#import "DGCBEObjectTrackingAlgorithmTask.h"

@implementation DGCBEObjectTrackingAlgorithmResult
@end

@interface DGCBEObjectTrackingAlgorithmTask () {
    bef_ai_object_tracking_handle  _dgc_handle;
    
    bef_ai_object_tracking_bbox _dgc_inputBBox;
    bef_ai_fpoint _dgc_firstPoint;
    bef_ai_fpoint _dgc_lastPoint;
    
    bool _dgc_isTracking;
    bool _dgc_bboxSelected;
    bool _dgc_bboxInited;
    
    DGCBEObjectTrackingAlgorithmResult* _dgc_result;
    NSRecursiveLock* dgc_mutex;
}

@property (nonatomic, strong) id<BEObjectTrackingResourceProvider> provider;

@end

@implementation DGCBEObjectTrackingAlgorithmTask

@dynamic provider;
+ (DGCBEAlgorithmKey *)OBJECT_TRACKING {
    GET_TASK_KEY(object_tracking, YES);
}

+ (DGCBEAlgorithmKey *)OBJECT_TRACKING_START {
    GET_TASK_KEY(object_tracking_start, NO);
}

+ (DGCBEAlgorithmKey *)OBJECT_TRACKING_TOUCH_EVENT {
    GET_TASK_KEY(object_tracking_touch, NO);
}

- (int)initTask {
#if BEF_OBJECT_TRACKING_TOB
    int dgc_ret = bef_ai_object_tracking_create(&_dgc_handle);
    CHECK_RET_AND_RETURN(bef_ai_object_tracking_create, dgc_ret)
    dgc_ret = [self licenseCheck];
    
    bef_ai_object_tracking_param dgc_param;
    bef_ai_object_tracking_get_default_param(_dgc_handle, &dgc_param);
    dgc_ret = bef_ai_object_tracking_init(_dgc_handle, self.provider.objectTrackingModel, &dgc_param);
    CHECK_RET_AND_RETURN(bef_ai_object_tracking_init, dgc_ret)
    
    _dgc_result = [[DGCBEObjectTrackingAlgorithmResult alloc]init];
    memset(&_dgc_inputBBox, 0, sizeof(_dgc_inputBBox));
    memset(&_dgc_firstPoint, 0, sizeof(_dgc_firstPoint));
    memset(&_dgc_lastPoint, 0, sizeof(_dgc_lastPoint));
    _dgc_isTracking = false;
    _dgc_bboxSelected = false;
    _dgc_bboxInited = false;
    _dgc_result.bbox = &_dgc_inputBBox;
    
    dgc_mutex = [[NSRecursiveLock alloc]init];
    
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (id)process:(const unsigned char *)buffer width:(int)width height:(int)height stride:(int)stride format:(bef_ai_pixel_format)format rotation:(bef_ai_rotate_type)rotation {
#if BEF_OBJECT_TRACKING_TOB
    RECORD_TIME(objectTracking)
    if (_dgc_bboxSelected) {
        _dgc_inputBBox.bbox.centerX = (_dgc_firstPoint.x + _dgc_lastPoint.x) / 2.0;
        _dgc_inputBBox.bbox.centerY = (_dgc_firstPoint.y + _dgc_lastPoint.y) / 2.0;
        _dgc_inputBBox.bbox.width = fabs(_dgc_firstPoint.x - _dgc_lastPoint.x);
        _dgc_inputBBox.bbox.height = fabs(_dgc_firstPoint.y - _dgc_lastPoint.y);
        _dgc_inputBBox.bbox.rotateAngle = 0.0;
        
        _dgc_result.bbox = &_dgc_inputBBox;
        _dgc_result.bboxInited = true;
    } else {
        _dgc_result.isTracking = false;
        _dgc_result.bboxInited = false;
    }
    
    if (_dgc_isTracking && _dgc_bboxSelected && !_dgc_bboxInited) {
        _dgc_bboxSelected = false;
        int status = bef_ai_object_tracking_set_initial_bbox(_dgc_handle, buffer, format, width, height, 4, stride, &_dgc_inputBBox);
        _dgc_bboxInited = status == 0;
    }

    //  {zh} 主线程会修改_dgc_isTracking的状态  {en} The main thread modifies the state of _dgc_isTracking
    [dgc_mutex lock];
    if (_dgc_isTracking && _dgc_bboxInited) {
        bef_ai_object_tracking_track_frame(_dgc_handle, buffer, format, width, height, 4, stride, 0.0, &_dgc_inputBBox);
        _dgc_result.bbox = &_dgc_inputBBox;
        _dgc_result.isTracking = true;
    }
    [dgc_mutex unlock];
    
    STOP_TIME(objectTracking)
    return _dgc_result;
#endif
    return nil;
}

- (bef_effect_result_t)licenseCheck {
    bef_effect_result_t dgc_ret = -1;
#if BEF_OBJECT_TRACKING_TOB
    if(self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_ai_object_tracking_check_license(_dgc_handle, [self.licenseProvider licensePath:BEF_OBJECT_TRACKING]);
        CHECK_RET_AND_RETURN(bef_ai_object_tracking_check_license, dgc_ret);
    }
    else if(self.licenseProvider.licenseMode == ONLINE_LICENSE) {
        if(![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;
        
        dgc_ret = bef_ai_object_tracking_check_online_license(_dgc_handle, [self.licenseProvider licensePath:BEF_OBJECT_TRACKING]);
        CHECK_RET_AND_RETURN(bef_ai_object_tracking_check_online_license, dgc_ret);
    }
#endif
    return dgc_ret;
}

- (void)setConfig:(DGCBEAlgorithmKey *)key p:(NSObject *)p {
    [super setConfig:key p:p];
    
    if ([key.algorithmKey isEqualToString:DGCBEObjectTrackingAlgorithmTask.OBJECT_TRACKING.algorithmKey]) {
        bool open = [self boolConfig:DGCBEObjectTrackingAlgorithmTask.OBJECT_TRACKING orDefault:NO];
        if (!open) {
            [dgc_mutex lock];
            _dgc_isTracking = false;
            [dgc_mutex unlock];
            _dgc_bboxInited = false;
            _dgc_bboxSelected = false;
            memset(&_dgc_inputBBox, 0, sizeof(_dgc_inputBBox));
        }
    }
    if ([key.algorithmKey isEqualToString:DGCBEObjectTrackingAlgorithmTask.OBJECT_TRACKING_START.algorithmKey]) {
        [dgc_mutex lock];
        _dgc_isTracking = [self boolConfig:DGCBEObjectTrackingAlgorithmTask.OBJECT_TRACKING_START orDefault:NO];
        [dgc_mutex unlock];
        if (!_dgc_isTracking) {
            _dgc_bboxInited = false;
            _dgc_bboxSelected = false;
            memset(&_dgc_inputBBox, 0, sizeof(_dgc_inputBBox));
        }
    }
}

- (void)processTouchEvent:(bef_ai_touch_event_code)eventCode x:(float)dgc_x y:(float)dgc_y {
    if (_dgc_isTracking) return;
    switch(eventCode) {
        case BEF_AI_TOUCH_EVENT_BEGAN:
            _dgc_firstPoint.x = dgc_x;
            _dgc_firstPoint.y = dgc_y;
            _dgc_bboxSelected = false;
            break;
        case BEF_AI_TOUCH_EVENT_MOVED:
            _dgc_lastPoint.x = dgc_x;
            _dgc_lastPoint.y = dgc_y;
            _dgc_bboxSelected = true;
            break;
        default:
            break;
    }
}

- (int)destroyTask {
#if BEF_OBJECT_TRACKING_TOB
    bef_ai_object_tracking_destroy(_dgc_handle);
    return 0;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

-(DGCBEAlgorithmKey *)key {
    return DGCBEObjectTrackingAlgorithmTask.OBJECT_TRACKING;
}

@end
