//  BEStudentIDOcrTask.h
// EffectsARSDK


#ifndef BEStudentIDOcrTask_h
#define BEStudentIDOcrTask_h

#import "DGCBEAlgorithmTask.h"
#import "bef_effect_ai_student_id_ocr.h"

@protocol BEStudentIdOcrResourceProvider <BEAlgorithmResourceProvider>

-(const char*)studentIdOocModel;

@end

@interface DGCBEStudentIdOcrAlgorithmResult : NSObject

@property (nonatomic, assign) bef_student_id_ocr_result *idInfo;

@end

@interface DGCBEStudentIdOcrTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)STUDENT_ID_OCR;

@end

#endif /* BEStudentIDOcrTask_h */
