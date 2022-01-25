// This file was autogenerated by some hot garbage in the `uniffi` crate.
// Trust me, you don't want to mess with it!

#pragma once

#include <stdbool.h>
#include <stdint.h>

// The following structs are used to implement the lowest level
// of the FFI, and thus useful to multiple uniffied crates.
// We ensure they are declared exactly once, with a header guard, UNIFFI_SHARED_H.
#ifdef UNIFFI_SHARED_H
    // We also try to prevent mixing versions of shared uniffi header structs.
    // If you add anything to the #else block, you must increment the version suffix in UNIFFI_SHARED_HEADER_V4
    #ifndef UNIFFI_SHARED_HEADER_V4
        #error Combining helper code from multiple versions of uniffi is not supported
    #endif // ndef UNIFFI_SHARED_HEADER_V4
#else
#define UNIFFI_SHARED_H
#define UNIFFI_SHARED_HEADER_V4
// ⚠️ Attention: If you change this #else block (ending in `#endif // def UNIFFI_SHARED_H`) you *must* ⚠️
// ⚠️ increment the version suffix in all instances of UNIFFI_SHARED_HEADER_V4 in this file.           ⚠️

typedef struct RustBuffer
{
    int32_t capacity;
    int32_t len;
    uint8_t *_Nullable data;
} RustBuffer;

typedef int32_t (*ForeignCallback)(uint64_t, int32_t, RustBuffer, RustBuffer *_Nonnull);

typedef struct ForeignBytes
{
    int32_t len;
    const uint8_t *_Nullable data;
} ForeignBytes;

// Error definitions
typedef struct RustCallStatus {
    int8_t code;
    RustBuffer errorBuf;
} RustCallStatus;

// ⚠️ Attention: If you change this #else block (ending in `#endif // def UNIFFI_SHARED_H`) you *must* ⚠️
// ⚠️ increment the version suffix in all instances of UNIFFI_SHARED_HEADER_V4 in this file.           ⚠️
#endif // def UNIFFI_SHARED_H

void ffi_logins_6d43_LoginStore_object_free(
      void*_Nonnull ptr,
    RustCallStatus *_Nonnull out_status
    );
void*_Nonnull logins_6d43_LoginStore_new(
      RustBuffer path,
    RustCallStatus *_Nonnull out_status
    );
RustBuffer logins_6d43_LoginStore_add(
      void*_Nonnull ptr,RustBuffer login,RustBuffer encryption_key,
    RustCallStatus *_Nonnull out_status
    );
RustBuffer logins_6d43_LoginStore_update(
      void*_Nonnull ptr,RustBuffer id,RustBuffer login,RustBuffer encryption_key,
    RustCallStatus *_Nonnull out_status
    );
RustBuffer logins_6d43_LoginStore_add_or_update(
      void*_Nonnull ptr,RustBuffer login,RustBuffer encryption_key,
    RustCallStatus *_Nonnull out_status
    );
int8_t logins_6d43_LoginStore_delete(
      void*_Nonnull ptr,RustBuffer id,
    RustCallStatus *_Nonnull out_status
    );
void logins_6d43_LoginStore_wipe(
      void*_Nonnull ptr,
    RustCallStatus *_Nonnull out_status
    );
void logins_6d43_LoginStore_wipe_local(
      void*_Nonnull ptr,
    RustCallStatus *_Nonnull out_status
    );
void logins_6d43_LoginStore_reset(
      void*_Nonnull ptr,
    RustCallStatus *_Nonnull out_status
    );
void logins_6d43_LoginStore_touch(
      void*_Nonnull ptr,RustBuffer id,
    RustCallStatus *_Nonnull out_status
    );
RustBuffer logins_6d43_LoginStore_list(
      void*_Nonnull ptr,
    RustCallStatus *_Nonnull out_status
    );
RustBuffer logins_6d43_LoginStore_get_by_base_domain(
      void*_Nonnull ptr,RustBuffer base_domain,
    RustCallStatus *_Nonnull out_status
    );
RustBuffer logins_6d43_LoginStore_find_login_to_update(
      void*_Nonnull ptr,RustBuffer look,RustBuffer encryption_key,
    RustCallStatus *_Nonnull out_status
    );
RustBuffer logins_6d43_LoginStore_get(
      void*_Nonnull ptr,RustBuffer id,
    RustCallStatus *_Nonnull out_status
    );
RustBuffer logins_6d43_LoginStore_import_multiple(
      void*_Nonnull ptr,RustBuffer login,RustBuffer encryption_key,
    RustCallStatus *_Nonnull out_status
    );
void logins_6d43_LoginStore_register_with_sync_manager(
      void*_Nonnull ptr,
    RustCallStatus *_Nonnull out_status
    );
RustBuffer logins_6d43_LoginStore_sync(
      void*_Nonnull ptr,RustBuffer key_id,RustBuffer access_token,RustBuffer sync_key,RustBuffer tokenserver_url,RustBuffer local_encryption_key,
    RustCallStatus *_Nonnull out_status
    );
RustBuffer logins_6d43_create_key(
      
    RustCallStatus *_Nonnull out_status
    );
RustBuffer logins_6d43_decrypt_login(
      RustBuffer login,RustBuffer encryption_key,
    RustCallStatus *_Nonnull out_status
    );
RustBuffer logins_6d43_encrypt_login(
      RustBuffer login,RustBuffer encryption_key,
    RustCallStatus *_Nonnull out_status
    );
RustBuffer logins_6d43_decrypt_fields(
      RustBuffer sec_fields,RustBuffer encryption_key,
    RustCallStatus *_Nonnull out_status
    );
RustBuffer logins_6d43_encrypt_fields(
      RustBuffer sec_fields,RustBuffer encryption_key,
    RustCallStatus *_Nonnull out_status
    );
RustBuffer logins_6d43_create_canary(
      RustBuffer text,RustBuffer encryption_key,
    RustCallStatus *_Nonnull out_status
    );
int8_t logins_6d43_check_canary(
      RustBuffer canary,RustBuffer text,RustBuffer encryption_key,
    RustCallStatus *_Nonnull out_status
    );
RustBuffer logins_6d43_migrate_logins(
      RustBuffer path,RustBuffer new_encryption_key,RustBuffer sqlcipher_path,RustBuffer sqlcipher_key,RustBuffer salt,
    RustCallStatus *_Nonnull out_status
    );
RustBuffer ffi_logins_6d43_rustbuffer_alloc(
      int32_t size,
    RustCallStatus *_Nonnull out_status
    );
RustBuffer ffi_logins_6d43_rustbuffer_from_bytes(
      ForeignBytes bytes,
    RustCallStatus *_Nonnull out_status
    );
void ffi_logins_6d43_rustbuffer_free(
      RustBuffer buf,
    RustCallStatus *_Nonnull out_status
    );
RustBuffer ffi_logins_6d43_rustbuffer_reserve(
      RustBuffer buf,int32_t additional,
    RustCallStatus *_Nonnull out_status
    );
