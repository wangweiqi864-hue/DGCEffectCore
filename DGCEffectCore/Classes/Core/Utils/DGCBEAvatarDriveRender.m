//
//  DGCBEAvatarDriveRender.m
//  Core
//
//  Created by Bytedance on 2023/2/16.
//

#import <Foundation/Foundation.h>
#import "DGCBEAvatarDriveRender.h"
#import "DGCBECommonUtils.h"
#import <GLKit/GLKit.h>
#import "DGCBETimeRecoder.h"

#import "Accelerate/Accelerate.h"

/* {zh} 
arch 使用 config.json来表示文件的结构
{
    "   ": "indices_file_name",
    "init_vertex": "init_vertex_file_name",
    "init_texture_cord": "init_texture_file_name",
    "blendshapes": { // 目前必须有52个维度，先从array角度进行处理
        "yaw_open_file_path", // vertex array
        "",
    }
    
}
    
 */
    
/* {en} 
Arch uses config.json to represent the structure of the file
 {
     ":" indices_file_name ",
    " init_vertex ":" init_vertex_file_name ",
    " init_texture_cord ":" init_texture_file_name ",
    " blendshapes ": { // must currently have 52 dimensions, first process from the perspective of array
         "yaw_open_file_path",//vertex array
         ",
    }
    
}
    
 */

#define CONFIG_FILE_NAME @"config.json"
#define BSFILE_KEY_VERTEX @"init_vertex"
#define BSFILE_KEY_TEXTURE_COORD @"init_texture_cord"
#define BSFILE_KEY_BLENS_SHAPE @"blendshapes"
#define BSFILE_KEY_INDICES @"indices"
#define BSFILE_KEY_DIFFUSE_IMAGE @"diffuse"

#define SAFE_DELETE_POINTER(point) \
if (point) { \
    free(point); \
    point = nil; \
} \

@interface  DGCBEAvatarDriveRender()

//@property (nonatomic, copy) NSString* resourceDir;

@property (nonatomic, assign) void* initVertexData;
@property (nonatomic, assign) void* initTextCordData;
@property (nonatomic, assign) void* initIndicesData;
@property (nonatomic, assign) float* vertexData;

@property (nonatomic, strong) NSMutableArray *bsData;

@property (nonatomic, assign) int initVertexDataCount;
@property (nonatomic, assign) int initTextureCordCount;
@property (nonatomic, assign) int initIndicesCount;
@property (nonatomic, assign) int inited;

// extra for hair draw
@property (nonatomic, assign) void* initVertexDataExtra;
@property (nonatomic, assign) int initVertexDataCountExtra;
@property (nonatomic, assign) int initIndicesCountExtra;

@property (nonatomic, assign) GLuint indicesEbo;
@property (nonatomic, assign) GLuint glVertexBuffer;
@property (nonatomic, assign) GLuint glTextCordBuffer;
@property (nonatomic, assign) GLuint glDiffuseTexture;

// extra for hair draw
@property (nonatomic, assign) GLuint indicesEboExtra;
@property (nonatomic, assign) GLuint glVertexBufferExtra;
@property (nonatomic, assign) GLuint glTextCordBufferExtra;
@property (nonatomic, assign) GLuint glDiffuseTextureExtra;

@end


@implementation DGCBEAvatarDriveRender

- (instancetype)initWithResourceDir:(NSString *)dir ExtraDir:(NSString *)extraDir{
    if (self = [super init]) {
        _inited = true;
        _bsData = [NSMutableArray new];
        
        _initVertexData = NULL;
        _initTextCordData = NULL;
        _initIndicesData = NULL;
        _vertexData = NULL;
        
        _glVertexBuffer = 0;
        _glTextCordBuffer = 0;
        _indicesEbo = 0;
        _glDiffuseTexture = 0;
        
        _initVertexDataExtra = NULL;
        
        _glVertexBufferExtra = 0;
        _glTextCordBufferExtra = 0;
        _indicesEboExtra = 0;
        _glDiffuseTextureExtra = 0;
    
        [self loadResource:dir VBO:&_glVertexBuffer texVBO:&_glTextCordBuffer EBO:&_indicesEbo textureID:&_glDiffuseTexture isExtra:false];
        [self loadResource:extraDir VBO:&_glVertexBufferExtra texVBO:&_glTextCordBufferExtra EBO:&_indicesEboExtra textureID:&_glDiffuseTextureExtra isExtra:true];
    }
    return self;
}

