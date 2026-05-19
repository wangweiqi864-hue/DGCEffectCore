//  DGCBEPetFaceAlgorithmTask.h
// EffectsARSDK


#import "DGCBEAlgorithmTask.h"
#import "bef_effect_ai_pet_face.h"

@protocol BEPetFaceResourceProvider <BEAlgorithmResourceProvider>

- (const char *)petFaceModelPath;

@end

@interface DGCBEPetFaceAlgorithmResult : NSObject

@property (nonatomic, assign) bef_ai_pet_face_result *petFaceInfo;

@end

@interface DGCBEPetFaceAlgorithmTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)PET_FACE;

@end
