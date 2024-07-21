/*
 * Copyright © 2018 Zoff
 *
 * This file is part of Tox, the free peer to peer instant messenger.
 *
 * Tox is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Tox is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Tox.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef TOXUTIL_H
#define TOXUTIL_H

//!TOKSTYLE-

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define TOX_CAPABILITY_BASIC 0
#define TOX_CAPABILITY_CAPABILITIES ((uint64_t)1) << 0
#define TOX_CAPABILITY_MSGV2 ((uint64_t)1) << 1
#define TOX_CAPABILITY_TOXAV_H264 ((uint64_t)1) << 2

void tox_utils_callback_self_connection_status(Tox *tox, tox_self_connection_status_cb *callback);
void tox_utils_self_connection_status_cb(Tox *tox,
        TOX_CONNECTION connection_status, void *user_data);

void tox_utils_callback_friend_connection_status(Tox *tox,
        tox_friend_connection_status_cb *callback);
void tox_utils_friend_connection_status_cb(Tox *tox, uint32_t friendnumber,
        TOX_CONNECTION connection_status, void *user_data);

void tox_utils_callback_friend_lossless_packet(Tox *tox,
        tox_friend_lossless_packet_cb *callback);
void tox_utils_friend_lossless_packet_cb(Tox *tox, uint32_t friend_number,
        const uint8_t *data, size_t length, void *user_data);

void tox_utils_callback_file_recv_control(Tox *tox, tox_file_recv_control_cb *callback);
void tox_utils_file_recv_control_cb(Tox *tox, uint32_t friend_number, uint32_t file_number,
                                    TOX_FILE_CONTROL control, void *user_data);

void tox_utils_callback_file_chunk_request(Tox *tox, tox_file_chunk_request_cb *callback);
void tox_utils_file_chunk_request_cb(Tox *tox, uint32_t friend_number, uint32_t file_number,
                                     uint64_t position, size_t length, void *user_data);

void tox_utils_callback_file_recv(Tox *tox, tox_file_recv_cb *callback);
void tox_utils_file_recv_cb(Tox *tox, uint32_t friend_number, uint32_t file_number,
                            uint32_t kind, uint64_t file_size,
                            const uint8_t *filename, size_t filename_length, void *user_data);

void tox_utils_callback_file_recv_chunk(Tox *tox, tox_file_recv_chunk_cb *callback);
void tox_utils_file_recv_chunk_cb(Tox *tox, uint32_t friend_number, uint32_t file_number,
                                  uint64_t position, const uint8_t *data, size_t length,
                                  void *user_data);


// ---- Msg V2 API ----

// HINT: receive a message in new messageV2 format
//       (you still need to register the "old" callback "tox_friend_message_cb"
//       to receive old format messages)
// params: message       raw messageV2 data incl. header
//         length        length of raw messageV2 data incl. header
typedef void tox_util_friend_message_v2_cb(Tox *tox, uint32_t friend_number,
        const uint8_t *message, size_t length);

void tox_utils_callback_friend_message_v2(Tox *tox, tox_util_friend_message_v2_cb *callback);


// HINT: receive a sync message in new messageV2 format
// params: message       raw messageV2 data incl. header
//         length        length of raw messageV2 data incl. header
typedef void tox_util_friend_sync_message_v2_cb(Tox *tox, uint32_t friend_number,
        const uint8_t *message, size_t length);

void tox_utils_callback_friend_sync_message_v2(Tox *tox, tox_util_friend_sync_message_v2_cb *callback);


// HINT: receive message receipt (ACK)
// params: friend_number friend
//         ts_sec        unixtimestamp when message was received by the friend (in seconds since epoch)
//         msgid         buffer of the message hash, exactly TOX_PUBLIC_KEY_SIZE byte long
typedef void tox_utils_friend_read_receipt_message_v2_cb(Tox *tox, uint32_t friend_number,
        uint32_t ts_sec, const uint8_t *msgid);

void tox_utils_callback_friend_read_receipt_message_v2(Tox *tox,
        tox_utils_friend_read_receipt_message_v2_cb *callback);


// HINT: use only this API function to send messages (it will automatically send old format if needed)
// params: friend_number friend to send message to
//         type          type of message (only used for old style messages)
//         ts_sec        unixtimestamp when message was sent (in seconds since epoch)
//         message       buffer with message text
//         length        bytes in buffer of message text
//         raw_message_back buffer of TOX_MAX_FILETRANSFER_SIZE_MSGV2 size
//                       the raw message (incl. header) will be put there
//         raw_msg_len_back number of bytes the raw message actually uses in the buffer
//         msgid_back    buffer of the message hash, exactly TOX_PUBLIC_KEY_SIZE byte long
//         error         error code used for both old and new style messages
// return: int64_t       always -1 for new style messages (to indicate new style was used)
//         int64_t       return value of tox_friend_send_message() for old style messages
//                       (can't be negative)
int64_t tox_util_friend_send_message_v2(Tox *tox, uint32_t friend_number, TOX_MESSAGE_TYPE type,
                                        uint32_t ts_sec, const uint8_t *message, size_t length,
                                        uint8_t *raw_message_back, uint32_t *raw_msg_len_back,
                                        uint8_t *msgid_back,
                                        TOX_ERR_FRIEND_SEND_MESSAGE *error);

// resend a message
// params: friend_number friend to send message to
//         raw_message   buffer of the raw message (incl. header)
//         raw_msg_len   number of bytes length of raw message
// return: bool          true -> if message was sent OK
bool tox_util_friend_resend_message_v2(Tox *tox, uint32_t friend_number,
                                       const uint8_t *raw_message,
                                       const uint32_t raw_msg_len,
                                       TOX_ERR_FRIEND_SEND_MESSAGE *error);

// send a sync message
// params: friend_number friend to send message to
//         raw_message   buffer of the raw message (incl. header)
//         raw_msg_len   number of bytes length of raw message
// return: bool          true -> if message was sent OK
bool tox_util_friend_send_sync_message_v2(Tox *tox, uint32_t friend_number,
        const uint8_t *raw_message, const uint32_t raw_msg_len,
        TOX_ERR_FRIEND_SEND_MESSAGE *error);
// send message receipt
// params: friend_number friend to send message to
//         msgid         buffer of the message hash, exactly TOX_PUBLIC_KEY_SIZE byte long
//         ts_sec        unixtimestamp when message was received (in seconds since epoch)
bool tox_util_friend_send_msg_receipt_v2(Tox *tox, uint32_t friend_number, uint8_t *msgid, uint32_t ts_sec);


// ---- Msg V2 API ----


Tox *tox_utils_new(const struct Tox_Options *options, TOX_ERR_NEW *error);
void tox_utils_kill(Tox *tox);
bool tox_utils_friend_delete(Tox *tox, uint32_t friend_number, TOX_ERR_FRIEND_DELETE *error);


#ifdef __cplusplus
}
#endif

//!TOKSTYLE+

#endif
