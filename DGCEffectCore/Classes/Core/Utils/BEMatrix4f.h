//  BEMatrix4f.h
//  Core


#ifndef BEMatrix4f_h
#define BEMatrix4f_h

#include <string>
#import "BEVector3f.h"
#import "BEQuaternion.h"

struct BEMatrix4f {
    // stored as colomn first
    float data[16];
    BEMatrix4f() { memset(data, 0, 16*sizeof(float)); data[0]=data[5]=data[10]=data[15]=1.0; }
    BEMatrix4f(float* mat) { memcpy(data, mat, 16*sizeof(float)); }
    
    float& Get(int row, int col);
    float& operator[](int i);
    float operator[](int i) const;
    void transpose();
    BEMatrix4f& Invert_Full();
    void SetColumn(int col, const BEVector3f& v);
    void getDecompose(BEVector3f *pos, BEVector3f *scale, BEQuaternion* quat, BEVector3f* skew);
    void getDecompose(BEVector3f* pos, BEVector3f* scale, BEQuaternion* quat);
    void SetTRS(const BEVector3f& pos, const BEQuaternion& q, const BEVector3f& s);
    void SetTRSS(const BEVector3f& pos, const BEQuaternion& q, const BEVector3f& s, const BEVector3f& skew);
    BEMatrix4f& SetPerspective(float fovy, float aspect, float zNear, float zFar);

    
    static BEMatrix4f identity() { return BEMatrix4f(); }
};

// functions
void MatrixToQuaternion(BEMatrix4f& kRot, BEQuaternion& q);
void QuaternionToMatrix(const BEQuaternion& q, BEMatrix4f& m);
bool InvertMatrix4x4_Full(const BEMatrix4f* m, BEMatrix4f* out);
BEMatrix4f operator*(const BEMatrix4f& lhs, const BEMatrix4f& rhs);
inline float Deg2Rad(float deg);

float& BEMatrix4f::Get(int row, int col) {
    assert(row<4 && col<4);
    return data[row + 4*col];
}

float& BEMatrix4f::operator[](int i) {
    return this->data[i];
}

float BEMatrix4f::operator[](int i) const {
    return this->data[i];
}

void BEMatrix4f::transpose() {
    for (int i = 0; i < 4; ++ i)
        for (int j = 0; j < i; ++ j)
            std::swap(data[i*4+j], data[i+j*4]);
}

BEMatrix4f& BEMatrix4f::Invert_Full() {
    InvertMatrix4x4_Full(this, this);
    return *this;
}

void BEMatrix4f::SetColumn(int col, const BEVector3f& v) {
    data[4*col] = v.x;
    data[4*col+1] = v.y;
    data[4*col+2] = v.z;
}

void BEMatrix4f::getDecompose(BEVector3f *pos, BEVector3f *scale, BEQuaternion *quat, BEVector3f *skew) {
    if (pos)
    {
        pos->x = data[12];
        pos->y = data[13];
        pos->z = data[14];
    }
    BEVector3f vx(data[0], data[1], data[2]);
    BEVector3f vy(data[4], data[5], data[6]);
    BEVector3f vz(data[8], data[9], data[10]);

    bool flip = Dot(Cross(vx, vy), vz) < 0 ? true : false;
    if (flip)
    {
        vx *= -1;
    }

    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;

    float yx = 0.0f;
    float xz = 0.0f;
    float yz = 0.0f;

    if (skew || scale || quat)
    {
        y = Magnitude(vy);

        if (y > BEVector3f::epsilon())
        {
            vy = vy / y;
        }

        yx = Dot(vy, vx);
        vx -= yx * vy;

        x = Magnitude(vx);

        if (x > BEVector3f::epsilon())
        {
            vx = vx / x;
            yx = yx / x;
        }

        yz = Dot(vy, vz);
        vz -= yz * vy;

        xz = Dot(vx, vz);
        vz -= xz * vx;

        z = Magnitude(vz);

        if (z > BEVector3f::epsilon())
        {
            vz = vz / z;
            yz = yz / z;
            xz = xz / z;
        }
    }

    if (scale)
    {
        *scale = BEVector3f(x, y, z);
        if (flip)
        {
            (*scale).x *= -1;
        }
    }
    if (skew)
    {
        *skew = BEVector3f(yx, yz, xz);
    }

    if (quat)
    {
        BEMatrix4f rotateMat = BEMatrix4f::identity();
        rotateMat.SetColumn(0, vx);
        rotateMat.SetColumn(1, vy);
        rotateMat.SetColumn(2, vz);
        MatrixToQuaternion(rotateMat, *quat);
    }
}

