//  DGCBEAlgorithmTaskFactory.h
//  Core


#ifndef BEAlgorithmTaskFactory_h
#define BEAlgorithmTaskFactory_h

#import "DGCBEAlgorithmTask.h"
#import "DGCBELicenseHelper.h"

typedef DGCBEAlgorithmTask *(^BEAlgorithmTaskGenerator) (id<BEAlgorithmResourceProvider>, id<BELicenseProvider>);

@interface DGCBEAlgorithmTaskFactory : NSObject

//   {zh} / @brief 注册算法     {en} /@brief registration algorithm 
//   {zh} / @param key 算法 key     {en} /@param key algorithm key 
//   {zh} / @param generator 算法生产者     {en} /@param generator algorithm producer 
+ (void)register:(DGCBEAlgorithmKey *)key generator:(BEAlgorithmTaskGenerator)generator;

//   {zh} / @brief 创建算法     {en} /@brief creation algorithm 
//   {zh} / @param key 算法 key     {en} /@param key algorithm key 
//   {zh} / @param provider 资源路径提供类     {en} /@param provider resource path provider class 
+ (DGCBEAlgorithmTask *)create:(DGCBEAlgorithmKey *)key provider:(id<BEAlgorithmResourceProvider>)provider licenseProvider:(id<BELicenseProvider>) licenseProvider;

@end

#endif /* BEAlgorithmTaskFactory_h */