- (void)dealloc {
    SAFE_DELETE_POINTER(_initVertexData)
    SAFE_DELETE_POINTER(_initTextCordData)
    SAFE_DELETE_POINTER(_initIndicesData)
    SAFE_DELETE_POINTER(_vertexData)
    SAFE_DELETE_POINTER(_initVertexDataExtra)
    
    if (_glVertexBuffer) glDeleteBuffers(1, &_glVertexBuffer);
    if (_glTextCordBuffer) glDeleteBuffers(1, &_glTextCordBuffer);
    if (_indicesEbo) glDeleteBuffers(1, &_indicesEbo);
    if (_glDiffuseTexture) glDeleteTextures(1, &_glDiffuseTexture);
    
    if (_glVertexBufferExtra) glDeleteBuffers(1, &_glVertexBufferExtra);
    if (_glTextCordBufferExtra) glDeleteBuffers(1, &_glTextCordBufferExtra);
    if (_indicesEboExtra) glDeleteBuffers(1, &_indicesEboExtra);
    if (_glDiffuseTextureExtra) glDeleteTextures(1, &_glDiffuseTextureExtra);
    
    for (NSNumber* bs in _bsData) {
        free( [bs pointerValue]);
    }
    [_bsData removeAllObjects];
}


- (bool) loadResource:(NSString* )path VBO:(unsigned int*)glVertexBuffer texVBO:(unsigned int*)glTextCordBuffer EBO:(unsigned int*)indicesEbo textureID:(unsigned int*)glDiffuseTexture isExtra:(BOOL)extra{
    // try to find the file
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSLog(@"dir %@ not exist", path);
        _inited = false;
        return false;
    }
    
    NSString* configFile = [path stringByAppendingPathComponent:CONFIG_FILE_NAME];
    if (![[NSFileManager defaultManager] fileExistsAtPath:configFile]) {
        NSLog(@"file %@ not exist", configFile);
        _inited = false;
        return false;
    }
    
    // parse the config file
    NSData *data = [[NSData alloc] initWithContentsOfFile:configFile];
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (error != nil || dict == nil) {
        NSLog(@"invalid json format, error is %@", error);
        _inited = false;
        return false;
    }
    
    NSString* initVertex = [dict objectForKey:BSFILE_KEY_VERTEX];
    NSString* initTextureCord = [dict objectForKey:BSFILE_KEY_TEXTURE_COORD];
    NSString* initIndices = [dict objectForKey:BSFILE_KEY_INDICES];
    NSString* diffuseImage = [dict objectForKey:BSFILE_KEY_DIFFUSE_IMAGE];
    NSArray*  bsFiles = [dict objectForKey:BSFILE_KEY_BLENS_SHAPE];
    
    if (!(initVertex && initTextureCord && initIndices && diffuseImage)) {
        NSLog(@"invalid json format, key lost");
        return false;
    }
    
    _initTextCordData = [DGCBECommonUtils loadBinaryFileData:[path stringByAppendingPathComponent:initTextureCord] dataLength:&_initTextureCordCount dataType:BEDataTypeFloat];
    if (extra == false) {
        _initVertexData = [DGCBECommonUtils loadBinaryFileData:[path stringByAppendingPathComponent:initVertex] dataLength:&_initVertexDataCount dataType:BEDataTypeFloat];
        _initIndicesData = [DGCBECommonUtils loadBinaryFileData:[path stringByAppendingPathComponent:initIndices] dataLength:&_initIndicesCount dataType:BEDataTypeShort];
        _inited &= (_initVertexDataCount * 2 == _initTextureCordCount * 3);
        
        for (NSString * bsFile in bsFiles) {
            void* tmp;
            int tmpLength = 0;
            
            tmp = [DGCBECommonUtils loadBinaryFileData:[path stringByAppendingPathComponent:bsFile] dataLength:&tmpLength dataType:BEDataTypeFloat];
            [_bsData addObject:[NSNumber valueWithPointer:tmp]];
            _inited &= (tmpLength == _initVertexDataCount);
        }
        
        float* src_addr = _initVertexData;
        
        for (NSNumber* bs in _bsData) {
            float* dst_addr = [bs pointerValue];
            
            for (int i = 0; i < _initVertexDataCount; i++) {
                dst_addr[i] -= src_addr[i];
            }
        }
        _vertexData = (float*)malloc(_initVertexDataCount * sizeof(float));
    } else {
        _initVertexDataExtra = [DGCBECommonUtils loadBinaryFileData:[path stringByAppendingPathComponent:initVertex] dataLength:&_initVertexDataCountExtra dataType:BEDataTypeFloat];
        _initIndicesData = [DGCBECommonUtils loadBinaryFileData:[path stringByAppendingPathComponent:initIndices] dataLength:&_initIndicesCountExtra dataType:BEDataTypeShort];
        _inited &= (_initVertexDataCountExtra * 2 == _initTextureCordCount * 3);
    }
    
    if (_inited) {
        [self createGlResource:[path stringByAppendingPathComponent:diffuseImage] VBO:glVertexBuffer texVBO:glTextCordBuffer EBO:indicesEbo textureID:glDiffuseTexture withDrive:!extra];
    }
    return true;
}

