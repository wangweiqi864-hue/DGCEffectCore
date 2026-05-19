//  DGCBEImageQualityProcessManager.m
// EffectsARSDK


#import <Foundation/Foundation.h>
#import "DGCBEImageQualityProcessManager.h"
#import "DGCBEVideoSRTask.h"
#import "DGCBEAdaptiveSharpenTask.h"
#import "DGCBEPhotoNightSceneTask.h"
#import "DGCBEVideoFrameInsertTask.h"
#import "DGCBEOnekeyEnhanceTask.h"
#import "DGCBETaintSceneDetectTask.h"
#import "DGCBECineMoveTask.h"
#import "BEImageOpeartion.h"
#import "DGCBEVidaTask.h"
#import "DGCBEVideoLiteHdrTask.h"

@interface DGCBEImageQualityProcessManager()

@property (nonatomic, strong) DGCBEVideoSRTask* videoSrTask;
@property (nonatomic, strong) DGCBEAdaptiveSharpenTask* adapterSharpenTask;
@property (nonatomic, strong) DGCBEPhotoNightSceneTask* photoNightSceneTask;
@property (nonatomic, strong) DGCBEVideoFrameInsertTask* frameInsertionTask;
@property (nonatomic, strong) DGCBEOnekeyEnhanceTask* onekeyEnhanceTask;
@property (nonatomic, strong) DGCBEVidaTask* vidaTask;
@property (nonatomic, strong) DGCBETaintSceneDetectTask* taintDetectTask;
@property (nonatomic, strong) DGCBEVideoLiteHdrTask* videoLiteHdrTask;
@property (nonatomic, strong) DGCBEVideoDeflickerTask* videoDeflickerTask;
@property (nonatomic, strong) DGCBEVideoStabTask* videoStabTask;
@property (nonatomic, strong) DGCBECineMoveTask* cineMoveTask;
@property (nonatomic, strong) id<BELicenseProvider> provider;

//  {zh} 视频防抖  {en} Video stabilizer
@property (nonatomic, assign) int videoStabFrameIdx;

@end

@implementation DGCBEImageQualityProcessManager

- (instancetype)initWithProvider:(id<BELicenseProvider>)provider {
    self = [super init];
    if (self) {
        _videoSrTask = nil;
        _adapterSharpenTask = nil;
        _photoNightSceneTask = nil;
        _frameInsertionTask = nil;
        _vidaTask = nil;
        _cineMoveTask = nil;
        _videoLiteHdrTask = nil;
        _enableVideoSr = false;
        _enableAdaptiveSharpen = false;
        _enablePhotoNightScene = false;
        _enableFrameInsertion = false;
        _enableVida = false;
        _enableVideoLiteHdr = false;
        _enableVideoDeflicker = false;
        _pause = false;
        _provider = provider;
        _frameInsertionRatio = 1.0;
        _needUpdate = true;
        _cineMoveType = 0;
    }
    return self;
}


/// Close all the inited task when dealloc
-(void)dealloc{
    if (_videoSrTask){ // Means we should destory it
        [_videoSrTask destroyTask];
        _videoSrTask = nil;
    }
    
    if(_adapterSharpenTask)
    {
        [_adapterSharpenTask destroyTask];
        _adapterSharpenTask = nil;
    }
    if (_photoNightSceneTask) {
        [_photoNightSceneTask destroyTask];
        _photoNightSceneTask = nil;
    }
    if (_frameInsertionTask) {
        [_frameInsertionTask destroyTask];
        _frameInsertionTask = nil;
    }
    if (_vidaTask) {
        [_vidaTask destroyTask];
        _vidaTask = nil;
    }
    if (_taintDetectTask) {
        [_taintDetectTask destroyTask];
        _taintDetectTask = nil;
    }
    if (_cineMoveTask) {
        [_cineMoveTask destroyTask];
        _cineMoveTask = nil;
    }
    if (_onekeyEnhanceTask) {
        [_onekeyEnhanceTask destroyTask];
        _onekeyEnhanceTask = nil;
    }
    
    if (_enableVideoLiteHdr) {
        [_videoLiteHdrTask destroyTask];
        _videoLiteHdrTask = nil;
    }
    
    if (_videoDeflickerTask) {
        [_videoDeflickerTask destroyTask];
        _videoDeflickerTask = nil;
    }
    if (_videoStabTask) {
        [_videoStabTask destroyTask];
        _videoStabTask = nil;
    }
    DGCBEImageBufferOperation *imageOp = [DGCBEImageBufferOperation sharedInstance];
    [imageOp releaseResouce];
}

