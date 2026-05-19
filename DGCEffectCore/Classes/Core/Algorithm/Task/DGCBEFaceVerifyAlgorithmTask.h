//  DGCBEFaceVerifyAlgorithmTask.h
// EffectsARSDK


#import "DGCBEAlgorithmTask.h"
#import "DGCBEFaceAlgorithmTask.h"
#import "DGCBEImageUtils.h"
#import "bef_effect_ai_face_verify.h"

@protocol BEFaceVerifyResourceProvider <BEAlgorithmResourceProvider, BEFaceResourceProvider>

- (const char *)faceVerifyModelPath;

@end

@interface DGCBEFaceVerifyAlgorithmResult : NSObject

@property (nonatomic, assign) BOOL valid;
@property (nonatomic, assign) bef_ai_face_verify_info *verifyInfo;
@property (nonatomic, assign) double similarity;
@property (nonatomic, assign) long costTime;

@end

@interface DGCBEFaceVerifyAlgorithmTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)FACE_VERIFY;

- (int)setFaceVerifySourceFeature:(unsigned char *)buffer format:(BEFormatType)format width:(int)width height:(int)height bytesPerRow:(int)bytesPerRow;
- (void)resetVerify;
@end