void BEMatrix4f::getDecompose(BEVector3f* pos, BEVector3f* scale, BEQuaternion* quat) {
    BEMatrix4f Matrix_RS = *this;
    Matrix_RS[12] = 0;
    Matrix_RS[13] = 0;
    Matrix_RS[14] = 0;

    if (pos)
    {
        pos->x = data[12];
        pos->y = data[13];
        pos->z = data[14];
    }

    BEVector3f vx(data[0], data[1], data[2]);
    BEVector3f vy(data[4], data[5], data[6]);
    BEVector3f vz(data[8], data[9], data[10]);
    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;
    if (scale || quat)
    {
        x = Magnitude(vx);
        y = Magnitude(vy);
        z = Magnitude(vz);
    }

    if (scale)
    {
        *scale = BEVector3f(x, y, z);
    }

    if (quat)
    {
        float m[] = {x, 0, 0, 0, 0, y, 0, 0, 0, 0, z, 0, 0, 0, 0, 1};
        BEMatrix4f scaleMat4(m);

        BEMatrix4f rotateMat4;

        rotateMat4 = Matrix_RS * scaleMat4.Invert_Full();

        MatrixToQuaternion(rotateMat4, *quat);
    }
}

void BEMatrix4f::SetTRS(const BEVector3f& pos, const BEQuaternion& q, const BEVector3f& s) {
    QuaternionToMatrix(q, *this);
    
    data[0] *= s[0];
    data[1] *= s[0];
    data[2] *= s[0];

    data[4] *= s[1];
    data[5] *= s[1];
    data[6] *= s[1];

    data[8] *= s[2];
    data[9] *= s[2];
    data[10] *= s[2];

    data[12] = pos[0];
    data[13] = pos[1];
    data[14] = pos[2];
}

void BEMatrix4f::SetTRSS(const BEVector3f& pos, const BEQuaternion& q, const BEVector3f& s, const BEVector3f& skew)
{
    QuaternionToMatrix(q, *this);

    data[8] += data[0] * skew.z;
    data[9] += data[1] * skew.z;
    data[10] += data[2] * skew.z;

    data[8] += data[4] * skew.y;
    data[9] += data[5] * skew.y;
    data[10] += data[6] * skew.y;

    data[0] += data[4] * skew.x;
    data[1] += data[5] * skew.x;
    data[2] += data[6] * skew.x;

    data[0] *= s[0];
    data[1] *= s[0];
    data[2] *= s[0];

    data[4] *= s[1];
    data[5] *= s[1];
    data[6] *= s[1];

    data[8] *= s[2];
    data[9] *= s[2];
    data[10] *= s[2];

    data[12] = pos[0];
    data[13] = pos[1];
    data[14] = pos[2];
}

BEMatrix4f& BEMatrix4f::SetPerspective(float fovy, float aspect, float zNear, float zFar) {
    float cotangent, deltaZ;
    float radians = Deg2Rad(fovy / 2.0f);
    cotangent = cos(radians) / sin(radians);
    deltaZ = zNear - zFar;

    Get(0, 0) = cotangent / aspect;
    Get(0, 1) = 0.0F;
    Get(0, 2) = 0.0F;
    Get(0, 3) = 0.0F;
    Get(1, 0) = 0.0F;
    Get(1, 1) = cotangent;
    Get(1, 2) = 0.0F;
    Get(1, 3) = 0.0F;
    Get(2, 0) = 0.0F;
    Get(2, 1) = 0.0F;
    Get(2, 2) = (zFar + zNear) / deltaZ;
    Get(2, 3) = 2.0F * zNear * zFar / deltaZ;
    Get(3, 0) = 0.0F;
    Get(3, 1) = 0.0F;
    Get(3, 2) = -1.0F;
    Get(3, 3) = 0.0F;

    return *this;
}