#pragma mark - public
-(ImageQualityProcessFinishStatus)imageQualityProcess:(const ImageQualityProcessData*)input output:(ImageQualityProcessData*)output{
    int ret = ImageQualityProcessFinishStatusDoNothing;
    CVPixelBufferRef destBuffer  = NULL;
    
    /// If paused just do nothing
    if (_pause){
        return ImageQualityProcessFinishStatusDoNothing;
    }
    
    // Whether do the video superpixel
    if (_enableVideoSr){
        if (_videoSrTask){ // process when inited
            // Only support yuv420f yuv420p at now
            if (input->type == ImageQualityDataTypeCVPixelBuffer){
                CVPixelBufferRef srcBuffer = input->data.pixelBuffer;
                OSType srcType = CVPixelBufferGetPixelFormatType(srcBuffer);
                CVPixelBufferRef inputBuffer = NULL;
                                
                ///First, gen a new CVPixelbuffer if need
                {
                    if (srcType != kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange && srcType != kCVPixelFormatType_420YpCbCr8BiPlanarFullRange){
                        inputBuffer = [self formtChangeIfNeeded:srcBuffer destFormat:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange];
                    }
                }
                
                /// Second, process the buffer
                {
                    if (inputBuffer != nil){
                        destBuffer = [_videoSrTask processCVPixelBuffer:inputBuffer];
                        CVPixelBufferRelease(inputBuffer);
                    }else {
                        destBuffer = [_videoSrTask processCVPixelBuffer:srcBuffer];
                    }
                }

                /// Third, gen a dest  format cvpixelbuffer is need
                {
                    if (destBuffer != NULL){
                        //   {zh} / 这里一定retain，不然当加速进行转换的时候有，会出现bad_access     {en} /It must be retained here, otherwise there will be bad_access when accelerating the conversion
                        CVPixelBufferRef outputBuffer = nil;
                        if (!input->yuvOnScreen) {
                            CVPixelBufferRetain(destBuffer);
                            outputBuffer = [self formtChangeIfNeeded:destBuffer destFormat:kCVPixelFormatType_32BGRA];
                            CVPixelBufferRelease(destBuffer);
                        }
                        
                        if (outputBuffer){
                            output->type = ImageQualityDataTypeCVPixelBuffer;
                            output->data.pixelBuffer = outputBuffer;
                            
                            return ImageQualityProcessFinishStatusSuccessNewPixelBuffer;
                        }else {
                            output->type = ImageQualityDataTypeCVPixelBuffer;
                            output->data.pixelBuffer = destBuffer;
                            
                            return ImageQualityProcessFinishStatusSuccess;
                        }
                    }else {
                        return ImageQualityProcessFinishStatusError;
                    }
                }
            }
        }
    }
    else if(_enableAdaptiveSharpen)
    {
        if (_adapterSharpenTask){ // process when inited
            // Only support yuv420f yuv420p at now
            if (input->type == ImageQualityDataTypeCVPixelBuffer){
                CVPixelBufferRef srcBuffer = input->data.pixelBuffer;
                OSType srcType = CVPixelBufferGetPixelFormatType(srcBuffer);
                CVPixelBufferRef inputBuffer = NULL;
                                
                ///First, gen a new CVPixelbuffer if need
                {
                    if (srcType != kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange && srcType != kCVPixelFormatType_420YpCbCr8BiPlanarFullRange){
                        inputBuffer = [self formtChangeIfNeeded:srcBuffer destFormat:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange];
                    }
                }
                
                /// Second, process the buffer
                {
                    if (inputBuffer != nil){
                        destBuffer = [_adapterSharpenTask processCVPixelBuffer:inputBuffer];
                        CVPixelBufferRelease(inputBuffer);
                    }else {
                        destBuffer = [_adapterSharpenTask processCVPixelBuffer:srcBuffer];
                    }
                }
                
                /// Third, gen a dest  format cvpixelbuffer is need
                {
                    if (destBuffer != NULL){
                        //   {zh} / 这里一定retain，不然当加速进行转换的时候有，会出现bad_access     {en} /It must be retained here, otherwise there will be bad_access when accelerating the conversion
                        CVPixelBufferRef outputBuffer = nil;
                        if (!input->yuvOnScreen) {
                            CVPixelBufferRetain(destBuffer);
                            outputBuffer = [self formtChangeIfNeeded:destBuffer destFormat:kCVPixelFormatType_32BGRA];
                            CVPixelBufferRelease(destBuffer);
                        }
                        
                        if (outputBuffer){
                            output->type = ImageQualityDataTypeCVPixelBuffer;
                            output->data.pixelBuffer = outputBuffer;
                            
                            return ImageQualityProcessFinishStatusSuccessNewPixelBuffer;
                        }else {
                            output->type = ImageQualityDataTypeCVPixelBuffer;
                            output->data.pixelBuffer = destBuffer;
                            
                            return ImageQualityProcessFinishStatusSuccess;
                        }
                    }else {
                        return ImageQualityProcessFinishStatusError;
                    }
                }
            }
        }
    } else if (_enablePhotoNightScene) {
        if (_photoNightSceneTask) {
            
            if (!_photoNightSceneTask.inited) {
                [_photoNightSceneTask initTaskWidth:_inputWidth height:_inputHeight imageNum:_photoNumBer];
            }
            
            if (input->type == ImageQualityDataTypeMutilCVPixelBuffers) {
                NSMutableArray<NSValue*>* inputBuffers = [NSMutableArray new];
                for (int i = 0; i < 6; i++) {
                    [inputBuffers addObject:[NSValue valueWithPointer:input->data.mutilCVPixelBuffers[i]]];
                }
                CVPixelBufferRef nightSceneResult = [_photoNightSceneTask processMutilBuffer:inputBuffers];
                if (!nightSceneResult) {
                    return ImageQualityProcessFinishStatusError;
                }
        
                output->type = ImageQualityDataTypeCVPixelBuffer;
                output->data.pixelBuffer = nightSceneResult;
                return ImageQualityProcessFinishStatusSuccess;
            } else {
                return ImageQualityProcessFinishStatusDoNothing;
            }
        } else {
            return ImageQualityProcessFinishStatusDoNothing;
        }
    } else if (_enableFrameInsertion) {
        if (_frameInsertionTask) {
            if (input->type == ImageQualityDataTypeCVPixelBuffer) {
                CVPixelBufferRef frontBuffer = input->data.mutilCVPixelBuffers[0];
                CVPixelBufferRef backBuffer = input->data.mutilCVPixelBuffers[1];
//                OSType srcType = CVPixelBufferGetPixelFormatType(srcBuffer);
                
                destBuffer = [_frameInsertionTask processCVPixelBuffer:frontBuffer nextCVPixelBuffer:backBuffer withRatio:_frameInsertionRatio Update:_needUpdate];

                if (destBuffer != nil) {
                    //   {zh} / 这里一定retain，不然当加速进行转换的时候有，会出现bad_access     {en} /It must be retained here, otherwise there will be bad_access when accelerating the conversion
                    CVPixelBufferRetain(destBuffer);
                    CVPixelBufferRef outputBuffer = [self formtChangeIfNeeded:destBuffer destFormat:kCVPixelFormatType_32BGRA];
                    CVPixelBufferRelease(destBuffer);

                    if (outputBuffer){
                        output->type = ImageQualityDataTypeCVPixelBuffer;
                        output->data.pixelBuffer = outputBuffer;

                        return ImageQualityProcessFinishStatusSuccessNewPixelBuffer;
                    }else {
                        output->type = ImageQualityDataTypeCVPixelBuffer;
                        output->data.pixelBuffer = destBuffer;

                        return ImageQualityProcessFinishStatusSuccess;
                    }
                } else {
                    return ImageQualityProcessFinishStatusDoNothing;
                }
            }
        }
    } else if (_enableOnekeyEnhance) {
        if (_onekeyEnhanceTask) {
            if (input->type == ImageQualityDataTypeCVPixelBuffer){
                CVPixelBufferRef srcBuffer = input->data.pixelBuffer;
                OSType srcType = CVPixelBufferGetPixelFormatType(srcBuffer);
                CVPixelBufferRef inputBuffer = nil;
                                
                ///First, gen a new CVPixelbuffer if need
                {
                    if (srcType != kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange && srcType != kCVPixelFormatType_420YpCbCr8BiPlanarFullRange){
                        inputBuffer = [self formtChangeIfNeeded:srcBuffer destFormat:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange];
                    }
                }
                
                /// Second, process the buffer
                {
                    if (inputBuffer != nil){
                        destBuffer = [_onekeyEnhanceTask processCVPixelBuffer:inputBuffer withRotation:0];
                        CVPixelBufferRelease(inputBuffer);
                    }else {
                        destBuffer = [_onekeyEnhanceTask processCVPixelBuffer:srcBuffer withRotation:0];
                    }
                }
                
                /// Third, gen a dest  format cvpixelbuffer is need
                {
                    if (destBuffer != NULL){
                        //   {zh} / 这里一定retain，不然当加速进行转换的时候有，会出现bad_access     {en} /It must be retained here, otherwise there will be bad_access when accelerating the conversion
                        CVPixelBufferRef outputBuffer = nil;
                        if (!input->yuvOnScreen) {
                            CVPixelBufferRetain(destBuffer);
                            outputBuffer = [self formtChangeIfNeeded:destBuffer destFormat:kCVPixelFormatType_32BGRA];
                            CVPixelBufferRelease(destBuffer);
                        }
                        
                        if (outputBuffer){
                            output->type = ImageQualityDataTypeCVPixelBuffer;
                            output->data.pixelBuffer = outputBuffer;
                            
                            return ImageQualityProcessFinishStatusSuccessNewPixelBuffer;
                        }else {
                            output->type = ImageQualityDataTypeCVPixelBuffer;
                            output->data.pixelBuffer = destBuffer;
                            
                            return ImageQualityProcessFinishStatusSuccess;
                        }
                    }else {
                        return ImageQualityProcessFinishStatusError;
                    }
                }
            }
        }
    } else if (_enableVideoLiteHdr) {
        if (_videoLiteHdrTask) {
            CVPixelBufferRef ret = [_videoLiteHdrTask processCVPixelBuffer:input->data.pixelBuffer];
            
            if (ret == NULL) {
                return ImageQualityProcessFinishStatusError;
            } else {
                output->type = ImageQualityDataTypeCVPixelBuffer;
                output->data.pixelBuffer = ret;
                return ImageQualityProcessFinishStatusSuccessNewPixelBuffer;
            }
        }
    } else if (_enableVida) {
        if (_vidaTask) {
            [_vidaTask processCVPixelBuffer:input->data.pixelBuffer];
            
            output->type = ImageQualityDataTypeCVPixelBuffer;
            output->data.pixelBuffer = input->data.pixelBuffer;
            return ImageQualityProcessFinishStatusSuccess;
        }
    }else if (_enableTaintDetect) {
        if (_taintDetectTask) {
            [_taintDetectTask processCVPixelBuffer:input->data.pixelBuffer];
            
            output->type = ImageQualityDataTypeCVPixelBuffer;
            output->data.pixelBuffer = input->data.pixelBuffer;
            return ImageQualityProcessFinishStatusSuccess;
        }
    }else if (_enableCineMove) {
        if (_cineMoveTask) {
            output->type = ImageQualityDataTypeCVPixelBuffer;
            output->data.pixelBuffer =[_cineMoveTask processCVPixelBuffer:input->data.pixelBuffer];
            return ImageQualityProcessFinishStatusSuccess;
        }
    }else if (_enableVideoDeflicker) {
        if (_videoDeflickerTask) {
            output->type = ImageQualityDataTypeCVPixelBuffer;
            output->data.pixelBuffer =[_videoDeflickerTask processCVPixelBuffer:input->data.pixelBuffer];
            return ImageQualityProcessFinishStatusSuccess;
        }
    }else if (_enableVideoStab) {
        if (_videoStabTask) {
            output->type = ImageQualityDataTypeCVPixelBuffer;
            if (_videoStabProcessType == BEVideoStabEstimate){
                output->data.pixelBuffer = [_videoStabTask estimateCVPixelBuffer:input->data.pixelBuffer atIndex:_videoStabFrameIdx];
            }else if(_videoStabProcessType == BEVideoStabWarp){
                output->data.pixelBuffer = [_videoStabTask warpCVPixelBuffer:input->data.pixelBuffer atIndex:_videoStabFrameIdx];
            }else{
                return ImageQualityProcessFinishStatusError;
            }
            _videoStabFrameIdx++;
            
            return _videoStabTask.validInput? ImageQualityProcessFinishStatusSuccess: ImageQualityProcessFinishStatusError;
        }
    } else {
        return ImageQualityProcessFinishStatusDoNothing;
    }
    
    /// If nothing happend, we also need the change format to support other sdk
    destBuffer = [self formtChangeIfNeeded:input->data.pixelBuffer destFormat:kCVPixelFormatType_32BGRA];
    
    if (destBuffer){
        output->data.pixelBuffer = destBuffer;
        output->type = ImageQualityDataTypeCVPixelBuffer;
        ret = ImageQualityProcessFinishStatusSuccessNewPixelBuffer;
    }
    return ret;
}

