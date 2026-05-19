//  DGCBEFaceAlgorithmTask.h
// EffectsARSDK


#import "DGCBEAlgorithmTask.h"
#import "bef_effect_ai_face_detect.h"
#import "bef_effect_ai_face_attribute.h"

@protocol BEFaceResourceProvider <BEAlgorithmResourceProvider>

- (const char *)faceModel;
- (const char *)faceExtraModel;
- (const char *)faceAttrModel;

@end

@interface DGCBEFaceAlgorithmResult : NSObject

@property (nonatomic, assign) bef_ai_face_info *faceInfo;
@property (nonatomic, assign) bef_ai_face_attribute_result *faceAttrInfo;
@property (nonatomic, assign) bef_ai_face_mask_info *faceMask;
@property (nonatomic, assign) bef_ai_mouth_mask_info *mouthMask;
@property (nonatomic, assign) bef_ai_teeth_mask_info *teethMask;

@end

@interface DGCBEFaceAlgorithmTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)FACE_106;
+ (DGCBEAlgorithmKey *)FACE_280;
+ (DGCBEAlgorithmKey *)FACE_ATTR;
+ (DGCBEAlgorithmKey *)FACE_MASK;
+ (DGCBEAlgorithmKey *)MOUTH_MASK;
+ (DGCBEAlgorithmKey *)TEETH_MASK;

@property (nonatomic, assign) unsigned long long initConfig;
@property (nonatomic, assign) unsigned long long detectConfig;
@property (nonatomic, assign) int maxFaceNum;

@end
