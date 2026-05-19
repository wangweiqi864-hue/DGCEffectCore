//  BEModelUtils.m
//  BECore


#import <Foundation/Foundation.h>
#import "BEModelUtils.h"
#import <vector>
#import <string>
#import <fstream>

@implementation DGCBEVec2

- (id)init {
    _X = 0.0;
    _Y = 0.0;
    return self;
}

- (id)initWithX:(float)px Y:(float)py {
    _X = px;
    _Y = py;
    return self;
}
@end

@implementation DGCBEVec3

- (id)init {
    _X = 0.0;
    _Y = 0.0;
    _Z = 0.0;
    return self;
}

- (id)initWithX:(float)px Y:(float)py Z:(float)pz {
    _X = px;
    _Y = py;
    _Z = pz;
    return self;
}

@end

@implementation DGCBEVertex
@end

@implementation DGCBEMaterial

- (id)init {
    _name = @"";
    _Ns = 0.0f;
    _Ni = 0.0f;
    _d = 0.0f;
    _illum = 0;
    return self;
}
@end

@implementation DGCBEMesh

- (id)initWithVertices:(NSArray<DGCBEVertex*> *)ver ind:(NSArray<NSNumber*> *)ind {
    _Vertices = [ver copy];
    _Indices = [ind copy];
    return self;
}

@end


inline std::string firstToken(const std::string &in)
{
    if (!in.empty())
    {
        size_t token_start = in.find_first_not_of(" \t");
        size_t token_end = in.find_first_of(" \t", token_start);
        if (token_start != std::string::npos && token_end != std::string::npos)
        {
            return in.substr(token_start, token_end - token_start);
        }
        else if (token_start != std::string::npos)
        {
            return in.substr(token_start);
        }
    }
    return "";
}

inline void split(const std::string &in,
                  std::vector<std::string> &out,
                  std::string token)
{
    out.clear();

    std::string temp;

    for (int i = 0; i < int(in.size()); i++)
    {
        std::string test = in.substr(i, token.size());

        if (test == token)
        {
            if (!temp.empty())
            {
                out.push_back(temp);
                temp.clear();
                i += (int)token.size() - 1;
            }
            else
            {
                out.push_back("");
            }
        }
        else if (i + token.size() >= in.size())
        {
            temp += in.substr(i, token.size());
            out.push_back(temp);
            break;
        }
        else
        {
            temp += in[i];
        }
    }
}

inline std::string tail(const std::string &in)
{
    size_t token_start = in.find_first_not_of(" \t");
    size_t space_start = in.find_first_of(" \t", token_start);
    size_t tail_start = in.find_first_not_of(" \t", space_start);
    size_t tail_end = in.find_last_not_of(" \t");
    if (tail_start != std::string::npos && tail_end != std::string::npos)
    {
        return in.substr(tail_start, tail_end - tail_start + 1);
    }
    else if (tail_start != std::string::npos)
    {
        return in.substr(tail_start);
    }
    return "";
}

template <class T>
inline const T & getElement(const std::vector<T> &elements, std::string &index)
{
    int idx = std::stoi(index);
    if (idx < 0)
        idx = int(elements.size()) + idx;
    else
        idx--;
    return elements[idx];
}

@implementation DGCBEOBJModelLoader {
    std::vector<DGCBEVec3 *> _dgc_positions;
    std::vector<DGCBEVec2 *> _dgc_texcoords;
    std::vector<DGCBEVec3 *> _dgc_normals;
    
    std::vector<DGCBEVertex *> _dgc_vertices;
    std::vector<NSNumber *> _dgc_indices;
    std::vector<NSString *> _dgc_meshMatNames;
    
    std::string _dgc_meshName;
    bool dgc_listening;
    
    float *dgc_vertices_ptr;
    unsigned short *dgc_indices_ptr;
}

- (id)init {
    dgc_vertices_ptr = nil;
    dgc_indices_ptr = nil;
    return self;
}

- (void)dealloc {
    free(dgc_vertices_ptr);
    free(dgc_indices_ptr);
}

