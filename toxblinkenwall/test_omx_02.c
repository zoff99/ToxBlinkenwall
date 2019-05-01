
#include "omx.h"

#include <time.h>
#include <assert.h>
#include <signal.h>
#include <stdarg.h>
#include <stdio.h>

/*
 * 
 *

gcc -O0 \
-DDEBUG_OMX_TEST_PROGRAM \
-DRASPBERRY_PI -DOMX_SKIP64BIT -DUSE_VCHIQ_ARM \
-I/opt/vc/include -I/opt/vc/interface/vmcs_host/linux -I/opt/vc/interface/vcos/pthreads \
-fPIC -export-dynamic -o test_omx_02 \
-lm \
test_omx_02.c omx.c \
-I/opt/vc/include -I/opt/vc/include/interface/vcos/pthreads \
-I/opt/vc/include/interface/vmcs_host/linux -lbrcmEGL -lbrcmGLESv2 \
-lbcm_host -L/opt/vc/lib \
-std=gnu99 \
-lrt \
-lpthread -lv4lconvert \
-lmmal -lmmal_core -lmmal_vc_client -lmmal_components -lmmal_util \
-L/opt/vc/lib -lbcm_host -lvcos -lopenmaxil -ldl

 * 
 */


void dbg(int level, const char *fmt, ...)
{
   va_list args;
   va_start(args, fmt);
   int r = vprintf(fmt, args);
   va_end(args);
}

void usleep_usec(uint64_t usec)
{
    struct timespec ts;
    ts.tv_sec = usec / 1000000;
    ts.tv_nsec = (usec % 1000000) * 1000;
    nanosleep(&ts, NULL);
}


// https://github.com/raspberrypi/userland/blob/master/host_applications/linux/apps/hello_pi/hello_encode/encode.c
#define WIDTH     1920
#define HEIGHT    1080
#define STRIDE    1920

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
    omx_display_disable(&omx);
    omx_deinit(&omx);
}

int main()
{
    void* pbuf;
    uint32_t buf_len, fill_len, i;
    int ret;
    int j;

    for (j = 0;j < 10;j++)
    {

        i = 20;

        ret = omx_init(&omx);
        assert(ret == 0);

        signal(SIGINT, deinit);

        ret = omx_display_enable(&omx, WIDTH, HEIGHT, STRIDE);
        assert(ret == 0);

        while (i--) {
            ret = omx_display_input_buffer(&omx, &pbuf, &buf_len);
            assert(ret == 0);

            generate_test_card(pbuf, &fill_len, i);
            assert(fill_len <= buf_len);

            ret = omx_display_flush_buffer(&omx, fill_len);
            assert(ret == 0);
        }

        deinit(0);

        dbg(9, "-- END %d --\n", j);

        // ======================
        usleep_usec(2 * 1000000);
        // ======================

    }

    // ======================
    usleep_usec(40 * 1000000);
    // ======================

}

