/**
 *
 * ToxBlinkenwall
 * (C)Zoff <zoff@zoff.cc> in 2017 - 2019
 *
 * https://github.com/zoff99/ToxBlinkenwall
 *
 */
/*
 * Copyright © 2016-2017 The TokTok team.
 * Copyright © 2013 Tox project.
 * Copyright © 2013 plutooo
 *
 * This file is part of Tox, the free peer to peer instant messenger.
 * This file is donated to the Tox Project.
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
#include "rb.h"

#include <stdlib.h>

struct BWRingBuffer
{
    uint16_t  size; /* Max size */
    uint16_t  start;
    uint16_t  end;
    void    **data;
    uint32_t *w;
    uint32_t *h;
};

bool bw_rb_full(const BWRingBuffer *b)
{
    return (b->end + 1) % b->size == b->start;
}

bool bw_rb_empty(const BWRingBuffer *b)
{
    return b->end == b->start;
}

/*
 * returns: NULL on success
            start address of element to delete on ringbuffer full, new element ist still written into buffer
 */
void *bw_rb_write(BWRingBuffer *b, void *p, uint32_t w, uint32_t h)
{
    void *rc = NULL;

    if ((b->end + 1) % b->size == b->start)   /* full */
    {
        rc = b->data[b->start];
    }

    b->data[b->end] = p;
    b->w[b->end] = w;
    b->h[b->end] = h;
    b->end = (b->end + 1) % b->size;

    if (b->end == b->start)
    {
        b->start = (b->start + 1) % b->size;
    }

    return rc;
}

bool bw_rb_read(BWRingBuffer *b, void **p, uint32_t *w, uint32_t *h)
{
    if (b->end == b->start)   /* Empty */
    {
        *p = NULL;
        return false;
    }

    *p = b->data[b->start];
    *w = b->w[b->start];
    *h = b->h[b->start];
    b->start = (b->start + 1) % b->size;
    return true;
}

BWRingBuffer *bw_rb_new(int size)
{
    BWRingBuffer *buf = (BWRingBuffer *)calloc(sizeof(BWRingBuffer), 1);

    if (!buf)
    {
        return NULL;
    }

    buf->size = size + 1; /* include empty elem */

    if (!(buf->data = (void **)calloc(buf->size, sizeof(void *))))
    {
        free(buf);
        return NULL;
    }

    if (!(buf->w = (uint32_t *)calloc(buf->size, sizeof(uint32_t))))
    {
        // TODO: ???
    }

    if (!(buf->h = (uint32_t *)calloc(buf->size, sizeof(uint32_t))))
    {
        // TODO: ???
    }

    return buf;
}

void bw_rb_kill(BWRingBuffer *b)
{
    if (b)
    {
        free(b->data);
        free(b->w);
        free(b->h);
        free(b);
    }
}

uint16_t bw_rb_size(const BWRingBuffer *b)
{
    if (bw_rb_empty(b))
    {
        return 0;
    }

    return
        b->end > b->start ?
        b->end - b->start :
        (b->size - b->start) + b->end;
}

uint16_t bw_rb_data(const BWRingBuffer *b, void **dest)
{
    uint16_t i = 0;

    for (; i < bw_rb_size(b); i++)
    {
        dest[i] = b->data[(b->start + i) % b->size];
    }

    return i;
}



