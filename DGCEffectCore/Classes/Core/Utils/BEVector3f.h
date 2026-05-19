//  BEVector3f.h
//  Core


#ifndef BEVector3f_h
#define BEVector3f_h

struct BEVector3f {
    float x, y, z;
    BEVector3f() { x=y=z=0.0; }
    BEVector3f(float a, float b, float c) { x=a;y=b;z=c; }
    BEVector3f(float* vec) { x=vec[0];y=vec[1];z=vec[2]; }
    
    static float epsilon();
    
    BEVector3f operator/(float s) { return BEVector3f(x/s, y/s, z/s); }
    BEVector3f operator*(float s) { return BEVector3f(x*s, y*s, z*s); }
    BEVector3f& operator*=(float s) { x*=s; y*=s; z*=s; return *this; }
    BEVector3f& operator-=(const BEVector3f& s) { x-=s.x; y-=s.y; z-=s.z; return *this; }
    BEVector3f& operator+=(const BEVector3f& s) { x+=s.x; y+=s.y; z+=s.z; return *this; }
    float operator[](int i) const{ return i == 0 ? x : (i == 1 ? y : z); }
};

inline float Dot(const BEVector3f& lhs, const BEVector3f& rhs)
{
    return lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z;
}

inline BEVector3f Cross(const BEVector3f& lhs, const BEVector3f& rhs)
{
    return BEVector3f(
        lhs.y * rhs.z - lhs.z * rhs.y,
        lhs.z * rhs.x - lhs.x * rhs.z,
        lhs.x * rhs.y - lhs.y * rhs.x);
}

inline float Magnitude(const BEVector3f& inV)
{
    return sqrt(Dot(inV, inV));
}

float BEVector3f::epsilon() {
    return 0.00001f;
}

BEVector3f operator*(float s, BEVector3f& vec) {
    return vec * s;
}


#endif /* BEVector3f_h */
