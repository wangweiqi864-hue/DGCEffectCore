//  DGCBESkeletonAnimation.mm
//  BECore


#include <vector>
#include <iostream>
#include <fstream>
#include <sstream>
#include <unordered_map>

#import <GLKit/GLKit.h>
#import "BETransform.h"
#import "DGCBESkeletonAnimation.h"

using namespace std;
#define PI 3.14159265359

//  {zh} 按照广度优先遍历的顺序对关节点进行存储，24个关节  {en} The joint points are stored in the order of breadth-first traversal, 24 joints
static vector<string> kBoneIds = {
    "ePelvis",
    "eLeftHip",
    "eRightHip",
    "eSpine",
    "eLeftKnee",
    "eRightKnee",
    "eSpine1",
    "eLeftAnkle",
    "eRightAnkle",
    "eSpine2",
    "eLeftFoot",
    "eRightFoot",
    "eNeck",
    "eLeftCollar",
    "eRightCollar",
    "eHead",
    "eLeftUpperArm",
    "eRightUpperArm",
    "eLeftForeArm",
    "eRightForeArm",
    "eLeftWrist",
    "eRightWrist",
    "eLeftHand",
    "eRightHand"
};

static unordered_map<string, string> kBoneNameMap = {
    {"ePelvis",         "Pelvis"},
    {"eSpine",          "Spine1"},
    {"eSpine1",         "Spine2"},
    {"eSpine2",         "Spine3"},
    {"eNeck",           "Neck"},
    {"eHead",           "Head"},
    {"eLeftCollar",     "L_Shoulder"},
    {"eLeftUpperArm",   "L_UpperArm"},
    {"eLeftForeArm",    "L_ForeArm"},
    {"eLeftWrist",      "L_Hand"},
    {"eRightCollar",    "R_Shoulder"},
    {"eRightUpperArm",  "R_UpperArm"},
    {"eRightForeArm",   "R_ForeArm"},
    {"eRightWrist",     "R_Hand"},
    {"eLeftHip",        "L_Thigh"},
    {"eLeftKnee",       "L_Leg"},
    {"eLeftAnkle",      "L_Foot"},
    {"eLeftFoot",       "L_Toe"},
    {"eRightHip",       "R_Thigh"},
    {"eRightKnee",      "R_Leg"},
    {"eRightAnkle",     "R_Foot"},
    {"eRightFoot",      "R_Toe"}
};

// keys are children, values are parents
static unordered_map<string, string> parentMap = {
    {"eLeftHip",       "ePelvis"},
    {"eLeftKnee",      "eLeftHip"},
    {"eLeftAnkle",     "eLeftKnee"},
    {"eLeftFoot",      "eLeftAnkle"},
    {"eRightHip",      "ePelvis"},
    {"eRightKnee",     "eRightHip"},
    {"eRightAnkle",    "eRightKnee"},
    {"eRightFoot",     "eRightAnkle"},
    {"eSpine",         "ePelvis"},
    {"eSpine1",        "eSpine"},
    {"eSpine2",        "eSpine1"},
    {"eNeck",          "eSpine2"},
    {"eHead",          "eNeck"},
    {"eLeftCollar",    "eSpine2"},
    {"eLeftUpperArm",  "eLeftCollar"},
    {"eLeftForeArm",   "eLeftUpperArm"},
    {"eLeftWrist",     "eLeftForeArm"},
    {"eLeftHand",      "eLeftWrist"},
    {"eRightCollar",   "eSpine2"},
    {"eRightUpperArm", "eRightCollar"},
    {"eRightForeArm",  "eRightUpperArm"},
    {"eRightWrist",    "eRightForeArm"},
    {"eRightHand",     "eRightWrist"},
};

struct InitBoneInfo {
    int id;
    BEMatrix4f offset;
    InitBoneInfo() { id = 0; offset = BEMatrix4f::identity(); }
};

struct Vertex {
    float Position[3];
    float TexCoords[2];
    float Normal[3];
    
    float BoneIds[4];
    float Weights[4];
};