- (BOOL)LoadFile:(NSString*)path
{
    std::string Path = std::string([path UTF8String]);
    if (Path.substr(Path.size() - 4, 4) != ".obj")
        return false;
    
    std::ifstream file(Path);
    if (!file.is_open())
        return false;
    
    std::string curline;
    dgc_listening = false;
    
    DGCBEMesh* tempMesh;
    while (std::getline(file, curline))
    {
        std::string first_token = firstToken(curline);
        // Generate a Mesh Object or Prepare for an object to be created
        if(first_token == "o" || first_token == "g" || curline[0] == 'g')
        {
            if (!dgc_listening)
            {
                dgc_listening = true;
                if (first_token == "o" || first_token == "g")
                {
                    _dgc_meshName = tail(curline);
                }
                else
                {
                    _dgc_meshName = "unnamed";
                }
            }
            else
            {
                // Generate the mesh to put into the array
                if (!_dgc_indices.empty() && !_dgc_vertices.empty())
                {
                    // Create Mesh
                    NSArray<DGCBEVertex *> *ver = [NSArray arrayWithObjects:&_dgc_vertices[0] count:_dgc_vertices.size()];
                    NSArray<NSNumber *> *ind = [NSArray arrayWithObjects:&_dgc_indices[0] count:_dgc_indices.size()];
                    tempMesh = [[DGCBEMesh alloc] initWithVertices:ver ind:ind];
                    tempMesh.MeshName = [NSString stringWithCString:_dgc_meshName.c_str() encoding:[NSString defaultCStringEncoding]];
                    // Insert Mesh
                    [_meshes addObject:tempMesh];

                    // Cleanup
                    _dgc_vertices.clear();
                    _dgc_indices.clear();
                    _dgc_meshName.clear();

                    _dgc_meshName = tail(curline);
                }
                else
                {
                    if (first_token == "o" || first_token == "g")
                    {
                        _dgc_meshName = tail(curline);
                    }
                    else
                    {
                        _dgc_meshName = "unnamed";
                    }
                }
            }
        }
        // Generate a Vertex Position
        if(first_token == "v")
        {
            std::vector<std::string> spos;
            DGCBEVec3* vpos = [[DGCBEVec3 alloc] init];
            split(tail(curline), spos, " ");

            vpos.X = std::stof(spos[0]);
            vpos.Y = std::stof(spos[1]);
            vpos.Z = std::stof(spos[2]);

            _dgc_positions.push_back(vpos);
        }
        // Generate a Vertex Texture Coordinate
        if (first_token == "vt")
        {
            std::vector<std::string> stex;
            DGCBEVec2* vtex = [[DGCBEVec2 alloc] init];
            split(tail(curline), stex, " ");

            vtex.X = std::stof(stex[0]);
            vtex.Y = std::stof(stex[1]);

            _dgc_texcoords.push_back(vtex);
        }
        // Generate a Vertex Normal;
        if (first_token == "vn")
        {
            std::vector<std::string> snor;
            DGCBEVec3* vnor = [[DGCBEVec3 alloc] init];
            split(tail(curline), snor, " ");

            vnor.X = std::stof(snor[0]);
            vnor.Y = std::stof(snor[1]);
            vnor.Z = std::stof(snor[2]);

            _dgc_normals.push_back(vnor);
        }
        // Generate a Face (vertices & indices)
        if (first_token == "f")
        {
            // Generate the vertices
            std::vector<DGCBEVertex *> vVerts;
            [self GenVerticesFromRawOBJ:vVerts pos:_dgc_positions itcoords:_dgc_texcoords normals:_dgc_normals curline:curline];
            for (DGCBEVertex* element: vVerts)
                _dgc_vertices.push_back(element);
            
            std::vector<unsigned int> iIndices;
            [self VertexTriangluation:iIndices index:vVerts];
            for(const unsigned int& element: iIndices) {
                NSNumber* indnum = [[NSNumber alloc] initWithUnsignedInt:(unsigned int)(_dgc_vertices.size() - vVerts.size()) + element];
                _dgc_indices.push_back(indnum);
            }
        }
        // Get Mesh Material Name
        if(first_token == "usemtl")
        {
            // TODO
        }
        if(first_token == "mtllib")
        {
            // TODO
        }
    }
    
    // Deal with last mesh
    if (!_dgc_indices.empty() && !_dgc_vertices.empty())
    {
        // Create Mesh
        NSArray<DGCBEVertex *> *ver = [NSArray arrayWithObjects:&_dgc_vertices[0] count:_dgc_vertices.size()];
        NSArray<NSNumber *> *ind = [NSArray arrayWithObjects:&_dgc_indices[0] count:_dgc_indices.size()];
        tempMesh = [[DGCBEMesh alloc] initWithVertices:ver ind:ind];
        tempMesh.MeshName = [NSString stringWithCString:_dgc_meshName.c_str() encoding:[NSString defaultCStringEncoding]];

        // Insert Mesh
        [_meshes addObject:tempMesh];
    }
    
    file.close();
    
    // TODO: Set Materials for each Mesh
    
    if([_meshes count] == 0 && _dgc_vertices.empty() && _dgc_indices.empty())
    {
        return false;
    }
    else
    {
        return true;
    }
}

