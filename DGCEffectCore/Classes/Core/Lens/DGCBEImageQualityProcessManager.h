//  DGCBEImageQualityProcessManager.h
// EffectsARSDK


#ifndef BEImageQualityProcessManager_h
#define BEImageQualityProcessManager_h

#import "DGCBEVideoSRTask.h"
#import "DGCBEVideoStabTask.h"
#import "DGCBEAdaptiveSharpenTask.h"
#import "DGCBEPhotoNightSceneTask.h"
#import "DGCBEOnekeyEnhanceTask.h"
#import "DGCBEVidaTask.h"
#import "DGCBEVideoLiteHdrTask.h"
#import "DGCBEVideoDeflickerTask.h"
#import <CoreVideo/CVPixelBuffer.h>

typedef union ImageQualityDataInternal{
    CVPixelBufferRef pixelBuffer;
    unsigned int texture[2];
    CVPixelBufferRef mutilCVPixelBuffers[6];
}ImageQualityDataInternal;

typedef NS_ENUM(NSInteger, ImageQualityDataType){
    ImageQualityDataTypeCVPixelBuffer,
    ImageQualityDataTypeOpenGlTexture,
    ImageQualityDataTypeMetalTexture,
    ImageQualityDataTypeMutilCVPixelBuffers,
};

typedef struct ImageQualityProcessData
{
    bool yuvOnScreen;
    ImageQualityDataType type;
    ImageQualityDataInternal data;
}ImageQualityProcessData;

typedef NS_ENUM(NSInteger, ImageQualityProcessFinishStatus)
{
    ImageQualityProcessFinishStatusDoNothing = 0, // do nothing
    ImageQualityProcessFinishStatusSuccess,   // success
    ImageQualityProcessFinishStatusError,     // error happened, the reason need to review the log
    ImageQualityProcessFinishStatusSuccessNewPixelBuffer // success and new new pixelBuffer, means user the release it after all the use
};

@protocol BEImageQualityResourceProvider <BEVideoSRResourceProvider, BEAdaptiveSharpenResourceProvider, BEPhotoNightSceneResourceProvider, BEVidaResourceProvider, BEVideoLiteHdrResourceProvider, BEVideoDeflickerResourceProvider>

@end

@interface DGCBEImageQualityProcessManager : NSObject

//   {zh} / @brief 构造函数     {en} /@brief constructor 
//   {zh} / @details 需要传入一个 BEImageQualityResourceProvider，一般情况下，     {en} /@details need to pass in a BEImageQualityResourceProvider, in general, 
//   {zh} / 可以直接用工程中的 DGCBELensResourceHelper 实现类。     {en} /You can directly implement the class with the DGCBELensResourceHelper in the project. 
//   {zh} / @param provider 资源提供类     {en} /@param provider class 
- (instancetype)initWithProvider:(id<BELicenseProvider>)provider;

//   {zh} / @brief SDK 调用     {en} /@brief SDK call 
//   {zh} / @details 需要给函数两个参数，分别为输入、输出数据，输入输出目前都仅支持 CVPixelBuffer     {en} /@details need to give the function two parameters, respectively, input and output data, input and output currently only support CVPixelBuffer 
//   {zh} / @param input 输入数据     {en} /@param input data 
//   {zh} / @param output 输出数据     {en} /@param output data 
-(ImageQualityProcessFinishStatus)imageQualityProcess:(const ImageQualityProcessData*)input output:(ImageQualityProcessData*)output;

@property (nonatomic, assign)bool enableVideoSr;
@property (nonatomic, assign)bool enableAdaptiveSharpen;
@property (nonatomic, assign)bool enablePhotoNightScene;
@property (nonatomic, assign)bool enableFrameInsertion;
@property (nonatomic, assign)bool enableVideoStab;
@property (nonatomic, assign)bool enableVida;
@property (nonatomic, assign)bool enableOnekeyEnhance;
@property (nonatomic, assign)bool enableTaintDetect;
@property (nonatomic, assign)bool enableVideoLiteHdr;
@property (nonatomic, assign)bool enableCineMove;
@property (nonatomic, assign)bool enableVideoDeflicker;
@property (nonatomic, assign)int  cineMoveType;

//Control whether do all the image quality work
@property (nonatomic, assign)bool pause;

//   {zh} / @brief 是否开启视频超分     {en} /@Briefing whether to turn on video super score 
//   {zh} / @param enableVideoSr 视频超分     {en} /@param enableVideoSr 
- (void)setEnableVideoSr:(bool)enableVideoSr;

//   {zh} / @brief 是否开启自适应锐化     {en} /@Briefing whether to turn on adaptive sharpening 
//   {zh} / @param enableAdaptiveSharpen 自适应锐化     {en} /@param enableAdaptiveSharpen 
- (void)setEnableAdaptiveSharpen:(bool)enableAdaptiveSharpen;

//   {zh} / @brief 是否开启智感高清     {en} /@Briefing whether to turn on smart high definition
//   {zh} / @param enableOnekeyEnhance 开关     {en} /@param enableOnekeyEnhance
- (void)setEnableOnekeyEnhance:(bool)enableOnekeyEnhance;

//   {zh} / @brief 是否开启脏镜头检测    {en} /@Briefing whether to turn on taint scene detection
//   {zh} / @param enableTaintDetect 开关     {en} /@param enableTaintDetect
- (void)setEnableTaintDetect:(bool)enableTaintDetect;

//   {zh} / @brief 是否开启脏镜头检测    {en} /@Briefing whether to turn on taint scene detection
//   {zh} / @param enableTaintDetect 开关     {en} /@param enableTaintDetect
- (void)setEnableVideoLiteHdr:(bool)enableVideoLiteHdr;

//   {zh} / @brief 是否开启律动运镜    {en} /@Briefing whether to turn on cine move
//   {zh} / @param enableCineMove 开关     {en} /@param enableCineMove
- (void)setEnableCineMove:(bool)enableCineMove type:(int)type;

//  {zh} 相机流的一些参数，用于拍照夜景  {en} Some parameters of the camera flow, used to take pictures of night scenes
@property (nonatomic, assign) unsigned int inputWidth;
@property (nonatomic, assign) unsigned int inputHeight;
@property (nonatomic, assign) unsigned int photoNumBer;

//  {zh} 视频防抖  {en} Video stabilizer
@property (nonatomic, assign) BEVideoStabProcessType videoStabProcessType;

//  {zh} 插帧比率参数  {en} Frame insertion ratio parameter
@property (nonatomic, assign) float frameInsertionRatio;
@property (nonatomic, assign) bool needUpdate;
//  {zh} 设置质感高清需要的相机ISO信息  {en} Set the camera ISO information required for high definition texture
- (void)setOnekeyEnhanceISOData: (float*) data;
- (void)resetOnekeyEnhanceFirstFrame;
- (void)resetOnekeyEnhanceResolution;

- (void)getVidaInfo:(float*)face aes:(float*)aes clarity:(float*)clarity;
- (void)getTaintSceneDetectScore:(float *)value;

@end

#endif /* BEImageQualityProcessManager_h */
