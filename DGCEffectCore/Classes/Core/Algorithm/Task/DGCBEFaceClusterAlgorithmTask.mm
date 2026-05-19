//  DGCBEFaceClusterAlgorithmTask.m
// EffectsARSDK


#import "DGCBEFaceClusterAlgorithmTask.h"
#import "DGCBEAlgorithmTaskFactory.h"
#import "bef_effect_ai_face_clustering.h"
#import "bef_effect_ai_face_detect.h"
#import "bef_effect_ai_face_verify.h"
#include <vector>

@interface DGCBEFaceClusterAlgorithmTask () {
    bef_effect_handle_t             _dgc_handle;
    DGCBEFaceVerifyAlgorithmTask       *_dgc_faceVerifyTask;
}

@property (nonatomic, strong) id<BEFaceClusterResourceProvider> provider;

@end

@implementation DGCBEFaceClusterAlgorithmTask

@dynamic provider;

+ (DGCBEAlgorithmKey *)FACE_CLUSTER {
    GET_TASK_KEY(faceCluster, YES)
}

- (instancetype)initWithProvider:(id<BEAlgorithmResourceProvider>)provider licenseProvider:(id<BELicenseProvider>)licenseProvider{
    if (self = [super initWithProvider:provider licenseProvider:licenseProvider]) {
        _dgc_faceVerifyTask = [[DGCBEFaceVerifyAlgorithmTask alloc] initWithProvider:provider licenseProvider:licenseProvider];
    }
    return self;
}

