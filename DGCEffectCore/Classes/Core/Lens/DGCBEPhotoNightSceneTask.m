//  DGCBEPhotoNightSceneTask.m
//  BECore


#import <Foundation/Foundation.h>
#import "DGCBEPhotoNightSceneTask.h"
#import "DGCBELensResourceHelper.h"
#import "BEImageOpeartion.h"

@interface DGCBEPhotoNightSceneTask()
@property(nonatomic, assign) bef_image_quality_enhancement_handle handle;
@property(nonatomic, assign) CVPixelBufferRef resultPixelBuffer;
@property(nonatomic, assign) int width;
@property(nonatomic, assign) int height;
@property(nonatomic, assign) int inputNum;
@end


@implementation DGCBEPhotoNightSceneTask

- (instancetype)init{
    if (self = [super init]) {
        self.inited = false;
    }
    return self;
}
-(int)initTaskWidth:(int)width height:(int)height imageNum:(int)imageNum
{
#if BEF_LENS_NIGHT_SCENE_TOB
    DGCBELensResourceHelper *resourceHelper = [DGCBELensResourceHelper new];
    int ret = bef_ai_image_quality_enhancement_photo_night_scene_create(&_handle, resourceHelper.skinSegPath, width, height, imageNum, BEF_AI_LENS_NV12);
    CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_photo_night_scene_create, ret)
    
    if (self.provider.licenseMode == OFFLINE_LICENSE) {
        ret = bef_ai_image_quality_enhancement_photo_night_scene_check_license(_handle, [self.provider licensePath:BEF_PHOTO_NIGHT_SCENE]);
    } else {
        ret = bef_ai_image_quality_enhancement_photo_night_scene_check_online_license(_handle, [self.provider licensePath:BEF_PHOTO_NIGHT_SCENE]);
    }
    
    CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_photo_night_scene_check_license, ret)
    _width = width;
    _height = height;
    _inputNum = imageNum;
    _inited = true;
    return ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}


-(CVPixelBufferRef)processMutilBuffer:(NSArray<NSValue*>*)buffers
{
#if BEF_LENS_NIGHT_SCENE_TOB
    if (!_inited) return nil;
    void* input[buffers.count];
    for (int i = 0; i < _inputNum; i ++) {
        input[i] = [buffers[i] pointerValue];
    }
    
    void* output = NULL;
    RECORD_TIME(night_scene);
    int ret = bef_ai_image_quality_enhancement_photo_night_scene_process(_handle, input, (int)_inputNum, &output);
    STOP_TIME(night_scene);
    CHECK_RET_AND_RETURN_RESULT(bef_ai_image_quality_enhancement_photo_night_scene_process, ret, nil)
    CVPixelBufferRef result = output;
    return result;
#endif
    return nil;
}


- (int)destroyTask{
#if BEF_LENS_NIGHT_SCENE_TOB
    if (_resultPixelBuffer != nil) {
        CFRelease(_resultPixelBuffer);
        _resultPixelBuffer = nil;
    }
    return bef_ai_image_quality_enhancement_photo_night_scene_destroy(_handle);
#endif
    return 0;
}
@end