#define MAT(m, r, c) (m->data)[(c)*4+(r)]

#define SWAP_ROWS(a, b)  \
    {                    \
        float* _tmp = a; \
        (a) = (b);       \
        (b) = _tmp;      \
    }

#define RETURN_ZERO                  \
    {                                \
        for (int i = 0; i < 16; i++) \
            out->data[i] = 0.0F;           \
        return false;                \
    }

bool InvertMatrix4x4_Full(const BEMatrix4f* m, BEMatrix4f* out) {
    float wtmp[4][8];
    float m0, m1, m2, m3, s;
    float *r0, *r1, *r2, *r3;

    r0 = wtmp[0];
    r1 = wtmp[1];
    r2 = wtmp[2];
    r3 = wtmp[3];

    r0[0] = MAT(m, 0, 0);
    r0[1] = MAT(m, 0, 1);
    r0[2] = MAT(m, 0, 2);
    r0[3] = MAT(m, 0, 3);
    r0[4] = 1.0;
    r0[5] = r0[6] = r0[7] = 0.0;

    r1[0] = MAT(m, 1, 0);
    r1[1] = MAT(m, 1, 1);
    r1[2] = MAT(m, 1, 2);
    r1[3] = MAT(m, 1, 3);
    r1[5] = 1.0;
    r1[4] = r1[6] = r1[7] = 0.0;

    r2[0] = MAT(m, 2, 0);
    r2[1] = MAT(m, 2, 1);
    r2[2] = MAT(m, 2, 2);
    r2[3] = MAT(m, 2, 3);
    r2[6] = 1.0;
    r2[4] = r2[5] = r2[7] = 0.0;

    r3[0] = MAT(m, 3, 0);
    r3[1] = MAT(m, 3, 1);
    r3[2] = MAT(m, 3, 2);
    r3[3] = MAT(m, 3, 3);
    r3[7] = 1.0;
    r3[4] = r3[5] = r3[6] = 0.0;

    /* choose pivot - or die */
    if (abs(r3[0]) > abs(r2[0]))
        SWAP_ROWS(r3, r2);
    if (abs(r2[0]) > abs(r1[0]))
        SWAP_ROWS(r2, r1);
    if (abs(r1[0]) > abs(r0[0]))
        SWAP_ROWS(r1, r0);
    if (0.0F == r0[0])
        RETURN_ZERO

    /* eliminate first variable     */
    m1 = r1[0] / r0[0];
    m2 = r2[0] / r0[0];
    m3 = r3[0] / r0[0];
    s = r0[1];
    r1[1] -= m1 * s;
    r2[1] -= m2 * s;
    r3[1] -= m3 * s;
    s = r0[2];
    r1[2] -= m1 * s;
    r2[2] -= m2 * s;
    r3[2] -= m3 * s;
    s = r0[3];
    r1[3] -= m1 * s;
    r2[3] -= m2 * s;
    r3[3] -= m3 * s;
    s = r0[4];
    if (s != 0.0F)
    {
        r1[4] -= m1 * s;
        r2[4] -= m2 * s;
        r3[4] -= m3 * s;
    }
    s = r0[5];
    if (s != 0.0F)
    {
        r1[5] -= m1 * s;
        r2[5] -= m2 * s;
        r3[5] -= m3 * s;
    }
    s = r0[6];
    if (s != 0.0F)
    {
        r1[6] -= m1 * s;
        r2[6] -= m2 * s;
        r3[6] -= m3 * s;
    }
    s = r0[7];
    if (s != 0.0F)
    {
        r1[7] -= m1 * s;
        r2[7] -= m2 * s;
        r3[7] -= m3 * s;
    }

    /* choose pivot - or die */
    if (abs(r3[1]) > abs(r2[1]))
        SWAP_ROWS(r3, r2);
    if (abs(r2[1]) > abs(r1[1]))
        SWAP_ROWS(r2, r1);
    if (0.0F == r1[1])
        RETURN_ZERO;

    /* eliminate second variable */
    m2 = r2[1] / r1[1];
    m3 = r3[1] / r1[1];
    r2[2] -= m2 * r1[2];
    r3[2] -= m3 * r1[2];
    r2[3] -= m2 * r1[3];
    r3[3] -= m3 * r1[3];
    s = r1[4];
    if (0.0F != s)
    {
        r2[4] -= m2 * s;
        r3[4] -= m3 * s;
    }
    s = r1[5];
    if (0.0F != s)
    {
        r2[5] -= m2 * s;
        r3[5] -= m3 * s;
    }
    s = r1[6];
    if (0.0F != s)
    {
        r2[6] -= m2 * s;
        r3[6] -= m3 * s;
    }
    s = r1[7];
    if (0.0F != s)
    {
        r2[7] -= m2 * s;
        r3[7] -= m3 * s;
    }

    /* choose pivot - or die */
    if (abs(r3[2]) > abs(r2[2]))
        SWAP_ROWS(r3, r2);
    if (0.0F == r2[2])
        RETURN_ZERO;

    /* eliminate third variable */
    m3 = r3[2] / r2[2];
    r3[3] -= m3 * r2[3];
    r3[4] -= m3 * r2[4];
    r3[5] -= m3 * r2[5];
    r3[6] -= m3 * r2[6];
    r3[7] -= m3 * r2[7];

    /* last check */
    if (0.0F == r3[3])
        RETURN_ZERO;

    s = 1.0F / r3[3]; /* now back substitute row 3 */
    r3[4] *= s;
    r3[5] *= s;
    r3[6] *= s;
    r3[7] *= s;

    m2 = r2[3]; /* now back substitute row 2 */
    s = 1.0F / r2[2];
    r2[4] = s * (r2[4] - r3[4] * m2);
    r2[5] = s * (r2[5] - r3[5] * m2);
    r2[6] = s * (r2[6] - r3[6] * m2);
    r2[7] = s * (r2[7] - r3[7] * m2);
    m1 = r1[3];
    r1[4] -= r3[4] * m1;
    r1[5] -= r3[5] * m1;
    r1[6] -= r3[6] * m1;
    r1[7] -= r3[7] * m1;
    m0 = r0[3];
    r0[4] -= r3[4] * m0;
    r0[5] -= r3[5] * m0;
    r0[6] -= r3[6] * m0;
    r0[7] -= r3[7] * m0;

    m1 = r1[2]; /* now back substitute row 1 */
    s = 1.0F / r1[1];
    r1[4] = s * (r1[4] - r2[4] * m1);
    r1[5] = s * (r1[5] - r2[5] * m1);
    r1[6] = s * (r1[6] - r2[6] * m1);
    r1[7] = s * (r1[7] - r2[7] * m1);
    m0 = r0[2];
    r0[4] -= r2[4] * m0;
    r0[5] -= r2[5] * m0;
    r0[6] -= r2[6] * m0;
    r0[7] -= r2[7] * m0;

    m0 = r0[1]; /* now back substitute row 0 */
    s = 1.0F / r0[0];
    r0[4] = s * (r0[4] - r1[4] * m0);
    r0[5] = s * (r0[5] - r1[5] * m0);
    r0[6] = s * (r0[6] - r1[6] * m0);
    r0[7] = s * (r0[7] - r1[7] * m0);

    MAT(out, 0, 0) = r0[4];
    MAT(out, 0, 1) = r0[5];
    MAT(out, 0, 2) = r0[6];
    MAT(out, 0, 3) = r0[7];
    MAT(out, 1, 0) = r1[4];
    MAT(out, 1, 1) = r1[5];
    MAT(out, 1, 2) = r1[6];
    MAT(out, 1, 3) = r1[7];
    MAT(out, 2, 0) = r2[4];
    MAT(out, 2, 1) = r2[5];
    MAT(out, 2, 2) = r2[6];
    MAT(out, 2, 3) = r2[7];
    MAT(out, 3, 0) = r3[4];
    MAT(out, 3, 1) = r3[5];
    MAT(out, 3, 2) = r3[6];
    MAT(out, 3, 3) = r3[7];

    return true;
}

