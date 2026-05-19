//  DGCBEAlgorithmResourceHelper.m
//  Algorithm


#import "DGCBEAlgorithmResourceHelper.h"

static NSString *LICENSE_PATH = @"LicenseBag";
//static NSString *MODEL_PATH = @"ModelResource";
static NSString *BUNDLE = @"bundle";

static NSString *FACE_MODEL = @"/ttfacemodel/algo_ggl1pqh_v11.1.model";
static NSString *FACE_EXTRA_MODEL = @"/ttfacemodel/algo_ggl1pqhlhmg7p_v14.0.model";
static NSString *FACE_ATTR_MODEL = @"/ttfaceattrmodel/algo_ggl1pqhlpgg754kghlgt4_v7.0.model";
static NSString *HAND_MODEL = @"/handmodel/algo_ggl0pcvlvhg_v11.0.model";
static NSString *HAND_BOX_MODEL = @"/handmodel/algo_ggl0pcvl4tml7ha_v12.0.model";
static NSString *HAND_GESTURE_MODEL = @"/handmodel/algo_ggl0pcvlahugk7hlgt4_v11.2.model";
static NSString *HAND_KEYPOINT_MODEL = @"/handmodel/algo_ggl0pcvlsi_v6.0.model";
static NSString *SKELETON_MODEL = @"/skeleton_model/algo_gglush9hgtc_v7.0.model";
static NSString *SKELETON3D_MODEL = @"/avatar3d/algo_gglprpgp7bvug5qsh7_v4.0.model";
static NSString *PET_FACE_MODEL = @"/petfacemodel/algo_gglihg1pqh_v5.2.model";
static NSString *HEAD_SEG_MODEL = @"/headsegmodel/algo_ggl0hpvuha_v6.0.model";
static NSString *PORTRAIT_MATTING_MODEL = @"/mattingmodel/algo_ggl8pgg5ca_v15.0.model";
static NSString *SALIENCY_MATTING_MODEL = @"/saliency_matting";
static NSString *HAIR_PARSER_MODEL = @"/hairparser/algo_ggl0p57_v11.0.model";
static NSString *SKY_SEG_MODEL = @"/skysegmodel/algo_gglus6uha_v7.0.model";
static NSString *LIGHT_CLS_MODEL = @"/lightcls/algo_ggl95a0gq9u_v1.0.model";
static NSString *GAZE_MODEL = @"/gazeestimationmodel/algo_gglap_h_v3.0.model";
static NSString *C1_MODEL = @"/c1/algo_gglqjlu8p99_v8.0.model";
static NSString *C3_MODEL = @"/c2";
static NSString *VIDEO_CLS_MODEL = @"/videoclsmodel/algo_gglr5vhtT9u_v4.0.model";
static NSString *CAR_DETECT_MODEL = @"/car_damage_detect/algo_gglqp7lvp8pahlvhghqg_v2.0.model";
static NSString *CAR_LANDMARK_MODEL = @"/car_damage_detect/algo_gglqp7l9pcv8p7su_v3.0.model";
static NSString *CAR_PLATE_OCR_MODEL = @"/car_damage_detect/algo_gglqp7li9pghltq7_v2.0.model";
static NSString *CAR_TRACK_MODEL = @"/car_damage_detect/algo_gglqp7lg7pqs_v2.0.model";
static NSString *FACE_VERIFY_MODEL = @"/faceverifymodel/algo_ggl1pqhrh7516_v7.0.model";
static NSString *ANIMOJI_MODEL = @"/avatar_drive/algo_gglprpgp7lv75rh_v1.0.model";
static NSString *ACTION_RECOGNITION_MODEL = @"/action_recognition/algo_gglush9hgtcpqglgt4_v7.2.model";
static NSString *ACTION_RECOGNITION_TMPL_OPENCLOSE = @"/action_recognition/algo_tihcq9tuh-g8i9.dat";
static NSString *ACTION_RECOGNITION_TMPL_PLANK = @"/action_recognition/algo_i9pcs-g8i9.dat";
static NSString *ACTION_RECOGNITION_TMPL_PUSHUP = @"/action_recognition/algo_iku0ki-g8i9.dat";
static NSString *ACTION_RECOGNITION_TMPL_SITUP = @"/action_recognition/algo_u5gki-g8i9.dat";
static NSString *ACTION_RECOGNITION_TMPL_SQUAT = @"/action_recognition/algo_u2kpg-g8i9.dat";
static NSString *DYNAMIC_GESTURE_MODEL = @"/dyngestmodel/";
static NSString *SKIN_SEGMENTATION_MODEL = @"/skin_seg/";
static NSString *BACH_SKELETON_MODEL = @"/bach_skeleton/";
static NSString *CHROMA_KEYING_MODEL = @"/chroma_keying/";
static NSString *ACTION_RECOGNITION_TMPL_HIGHRUN = @"/action_recognition/algo_05a0l7kc.dat";
static NSString *ACTION_RECOGNITION_TMPL_HIPBRIDGE = @"/action_recognition/algo_05il475vah.dat";
static NSString *ACTION_RECOGNITION_TMPL_KNEELINGPUSHUP = @"/action_recognition/algo_schh95caliku0ki.dat";
static NSString *ACTION_RECOGNITION_TMPL_LUNGESQUAT = @"/action_recognition/algo_9kcahlu2kpg.dat";
static NSString *ACTION_RECOGNITION_TMPL_LUNGE = @"/action_recognition/algo_9kcah.dat";
static NSString *SLAM_AR_MODEL = @"/slam_ar/algo_ik4lggu9p88tvh9_v5.0.model";
static NSString *FACE_FITTING_MODEL = @"/facefitting/algo_ggl1pqh15gg5cajfde_v2.0.model";
static NSString *AVABOOST_MODEL = @"";  // depends on ttfacemodel
static NSString *OBJECT_TRACKING_MODEL = @"/object_tracking/algo_45catlt43hqgS7pqs5ca_v1.0.dat";

