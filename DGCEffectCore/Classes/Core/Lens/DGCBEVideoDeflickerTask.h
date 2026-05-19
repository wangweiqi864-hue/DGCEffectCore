//
//  BEVideoDeflicker.h
//  Core
//
//  Created by ByteDance on 2023/05/26.
//

#ifndef BEVideoDeflicker_h
#define BEVideoDeflicker_h

#import <CoreVideo/CoreVideo.h>
#import "DGCBELicenseHelper.h"

@protocol BEVideoDeflickerResourceProvider <NSObject>

- (const char *)videoDeflickerLibPath;

@end

@interface DGCBEVideoDeflickerTask:NSObject

@property (nonatomic, strong) id<BELicenseProvider> provider;

- (int)initTask;
- (CVPixelBufferRef)processCVPixelBuffer:(CVPixelBufferRef)buffer;
- (int)destroyTask;

@end


#endif /* BEVideoDeflicker_h */