- (float*)GetVertices {
    if(dgc_vertices_ptr != nil) {
        free(dgc_vertices_ptr);
    }

    dgc_vertices_ptr = (float*)malloc(sizeof(float) * _dgc_vertices.size() * 8);
    unsigned int index = 0;
    for(const DGCBEVertex* element: _dgc_vertices) {
        dgc_vertices_ptr[index] = element.Position.X;
        dgc_vertices_ptr[index + 1] = element.Position.Y;
        dgc_vertices_ptr[index + 2] = element.Position.Z;
        dgc_vertices_ptr[index + 3] = element.TextureCoordinate.X;
        dgc_vertices_ptr[index + 4] = element.TextureCoordinate.Y;
        dgc_vertices_ptr[index + 5] = element.Normal.X;
        dgc_vertices_ptr[index + 6] = element.Normal.Y;
        dgc_vertices_ptr[index + 7] = element.Normal.Z;
        index += 8;
    }
    return dgc_vertices_ptr;
}

- (unsigned long)GetVerticesSize {
    return sizeof(float) * _dgc_vertices.size() * 8;
}

- (unsigned short*)GetIndices {
    if(dgc_indices_ptr != nil) {
        free(dgc_indices_ptr);
    }
    dgc_indices_ptr = (unsigned short*)malloc(sizeof(unsigned short) * _dgc_indices.size());
    unsigned int index = 0;
    for(const NSNumber* element: _dgc_indices) {
        dgc_indices_ptr[index ++] = [element unsignedShortValue];
    }
    return dgc_indices_ptr;
}

- (unsigned long)GetIndicesSize {
    return sizeof(unsigned short) * _dgc_indices.size();
}

- (void)GenVerticesFromRawOBJ:(std::vector<DGCBEVertex *>&)oVerts pos:(const std::vector<DGCBEVec3 *>&)iPositions itcoords:(const std::vector<DGCBEVec2 *>&)iTCoords normals:(const std::vector<DGCBEVec3 *>&)iNormals curline:(std::string)icurline
{
    std::vector<std::string> sface, svert;
    // remove extra charactor
    icurline.erase(std::remove_if(icurline.begin(), icurline.end(), [](char ch){ return ch == '\n' || ch == '\r';}), icurline.end());
    split(tail(icurline), sface, " ");

    bool noNormal = false;

    for (int i = 0; i < int(sface.size()); i++)
    {
        DGCBEVertex* vVert = [[DGCBEVertex alloc] init];
        // See What type the vertex is.
        int vtype = 0;

        split(sface[i], svert, "/");

        // Check for just position - v1
        if (svert.size() == 1)
        {
            // Only position
            vtype = 1;
        }

        // Check for position & texture - v1/vt1
        if (svert.size() == 2)
        {
            // Position & Texture
            vtype = 2;
        }

        // Check for Position, Texture and Normal - v1/vt1/vn1
        // or if Position and Normal - v1//vn1
        if (svert.size() == 3)
        {
            if (svert[1] != "")
            {
                // Position, Texture, and Normal
                vtype = 4;
            }
            else
            {
                // Position & Normal
                vtype = 3;
            }
        }

        // Calculate and store the vertex
        switch (vtype)
        {
            case 1: // P
            {
                vVert.Position = getElement(iPositions, svert[0]);
                vVert.TextureCoordinate = [[DGCBEVec2 alloc] init];
                noNormal = true;
                oVerts.push_back(vVert);
                break;
            }
            case 2: // P/T
            {
                vVert.Position = getElement(iPositions, svert[0]);
                vVert.TextureCoordinate = getElement(iTCoords, svert[1]);
                noNormal = true;
                oVerts.push_back(vVert);
                break;
            }
            case 3: // P//N
            {
                vVert.Position = getElement(iPositions, svert[0]);
                vVert.TextureCoordinate = [[DGCBEVec2 alloc] init];
                vVert.Normal = getElement(iNormals, svert[2]);
                oVerts.push_back(vVert);
                break;
            }
            case 4: // P/T/N
            {
                vVert.Position = getElement(iPositions, svert[0]);
                vVert.TextureCoordinate = getElement(iTCoords, svert[1]);
                vVert.Normal = getElement(iNormals, svert[2]);
                oVerts.push_back(vVert);
                break;
            }
            default:
            {
                break;
            }
        }
    }
}

