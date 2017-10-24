#include <string.h>
#include "Hash.h"
#include "SpookyV2.h"

inline SpookyHash* get(Hasher* storage) {
    return reinterpret_cast<SpookyHash*>(storage);
}

inline const SpookyHash* get(const Hasher* storage) {
    return reinterpret_cast<const SpookyHash*>(storage);
}

void Hasher_Init(Hasher* hasher) {
    static_assert(sizeof(SpookyHash) <= sizeof(Hasher), "Not enough storage");
    static_assert(alignof(SpookyHash) <= alignof(Hasher), "Not aligned enough");
    get(hasher)->Init(0, 0xc4133);
}

void Hasher_Mix_UInt8(Hasher* hasher, uint8_t value) {
    get(hasher)->Update(&value, sizeof(value));
}

void Hasher_Mix_UInt16(Hasher* hasher, uint16_t value) {
    get(hasher)->Update(&value, sizeof(value));
}

void Hasher_Mix_UInt32(Hasher* hasher, uint32_t value) {
    get(hasher)->Update(&value, sizeof(value));
}

void Hasher_Mix_UInt64(Hasher* hasher, uint64_t value) {
    get(hasher)->Update(&value, sizeof(value));
}

void Hasher_Mix_Int8(Hasher* hasher, int8_t value) {
    get(hasher)->Update(&value, sizeof(value));
}

void Hasher_Mix_Int16(Hasher* hasher, int16_t value) {
    get(hasher)->Update(&value, sizeof(value));
}

void Hasher_Mix_Int32(Hasher* hasher, int32_t value) {
    get(hasher)->Update(&value, sizeof(value));
}

void Hasher_Mix_Int64(Hasher* hasher, int64_t value) {
    get(hasher)->Update(&value, sizeof(value));
}

void Hasher_Mix_UInt64_2(Hasher* hasher, uint64_t hash1, uint64_t hash2) {
    uint64_t both[2] = { hash1, hash2 };
    get(hasher)->Update(both, sizeof(both));
}

void Hasher_Final(const Hasher* hasher, uint64_t* hash1, uint64_t* hash2) {
    get(hasher)->Final(hash1, hash2);
}