@interface DGCBEAlgorithmResourceHelper () {
    
    NSString            *_dgc_licensePrefix;
}

@end

@implementation DGCBEAlgorithmResourceHelper

- (const char *)faceModel {
    return [self modelPath:FACE_MODEL];
}

- (const char *)faceAttrModel {
    return [self modelPath:FACE_ATTR_MODEL];
}

- (const char *)faceExtraModel {
    return [self modelPath:FACE_EXTRA_MODEL];
}

- (const char *)handModel {
    return [self modelPath:HAND_MODEL];
}

- (const char *)handBoxModel {
    return [self modelPath:HAND_BOX_MODEL];
}

- (const char *)handGestureModel {
    return [self modelPath:HAND_GESTURE_MODEL];
}

- (const char *)handKeyPointModel {
    return [self modelPath:HAND_KEYPOINT_MODEL];
}

- (const char *)skeletonModel {
    return [self modelPath:SKELETON_MODEL];
}

- (const char *)skeleton3DModel {
    return [self modelPath:SKELETON3D_MODEL];
}

- (const char *)petFaceModelPath {
    return [self modelPath:PET_FACE_MODEL];
}

- (const char *)headSegmentModelPath {
    return [self modelPath:HEAD_SEG_MODEL];
}

- (const char *)portraitMattingModelPath {
    return [self modelPath:PORTRAIT_MATTING_MODEL];
}

- (const char *)saliencyMattingModelPath {
    return [self modelPath:SALIENCY_MATTING_MODEL];
}

- (const char *)hairParserModelPath {
    return [self modelPath:HAIR_PARSER_MODEL];
}

- (const char *)skySegModelPath {
    return [self modelPath:SKY_SEG_MODEL];
}

- (const char *)lightClsModelPath {
    return [self modelPath:LIGHT_CLS_MODEL];
}

- (const char *)gazeModel {
    return [self modelPath:GAZE_MODEL];
}

