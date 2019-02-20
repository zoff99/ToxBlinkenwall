#include "omx.h"

#include <time.h>
#include <assert.h>
#include <signal.h>

void dbg(int level, const char *fmt, ...)
{
}

void usleep_usec(uint64_t usec)
{
    struct timespec ts;
    ts.tv_sec = usec / 1000000;
    ts.tv_nsec = (usec % 1000000) * 1000;
    nanosleep(&ts, NULL);
}


// https://github.com/raspberrypi/userland/blob/master/host_applications/linux/apps/hello_pi/hello_encode/encode.c
#define WIDTH     640
#define HEIGHT    480
#define STRIDE    640

// generate an animated test card in YUV format
static int
generate_test_card(void *buf, uint32_t* filledLen, int frame)
{
   int i, j;
   char *y = buf;
   char *u = y + STRIDE * HEIGHT;
   char *v = u + (STRIDE >> 1) * (HEIGHT >> 1);

   for (j = 0; j < HEIGHT / 2; j++) {
      char *py = y + 2 * j * STRIDE;
      char *pu = u + j * (STRIDE>> 1);
      char *pv = v + j * (STRIDE>> 1);
      for (i = 0; i < WIDTH / 2; i++) {
         int z = (((i + frame) >> 4) ^ ((j + frame) >> 4)) & 15;
         py[0] = py[1] = py[STRIDE] = py[STRIDE + 1] = 0x80 + z * 0x8;
         if(i < 4 || i > (WIDTH / 2 - 20)) py[0] = py[1] = py[STRIDE] = py[STRIDE + 1] = 0x0f; // mark horizontal border
         if(j  < 4 || j > (HEIGHT / 2 - 40)) py[0] |= py[1] |= py[STRIDE] |= py[STRIDE + 1] |= 0xf0; // mark vertical border
         pu[0] = 0x00 + z * 0x10;
         pv[0] = 0x80 + z * 0x30;
         py += 2;
         pu++;
         pv++;

      }
   }
   *filledLen = (STRIDE* HEIGHT * 3) >> 1;
   return 1;
}

struct omx_state omx;

void deinit(int sig)
{
    omx_deinit(&omx);
}

int main()
{
    void* pbuf;
    uint32_t buf_len, fill_len, i;
    int ret;

    int angle = 0;
    i = 400;

    ret = omx_init(&omx);
    assert(ret == 0);

    signal(SIGINT, deinit);

    ret = omx_display_enable(&omx, WIDTH, HEIGHT, STRIDE);
    assert(ret == 0);

    while (angle < 360) {
        if (i-- == 0)
        {
             i = 400;
             angle += 90;
        }

	ret = omx_change_video_out_rotation(&omx, angle);
        assert(ret == 0);

        ret = omx_display_input_buffer(&omx, &pbuf, &buf_len);
        assert(ret == 0);

        generate_test_card(pbuf, &fill_len, i);
        assert(fill_len == buf_len);

        ret = omx_display_flush_buffer(&omx, fill_len);
        assert(ret == 0);
    }

    deinit(0);
}