- (void)setOnekeyEnhanceISOData: (float*) data {
    if (!_enableOnekeyEnhance || !_onekeyEnhanceTask)
        return;
    [_onekeyEnhanceTask setISOData:data];
}

- (void)resetOnekeyEnhanceFirstFrame {
    if (!_enableOnekeyEnhance || !_onekeyEnhanceTask || !_enableVideoLiteHdr || !_videoLiteHdrTask)
        return;
    if (_videoLiteHdrTask) {
        [_onekeyEnhanceTask resetFirstFrame];
    }
    if (_videoLiteHdrTask) {
        [_videoLiteHdrTask resetFirstFrame];
    }
}

- (void)resetOnekeyEnhanceResolution {
    if (!_enableOnekeyEnhance || !_onekeyEnhanceTask)
        return;
    [_onekeyEnhanceTask destroyTask];
}

- (void)getVidaInfo:(float*)face aes:(float*)aes clarity:(float*)clarity {
    if (_enableVida && _vidaTask) {
        [_vidaTask getVidaResult:face aes:aes clarity:clarity];
    }
}

- (void)getTaintSceneDetectScore:(float *)value {
    if (_enableTaintDetect && _taintDetectTask) {
        *value = _taintDetectTask.taintScore;
    }
}
#pragma mark - private change CVPixelbuffer format if needed

