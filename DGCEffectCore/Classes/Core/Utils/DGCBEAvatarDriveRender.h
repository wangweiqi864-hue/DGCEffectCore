//
//  DGCBEAvatarDriveRender.h
//  Core
//
//  Created by Bytedance on 2023/2/16.
//

#ifndef BEAvatarDriveRender_h
#define BEAvatarDriveRender_h

#import <Foundation/Foundation.h>
#import "bef_effect_ai_avatar_drive.h"
#import "bef_effect_ai_avaboost.h"
#import <GLKit/GLKit.h>


@interface  DGCBEAvatarDriveRender: NSObject

- (instancetype) initWithResourceDir:(NSString*) dir ExtraDir:(NSString *)extraDir;

- (void)renderAvatarDrive:(bef_ai_avatar_info *)info vertexLocation:(GLuint)vl textureCordLocation:(GLuint)tl textureUniform:(GLuint)tu;
- (void)renderAvaBoost:(bef_ai_avaboost_ret *)info vertexLocation:(GLuint)vl textureCordLocation:(GLuint)tl textureUniform:(GLuint)tu;

@end

#endif /* BEAvatarDriveRender_h */