struct SkeletonMesh {
    vector<Vertex> vertices;
    vector<unsigned short> indices;
    string texturePath;
    vector<string> boneHierarchy;   //  {zh} 广度优先遍历骨骼层级结构  {en} Breadth-first traversal of skeletal hierarchies
    unordered_map<string, InitBoneInfo> boneInfoDict; //  {zh} 保存inv矩阵  {en} Save inv matrix
};

@implementation DGCBESkeletonAnimation {
    string dgc_directory;
    vector<SkeletonMesh> dgc_meshes;
    unordered_map<string, BETransform> dgc_boneTransforms;  //  {zh} 保存了每个关节点的初始pose和对应的父节点  {en} The initial pose and corresponding parent node of each joint point are saved
    unordered_map<string, BEQuaternion> currentBoneOrientation;
    unordered_map<string, BEQuaternion> initBoneOrientation;
    BEVector3f pelvisInitPosition;
    // rendering
    vector<unsigned int> VBOs;
    vector<unsigned int> EBOs;
    vector<unsigned int> textures;
}

- (id)initWithPath:(NSString*)path {
    _meshNum = 0;
    dgc_directory = string([path UTF8String]);
    if([super init]) {
        BOOL success = [self loadMesh:@"/body/body" texPath:@"/diffuse.jpg"];
        success = [self loadMesh:@"/body/hudiejie" texPath:@"/diffuse.jpg"];
        success = [self loadMesh:@"/body/yanqiu" texPath:@"/diffuse.jpg"];
        NSAssert(success, @"skeleton animation file loaded failed!");
        [self loadSkeleton];
        [self glEnvSetup];
    }
    return self;
}

- (BOOL)loadMesh:(NSString*)path texPath:(NSString*)texturePath {
    int idx = (int)dgc_meshes.size();
    dgc_meshes.push_back(SkeletonMesh());
    // ------------------ VERTEX.TXT ------------------
    string comb_path = dgc_directory + string([path UTF8String]) + "/vertex.txt";
    FILE *fp = fopen(comb_path.c_str(), "r");
    char line[1000];
    if (fp == nullptr) {
        cout << comb_path + " is not existed!\n";
        return false;
    }
    std::vector<Vertex> vertices;
    while(!feof(fp))
    {
        fgets(line,1000,fp);
        stringstream ss;
        ss << line;
        Vertex vert;
        float vert_data[16] = {0};
        string element;
        for (int i = 0; i < 16; ++i) {
            if (ss >> element)
                vert_data[i] = stof(element);
            else assert(0);
        }
        memcpy(&vert, vert_data, sizeof(Vertex));
        
        dgc_meshes[idx].vertices.push_back(vert);
    }
    fclose(fp);
    
    // ------------------ INDICES.TXT ------------------
    comb_path = dgc_directory + string([path UTF8String]) + "/indices.txt";
    fp = fopen(comb_path.c_str(), "r");
    if (fp == nullptr) {
        cout << comb_path + " is not existed!\n";
        return false;
    }
    while (fscanf(fp, "%s", line) != EOF)
    {
        //  {zh} 最大索引数 2B -> 65535  {en} Maximum number of indexes 2B - > 65535
        dgc_meshes[idx].indices.push_back((unsigned short)stoi(string(line)));
    }
    fclose(fp);
    
    // ------------------ SKININV ------------------
    comb_path = dgc_directory + string([path UTF8String]) + "/skinInv.txt"; // matrix stored as colomn first
    fp = fopen(comb_path.c_str(), "r");
    if (fp == nullptr) {
        cout << comb_path + " is not existed!\n";
        return false;
    }
    int boneCounter = 0;
    while(!feof(fp))
    {
        fgets(line,1000,fp);
        stringstream ss;
        ss << line;
        InitBoneInfo boneinfo;
        std::string bonename;
        ss >> bonename;
        string element;
        for (int i = 0; i < 16; ++ i) {
            if (ss >> element)
                boneinfo.offset[i] = stof(element);
            else assert(0);
        }
        boneinfo.id = boneCounter ++;
        dgc_meshes[idx].boneInfoDict[bonename] = boneinfo;
        
        dgc_meshes[idx].boneHierarchy.push_back(bonename);
    }
    fclose(fp);
    
    // ------------------ TEXTURE ------------------
    dgc_meshes[idx].texturePath = dgc_directory + string([path UTF8String]) + string([texturePath UTF8String]);
    _meshNum ++;
    return true;
}