-(CVPixelBufferRef)formtChangeIfNeeded:(CVPixelBufferRef)srcBuffer destFormat:(OSType)destFormat
{
    DGCBEImageBufferOperation *imageOp = [DGCBEImageBufferOperation sharedInstance];
    return [imageOp transforPixelbuffer:srcBuffer destFormat:destFormat];
}

#pragma  mark - setter
-(void)setEnableVideoSr:(bool)enableVideoSr{
    // Dont't need to de anything
    if (_enableVideoSr == enableVideoSr)
        return ;
    
    if (enableVideoSr){
        if (!_videoSrTask){ // If not inited, we should init one
            _videoSrTask = [[DGCBEVideoSRTask alloc]init];
            _videoSrTask.provider = self.provider;
            
            if ([_videoSrTask initTask]){ // No zero means initlization error
                _videoSrTask = nil;
            }
        }
    }else {
        if (_videoSrTask){ // Means we should destory it
            [_videoSrTask destroyTask];
            _videoSrTask = nil;
        }
    }
    _enableVideoSr = enableVideoSr;
}

- (void)setEnableAdaptiveSharpen:(bool)enableAdaptiveSharpen
{
    // Dont't need to de anything
    if (_enableAdaptiveSharpen == enableAdaptiveSharpen)
        return ;
    
    if (enableAdaptiveSharpen){
        if (!_adapterSharpenTask){ // If not inited, we should init one
            _adapterSharpenTask = [[DGCBEAdaptiveSharpenTask alloc]init];
            _adapterSharpenTask.provider = self.provider;
            
            if ([_adapterSharpenTask initTask]){ // No zero means initlization error
                _adapterSharpenTask = nil;
            }
        }
    }else {
        if (_adapterSharpenTask){ // Means we should destory it
            [_adapterSharpenTask destroyTask];
            _adapterSharpenTask = nil;
        }
    }
    _enableAdaptiveSharpen = enableAdaptiveSharpen;
}