void MatrixToQuaternion(BEMatrix4f& kRot, BEQuaternion& q) {
    float fTrace = kRot.Get(0, 0) + kRot.Get(1, 1) + kRot.Get(2, 2);
    float fRoot;
    
    if (fTrace > 0.0f) {
        // |w| > 1/2, may as well choose w > 1/2
        fRoot = sqrt(fTrace + 1.0f); // 2w
        q.w = 0.5f * fRoot;
        fRoot = 0.5f / fRoot; // 1/(4w)
        q.x = (kRot.Get(2, 1) - kRot.Get(1, 2)) * fRoot;
        q.y = (kRot.Get(0, 2) - kRot.Get(2, 0)) * fRoot;
        q.z = (kRot.Get(1, 0) - kRot.Get(0, 1)) * fRoot;
    }
    else
    {
        // |w| <= 1/2
        int s_iNext[3] = {1, 2, 0};
        int i = 0;
        if (kRot.Get(1, 1) > kRot.Get(0, 0))
            i = 1;
        if (kRot.Get(2, 2) > kRot.Get(i, i))
            i = 2;
        int j = s_iNext[i];
        int k = s_iNext[j];

        fRoot = sqrt(kRot.Get(i, i) - kRot.Get(j, j) - kRot.Get(k, k) + 1.0f);
        float* apkQuat[3] = {&q.x, &q.y, &q.z};
        assert(!(fRoot < BEVector3f::epsilon()));
        *apkQuat[i] = 0.5f * fRoot;
        fRoot = 0.5f / fRoot;
        q.w = (kRot.Get(k, j) - kRot.Get(j, k)) * fRoot;
        *apkQuat[j] = (kRot.Get(j, i) + kRot.Get(i, j)) * fRoot;
        *apkQuat[k] = (kRot.Get(k, i) + kRot.Get(i, k)) * fRoot;
    }
    Normalize(q);
}

