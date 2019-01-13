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
#ifndef BW_RING_BUFFER_H
#define BW_RING_BUFFER_H

#include <stdbool.h>
#include <stdint.h>

/* Ring buffer */
typedef struct BWRingBuffer BWRingBuffer;
bool bw_rb_full(const BWRingBuffer *b);
bool bw_rb_empty(const BWRingBuffer *b);
void *bw_rb_write(BWRingBuffer *b, void *p, uint32_t w, uint32_t h);
bool bw_rb_read(BWRingBuffer *b, void **p, uint32_t *w, uint32_t *h);
BWRingBuffer *bw_rb_new(int size);
void bw_rb_kill(BWRingBuffer *b);
uint16_t bw_rb_size(const BWRingBuffer *b);
uint16_t bw_rb_data(const BWRingBuffer *b, void **dest);

#endif /* BW_RING_BUFFER_H */

