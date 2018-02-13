#ifndef Hash_hpp
#define Hash_hpp

#include <stdint.h>

// Aligned struct containing enough room for the internal hasher.
typedef struct Hasher_t {
    // SpookyHash's state is 12 64-bit state variables, 24 64-bit
    // slots for partial buffers, one length, and one byte.
    // That's 304 bytes on 64-bit platforms and 296 bytes on
    // 32-bit platforms.
    uint64_t internal[38];
} Hasher;

#ifdef __cplusplus
extern "C" {
#endif

    // Initializes the given storage as a hasher.
    void Hasher_Init(Hasher* hasher);

    // The following functions mix various forms of data into the hasher.

    void Hasher_Mix_UInt8(Hasher* hasher, uint8_t value);
    void Hasher_Mix_UInt16(Hasher* hasher, uint16_t value);
    void Hasher_Mix_UInt32(Hasher* hasher, uint32_t value);
    void Hasher_Mix_UInt64(Hasher* hasher, uint64_t value);
    void Hasher_Mix_Int8(Hasher* hasher, int8_t value);
    void Hasher_Mix_Int16(Hasher* hasher, int16_t value);
    void Hasher_Mix_Int32(Hasher* hasher, int32_t value);
    void Hasher_Mix_Int64(Hasher* hasher, int64_t value);
    void Hasher_Mix_UInt64_2(Hasher* hasher, uint64_t hash1, uint64_t hash2);

    // Produces the final 128-bit hash value.  Does not modify the hasher's state.
    // hash1 and hash2 are the output variables.
    // SpookyHash does not support big-endian, but big-endian is dead (thank the heavens).
    void Hasher_Final(const Hasher* hasher, uint64_t* hash1, uint64_t* hash2);

#ifdef __cplusplus
}
#endif

#endif