- (const char *)c1ModelPath {
    return [self modelPath:C1_MODEL];
}

- (const char *)c2Model {
    return [self modelPath:C3_MODEL];
}

- (const char *)videoClsModelPath {
    return [self modelPath:VIDEO_CLS_MODEL];
}

- (const char *)carDetectModel {
    return [self modelPath:CAR_DETECT_MODEL];
}

- (const char *)carLandmarkModel {
    return [self modelPath:CAR_LANDMARK_MODEL];
}

- (const char *)carPlateOcrModel {
    return [self modelPath:CAR_PLATE_OCR_MODEL];
}

- (const char *)carTrackModel {
    return [self modelPath:CAR_TRACK_MODEL];
}

- (const char *)faceVerifyModelPath {
    return [self modelPath:FACE_VERIFY_MODEL];
}

- (const char *)animojiModelPath {
    return [self modelPath:ANIMOJI_MODEL];
}

- (const char *)actionRecognitionModel
{
    return [self modelPath:ACTION_RECOGNITION_MODEL];
}

- (const char *)actionRecognitionTMPL_OpenClose
{
    return [self modelPath:ACTION_RECOGNITION_TMPL_OPENCLOSE];
}

- (const char *)actionRecognitionTMPL_PLANK
{
    return [self modelPath:ACTION_RECOGNITION_TMPL_PLANK];
}

- (const char *)actionRecognitionTMPL_SITUP
{
    return [self modelPath:ACTION_RECOGNITION_TMPL_SITUP];
}

- (const char *)actionRecognitionTMPL_SQUAT
{
    return [self modelPath:ACTION_RECOGNITION_TMPL_SQUAT];
}

- (const char *)actionRecognitionTMPL_PUSHUP
{
    return [self modelPath:ACTION_RECOGNITION_TMPL_PUSHUP];
}

- (const char *)dynamicGestureModelPath {
    return [self modelPath:DYNAMIC_GESTURE_MODEL];
}

- (const char *)skinSegmentationModelPath {
    return [self modelPath:SKIN_SEGMENTATION_MODEL];
}
- (const char *)bachSkeletonModel {
    return [self modelPath:BACH_SKELETON_MODEL];
}
- (const char *)chromaKeyingModelPath {
    return [self modelPath:CHROMA_KEYING_MODEL];
}
- (const char *)actionRecognitionTMPL_HIGHRUN
{
    return [self modelPath:ACTION_RECOGNITION_TMPL_HIGHRUN];
}

- (const char *)actionRecognitionTMPL_HIPBRIDGE
{
    return [self modelPath:ACTION_RECOGNITION_TMPL_HIPBRIDGE];
}

- (const char *)actionRecognitionTMPL_LUNGE
{
    return [self modelPath:ACTION_RECOGNITION_TMPL_LUNGE];
}

- (const char *)actionRecognitionTMPL_LUNGESQUAT
{
    return [self modelPath:ACTION_RECOGNITION_TMPL_LUNGESQUAT];
}

- (const char *)actionRecognitionTMPL_KNEELINGPUSHUP
{
    return [self modelPath:ACTION_RECOGNITION_TMPL_KNEELINGPUSHUP];
}

- (const char *)slamARModel {
    return [self modelPath:SLAM_AR_MODEL];
}

- (const char *)faceFittingModel {
    return [self modelPath:FACE_FITTING_MODEL];
}

- (const char *)avaboostModel {
    return [self modelPath:AVABOOST_MODEL];
}

- (const char *)objectTrackingModel {
    return [self modelPath:OBJECT_TRACKING_MODEL];
}

- (const char *)modelPath:(NSString *)model {
    return [[[self modelDirPath] stringByAppendingString:model] UTF8String];
}

- (NSString *)modelDirPath
{
    NSString *documentDir = [[[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil] path];
    return [documentDir stringByAppendingString:@"/BDCV_ModelResource"];
}

@end
