//  BEQuaternion.h
//  Core


#ifndef BEQuaternion_h
#define BEQuaternion_h

struct BEQuaternion {
    float w, x, y, z;
    BEQuaternion() { w=1.0;x=y=z=0.0; }
    BEQuaternion(float* quat) { w=quat[0];x=quat[1];y=quat[2];z=quat[3]; }
    BEQuaternion(float inX, float inY, float inZ, float inW) {
        x=inX;y=inY;z=inZ;w=inW;
    }
    
    float SqrMagnitude() { return (w*w + x*x + y*y + z*z);}
    float Magnitude() { return sqrt(SqrMagnitude()); }
};

BEQuaternion operator/(const BEQuaternion& q, const float& s) {
    BEQuaternion ret;
    ret.w = q.w / s;
    ret.x = q.x / s;
    ret.y = q.y / s;
    ret.z = q.z / s;
    return ret;
}

BEQuaternion operator*(const BEQuaternion& lhs, const BEQuaternion& rhs) {
    return BEQuaternion(
        lhs.w * rhs.x + lhs.x * rhs.w + lhs.y * rhs.z - lhs.z * rhs.y,
        lhs.w * rhs.y + lhs.y * rhs.w + lhs.z * rhs.x - lhs.x * rhs.z,
        lhs.w * rhs.z + lhs.z * rhs.w + lhs.x * rhs.y - lhs.y * rhs.x,
        lhs.w * rhs.w - lhs.x * rhs.x - lhs.y * rhs.y - lhs.z * rhs.z);
}

void Normalize(BEQuaternion& qua) {
    float mag = qua.Magnitude();
    assert(fabs(mag) > 0.00001f);
    qua = qua / mag;
}

bool valid_quat(const BEQuaternion& q) {
    float value = q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w;
    return fabs(value-1.0) < 0.2 ? true : false;
}

#endif /* BEQuaternion_h */
