/**
 *
 * ToxBlinkenwall
 * (C)Zoff <zoff@zoff.cc> in 2017 - 2019
 *
 * https://github.com/zoff99/ToxBlinkenwall
 *
 */
/**
 * @file omx.h     Raspberry Pi VideoCoreIV OpenMAX interface
 *
 * Copyright (C) 2016 - 2017 Creytiv.com
 * Copyright (C) 2016 - 2017 Jonathan Sieber
 */

#include <semaphore.h>

#include <IL/OMX_Core.h>
#include <IL/OMX_Video.h>
#include <IL/OMX_Broadcom.h>

#include <pthread.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <time.h>


struct omx_state
{
    OMX_HANDLETYPE video_render;
    OMX_BUFFERHEADERTYPE **buffers;
    int num_buffers;
    int current_buffer;
};

int omx_init(struct omx_state *st);
void omx_deinit(struct omx_state *st);
int omx_get_display_input_buffer(struct omx_state *st,
                                 void **pbuf, uint32_t *plen);
int omx_display_flush_buffer(struct omx_state *st, uint32_t data_len);
int omx_change_video_out_rotation(struct omx_state *st, int angle);
int omx_display_enable(struct omx_state *st,
                       int width, int height, int stride);
void omx_display_disable(struct omx_state *st);

/*
typedef enum OMX_ERRORTYPE
00123 {
00124   OMX_ErrorNone = 0,
00125
00127   OMX_ErrorInsufficientResources = 0x80001000,
00128
00130   OMX_ErrorUndefined = 0x80001001,
00131
00133   OMX_ErrorInvalidComponentName = 0x80001002,
00134
00136   OMX_ErrorComponentNotFound = 0x80001003,
00137
00140   OMX_ErrorInvalidComponent = 0x80001004,
00141
00143   OMX_ErrorBadParameter = 0x80001005,
00144
00146   OMX_ErrorNotImplemented = 0x80001006,
00147
00149   OMX_ErrorUnderflow = 0x80001007,
00150
00152   OMX_ErrorOverflow = 0x80001008,
00153
00155   OMX_ErrorHardware = 0x80001009,
00156
00158   OMX_ErrorInvalidState = 0x8000100A,
00159
00161   OMX_ErrorStreamCorrupt = 0x8000100B,
00162
00164   OMX_ErrorPortsNotCompatible = 0x8000100C,
00165
00168   OMX_ErrorResourcesLost = 0x8000100D,
00169
00171   OMX_ErrorNoMore = 0x8000100E,
00172
00174   OMX_ErrorVersionMismatch = 0x8000100F,
00175
00177   OMX_ErrorNotReady = 0x80001010,
00178
00180   OMX_ErrorTimeout = 0x80001011,
00181
00183   OMX_ErrorSameState = 0x80001012,
00184
00187   OMX_ErrorResourcesPreempted = 0x80001013,
00188
00193   OMX_ErrorPortUnresponsiveDuringAllocation = 0x80001014,
00194
00199   OMX_ErrorPortUnresponsiveDuringDeallocation = 0x80001015,
00200
00205   OMX_ErrorPortUnresponsiveDuringStop = 0x80001016,
00206
00208   OMX_ErrorIncorrectStateTransition = 0x80001017,
00209
00210   Attempting a command that is not allowed during the present state.
00211   OMX_ErrorIncorrectStateOperation = 0x80001018,
00212
00214   OMX_ErrorUnsupportedSetting = 0x80001019,
00215
00217   OMX_ErrorUnsupportedIndex = 0x8000101A,
00218
00220   OMX_ErrorBadPortIndex = 0x8000101B,
00221
00223   OMX_ErrorPortUnpopulated = 0x8000101C,
00224
00226   OMX_ErrorComponentSuspended = 0x8000101D,
00227
00229   OMX_ErrorDynamicResourcesUnavailable = 0x8000101E,
00230
00233   OMX_ErrorMbErrorsInFrame = 0x8000101F,
00234
00236   OMX_ErrorFormatNotDetected = 0x80001020,
00237
00239   OMX_ErrorContentPipeOpenFailed = 0x80001021,
00240
00242   OMX_ErrorContentPipeCreationFailed = 0x80001022,
00243
00245   OMX_ErrorSeperateTablesUsed = 0x80001023,
00246
00248   OMX_ErrorTunnelingUnsupported = 0x80001024,
00249
00250   OMX_ErrorMax = 0x7FFFFFFF,
00251 } OMX_ERRORTYPE;

*/