- (BOOL)loadSkeleton {
    // ------------------ INITPOSE ------------------
    string comb_path = dgc_directory + "/jointInit.txt";
    FILE *fp = fopen(comb_path.c_str(), "r");
    char line[1000];
    if (fp == nullptr) {
        cout << comb_path + " is not existed!\n";
        return false;
    }
    while(!feof(fp))
    {
        fgets(line,1000,fp);
        stringstream ss;
        ss << line;
        std::string boneName;
        ss >> boneName;
        float pose[10] = {0.0};
        for (int i = 0; i < 10; i ++) {
            std::string num;
            if(ss >> num) pose[i] = stof(num);
            else assert(0);
        }
        
        BEVector3f pos(pose);
        BEVector3f scale(pose+3);
        BEQuaternion rotation(pose+6);
        BETransform transform(pos, scale, rotation);
        transform.setName(boneName);
        dgc_boneTransforms[boneName] = transform;
    }
    fclose(fp);

    // ------------------ PARENT ------------------
    comb_path = dgc_directory + "/jointInfo.txt";
    fp = fopen(comb_path.c_str(), "r");
    if (fp == nullptr) {
        cout << comb_path + " is not existed!\n";
        return false;
    }
    while(!feof(fp))
    {
        fgets(line,1000,fp);
        stringstream ss;
        ss << line;
        std::string boneName, boneParent;
        ss >> boneName >> boneParent;
        dgc_boneTransforms[boneName].setParent(&dgc_boneTransforms[boneParent]);
    }
    fclose(fp);
    
    // related variable init
    for (auto& k: kBoneNameMap) {
        initBoneOrientation[k.first] = dgc_boneTransforms[k.second].getWorldOrientation();
    }
    pelvisInitPosition = dgc_boneTransforms["Pelvis"].getWorldPosition();

    return true;
}

- (void)glEnvSetup {
    for (int i = 0; i < _meshNum; ++ i) {
        unsigned int VBO, EBO;
        glGenBuffers(1, &VBO);
        glGenBuffers(1, &EBO);
        
        SkeletonMesh& mesh = dgc_meshes[i];
        glBindBuffer(GL_ARRAY_BUFFER, VBO);
        glBufferData(GL_ARRAY_BUFFER, mesh.vertices.size() * sizeof(Vertex), &mesh.vertices[0], GL_STATIC_DRAW);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, mesh.indices.size() * sizeof(unsigned short), &mesh.indices[0], GL_STATIC_DRAW);
        
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        VBOs.push_back(VBO);
        EBOs.push_back(EBO);
        
        // prepare texture
        if (mesh.texturePath != "") {
            NSString *texturePath = [NSString stringWithUTF8String:mesh.texturePath.c_str()];
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
                return;
            }
            glBindTexture(base_texture.target, base_texture.name);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            textures.push_back(base_texture.name);
        }
    }
}

- (void)UpdatePoseInfo:(bef_ai_skeleton3d_target*) poseInfo {
    float* quaternions = poseInfo->quaternion;
    
    for (int i = 0; i < kBoneIds.size(); ++ i) {
        string boneName = kBoneIds[i];
        BEQuaternion qua(quaternions + 4*i);
        if (parentMap.find(boneName) != parentMap.end()) {
            string parentName = parentMap[boneName];
            
            BEQuaternion quaParent;
            if (currentBoneOrientation.find(parentName) != currentBoneOrientation.end()) {
                quaParent = currentBoneOrientation[parentName];
            }
            currentBoneOrientation[boneName] = quaParent * qua;
        } else {
            currentBoneOrientation[boneName] = qua;
        }
        
        qua = currentBoneOrientation[boneName];
        if (kBoneNameMap.find(boneName) != kBoneNameMap.end()) {
            string algoName = kBoneNameMap[boneName];
            if (dgc_boneTransforms.find(algoName) != dgc_boneTransforms.end() && valid_quat(qua)) {
                BEQuaternion srcQua = initBoneOrientation[boneName];
                BEQuaternion dstQua = qua * srcQua;
                dgc_boneTransforms[algoName].setWorldOrientation(dstQua);
            }
        }
    }
    
    // update position
    float* joints = poseInfo->joints;
    BEVector3f pelvisAlgoPos(joints);
    pelvisAlgoPos -= BEVector3f(0, 0, -15);
    pelvisAlgoPos *= 20;
    pelvisAlgoPos += pelvisInitPosition;
    dgc_boneTransforms["Pelvis"].setWorldPosition(pelvisAlgoPos);
}