- (void) createGlResource:(NSString*) texturePath VBO:(unsigned int*)glVertexBuffer texVBO:(unsigned int*)glTextCordBuffer EBO:(unsigned int*)indicesEbo textureID:(unsigned int*)glDiffuseTexture withDrive:(BOOL)drive{
    GLuint buffer[3];
    glGenBuffers(3, (GLuint*) &buffer);
    
    *glVertexBuffer = buffer[0];
    *glTextCordBuffer = buffer[1];
    *indicesEbo = buffer[2];

    glBindBuffer(GL_ARRAY_BUFFER, *glVertexBuffer);
    if (drive) {
        glBufferData(GL_ARRAY_BUFFER, _initVertexDataCount * sizeof(float), _initVertexData, GL_STATIC_DRAW);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, *indicesEbo);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, _initIndicesCount * sizeof(unsigned short), _initIndicesData, GL_STATIC_DRAW);
    } else {
        glBufferData(GL_ARRAY_BUFFER, _initVertexDataCountExtra * sizeof(float), _initVertexDataExtra, GL_STATIC_DRAW);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, *indicesEbo);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, _initIndicesCountExtra * sizeof(unsigned short), _initIndicesData, GL_STATIC_DRAW);
    }
    SAFE_DELETE_POINTER(_initIndicesData)
    
    glBindBuffer(GL_ARRAY_BUFFER, *glTextCordBuffer);
    glBufferData(GL_ARRAY_BUFFER, _initTextureCordCount * sizeof(float), _initTextCordData, GL_STATIC_DRAW);
    SAFE_DELETE_POINTER(_initTextCordData)
    
    *glDiffuseTexture = [DGCBECommonUtils loadTextureFromFile:texturePath];
}

#pragma mark - render

- (void)checkGLError {
    int error = glGetError();
    if (error != GL_NO_ERROR) {
        NSLog(@"checkGLError %d", error);
        @throw [NSException exceptionWithName:@"GLError" reason:@"error " userInfo:nil];
    }
}

- (void)renderAvatarDrive:(bef_ai_avatar_info *)info vertexLocation:(GLuint)vl textureCordLocation:(GLuint)tl textureUniform:(GLuint)tu{
    if (info == nil || !info->succ || !_inited)
        return ;
    
    [self updateVertex:info->beta];
    [self driveAnimojiWithvertexLocation:vl textureCordLocation:tl textureUniform:tu];
}

- (void)renderAvaBoost:(bef_ai_avaboost_ret *)info vertexLocation:(GLuint)vl textureCordLocation:(GLuint)tl textureUniform:(GLuint)tu{
    if (info == nil || !_inited)
        return ;
    
    [self updateVertex:info->beta];
    [self driveAnimojiWithvertexLocation:vl textureCordLocation:tl textureUniform:tu];
}

- (void)driveAnimojiWithvertexLocation:(GLuint)vl textureCordLocation:(GLuint)tl textureUniform:(GLuint)tu{
    // update avatar with expression model
    glBindBuffer(GL_ARRAY_BUFFER, _glVertexBuffer);
    glEnableVertexAttribArray(vl);
    glVertexAttribPointer(vl, 3, GL_FLOAT, GL_FALSE, 0, NULL);

    glBindBuffer(GL_ARRAY_BUFFER, _glTextCordBuffer);
    glEnableVertexAttribArray(tl);
    glVertexAttribPointer(tl, 2, GL_FLOAT, GL_FALSE, 0, NULL);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _glDiffuseTexture);
    glUniform1i(tu, 0);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indicesEbo);
    glDrawElements(GL_TRIANGLES, _initIndicesCount, GL_UNSIGNED_SHORT, NULL);
    
    // update extra model (hair)
    glBindBuffer(GL_ARRAY_BUFFER, _glVertexBufferExtra);
    glEnableVertexAttribArray(vl);
    glVertexAttribPointer(vl, 3, GL_FLOAT, GL_FALSE, 0, NULL);

    glBindBuffer(GL_ARRAY_BUFFER, _glTextCordBufferExtra);
    glEnableVertexAttribArray(tl);
    glVertexAttribPointer(tl, 2, GL_FLOAT, GL_FALSE, 0, NULL);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _glDiffuseTextureExtra);
    glUniform1i(tu, 0);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indicesEboExtra);
    glDrawElements(GL_TRIANGLES, _initIndicesCountExtra, GL_UNSIGNED_SHORT, NULL);
    
    glDisable(GL_BLEND);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

- (void)updateVertex:(float*) bsValue{
    if (!_vertexData) return;
    memcpy(_vertexData, _initVertexData, _initVertexDataCount * sizeof(float));

    for (int i = 0; i < 52; i ++) {
        float value = bsValue[i];
        NSNumber* number = [_bsData objectAtIndex:i] ;
        float* diff = [number pointerValue];
        vDSP_vsma(diff, 1, &value, _vertexData, 1, _vertexData, 1, _initVertexDataCount);
    }
    
    glBindBuffer(GL_ARRAY_BUFFER, _glVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, _initVertexDataCount * sizeof(float), _vertexData, GL_DYNAMIC_DRAW);
}

@end