- (void)setEnablePhotoNightScene:(bool)enablePhotoNightScene
{
    if (_enablePhotoNightScene == enablePhotoNightScene)
        return ;
    
    if (enablePhotoNightScene) {
        if (!_photoNightSceneTask) {
            _photoNightSceneTask = [[DGCBEPhotoNightSceneTask alloc] init];
            _photoNightSceneTask.provider = self.provider;
            
        
        }
    } else {
        if (_photoNightSceneTask) {
            [_photoNightSceneTask destroyTask];
            _photoNightSceneTask = nil;
        }
    }
    _enablePhotoNightScene = enablePhotoNightScene;
}

- (void)setEnableFrameInsertion:(bool)enableFrameInsertion
{
    if (_enableFrameInsertion == enableFrameInsertion)
        return;
    
    if (enableFrameInsertion) {
        if (!_frameInsertionTask) {
            _frameInsertionTask = [[DGCBEVideoFrameInsertTask alloc] init];
            _frameInsertionTask.provider = self.provider;
            
            if ([_frameInsertionTask initTask]){ // No zero means initlization error
                _frameInsertionTask = nil;
            }
        }
    } else {
        if (_frameInsertionTask) {
            [_frameInsertionTask destroyTask];
            _frameInsertionTask = nil;
        }
    }
    _enableFrameInsertion = enableFrameInsertion;
}