void QuaternionToMatrix(const BEQuaternion& q, BEMatrix4f& m) {
    // Precalculate coordinate products
    float x = q.x * 2.0F;
    float y = q.y * 2.0F;
    float z = q.z * 2.0F;
    float xx = q.x * x;
    float yy = q.y * y;
    float zz = q.z * z;
    float xy = q.x * y;
    float xz = q.x * z;
    float yz = q.y * z;
    float wx = q.w * x;
    float wy = q.w * y;
    float wz = q.w * z;

    // Calculate 3x3 matrix from orthonormal basis
    m[0] = 1.0f - (yy + zz);
    m[1] = xy + wz;
    m[2] = xz - wy;
    m[3] = 0.0F;

    m[4] = xy - wz;
    m[5] = 1.0f - (xx + zz);
    m[6] = yz + wx;
    m[7] = 0.0F;

    m[8] = xz + wy;
    m[9] = yz - wx;
    m[10] = 1.0f - (xx + yy);
    m[11] = 0.0F;

    m[12] = 0.0F;
    m[13] = 0.0F;
    m[14] = 0.0F;
    m[15] = 1.0F;
}

BEMatrix4f operator*(const BEMatrix4f& lhs, const BEMatrix4f& rhs) {
    BEMatrix4f res;
    for (int i = 0; i < 4; i++)
    {
        res.data[i] = lhs.data[i] * rhs.data[0] + lhs.data[i + 4] * rhs.data[1] + lhs.data[i + 8] * rhs.data[2] + lhs.data[i + 12] * rhs.data[3];
        res.data[i + 4] = lhs.data[i] * rhs.data[4] + lhs.data[i + 4] * rhs.data[5] + lhs.data[i + 8] * rhs.data[6] + lhs.data[i + 12] * rhs.data[7];
        res.data[i + 8] = lhs.data[i] * rhs.data[8] + lhs.data[i + 4] * rhs.data[9] + lhs.data[i + 8] * rhs.data[10] + lhs.data[i + 12] * rhs.data[11];
        res.data[i + 12] = lhs.data[i] * rhs.data[12] + lhs.data[i + 4] * rhs.data[13] + lhs.data[i + 8] * rhs.data[14] + lhs.data[i + 12] * rhs.data[15];
    }
    return res;
}

inline float Deg2Rad(float deg)
{
    // TODO : should be deg * kDeg2Rad, but can't be changed,
    // because it changes the order of operations and that affects a replay in some RegressionTests
    return deg / 360.0F * 2.0F * 3.14159265358979323846264338327950288419716939937510F;
}

#endif /* BEMatrix4f_h */
