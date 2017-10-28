#include <string.h>
#include <stdio.h>
#include <fcntl.h>
#include <linux/videodev2.h>

//
// gcc print_cam_formats.c   -o print_cam_formats -lv4l2
//

int main()
{
    int fd = v4l2_open("/dev/video0", O_RDWR);
    if (fd != -1)
    {
        struct v4l2_fmtdesc fmtdesc;
        memset(&fmtdesc,0,sizeof(fmtdesc));
        fmtdesc.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
        while (ioctl(fd,VIDIOC_ENUM_FMT,&fmtdesc) == 0)
        {
            printf("%d %s\n",(int)fmtdesc.pixelformat, fmtdesc.description);
            fmtdesc.index++;
        }
        v4l2_close(fd);
    }
}