- (void)setEnableOnekeyEnhance:(bool)enableOnekeyEnhance
{
    if (_enableOnekeyEnhance == enableOnekeyEnhance)
        return;
    
    if (enableOnekeyEnhance) {
        if (!_onekeyEnhanceTask) {
            _onekeyEnhanceTask = [[DGCBEOnekeyEnhanceTask alloc] init];
            _onekeyEnhanceTask.provider = self.provider;
        }
    } else {
        if (_onekeyEnhanceTask) {
            [_onekeyEnhanceTask destroyTask];
            _onekeyEnhanceTask = nil;
        }
    }
    _enableOnekeyEnhance = enableOnekeyEnhance;
}

-(void)setEnableVida:(bool)enableVida {
    if (_enableVida == enableVida)
        return ;
    
    if (enableVida) {
        if (!_vidaTask) {
            _vidaTask = [[DGCBEVidaTask alloc] init];
            _vidaTask.provider = self.provider;
            [_vidaTask initTask];
        }
    } else {
        if (_vidaTask) {
            [_vidaTask destroyTask];
            _vidaTask = nil;
        }
    }
    _enableVida = enableVida;
}

- (void)setEnableTaintDetect:(bool)enableTaintDetect
{
    if (_enableTaintDetect == enableTaintDetect)
        return;
    
    if (enableTaintDetect) {
        if (!_taintDetectTask) {
            _taintDetectTask = [[DGCBETaintSceneDetectTask alloc] init];
            _taintDetectTask.provider = self.provider;
            [_taintDetectTask initTask];
        }
    } else {
        if (_taintDetectTask) {
            [_taintDetectTask destroyTask];
            _taintDetectTask = nil;
        }
    }
    _enableTaintDetect = enableTaintDetect;
}