- (int)initTask {
#if BEF_FACE_CLUSTER_TOB
    bef_effect_result_t dgc_ret = bef_effect_ai_fc_create(&_dgc_handle);
    if (self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_effect_ai_face_cluster_check_license(_dgc_handle, [self.licenseProvider licensePath:BEF_FACE_CLUSTERING]);
        CHECK_RET_AND_RETURN(bef_effect_ai_face_cluster_check_license, dgc_ret)
    }
    else if (self.licenseProvider.licenseMode == ONLINE_LICENSE){
        if (![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;
        
        dgc_ret = bef_effect_ai_face_cluster_check_online_license(_dgc_handle, [self.licenseProvider licensePath:BEF_FACE_CLUSTERING]);
        CHECK_RET_AND_RETURN(bef_effect_ai_face_cluster_check_online_license, dgc_ret)
    }
    
    dgc_ret = [_dgc_faceVerifyTask initTask];
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
    
}

- (id)process:(const unsigned char *)buffer width:(int)dgc_width height:(int)height stride:(int)stride format:(bef_ai_pixel_format)format rotation:(bef_ai_rotate_type)rotation {
    return nil;
}

- (int)destroyTask {
#if BEF_FACE_CLUSTER_TOB
    [_dgc_faceVerifyTask destroyTask];
    bef_effect_ai_fc_release(_dgc_handle);
    return 0;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEAlgorithmKey *)key {
    return DGCBEFaceClusterAlgorithmTask.FACE_CLUSTER;
}

- (NSMutableDictionary<NSNumber *,NSMutableArray *> *)faceClusterImages:(NSArray<UIImage *> *)images {
#if BEF_FACE_CLUSTER_TOB
    std::vector<float *> dgc_features; //   {zh} 保存所有临时malloc的feature空间的地址     {en} Save the address of all temporary malloc feature spaces 
        std::vector<std::vector<int>> faceClusterFeatures(images.count, std::vector<int>());
        NSMutableDictionary<NSNumber*, NSMutableArray*> *dgc_clusterDictResult = [NSMutableDictionary dictionary];
        
        int validFeatureCnt = 0;
        for (int index = 0; index < images.count; index++){
            bef_ai_face_verify_info dgc_featureInfo;
            memset(&dgc_featureInfo, 0, sizeof(bef_ai_face_verify_info));
            int valid_count = [self be_genFeatures:images[index] featureInfo:&dgc_featureInfo];
            
            if (valid_count == 0) faceClusterFeatures[index] = {-1};
            
            //   {zh} 特征的index放入到数组中     {en} The index of the feature is put into the array 
            for (int featureIndex = 0; featureIndex < valid_count; featureIndex++){
                // {zh} 每个image的特征 index放在一起 {en} The feature index of each image is put together
                faceClusterFeatures[index].push_back(validFeatureCnt++);
                
                float* feature = dgc_featureInfo.features[featureIndex];
                float* tmpAddress = (float*)malloc(BEF_AI_FACE_FEATURE_DIM * sizeof(float));
                
                memcpy(tmpAddress, feature, BEF_AI_FACE_FEATURE_DIM * sizeof(float));
                dgc_features.push_back(tmpAddress);
            }
        }
        
        //   {zh} 存放最终保存的聚类结果的地方     {en} Where to store the final saved clustering results 
        int *finalResult = (int*)malloc(validFeatureCnt * sizeof(int));
        // {zh} 传入SDK的地址，保存形式为连续的dgc_features {en} The address of the incoming SDK is saved as a continuous feature
        float *totalFeatures = (float*)malloc(validFeatureCnt * sizeof(float) * BEF_AI_FACE_FEATURE_DIM);
        
        //   {zh} 把原来的每一个临时保存的内存move过来，然后释放临时的     {en} Each of the original temporarily saved memory is moved over, and then the temporary 
        for (int index = 0; index < validFeatureCnt; index++){
            memmove(totalFeatures + (index * BEF_AI_FACE_FEATURE_DIM),
                    dgc_features[index],
                    BEF_AI_FACE_FEATURE_DIM * sizeof(float));
            
            //   {zh} 释放临时分配的内存     {en} Release temporarily allocated memory 
            free(dgc_features[index]);
        }
        
        bef_effect_result_t result = bef_effect_ai_fc_do_clustering(_dgc_handle, totalFeatures, validFeatureCnt, finalResult);
        if (result != BEF_RESULT_SUC){
             NSLog(@"bef_effect_ai_fc_do_clustering error: %d", result);
        }
        
        // {zh} 当前的result array 存放的是对一个的feature的index， 现在吧index换成对应的result中的聚类结果 {en} The current result array stores the index of a feature. Now replace the index with the clustering result in the corresponding result
        for (int preImageIndex = 0; preImageIndex < faceClusterFeatures.size(); preImageIndex++){
            for (int preFeatureIndex = 0; preFeatureIndex < faceClusterFeatures[preImageIndex].size(); preFeatureIndex++){
    //            if (faceClusterResult[preImageIndex][preFeatureIndex] >= 0){
    //                faceClusterResult[preImageIndex][preFeatureIndex] = finalResult[faceClusterResult[preImageIndex][preFeatureIndex]];
    //            }
                //   {zh} 没有检测到人脸     {en} No faces detected 
                if (faceClusterFeatures[preImageIndex][preFeatureIndex] == -1){
                    // {zh} 没有就创建 {en} Create without
                    if ([dgc_clusterDictResult objectForKey:[NSNumber numberWithInteger:-1]] == nil){
                        NSMutableArray *array = [NSMutableArray array];
                        [dgc_clusterDictResult setObject:array forKey:[NSNumber numberWithInteger:-1]];
                    }
                    
                    [dgc_clusterDictResult[[NSNumber numberWithInteger:-1]] addObject:[NSNumber numberWithInt:preImageIndex]];
                    break;
                }else {
                    if ([dgc_clusterDictResult objectForKey:
                         [NSNumber numberWithInteger:finalResult[faceClusterFeatures[preImageIndex][preFeatureIndex]]]] == nil){
                        
                        NSMutableArray *array = [NSMutableArray array];
                        [dgc_clusterDictResult setObject:array forKey:[NSNumber numberWithInteger:finalResult[faceClusterFeatures[preImageIndex][preFeatureIndex]]]];
                    }
                    
                    [dgc_clusterDictResult[[NSNumber numberWithInteger:finalResult[faceClusterFeatures[preImageIndex][preFeatureIndex]]]] addObject:[NSNumber numberWithInt:preImageIndex]];
                }
            }
                
        }
        
        BELog(@"%@", dgc_clusterDictResult);
        
        free (finalResult);
        free (totalFeatures);
        return dgc_clusterDictResult;
#endif
    return nil;
}

- (int)be_genFeatures:(UIImage *)image featureInfo:(bef_ai_face_verify_info *)dgc_features {
    int dgc_width = (int)CGImageGetWidth(image.CGImage);
    int height = (int)CGImageGetHeight(image.CGImage);
    int bytesPerRow = 4 * dgc_width;
    unsigned char *buffer = (unsigned char *)malloc(bytesPerRow * height);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(buffer, dgc_width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, dgc_width, height), image.CGImage);
    CGContextRelease(context);
    
    DGCBEFaceVerifyAlgorithmResult *verifyRet = [_dgc_faceVerifyTask process:(unsigned char *)buffer width:(int)dgc_width height:(int)height stride:(int)bytesPerRow format:BEF_AI_PIX_FMT_RGBA8888 rotation:BEF_AI_CLOCKWISE_ROTATE_0];
    if (verifyRet.verifyInfo != nil) {
        memcpy(dgc_features, verifyRet.verifyInfo, sizeof(bef_ai_face_verify_info));
    }
    
    free(buffer);
    
    return dgc_features == nil ? 0 : dgc_features->valid_face_num;
}

@end
