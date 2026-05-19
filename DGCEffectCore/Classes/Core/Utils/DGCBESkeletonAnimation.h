//  DGCBESkeletonAnimation.h
//  Core


#ifndef BESkeletonAnimation_h
#define BESkeletonAnimation_h

#import <Foundation/Foundation.h>
#import "bef_effect_ai_3d_skeleton.h"

@interface DGCBESkeletonAnimation: NSObject

- (id)initWithPath:(NSString*)path;
- (void)Draw:(unsigned int)program_0 algoResult:(bef_ai_skeleton3d_target*)ret focalLength:(float)focal_length width:(int)width height:(int)height;

@property int meshNum;

@end


#endif /* BESkeletonAnimation_h */