- (void)setEnableVideoLiteHdr:(bool)enableVideoLiteHdr
{
    if (_enableVideoLiteHdr == enableVideoLiteHdr)
        return;
    
    if (enableVideoLiteHdr) {
        if (!_videoLiteHdrTask) {
            _videoLiteHdrTask = [[DGCBEVideoLiteHdrTask alloc] init];
            _videoLiteHdrTask.provider = self.provider;
            [_videoLiteHdrTask initTask];
        }
    } else {
        if (_videoLiteHdrTask) {
            [_videoLiteHdrTask destroyTask];
            _videoLiteHdrTask = nil;
        }
    }
    _enableVideoLiteHdr = enableVideoLiteHdr;
}


- (void)setEnableCineMove:(bool)enableCineMove type:(int)type;
{
    if (_enableCineMove == enableCineMove && _cineMoveType == type)
        return;
    
    if (enableCineMove) {
        if (!_cineMoveTask) {
            _cineMoveTask = [[DGCBECineMoveTask alloc] init];
            _cineMoveTask.provider = self.provider;
        }
        else {
            [_cineMoveTask destroyTask];
        }
        [_cineMoveTask initTaskWithType:type featureTypeList:nil];
        _cineMoveType = type;
    } else {
        if (_cineMoveTask) {
            [_cineMoveTask destroyTask];
            _cineMoveTask = nil;
        }
    }
    _enableCineMove = enableCineMove;
}

- (void)setEnableVideoDeflicker:(bool)enableVideoDeflicker
{
    if (_enableVideoDeflicker == enableVideoDeflicker)
        return;
    
    if (enableVideoDeflicker) {
        if (!_videoDeflickerTask) {
            _videoDeflickerTask = [[DGCBEVideoDeflickerTask alloc] init];
            _videoDeflickerTask.provider = self.provider;
            
            if ([_videoDeflickerTask initTask]){ // No zero means initlization error
                _videoDeflickerTask = nil;
            }
        }
    } else {
        if (_videoDeflickerTask) {
            [_videoDeflickerTask destroyTask];
            _videoDeflickerTask = nil;
        }
    }
    _enableVideoDeflicker = enableVideoDeflicker;
}

- (void)setEnableVideoStab:(bool)enableVideoStab
{
    if (_enableVideoStab == enableVideoStab)
        return;
    
    if (enableVideoStab) {
        if (!_videoStabTask) {
            _videoStabTask = [[DGCBEVideoStabTask alloc] init];
            _videoStabTask.provider = self.provider;
            
            if ([_videoStabTask initTask]){ // No zero means initlization error
                _videoStabTask = nil;
            }
        }
    } else {
        if (_videoStabTask) {
            [_videoStabTask destroyTask];
            _videoStabTask = nil;
        }
    }
    _enableVideoStab = enableVideoStab;
}

- (void)setVideoStabProcessType: (BEVideoStabProcessType)type{
    _videoStabProcessType = type;
    _videoStabFrameIdx = 0;
}


@end
