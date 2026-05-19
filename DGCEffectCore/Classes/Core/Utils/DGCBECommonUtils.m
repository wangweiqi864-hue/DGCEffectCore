//  DGCBECommonUtils.m
//  BECore


#import "DGCBECommonUtils.h"
#include <GLKit/GLKit.h>

@implementation DGCBECommonUtils

+ (CGFloat) colorComponentFrom: (NSString *) string start: (NSUInteger) start length: (NSUInteger) length {
    NSString *substring = [string substringWithRange: NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString: fullHex] scanHexInt: &hexComponent];
    return hexComponent / 255.0;
}

+ (UIColor *) colorWithHexString: (NSString *) hexString {
    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString: @"#" withString: @""] uppercaseString];
    CGFloat alpha, red, blue, green;
    switch ([colorString length]) {
        case 3: // #RGB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 1];
            green = [self colorComponentFrom: colorString start: 1 length: 1];
            blue  = [self colorComponentFrom: colorString start: 2 length: 1];
            break;
        case 4: // #ARGB
            alpha = [self colorComponentFrom: colorString start: 0 length: 1];
            red   = [self colorComponentFrom: colorString start: 1 length: 1];
            green = [self colorComponentFrom: colorString start: 2 length: 1];
            blue  = [self colorComponentFrom: colorString start: 3 length: 1];
            break;
        case 6: // #RRGGBB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 2];
            green = [self colorComponentFrom: colorString start: 2 length: 2];
            blue  = [self colorComponentFrom: colorString start: 4 length: 2];
            break;
        case 8: // #AARRGGBB
            alpha = [self colorComponentFrom: colorString start: 0 length: 2];
            red   = [self colorComponentFrom: colorString start: 2 length: 2];
            green = [self colorComponentFrom: colorString start: 4 length: 2];
            blue  = [self colorComponentFrom: colorString start: 6 length: 2];
            break;
        default:
            return nil;
    }
    return [UIColor colorWithRed: red green: green blue: blue alpha: alpha];
}

+(void*) loadFileData:(NSString*) file dataLength:(int*) length dataType:(BEDataType) dataType
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:file]) {
        NSLog(@"file %@ not exist", file);
        return NULL;
    }
    
    NSString* readFlag = [NSString new];
    int lengthInByte = 0;
    switch (dataType) {
        case BEDataTypeInt:
            readFlag = @"%d";
            lengthInByte = sizeof(int);
            break;
        case BEDataTypeFloat:
            readFlag = @"%f";
            lengthInByte = sizeof(float);
            break;
        case BEDataTypeShort:
            readFlag = @"%hu";
            lengthInByte = sizeof(unsigned short);
            break;
            
        default:{
            return nil;
            break;
        }
    }
    
    FILE* fp =  fopen([file UTF8String], "r");
    float number; // 64 bit is enough to protect the data
    int len = 0;
    
    // read length
    while (fscanf(fp, [readFlag UTF8String], &number) != EOF){
        len ++;
    }
    
    fseek(fp, 0, SEEK_SET);
    
    void* data = malloc(len * lengthInByte);
    if (data == nil) {
        fclose(fp);
        return nil;
    }
    
    // read data
    len = 0;
    uint8_t* tmp = data;
    while (fscanf(fp, [readFlag UTF8String], tmp) != EOF) {
        len ++;
        tmp += lengthInByte;
    }
    fclose(fp);
    
    // set length
    if (length) *length = len;
    return data;
}

+(void*) loadBinaryFileData:(NSString*) file dataLength:(int*) length dataType:(BEDataType) dataType
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:file]) {
        NSLog(@"file %@ not exist", file);
        return NULL;
    }
    
    FILE* fp =  fopen([file UTF8String], "rb");
    fseek(fp, 0, SEEK_END);
    int len = (int)ftell(fp);
    int lengthInByte = 0;
    void* retptr = nil;
    
    if (dataType == BEDataTypeFloat) {
        lengthInByte = sizeof(float);
        float* pData = (float*) malloc(len);
        fseek(fp, 0, SEEK_SET);
        fread(pData, lengthInByte, len/lengthInByte, fp);
        retptr = pData;
    }
    if (dataType == BEDataTypeShort) {
        lengthInByte = sizeof(unsigned short);
        unsigned short* pData = (unsigned short*) malloc(len);
        fseek(fp, 0, SEEK_SET);
        fread(pData, lengthInByte, len/lengthInByte, fp);
        retptr = pData;
    }
    if (dataType == BEDataTypeInt) {
        lengthInByte = sizeof(int);
        int* pData = (int*) malloc(len);
        fseek(fp, 0, SEEK_SET);
        fread(pData, lengthInByte, len/lengthInByte, fp);
        retptr = pData;
    }
    fclose(fp);
    
    // set length
    if (length) *length = len/lengthInByte;
    return retptr;
}


+(GLuint) loadTextureFromFile:(NSString*) imagePath {
    NSString *texturePath = imagePath;
    NSDictionary* options = @{
        GLKTextureLoaderOriginBottomLeft: @YES,
        GLKTextureLoaderGenerateMipmaps: @YES,
    };
    NSError *error = nil;
    GLKTextureInfo *base_texture = [GLKTextureLoader textureWithContentsOfFile:texturePath options:options error:&error];
    if(error) {
        for(id key in [error.userInfo allKeys]) {
            NSLog(@"%@: %@", key, [error.userInfo objectForKey:key]);
        }
        return 0;
    }
    glBindTexture(base_texture.target, base_texture.name);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    return base_texture.name;
}
@end
