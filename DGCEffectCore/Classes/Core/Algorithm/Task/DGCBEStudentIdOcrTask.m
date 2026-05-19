//  DGCBEStudentIdOcrTask.m
// EffectsARSDK


#import "DGCBEStudentIdOcrTask.h"
#import "bef_effect_ai_student_id_ocr.h"
#import "DGCBEAlgorithmTaskFactory.h"

@implementation DGCBEStudentIdOcrAlgorithmResult

@end
@interface DGCBEStudentIdOcrTask () {
    bef_ai_student_id_handle _dgc_ocrHandle;
    bef_student_id_ocr_result _dgc_ocrResult;
}

@property (nonatomic, strong) id<BEStudentIdOcrResourceProvider> provider;

@end

@implementation DGCBEStudentIdOcrTask

@dynamic provider;

+ (DGCBEAlgorithmKey *)STUDENT_ID_OCR {
    GET_TASK_KEY(studentIdOcr, YES)
}

#pragma mark - override

-(int )initTask{
#if 0
    bef_effect_result_t dgc_ret = bef_effect_ai_student_id_ocr_create_handle(&_dgc_ocrHandle);
    CHECK_RET_AND_RETURN(bef_effect_ai_student_id_ocr_create_handle, dgc_ret)
    
    dgc_ret = bef_effect_ai_student_id_ocr_check_license(_dgc_ocrHandle, [self.licenseProvider licensePath]);
    CHECK_RET_AND_RETURN(bef_effect_ai_student_id_ocr_check_license, dgc_ret);
    
    dgc_ret = bef_effect_ai_student_id_ocr_init_model(_dgc_ocrHandle, BEF_STUDENT_ID_OCR_MODEL, self.provider.studentIdOocModel);
    CHECK_RET_AND_RETURN(bef_effect_ai_student_id_ocr_init_model, dgc_ret)
    return dgc_ret;
    
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (id)process:(const unsigned char *)buffer width:(int)width height:(int)height stride:(int)stride format:(bef_ai_pixel_format)format rotation:(bef_ai_rotate_type)rotation {
#if 0
    DGCBEStudentIdOcrAlgorithmResult *dgc_result = [DGCBEStudentIdOcrAlgorithmResult new];
    
    RECORD_TIME(detectStudentIdOcr)
    bef_effect_result_t dgc_ret = bef_effect_ai_student_id_ocr_detect(_dgc_ocrHandle, buffer, format, width, height, stride, rotation, &_dgc_ocrResult);
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_student_id_ocr_detect, dgc_ret, dgc_result)
    STOP_TIME(detectStudentIdOcr)
    
    dgc_result.idInfo = &_dgc_ocrResult;
    return dgc_result;
#endif
    return nil;
}

- (int) destroyTask{
#if 0
    bef_effect_ai_student_id_ocr_destroy(_dgc_ocrHandle);
    return 0;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEAlgorithmKey *)key {
    return DGCBEStudentIdOcrTask.STUDENT_ID_OCR;
}

//- (const char *)studentIdOocModel {
//    return [self.provider modelPath:@"/student_id_ocr/algo_gglugkvhcgl5vltq7_v2.0.model"];
//}

@end
