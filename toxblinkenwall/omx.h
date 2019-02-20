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

struct omx_state
{
    OMX_HANDLETYPE video_render;
    OMX_BUFFERHEADERTYPE **buffers;
    int num_buffers;
    int current_buffer;
};

int omx_init(struct omx_state *st);
void omx_deinit(struct omx_state *st);
int omx_display_input_buffer(struct omx_state *st,
                             void **pbuf, uint32_t *plen);
int omx_display_flush_buffer(struct omx_state *st, uint32_t data_len);
int omx_change_video_out_rotation(struct omx_state *st, int angle);
int omx_display_enable(struct omx_state *st,
                       int width, int height, int stride);
void omx_display_disable(struct omx_state *st);
