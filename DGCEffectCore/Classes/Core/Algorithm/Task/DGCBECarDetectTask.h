//  BECarDamageDetectTask.h
// EffectsARSDK


#import "DGCBEAlgorithmTask.h"
#import "bef_effect_ai_car_detect.h"

@protocol BECarResourceProvider <BEAlgorithmResourceProvider>

- (const char *)carDetectModel;
- (const char *)carLandmarkModel;
- (const char *)carPlateOcrModel;
- (const char *)carTrackModel;

@end

@interface DGCBECarAlgorithmResult : NSObject

@property (nonatomic, assign) bef_ai_car_ret *carInfo;

@end

@interface DGCBECarDetectTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)CAR;

+ (DGCBEAlgorithmKey *)CAR_DETECT;

+ (DGCBEAlgorithmKey *)CAR_BRAND_DETECT;
@end