- (void)ComputeNormalOfTriangle:(std::vector<DGCBEVec3 *>&)tri {
    
}

- (void)VertexTriangluation:(std::vector<unsigned int>&)oIndices index:(const std::vector<DGCBEVertex *>&)iVerts
{
    if (iVerts.size() < 3) return;
    if (iVerts.size() == 3)
    {
        oIndices.push_back(0);
        oIndices.push_back(1);
        oIndices.push_back(2);
        return;
    }

    // Create a list of vertices
    std::vector<DGCBEVertex *> tVerts = iVerts;

    while (true)
    {
        // For every vertex
        for (int i = 0; i < int(tVerts.size()); i++)
        {
            // pPrev = the previous vertex in the list
            DGCBEVertex* pPrev;
            if (i == 0)
            {
                pPrev = tVerts[tVerts.size() - 1];
            }
            else
            {
                pPrev = tVerts[i - 1];
            }

            // pCur = the current vertex;
            DGCBEVertex* pCur = tVerts[i];

            // pNext = the next vertex in the list
            DGCBEVertex* pNext;
            if (i == tVerts.size() - 1)
            {
                pNext = tVerts[0];
            }
            else
            {
                pNext = tVerts[i + 1];
            }

            // Check to see if there are only 3 verts left
            // if so this is the last triangle
            if (tVerts.size() == 3)
            {
                // Create a triangle from pCur, pPrev, pNext
                for (int j = 0; j < int(tVerts.size()); j++)
                {
                    if (iVerts[j].Position == pCur.Position)
                        oIndices.push_back(j);
                    if (iVerts[j].Position == pPrev.Position)
                        oIndices.push_back(j);
                    if (iVerts[j].Position == pNext.Position)
                        oIndices.push_back(j);
                }

                tVerts.clear();
                break;
            }
            if (tVerts.size() == 4)
            {
                // Create a triangle from pCur, pPrev, pNext
                for (int j = 0; j < int(iVerts.size()); j++)
                {
                    if (iVerts[j].Position == pCur.Position)
                        oIndices.push_back(j);
                    if (iVerts[j].Position == pPrev.Position)
                        oIndices.push_back(j);
                    if (iVerts[j].Position == pNext.Position)
                        oIndices.push_back(j);
                }

                DGCBEVec3* tempVec;
                for (int j = 0; j < int(tVerts.size()); j++)
                {
                    if (tVerts[j].Position != pCur.Position
                        && tVerts[j].Position != pPrev.Position
                        && tVerts[j].Position != pNext.Position)
                    {
                        tempVec = tVerts[j].Position;
                        break;
                    }
                }

                // Create a triangle from pCur, pPrev, pNext
                for (int j = 0; j < int(iVerts.size()); j++)
                {
                    if (iVerts[j].Position == pPrev.Position)
                        oIndices.push_back(j);
                    if (iVerts[j].Position == pNext.Position)
                        oIndices.push_back(j);
                    if (iVerts[j].Position == tempVec)
                        oIndices.push_back(j);
                }

                tVerts.clear();
                break;
            }

            // Create a triangle from pCur, pPrev, pNext
            for (int j = 0; j < int(iVerts.size()); j++)
            {
                if (iVerts[j].Position == pCur.Position)
                    oIndices.push_back(j);
                if (iVerts[j].Position == pPrev.Position)
                    oIndices.push_back(j);
                if (iVerts[j].Position == pNext.Position)
                    oIndices.push_back(j);
            }

            // Delete pCur from the list
            for (int j = 0; j < int(tVerts.size()); j++)
            {
                if (tVerts[j].Position == pCur.Position)
                {
                    tVerts.erase(tVerts.begin() + j);
                    break;
                }
            }

            // reset i to the start
            // -1 since loop will add 1 to it
            i = -1;
        }

        // if no triangles were created
        if (oIndices.size() == 0)
            break;

        // if no more vertices
        if (tVerts.size() == 0)
            break;
    }
}


@end
