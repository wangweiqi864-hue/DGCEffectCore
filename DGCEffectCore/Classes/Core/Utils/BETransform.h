//  BETransform.h
//  Core


#ifndef BETransform_h
#define BETransform_h

#import <Foundation/Foundation.h>
#import "BEMatrix4f.h"

const unsigned char TRANSFORM_DIRTY_LOCAL_MATRIX = 1 << 0;
const unsigned char TRANSFORM_DIRTY_WORLD_MATRIX = 1 << 1;
const unsigned char TRANSFORM_DIRTY_ALL = (TRANSFORM_DIRTY_LOCAL_MATRIX | TRANSFORM_DIRTY_WORLD_MATRIX);
const unsigned char TRANSFORM_USE_LOCAL_MATRIX = 1 << 2;

struct BETransform {
    BEVector3f m_localPosition;
    BEVector3f m_localScale;
    BEQuaternion m_localOrientation;
    BEMatrix4f m_localMatrix;
    BEMatrix4f m_worldMatrix;
    std::string name;

    unsigned char m_dirtyFlag;
    BETransform* m_parent;
    
    BETransform() {
        m_localPosition = m_localScale = BEVector3f();
        m_localOrientation = BEQuaternion();
        m_localMatrix = m_worldMatrix = BEMatrix4f::identity();
        m_dirtyFlag = TRANSFORM_DIRTY_ALL;
        m_parent = nullptr;
    }
    
    BETransform(const BEVector3f& localPos, const BEVector3f& localScale, const BEQuaternion& localRotation) {
        m_localPosition = localPos;
        m_localScale = localScale;
        m_localOrientation = localRotation;
        m_localMatrix = BEMatrix4f::identity();
        m_worldMatrix = BEMatrix4f::identity();
        m_dirtyFlag = TRANSFORM_DIRTY_ALL;
        m_parent = nullptr;
    }

    void setName(std::string name) { this->name = name; }
    void setParent(BETransform* parent) { this->m_parent = parent; }
    
    BEMatrix4f getLocalMatrix();
    BEMatrix4f getWorldMatrix();
    BEVector3f getLocalPosition();
    BEVector3f getWorldPosition();
    void setLocalPosition(const BEVector3f& position);
    void setWorldPosition(const BEVector3f& newPosition);
    BEQuaternion getWorldOrientation();
    BEQuaternion getLocalOrientation();
    void setWorldOrientation(const BEQuaternion& worldOrientation);
    void setLocalOrientation(const BEQuaternion& orientation);
};


BEMatrix4f BETransform::getLocalMatrix() {
    if (m_dirtyFlag & TRANSFORM_DIRTY_LOCAL_MATRIX)
    {
        m_localMatrix.SetTRS(m_localPosition, m_localOrientation, m_localScale);
        m_dirtyFlag &= ~TRANSFORM_DIRTY_LOCAL_MATRIX;
        m_dirtyFlag |= TRANSFORM_DIRTY_WORLD_MATRIX;
    }
    return m_localMatrix;
}

BEMatrix4f BETransform::getWorldMatrix() {
    if (m_dirtyFlag & TRANSFORM_DIRTY_WORLD_MATRIX)
    {
        m_worldMatrix = m_parent == nullptr ? this->getLocalMatrix() : m_parent->getWorldMatrix() * this->getLocalMatrix();
//        m_dirtyFlag &= ~TRANSFORM_DIRTY_WORLD_MATRIX;
    }
    return m_worldMatrix;
}

BEVector3f BETransform::getLocalPosition() {
    if (m_dirtyFlag & TRANSFORM_USE_LOCAL_MATRIX)
    {
        m_localMatrix.getDecompose(&m_localPosition, &m_localScale, &m_localOrientation);
        m_dirtyFlag &= ~TRANSFORM_USE_LOCAL_MATRIX;
    }
    return m_localPosition;
}

BEVector3f BETransform::getWorldPosition() {
    if (m_parent)
    {
        BEMatrix4f worldMat = this->getWorldMatrix();
        BEVector3f position;
        worldMat.getDecompose(&position, nullptr, (BEQuaternion*)nullptr, nullptr);
        return position;
    }
    return getLocalPosition();
}

void BETransform::setLocalPosition(const BEVector3f& pos) {
    if (m_dirtyFlag & TRANSFORM_USE_LOCAL_MATRIX)
    {
        m_localMatrix.getDecompose(nullptr, &m_localScale, &m_localOrientation);
        m_dirtyFlag &= ~TRANSFORM_USE_LOCAL_MATRIX;
    }
    m_localPosition = pos;
    m_dirtyFlag |= TRANSFORM_DIRTY_LOCAL_MATRIX;
    m_dirtyFlag |= TRANSFORM_DIRTY_WORLD_MATRIX;
}

void BETransform::setWorldPosition(const BEVector3f& worldPos) {
    if (m_parent)
    {
        BEVector3f skew, scale, position;
        BEQuaternion quat;

        BEMatrix4f localMatrix = getWorldMatrix();
        localMatrix.getDecompose(&position, &scale, &quat, &skew);

        localMatrix.SetTRSS(worldPos, quat, scale, skew);

        BEMatrix4f parentWorldInv = m_parent->getWorldMatrix();
        parentWorldInv.Invert_Full();
        localMatrix = parentWorldInv * localMatrix;

        localMatrix.getDecompose(&position, nullptr, nullptr, nullptr);
        setLocalPosition(position);
    }
    else
    {
        setLocalPosition(worldPos);
    }
}

BEQuaternion BETransform::getWorldOrientation() {
    if (m_parent)
    {
        BEMatrix4f worldMat = this->getWorldMatrix();
        BEQuaternion orientation;
        worldMat.getDecompose(nullptr, nullptr, &orientation, nullptr);
        return orientation;
    }
    return getLocalOrientation();
}

BEQuaternion BETransform::getLocalOrientation() {
    if (m_dirtyFlag & TRANSFORM_USE_LOCAL_MATRIX)
    {
        m_localMatrix.getDecompose(&m_localPosition, &m_localScale, &m_localOrientation);
        m_dirtyFlag &= ~TRANSFORM_USE_LOCAL_MATRIX;
    }
    return m_localOrientation;
}

void BETransform::setWorldOrientation(const BEQuaternion& worldOrientation) {
    if (m_parent)
    {
        BEVector3f pos, scale, skew;
        BEQuaternion quat;

        BEMatrix4f localMatrix = getWorldMatrix();
        localMatrix.getDecompose(&pos, &scale, nullptr, &skew);
        localMatrix.SetTRSS(pos, worldOrientation, scale, skew);

        BEMatrix4f parentWorldInv = m_parent->getWorldMatrix();
        parentWorldInv.Invert_Full();
        localMatrix = parentWorldInv * localMatrix;

        localMatrix.getDecompose(nullptr, nullptr, &quat, nullptr);
        setLocalOrientation(quat);
    }
    else
    {
        setLocalOrientation(worldOrientation);
    }
}

void BETransform::setLocalOrientation(const BEQuaternion& orientation) {
    if (m_dirtyFlag & TRANSFORM_USE_LOCAL_MATRIX)
    {
        m_localMatrix.getDecompose(&m_localPosition, &m_localScale, (BEQuaternion*)nullptr);
        m_dirtyFlag &= ~TRANSFORM_USE_LOCAL_MATRIX;
    }
    m_localOrientation = orientation;
    m_dirtyFlag |= TRANSFORM_DIRTY_LOCAL_MATRIX;
    m_dirtyFlag |= TRANSFORM_DIRTY_WORLD_MATRIX;
}


#endif /* BETransform_h */