- (void)Draw:(unsigned int)program_0 algoResult:(bef_ai_skeleton3d_target*)ret focalLength:(float)focal_length width:(int)width height:(int)height{
    GLuint program = program_0;
    for (int i = 0; i < _meshNum; ++ i) {
        [self UpdatePoseInfo:ret];
        unsigned int VBO = VBOs[i];
        unsigned int EBO = EBOs[i];
        unsigned int texture = textures[i];
        glUseProgram(program);
        glBindBuffer(GL_ARRAY_BUFFER, VBO);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
        
        // positions
        GLuint a_position = glGetAttribLocation(program, "pos");
        glEnableVertexAttribArray(a_position);
        glVertexAttribPointer(a_position, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)0);
        // texture coords
        GLuint a_texcoord = glGetAttribLocation(program, "tex");
        glEnableVertexAttribArray(a_texcoord);
        glVertexAttribPointer(a_texcoord, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)offsetof(Vertex, TexCoords));
        // ids
        GLuint a_boneID = glGetAttribLocation(program, "boneIds");
        glEnableVertexAttribArray(a_boneID);
        glVertexAttribPointer(a_boneID, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)offsetof(Vertex, BoneIds));
        // weights
        GLuint a_weights = glGetAttribLocation(program, "weights");
        glEnableVertexAttribArray(a_weights);
        glVertexAttribPointer(a_weights, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)offsetof(Vertex, Weights));
        
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
        BEMatrix4f proj;
        float model[16] = {1,0,0,0,0,1,0,0,0,0,1,0,0,0,-300,1};
        float tanAlgoHalfFov = (0.5 * (float)height) / (focal_length * 1.0);
        float kFovy = atan(tanAlgoHalfFov) * 360.f / PI;
        proj.SetPerspective(kFovy, (float)width/(float)height, 10.0, 1000.0);
        glUniformMatrix4fv(glGetUniformLocation(program, "modelView"), 1, GL_FALSE, model);
        glUniformMatrix4fv(glGetUniformLocation(program, "projection"), 1, GL_FALSE, proj.data);
        
        for (int k = 0; k < dgc_meshes[i].boneHierarchy.size(); ++ k) {
            string boneName = dgc_meshes[i].boneHierarchy[k];
            BEMatrix4f world = dgc_boneTransforms[boneName].getWorldMatrix();
            BEMatrix4f result = world * dgc_meshes[i].boneInfoDict[boneName].offset;
            GLuint u_boneMat = glGetUniformLocation(program, ("finalBonesMatrices[" + to_string(k) + "]").c_str());
            glUniformMatrix4fv(u_boneMat, 1, GL_FALSE, result.data);
        }
        
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, texture);
        GLuint u_sampler = glGetUniformLocation(program, "texture_diffuse1");
        glUniform1i(u_sampler, 0);
        
        glDrawElements(GL_TRIANGLES, (int)dgc_meshes[i].indices.size(), GL_UNSIGNED_SHORT, 0);
        
        glDisable(GL_BLEND);
        glDisableVertexAttribArray(a_position);
        glDisableVertexAttribArray(a_texcoord);
        glDisableVertexAttribArray(a_boneID);
        glDisableVertexAttribArray(a_weights);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    }
}

@end
