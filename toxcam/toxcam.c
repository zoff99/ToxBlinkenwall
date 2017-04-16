/*
 * 
 * Zoff <zoff@zoff.cc>
 * in 2016
 *
 * dirty hack (echobot and toxic were used as blueprint)
 *
 *
 * compile on linux (dynamic):
 *  gcc -O2 -fPIC -Wall -Wextra -Wpedantic -o toxdoorspy toxdoorspy.c -std=gnu99 -lsodium -I/usr/local/include/ -ltoxcore -ltoxav -lpthread -lvpx -lv4lconvert
 * compile for debugging (dynamic):
 *  gcc -O0 -g -fPIC -Wall -Wextra -Wpedantic -o toxdoorspy toxdoorspy.c -std=gnu99 -lsodium -I/usr/local/include/ -ltoxcore -ltoxav -lpthread -lvpx -lv4lconvert
 *
 * compile on linux (static):
 *  gcc -O2 -Wall -Wextra -Wpedantic -o toxdoorspy_static toxdoorspy.c -static -std=gnu99 -L/usr/local/lib -I/usr/local/include/ \
    -lsodium -ltoxcore -ltoxav -ltoxgroup -ltoxmessenger -ltoxfriends -ltoxnetcrypto \
    -ltoxdht -ltoxnetwork -ltoxcrypto -lsodium -lpthread -static-libgcc -static-libstdc++ \
    -lopus -lvpx -lm -lpthread -lv4lconvert
 *


** motion -->
ffmpeg_open vbr/crf for codec: 7530
ffmpeg_open Selected Output FPS 5
ffmpeg_avcodec_log: Using AVStream.codeco pass codec parameters to muxers is deprecated, use AVStream.codecpar instead
** motion -->

 *
 *
 */


#include <ctype.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <time.h>
#include <dirent.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <getopt.h>
#include <fcntl.h>
#include <assert.h>
#include <errno.h>
#include <pthread.h>
#include <signal.h>

#include <sodium/utils.h>
#include <tox/tox.h>
#include <tox/toxav.h>

#include <linux/videodev2.h>
#include <vpx/vpx_image.h>
#include <sys/mman.h>

#undef NO_V4LCONVERT

#ifndef NO_V4LCONVERT
#include <libv4lconvert.h>
#endif

#ifndef NO_V4LCONVERT
static struct v4lconvert_data *v4lconvert_data;
#endif

#include "miniz.c"

// ----------- version -----------
// ----------- version -----------
#define VERSION_MAJOR 0
#define VERSION_MINOR 99
#define VERSION_PATCH 7
static const char global_version_string[] = "0.99.7";
// ----------- version -----------
// ----------- version -----------

typedef struct DHT_node {
    const char *ip;
    uint16_t port;
    const char key_hex[TOX_PUBLIC_KEY_SIZE*2 + 1];
    unsigned char key_bin[TOX_PUBLIC_KEY_SIZE];
} DHT_node;



#define MAX_AVATAR_FILE_SIZE 65536
#define TOXIC_MAX_NAME_LENGTH 32   /* Must be <= TOX_MAX_NAME_LENGTH */
#define TIME_STR_SIZE 32
#define MAX_STR_SIZE 200

#define CURRENT_LOG_LEVEL 9 // 0 -> error, 1 -> warn, 2 -> info, 9 -> debug

#define KiB 1024
#define MiB 1048576       /* 1024^2 */
#define GiB 1073741824    /* 1024^3 */

#define seconds_since_last_mod 1 // how long to wait before we process image files in seconds
#define MAX_FILES 6 // how many filetransfers to/from 1 friend at the same time?
#define MAX_RESEND_FILE_BEFORE_ASK 6
#define AUTO_RESEND_SECONDS 60*5 // resend for this much seconds before asking again [5 min]
#define VIDEO_BUFFER_COUNT 4
#define DEFAULT_GLOBAL_VID_BITRATE 100 // kb/sec
#define DEFAULT_FPS_SLEEP_MS 160 // default video fps (sleep in msecs. !!)

#define CLEAR(x) memset(&(x), 0, sizeof(x))
#define c_sleep(x) usleep(1000*x)

typedef enum FILE_TRANSFER_STATE {
    FILE_TRANSFER_INACTIVE, // == 0 , this is important
    FILE_TRANSFER_PAUSED,
    FILE_TRANSFER_PENDING,
    FILE_TRANSFER_STARTED,
} FILE_TRANSFER_STATE;

typedef enum FILE_TRANSFER_DIRECTION {
    FILE_TRANSFER_SEND,
    FILE_TRANSFER_RECV
} FILE_TRANSFER_DIRECTION;

struct FileTransfer {
    FILE *file;
    FILE_TRANSFER_STATE state;
    FILE_TRANSFER_DIRECTION direction;
    uint8_t file_type;
    char file_name[TOX_MAX_FILENAME_LENGTH + 1];
    char file_path[PATH_MAX + 1];    /* Not used by senders */
    double   bps;
    uint32_t filenum;
    uint32_t friendnum;
    size_t   index;
    uint64_t file_size;
    uint64_t position;
    time_t   last_keep_alive;  /* The last time we sent or received data */
    uint32_t line_id;
    uint8_t  file_id[TOX_FILE_ID_LENGTH];
};


struct LastOnline {
    uint64_t last_on;
    struct tm tm;
    char hour_min_str[TIME_STR_SIZE];    /* holds 24-hour time string e.g. "15:43:24" */
};

struct GroupChatInvite {
    char *key;
    uint16_t length;
    uint8_t type;
    bool pending;
};

typedef struct {
    char name[TOXIC_MAX_NAME_LENGTH + 1];
    int namelength;
    char statusmsg[TOX_MAX_STATUS_MESSAGE_LENGTH + 1];
    size_t statusmsg_len;
    char pub_key[TOX_PUBLIC_KEY_SIZE];
    char pubkey_string[(TOX_ADDRESS_SIZE * 2 + 1)];
    char worksubdir[MAX_STR_SIZE];
    uint32_t num;
    bool active;
    TOX_CONNECTION connection_status;
    bool is_typing;
    uint8_t status;
    struct LastOnline last_online;
    int have_resumed_fts; // wait with new FTs until all old FTs have been started (to resume) including avatars!
    struct FileTransfer file_receiver[MAX_FILES];
    struct FileTransfer file_sender[MAX_FILES];
	char last_answer[100];
	int waiting_for_answer; // 0 -> no, 1 -> waiting for answer, 2 -> got answer
	time_t auto_resend_start_time;
	mz_zip_archive zip_archive;
} ToxicFriend;

typedef struct {
    char name[TOXIC_MAX_NAME_LENGTH + 1];
    int namelength;
    char pub_key[TOX_PUBLIC_KEY_SIZE];
    uint32_t num;
    bool active;
    uint64_t last_on;
} BlockedFriend;

typedef struct {
    int num_selected;
    size_t num_friends;
    size_t num_online;
    size_t max_idx;    /* 1 + the index of the last friend in list */
    uint32_t *index;
    ToxicFriend *list;
} FriendsList;


static struct Avatar {
    char name[TOX_MAX_FILENAME_LENGTH + 1];
    size_t name_len;
    char path[PATH_MAX + 1];
    size_t path_len;
    off_t size;
} Avatar;

typedef struct {
    bool incoming;
    uint32_t state;
	uint32_t audio_bit_rate;
	uint32_t video_bit_rate;
    pthread_mutex_t arb_mutex[1];
} CallControl;


struct buffer {
	void * start;
	size_t length;
};

typedef struct DOORSPY_AV_VIDEO_FRAME {
    uint16_t w, h;
    uint8_t *y, *u, *v;
} doorspy_av_video_frame;



void on_avatar_chunk_request(Tox *m, struct FileTransfer *ft, uint64_t position, size_t length);
int avatar_send(Tox *m, uint32_t friendnum);
struct FileTransfer *new_file_transfer(uint32_t friendnum, uint32_t filenum, FILE_TRANSFER_DIRECTION direction, uint8_t type);
void kill_all_file_transfers_friend(Tox *m, uint32_t friendnum);
int has_reached_max_file_transfer_for_friend(uint32_t num);
static int find_friend_in_friendlist(uint32_t friendnum);
int is_friend_online(Tox *tox, uint32_t num);
void av_local_disconnect(ToxAV *av, uint32_t num);
void run_cmd_return_output(const char *command, char* output, int lastline);
void save_resumable_fts(Tox *m, uint32_t friendnum);
void resume_resumable_fts(Tox *m, uint32_t friendnum);



const char *savedata_filename = "savedata.tox";
const char *savedata_tmp_filename = "savedata.tox.tmp";
const char *log_filename = "toxdoorspy.log";
const char *my_avatar_filename = "avatar.png";
const char *motion_pics_dir = "./m/";
const char *motion_pics_work_dir = "./work/";
const char *motion_capture_file_extension = ".jpg";
const char *motion_capture_file_extension_mov = ".avi";
const char *file_extension_archive = ".zip";

char *v4l2_device; // video device filename

const char *shell_cmd__single_shot = "./scripts/single_shot.sh 2> /dev/null";
const char *shell_cmd__get_cpu_temp = "./scripts/get_cpu_temp.sh 2> /dev/null";
const char *shell_cmd__get_gpu_temp = "./scripts/get_gpu_temp.sh 2> /dev/null";
const char *shell_cmd__get_my_number_of_open_files = "cat /proc/sys/fs/file-nr 2> /dev/null";
int global_want_restart = 0;
const char *global_timestamp_format = "%H:%M:%S";
const char *global_long_timestamp_format = "%Y-%m-%d %H:%M:%S";
uint64_t global_start_time;
int global_cam_device_fd = 0;
uint32_t n_buffers;
struct buffer *buffers = NULL;
uint16_t video_width = 0;
uint16_t video_height = 0;
struct v4l2_format format;
struct v4l2_format dest_format;
doorspy_av_video_frame av_video_frame;
vpx_image_t input;
int global_video_active = 0;
uint32_t global_audio_bit_rate = 0;
uint32_t global_video_bit_rate = DEFAULT_GLOBAL_VID_BITRATE;
ToxAV *mytox_av = NULL;
int tox_loop_running = 1;

// -- hardcoded --
// -- hardcoded --
// -- hardcoded --
uint32_t friend_to_send_video_to = 0;
// -- hardcoded --
// -- hardcoded --
// -- hardcoded --

int video_call_enabled = 1;

TOX_CONNECTION my_connection_status = TOX_CONNECTION_NONE;
FILE *logfile = NULL;
FriendsList Friends;

void dbg(int level, const char *fmt, ...)
{
	char *level_and_format = NULL;
	char *fmt_copy = NULL;

	if (fmt == NULL)
	{
		return;
	}

	if (strlen(fmt) < 1)
	{
		return;
	}

	if (!logfile)
	{
		return;
	}

	if ((level < 0) || (level > 9))
	{
		level = 0;
	}

	level_and_format = malloc(strlen(fmt) + 3);

	if (!level_and_format)
	{
		// fprintf(stderr, "free:000a\n");
		return;
	}

	fmt_copy = level_and_format + 2;
	strcpy(fmt_copy, fmt);
	level_and_format[1] = ':';
	if (level == 0)
	{
		level_and_format[0] = 'E';
	}
	else if (level == 1)
	{
		level_and_format[0] = 'W';
	}
	else if (level == 2)
	{
		level_and_format[0] = 'I';
	}
	else
	{
		level_and_format[0] = 'D';
	}

	if (level <= CURRENT_LOG_LEVEL)
	{
		va_list ap;
		va_start(ap, fmt);
		vfprintf(logfile, level_and_format, ap);
		va_end(ap);
	}

	// fprintf(stderr, "free:001\n");
	if (level_and_format)
	{
		// fprintf(stderr, "free:001.a\n");
		free(level_and_format);
	}
	// fprintf(stderr, "free:002\n");
}






// linked list ----------
typedef struct ll_node {
    void* val;
    struct ll_node* next;
} ll_node_t;


void ll_fill_val(void **val, size_t data_size, void* data)
{
	if (*val != NULL)
	{
		free(*val);
		*val = NULL;
	}

	*val = malloc(data_size);
	memcpy(*val, data, data_size);
}


// add to the beginning of the list
void ll_push(ll_node_t** head, size_t data_size, void* data)
{
    ll_node_t* new_node;
    new_node = calloc(1, sizeof(ll_node_t));
	ll_fill_val(&(new_node->val), data_size, data);
    new_node->next = *head;
    *head = new_node;
}

void* ll_pop(ll_node_t** head)
{
    void* retval = NULL;
    ll_node_t* next_node = NULL;

    if (*head == NULL)
	{
        return NULL;
	}

    next_node = (*head)->next;
    retval = (*head)->val;
    free(*head);
    *head = next_node;

    return retval;
}

void ll_free_val(void* val)
{
	if (val != NULL)
	{
		free(val);
		val = NULL;
	}
}

void* ll_remove_by_index(ll_node_t** head, int n)
{
    int i = 0;
    void* retval = NULL;
    ll_node_t* current = *head;
    ll_node_t* temp_node = NULL;

    if (n == 0)
	{
        return ll_pop(head);
    }

    for (i = 0; i < n-1; i++)
        {
        if (current->next == NULL)
                {
            return NULL;
        }
        current = current->next;
    }

    temp_node = current->next;
	if (temp_node != NULL)
	{
			retval = temp_node->val;
			current->next = temp_node->next;
			free(temp_node);
	}

    return retval;
}

#if 0
void ll_print_list(ll_node_t* head)
{
    ll_node_t* current = head;
    int i = 0;

    while (current != NULL)
	{
		dbg(9, "element #%d=%p\n", i, current->val);
		i++;
		current = current->next;
	}
}
#endif

ll_node_t* resumable_filetransfers = NULL;

// linked list ----------









time_t get_unix_time(void)
{
    return time(NULL);
}

void yieldcpu(uint32_t ms)
{
    usleep(1000 * ms);
}


Tox *create_tox()
{
    Tox *tox;
	struct Tox_Options options;

/*
	TOX_ERR_OPTIONS_NEW err_options;
    struct Tox_Options options = tox_options_new(&err_options);
	if (err_options != TOX_ERR_OPTIONS_NEW_OK)
	{
		dbg(0, "tox_options_new error\n");
	}
*/

    tox_options_default(&options);


	options.ipv6_enabled = false;
	options.udp_enabled = true;
	options.local_discovery_enabled = true;
	options.hole_punching_enabled = true;

    FILE *f = fopen(savedata_filename, "rb");
    if (f)
	{
        fseek(f, 0, SEEK_END);
        long fsize = ftell(f);
        fseek(f, 0, SEEK_SET);

        uint8_t *savedata = malloc(fsize);

        size_t dummy = fread(savedata, fsize, 1, f);
		if (dummy < 1)
		{
			dbg(0, "reading savedata failed\n");
		}
        fclose(f);

        options.savedata_type = TOX_SAVEDATA_TYPE_TOX_SAVE;
        options.savedata_data = savedata;
        options.savedata_length = fsize;

        tox = tox_new(&options, NULL);

        free((void *)savedata);
    }
	else
	{
        tox = tox_new(&options, NULL);
    }

    return tox;
}

void replace_bad_char_from_string(char *str, const char replace_with)
{
	// win32: '\ / : * ? " < > |'
	char bad_chars[] = "/:*?<>|\"";
	int i;
	int j;

	if ((str) && (strlen(str) > 0))
	{
		for(i = 0; i < strlen(str) ;i++)
		{
			for(j = 0; j < strlen(bad_chars); j++)
			if (str[i] == bad_chars[j])
			{
				str[i] = replace_with;
			}
		}
	}
}


void update_savedata_file(const Tox *tox)
{
    size_t size = tox_get_savedata_size(tox);
    char *savedata = malloc(size);
    tox_get_savedata(tox, (uint8_t *)savedata);

    FILE *f = fopen(savedata_tmp_filename, "wb");
    fwrite(savedata, size, 1, f);
    fclose(f);

    rename(savedata_tmp_filename, savedata_filename);

    free(savedata);
}

off_t file_size(const char *path)
{
    struct stat st;

    if (stat(path, &st) == -1)
    {
        return 0;
    }

    return st.st_size;
}

int bin_id_to_string(const char *bin_id, size_t bin_id_size, char *output, size_t output_size)
{
    if (bin_id_size != TOX_ADDRESS_SIZE || output_size < (TOX_ADDRESS_SIZE * 2 + 1))
    {
        return -1;
    }

    size_t i;
    for (i = 0; i < TOX_ADDRESS_SIZE; ++i)
    {
        snprintf(&output[i * 2], output_size - (i * 2), "%02X", bin_id[i] & 0xff);
    }

	return 0;
}

void random_char(char *output, int len)
{
	int i;
	srandom(time(NULL));

	for (i = 0; i < len - 1; i++)
	{
		output[i] = (unsigned char) (rand() % 255 + 1);
	}
	output[len - 1] = '\0';
}

void bin_id_to_string_all(const char *bin_id, size_t bin_id_size, char *output, size_t output_size)
{
	if (bin_id)
	{
		size_t i;
		for (i = 0; i < bin_id_size; ++i)
		{
			snprintf(&output[i * 2], output_size - (i * 2), "%02X", bin_id[i] & 0xff);
		}
	}
}


size_t get_file_name(char *namebuf, size_t bufsize, const char *pathname)
{
    int len = strlen(pathname) - 1;
    char *path = strdup(pathname);

    if (path == NULL)
    {
        // TODO
    }

    while (len >= 0 && pathname[len] == '/')
    {
        path[len--] = '\0';
    }

    char *finalname = strdup(path);

    if (finalname == NULL)
    {
        // TODO
    }

    const char *basenm = strrchr(path, '/');
    if (basenm != NULL)
    {
        if (basenm[1])
        {
            strcpy(finalname, &basenm[1]);
        }
    }

    snprintf(namebuf, bufsize, "%s", finalname);
    free(finalname);
    free(path);

    return strlen(namebuf);
}

void bootstrap(Tox *tox)
{
    DHT_node nodes[] =
    {
        {"178.62.250.138",             33445, "788236D34978D1D5BD822F0A5BEBD2C53C64CC31CD3149350EE27D4D9A2F9B6B", {0}},
        {"2a03:b0c0:2:d0::16:1",       33445, "788236D34978D1D5BD822F0A5BEBD2C53C64CC31CD3149350EE27D4D9A2F9B6B", {0}},
        {"tox.zodiaclabs.org",         33445, "A09162D68618E742FFBCA1C2C70385E6679604B2D80EA6E84AD0996A1AC8A074", {0}},
        {"163.172.136.118",            33445, "2C289F9F37C20D09DA83565588BF496FAB3764853FA38141817A72E3F18ACA0B", {0}},
        {"2001:bc8:4400:2100::1c:50f", 33445, "2C289F9F37C20D09DA83565588BF496FAB3764853FA38141817A72E3F18ACA0B", {0}},
        {"128.199.199.197",            33445, "B05C8869DBB4EDDD308F43C1A974A20A725A36EACCA123862FDE9945BF9D3E09", {0}},
        {"2400:6180:0:d0::17a:a001",   33445, "B05C8869DBB4EDDD308F43C1A974A20A725A36EACCA123862FDE9945BF9D3E09", {0}},
        {"biribiri.org",               33445, "F404ABAA1C99A9D37D61AB54898F56793E1DEF8BD46B1038B9D822E8460FAB67", {0}}
    };

    for (size_t i = 0; i < sizeof(nodes)/sizeof(DHT_node); i ++) {
        sodium_hex2bin(nodes[i].key_bin, sizeof(nodes[i].key_bin),
                       nodes[i].key_hex, sizeof(nodes[i].key_hex)-1, NULL, NULL, NULL);
        tox_bootstrap(tox, nodes[i].ip, nodes[i].port, nodes[i].key_bin, NULL);
    }
}

// fill string with toxid in upper case hex.
// size of toxid_str needs to be: [TOX_ADDRESS_SIZE*2 + 1] !!
void get_my_toxid(Tox *tox, char *toxid_str)
{
    uint8_t tox_id_bin[TOX_ADDRESS_SIZE];
    tox_self_get_address(tox, tox_id_bin);

	char tox_id_hex_local[TOX_ADDRESS_SIZE*2 + 1];
    sodium_bin2hex(tox_id_hex_local, sizeof(tox_id_hex_local), tox_id_bin, sizeof(tox_id_bin));

    for (size_t i = 0; i < sizeof(tox_id_hex_local)-1; i ++)
	{
        tox_id_hex_local[i] = toupper(tox_id_hex_local[i]);
    }

	snprintf(toxid_str, (size_t)(TOX_ADDRESS_SIZE*2 + 1), "%s", (const char*)tox_id_hex_local);
}

void print_tox_id(Tox *tox)
{
    char tox_id_hex[TOX_ADDRESS_SIZE*2 + 1];
	get_my_toxid(tox, tox_id_hex);

    if (logfile)
    {
		dbg(2, "--MyToxID--:%s\n", tox_id_hex);
        int fd = fileno(logfile);
        fsync(fd);
    }
}

int is_friend_online(Tox *tox, uint32_t num)
{
	int j = find_friend_in_friendlist(num);
	switch (Friends.list[j].connection_status)
	{
		case TOX_CONNECTION_NONE:
			return 0;
			break;
		case TOX_CONNECTION_TCP:
			return 1;
			break;
		case TOX_CONNECTION_UDP:
			return 1;
			break;
		default:
			return 0;
			break;
	}
}

static int find_friend_in_friendlist(uint32_t friendnum)
{
	int i;

	for (i = 0; i <= Friends.max_idx; ++i)
	{
        if (Friends.list[i].num == friendnum)
		{
			return i;
		}
	}

	return -1;
}

static void update_friend_last_online(uint32_t num, time_t timestamp)
{
	int friendlistnum = find_friend_in_friendlist(num);

    Friends.list[friendlistnum].last_online.last_on = timestamp;
    Friends.list[friendlistnum].last_online.tm = *localtime((const time_t *)&timestamp);

    /* if the format changes make sure TIME_STR_SIZE is the correct size !! */
    strftime(Friends.list[friendlistnum].last_online.hour_min_str, TIME_STR_SIZE, global_timestamp_format, &Friends.list[friendlistnum].last_online.tm);
}

void send_file_to_friend_real(Tox *m, uint32_t num, const char* filename, int resume, uint8_t* fileid_resume)
{
    // ------- hack to send file --------
    // ------- hack to send file --------
    const char *errmsg = NULL;
    char path[MAX_STR_SIZE];

    snprintf(path, sizeof(path), "%s", filename);
    dbg(2, "send_file_to_friend_real:path=%s\n", path);

    FILE *file_to_send = fopen(path, "r");

    if (file_to_send == NULL)
    {
		dbg(0, "send_file_to_friend_real:error opening file\n");
		return;
    }

    off_t filesize = file_size(path);

    if (filesize == 0)
    {
		dbg(0, "send_file_to_friend_real:filesize 0\n");
		fclose(file_to_send);
		return;
    }

    char file_name[TOX_MAX_FILENAME_LENGTH];
    size_t namelen = get_file_name(file_name, sizeof(file_name), path);

    TOX_ERR_FILE_SEND err;

	char *o = calloc(1, (size_t)TOX_FILE_ID_LENGTH);
	uint32_t filenum = -1;
	if (resume == 0)
	{
		dbg(9, "resume == 0\n");
		random_char(o, (int)TOX_FILE_ID_LENGTH);

		filenum = tox_file_send(m, num, TOX_FILE_KIND_DATA, (uint64_t)filesize, (uint8_t*)o,
			(uint8_t *)file_name, namelen, &err);
	}
	else
	{
		dbg(9, "resume == 1\n");

		filenum = tox_file_send(m, num, TOX_FILE_KIND_DATA, (uint64_t)filesize, fileid_resume,
			(uint8_t *)file_name, namelen, &err);
	}
	dbg(2, "send_file_to_friend:tox_file_send=%s filenum=%d\n", file_name, (int)filenum);

    if (err != TOX_ERR_FILE_SEND_OK)
    {
		dbg(0, "send_file_to_friend_real: ! TOX_ERR_FILE_SEND_OK\n");
		goto on_send_error;
    }

	dbg(2, "send_file_to_friend_real(1):tox_file_send=%s filenum=%d\n", file_name, (int)filenum);
    struct FileTransfer *ft = new_file_transfer(num, filenum, FILE_TRANSFER_SEND, TOX_FILE_KIND_DATA);
	dbg(2, "send_file_to_friend_real(2):tox_file_send=%s filenum=%d\n", file_name, (int)filenum);

    if (!ft)
    {
		dbg(0, "send_file_to_friend_real:ft=NULL\n");
		err = TOX_ERR_FILE_SEND_TOO_MANY;
		goto on_send_error;
    }

    memcpy(ft->file_name, file_name, namelen + 1);
    ft->file = file_to_send;
    ft->file_size = filesize;

	if (resume == 0)
	{
		dbg(9, "resume == 0\n");
		memcpy(ft->file_id, o, (size_t)TOX_FILE_ID_LENGTH);
	}
	else
	{
		dbg(9, "resume == 1\n");
		memcpy(ft->file_id, fileid_resume, (size_t)TOX_FILE_ID_LENGTH);
	}

	dbg(0, "send_file_to_friend_real:tox_file_get_file_id num=%d filenum=%d\n", (int)num, (int)filenum);
	dbg(0, "send_file_to_friend_real:file_id_resume=%d ft->file_id=%d\n", (int)fileid_resume, (int)ft->file_id);
	dbg(0, "send_file_to_friend_real:o=%d ft->file_id=%d\n", (int)o, (int)ft->file_id);

	char file_id_str[TOX_FILE_ID_LENGTH * 2 + 1];
	bin_id_to_string_all((char*)ft->file_id, (size_t)TOX_FILE_ID_LENGTH, file_id_str, (size_t)(TOX_FILE_ID_LENGTH * 2 + 1));
	dbg(2, "send_file_to_friend_real:file_id=%s\n", file_id_str);
	bin_id_to_string_all((char*)fileid_resume, (size_t)TOX_FILE_ID_LENGTH, file_id_str, (size_t)(TOX_FILE_ID_LENGTH * 2 + 1));
	dbg(2, "send_file_to_friend_real:fileid_resume=%s\n", file_id_str);
	bin_id_to_string_all((char*)o, (size_t)TOX_FILE_ID_LENGTH, file_id_str, (size_t)(TOX_FILE_ID_LENGTH * 2 + 1));
	dbg(2, "send_file_to_friend_real:o=%s\n", file_id_str);

	free(o);
	o = NULL;

    return;

on_send_error:

	free(o);
	o = NULL;

    switch (err)
	{
        case TOX_ERR_FILE_SEND_FRIEND_NOT_FOUND:
            errmsg = "File transfer failed: Invalid friend.";
            break;

        case TOX_ERR_FILE_SEND_FRIEND_NOT_CONNECTED:
            errmsg = "File transfer failed: Friend is offline.";

            break;

        case TOX_ERR_FILE_SEND_NAME_TOO_LONG:
            errmsg = "File transfer failed: Filename is too long.";
            break;

        case TOX_ERR_FILE_SEND_TOO_MANY:
            errmsg = "File transfer failed: Too many concurrent file transfers.";

            break;

        default:
            errmsg = "File transfer failed.";
            break;
    }

    dbg(0, "send_file_to_friend_real:ft error=%s\n", errmsg);
    tox_file_control(m, num, filenum, TOX_FILE_CONTROL_CANCEL, NULL);
    fclose(file_to_send);

    // ------- hack to send file --------
    // ------- hack to send file --------
}

void resume_file_to_friend(Tox *m, uint32_t num, struct FileTransfer* ft)
{
	char *file_name_incl_full_path = NULL;
	int j = find_friend_in_friendlist(ft->friendnum);

	if (j > -1)
	{
		file_name_incl_full_path = malloc(300);
		snprintf(file_name_incl_full_path, 299, "%s/%s", (const char*)Friends.list[j].worksubdir, ft->file_name);
		dbg(2, "resume_file_to_friend:full path=%s\n", file_name_incl_full_path);
		char file_id_str[TOX_FILE_ID_LENGTH * 2 + 1];
		bin_id_to_string_all((char*)ft->file_id, (size_t)TOX_FILE_ID_LENGTH, file_id_str, (size_t)(TOX_FILE_ID_LENGTH * 2 + 1));
		dbg(2, "resume_file_to_friend:file_id=%d file_id_bin=%d\n", (int)file_id_str, (int)ft->file_id);
		dbg(2, "resume_file_to_friend:file_id=%s\n", file_id_str);

		dbg(2, "resume_file_to_friend:path=%s friendnum=%d filenum=%d\n", file_name_incl_full_path, (int)ft->friendnum, (int)ft->filenum);
		send_file_to_friend_real(m, ft->friendnum, file_name_incl_full_path, 1, ft->file_id);
	}
	else
	{
		dbg(0, "resume_file_to_friend:friend %d not found in friendlist\n", (int)ft->friendnum);
	}
}

void send_file_to_friend(Tox *m, uint32_t num, const char* filename)
{
	send_file_to_friend_real(m, num, filename, 0, NULL);
}


int copy_file(const char *from, const char *to)
{
    int fd_to, fd_from;
    char buf[4096];
    ssize_t nread;
    int saved_errno;

    fd_from = open(from, O_RDONLY);

    if (fd_from < 0)
	{
		dbg(0, "copy_file:002\n");
        return -1;
	}

    fd_to = open(to, O_WRONLY | O_CREAT | O_EXCL, 0666);
    if (fd_to < 0)
	{
		dbg(0, "copy_file:003\n");
        goto out_error;
	}

    while (nread = read(fd_from, buf, sizeof buf), nread > 0)
    {
        char *out_ptr = buf;
        ssize_t nwritten;

        do
		{
            nwritten = write(fd_to, out_ptr, nread);

            if (nwritten >= 0)
            {
                nread -= nwritten;
                out_ptr += nwritten;
            }
            else if (errno != EINTR)
            {
				dbg(0, "copy_file:004\n");
                goto out_error;
            }

        } while (nread > 0);
    }

    if (nread == 0)
    {
        if (close(fd_to) < 0)
        {
            fd_to = -1;
            dbg(0, "copy_file:005\n");
            goto out_error;
        }

        close(fd_from);

        /* Success! */
        return 0;
    }


  out_error:
    saved_errno = errno;

    close(fd_from);
    if (fd_to >= 0)
	{
        close(fd_to);
	}

	dbg(0, "copy_file:009\n");

    errno = saved_errno;
    return -1;
}



char* copy_file_to_friend_subdir(int friendlistnum, const char* file_with_path, const char* filename)
{
	dbg(2, "newpath=%s %s\n", file_with_path, filename);
	int errcode;

	char *newname = NULL;
	newname = malloc(300);
	snprintf(newname, 299, "%s/%s", (const char*)Friends.list[friendlistnum].worksubdir, filename);
	dbg(2, "copy_file %s -> %s\n", file_with_path, newname);
	dbg(2, "copy_file friend:workdir=%s\n", (const char*)Friends.list[friendlistnum].worksubdir);
	errcode = copy_file(file_with_path, newname);
	dbg(9, "copy_file:ready:res=%d\n", errcode);

	dbg(9, "newpath=%s\n", newname);

	return newname;
}

int have_resumed_fts_friend(uint32_t friendnum)
{
	int j = find_friend_in_friendlist(friendnum);

	if (Friends.list[j].have_resumed_fts == 1)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

void send_file_to_all_friends(Tox *m, const char* file_with_path, const char* filename)
{
    size_t i;
	// TODO
    size_t numfriends = tox_self_get_friend_list_size(m);
	char *newname = NULL;
	int j = -1;

    for (i = 0; i < numfriends; ++i)
    {
        dbg(2, "sending file (%s) to friendnum=%d\n", file_with_path, (int)i);

		j = find_friend_in_friendlist((uint32_t) i);
		if (j > -1)
		{
			newname = copy_file_to_friend_subdir((int) j, file_with_path, filename);

			// see if we have reached max filetransfers
			if (has_reached_max_file_transfer_for_friend((uint32_t) i) == 0)
			{
				if (is_friend_online(m, (uint32_t) i) == 1)
				{
					if (have_resumed_fts_friend((uint32_t)i) == 1)
					{
						send_file_to_friend(m, i, newname);
					}
				}
			}
			free(newname);
			newname = NULL;
		}
    }

    unlink(file_with_path);
}

void on_tox_friend_status(Tox *tox, uint32_t friend_number, TOX_USER_STATUS status, void *user_data)
{
	dbg(2, "on_tox_friend_status:friendnum=%d status=%d\n", (int)friend_number, (int)status);
}

void friendlist_onConnectionChange(Tox *m, uint32_t num, TOX_CONNECTION connection_status, void *user_data)
{
	int friendlistnum = find_friend_in_friendlist(num);
    dbg(2, "friendlist_onConnectionChange:*ENTER*:friendnum=%d %d\n", (int)num, (int)connection_status);

    Friends.list[friendlistnum].connection_status = connection_status;
	update_friend_last_online(num, get_unix_time());

	if (is_friend_online(m, num) == 1)
	{
		dbg(0, "friend %d just got online\n", num);

		resume_resumable_fts(m, num);

		if (avatar_send(m, num) == -1)
		{
			dbg(0, "avatar_send failed for friend %d\n", num);
		}
	}
	else
	{
		dbg(0, "friend %d went *OFFLINE*\n", num);

		// save all resumeable FTs
		save_resumable_fts(m, num);
		// friend went offline -> cancel all filetransfers
		kill_all_file_transfers_friend(m, num);
		// friend went offline -> hang up on all calls
		av_local_disconnect(mytox_av, num);
	}

    dbg(2, "friendlist_onConnectionChange:*READY*:friendnum=%d %d\n", (int)num, (int)connection_status);

}

void friendlist_onFriendAdded(Tox *m, uint32_t num, bool sort)
{
    dbg(9, "friendlist_onFriendAdded:001\n");

    if (Friends.max_idx == 0)
    {
		dbg(9, "friendlist_onFriendAdded:001.a malloc 1 friend struct, max_id=%d, num=%d\n", (int)Friends.max_idx, (int)num);
        Friends.list = malloc(sizeof(ToxicFriend));
    }
    else
    {
		dbg(9, "friendlist_onFriendAdded:001.b realloc %d friend struct, max_id=%d, num=%d\n", (int)(Friends.max_idx + 1), (int)Friends.max_idx, (int)num);
        Friends.list = realloc(Friends.list, ((Friends.max_idx + 1) * sizeof(ToxicFriend)));
    }

	dbg(9, "friendlist_onFriendAdded:001.c set friend to all 0 values\n");
    memset(&Friends.list[Friends.max_idx], 0, sizeof(ToxicFriend)); // fill friend with "0" bytes


	dbg(2, "friendlist_onFriendAdded:003:%d\n", (int)Friends.max_idx);
	Friends.list[Friends.max_idx].num = num;
	Friends.list[Friends.max_idx].active = true;
	Friends.list[Friends.max_idx].connection_status = TOX_CONNECTION_NONE;
	Friends.list[Friends.max_idx].status = TOX_USER_STATUS_NONE;
	Friends.list[Friends.max_idx].waiting_for_answer = 0;
	Friends.list[Friends.max_idx].auto_resend_start_time = 0;
	Friends.list[Friends.max_idx].have_resumed_fts = 0;

	TOX_ERR_FRIEND_GET_PUBLIC_KEY pkerr;
	tox_friend_get_public_key(m, num, (uint8_t *) Friends.list[Friends.max_idx].pub_key, &pkerr);

	if (pkerr != TOX_ERR_FRIEND_GET_PUBLIC_KEY_OK)
	{
		dbg(0, "tox_friend_get_public_key failed (error %d)\n", pkerr);
	}

	bin_id_to_string(Friends.list[Friends.max_idx].pub_key, (size_t) TOX_ADDRESS_SIZE, Friends.list[Friends.max_idx].pubkey_string, (size_t) (TOX_ADDRESS_SIZE * 2 + 1));
	dbg(2, "friend pubkey=%s\n", Friends.list[Friends.max_idx].pubkey_string);

	// mkdir subdir of workdir for this friend
	snprintf(Friends.list[Friends.max_idx].worksubdir, sizeof(Friends.list[Friends.max_idx].worksubdir), "%s/%s/", motion_pics_work_dir, (const char*)Friends.list[Friends.max_idx].pubkey_string);
	dbg(2, "friend subdir=%s\n", Friends.list[Friends.max_idx].worksubdir);
	mkdir(Friends.list[Friends.max_idx].worksubdir, S_IRWXU | S_IRWXG); // og+rwx

	TOX_ERR_FRIEND_GET_LAST_ONLINE loerr;
	time_t t = tox_friend_get_last_online(m, num, &loerr);

	if (loerr != TOX_ERR_FRIEND_GET_LAST_ONLINE_OK)
	{
	    t = 0;
	}

	update_friend_last_online(num, t);

	Friends.max_idx++;

}

// after you are finished call free_friendlist_nums !
uint32_t* load_friendlist_nums(Tox *m)
{
	size_t numfriends = tox_self_get_friend_list_size(m);
	uint32_t *friend_list = malloc(numfriends * sizeof(uint32_t));
	tox_self_get_friend_list(m, friend_list);

	return friend_list;
}

void free_friendlist_nums(void* friend_list)
{
	if (friend_list)
	{
		free(friend_list);
		friend_list = NULL;
	}
}

static void load_friendlist(Tox *m)
{
    size_t i;
	// TODO
    size_t numfriends = tox_self_get_friend_list_size(m);
	uint32_t* friend_lookup_list = load_friendlist_nums(m);

    for (i = 0; i < numfriends; ++i)
    {
        friendlist_onFriendAdded(m, friend_lookup_list[i], false);
        dbg(2, "loading friend num:%d pubkey=%s\n", (int)friend_lookup_list[i], Friends.list[Friends.max_idx - 1].pubkey_string);
    }

	free_friendlist_nums((void*) friend_lookup_list);
}




void close_file_transfer(Tox *m, struct FileTransfer *ft, int CTRL)
{
    dbg(9, "close_file_transfer:001\n");

    if (!ft)
	{
        return;
	}

    if (ft->state == FILE_TRANSFER_INACTIVE)
	{
        return;
	}

    if (ft->file)
	{
        fclose(ft->file);
	}

    if (CTRL >= 0)
	{
        tox_file_control(m, ft->friendnum, ft->filenum, (TOX_FILE_CONTROL) CTRL, NULL);
	}

    memset(ft, 0, sizeof(struct FileTransfer));
	ft->state = FILE_TRANSFER_INACTIVE; // == 0

}

int has_reached_max_file_transfer_for_friend(uint32_t num)
{
	int active_ft = 0;
	int friendlistnum = find_friend_in_friendlist(num);
	int i;

    for (i = 0; i < MAX_FILES; ++i)
    {
        struct FileTransfer *ft_send = &Friends.list[friendlistnum].file_sender[i];

        if (ft_send->state != FILE_TRANSFER_INACTIVE)
        {
			if (ft_send->file_name != NULL)
			{
				active_ft++;
			}
		}
	}

	if (active_ft < MAX_FILES)
	{
		return 0;
	}
	else
	{
		// have reached max filetransfers already
		return 1;
	}
}

struct FileTransfer *get_file_transfer_from_filename_struct(int friendlistnum, const char* filename)
{
    size_t i;

    for (i = 0; i < MAX_FILES; ++i)
    {
        struct FileTransfer *ft_send = &Friends.list[friendlistnum].file_sender[i];

        if (ft_send->state != FILE_TRANSFER_INACTIVE)
        {
			if (ft_send->file_name != NULL)
			{
				if ((strlen(ft_send->file_name) > 0) && (filename != NULL) && (strlen(filename) > 0))
				{
					if (strncmp((char*)ft_send->file_name, filename, strlen(ft_send->file_name)) == 0)
					{
						// dbg(9, "found ft by filename:%s\n", ft_send->file_name);
						return ft_send;
					}
				}
			}
        }
    }

    return NULL;
}


struct FileTransfer *get_file_transfer_struct(uint32_t friendnum, uint32_t filenum)
{
    size_t i;

	int friendlistnum = find_friend_in_friendlist(friendnum);

    for (i = 0; i < MAX_FILES; ++i)
    {
        struct FileTransfer *ft_send = &Friends.list[friendlistnum].file_sender[i];

        if (ft_send->state != FILE_TRANSFER_INACTIVE && ft_send->filenum == filenum)
        {
            return ft_send;
        }

        struct FileTransfer *ft_recv = &Friends.list[friendlistnum].file_receiver[i];

        if (ft_recv->state != FILE_TRANSFER_INACTIVE && ft_recv->filenum == filenum)
        {
            return ft_recv;
        }
    }

    return NULL;
}

//
// cut message at 999 chars length !!
//
void send_text_message_to_friend(Tox *tox, uint32_t friend_number, const char *fmt, ...)
{
	char msg2[1000];
	size_t length = 0;

	if (fmt == NULL)
	{
		dbg(9, "send_text_message_to_friend:no message to send\n");
		return;
	}

	va_list ap;
	va_start(ap, fmt);
	vsnprintf(msg2, 999, fmt, ap);
	va_end(ap);

	length = (size_t)strlen(msg2);
	tox_friend_send_message(tox, friend_number, TOX_MESSAGE_TYPE_NORMAL, (uint8_t *)msg2, length, NULL);
}


void friend_request_cb(Tox *tox, const uint8_t *public_key, const uint8_t *message, size_t length,
                                   void *user_data)
{
    uint32_t friendnum = tox_friend_add_norequest(tox, public_key, NULL);
    dbg(2, "add friend:002:friendnum=%d max_id=%d\n", friendnum, (int)Friends.max_idx);
    friendlist_onFriendAdded(tox, friendnum, 0);

    update_savedata_file(tox);
}

/* ssssshhh I stole this from ToxBot, don't tell anyone.. */
/* ssssshhh and I stole this from EchoBot, don't tell anyone.. */
static void get_elapsed_time_str(char *buf, int bufsize, uint64_t secs)
{
	long unsigned int minutes = (secs % 3600) / 60;
	long unsigned int hours = (secs / 3600) % 24;
	long unsigned int days = (secs / 3600) / 24;

	snprintf(buf, bufsize, "%lud %luh %lum", days, hours, minutes);
}

//
// lastline param ignored for now!!
//
void run_cmd_return_output(const char *command, char* output, int lastline)
{
	FILE *fp = NULL;
	char path[1035];
	char *pos = NULL;

	if (!output)
	{
		return;
	}

	/* Open the command for reading. */
	fp = popen(command, "r");
	if (fp == NULL)
	{
		dbg(0, "Failed to run command: %s errno=%d error=%s\n", command, errno, strerror(errno));
		output[0] = '\0';
		return;
	}

	/* Read the output a line at a time - output it. */
	while (fgets(path, sizeof(path)-1, fp) != NULL)
	{
        snprintf(output, 299, "%s", (const char*)path);
	}

	if (strlen(output) > 1)
	{
		if ((pos = strchr(output, '\n')) != NULL)
		{
			*pos = '\0';
		}
	}

	/* close */
	pclose(fp);
}

void remove_friend(Tox *tox, uint32_t friend_number)
{
	TOX_ERR_FRIEND_DELETE error;
	tox_friend_delete(tox, friend_number, &error);
}

void cmd_delfriend(Tox *tox, uint32_t friend_number, const char* message)
{
	uint32_t del_friend_number = -1;
	if (friend_number != del_friend_number)
	{
		// remove_friend(tox, del_friend_number);
	}
}

void cmd_stats(Tox *tox, uint32_t friend_number)
{
	switch (my_connection_status)
	{
		case TOX_CONNECTION_NONE:
			send_text_message_to_friend(tox, friend_number, "doorspy status:offline");
			break;
		case TOX_CONNECTION_TCP:
			send_text_message_to_friend(tox, friend_number, "doorspy status:Online, using TCP");
			break;
		case TOX_CONNECTION_UDP:
			send_text_message_to_friend(tox, friend_number, "doorspy status:Online, using UDP");
			break;
		default:
			send_text_message_to_friend(tox, friend_number, "doorspy status:*unknown*");
			break;
	}

	// ----- uptime -----
	char time_str[200];
	uint64_t cur_time = time(NULL);
	get_elapsed_time_str(time_str, sizeof(time_str), cur_time - global_start_time);
	send_text_message_to_friend(tox, friend_number, "Uptime: %s", time_str);
	// ----- uptime -----

	char output_str[1000];
	run_cmd_return_output(shell_cmd__get_my_number_of_open_files, output_str, 1);
	if (strlen(output_str) > 0)
	{
		send_text_message_to_friend(tox, friend_number, "doorspy open files:%s", output_str);
	}
	else
	{
		send_text_message_to_friend(tox, friend_number, "ERROR getting open files");
	}

	// --- temp ---
	run_cmd_return_output(shell_cmd__get_cpu_temp, output_str, 1);
	if (strlen(output_str) > 0)
	{
		send_text_message_to_friend(tox, friend_number, "doorspy Cpu temp:%s\xC2\xB0%s", output_str, "C");
	}
	else
	{
		send_text_message_to_friend(tox, friend_number, "ERROR getting Cpu temp");
	}

	run_cmd_return_output(shell_cmd__get_gpu_temp, output_str, 1);
	if (strlen(output_str) > 0)
	{
		send_text_message_to_friend(tox, friend_number, "doorspy GPU temp:%s\xC2\xB0%s", output_str, "C");
	}
	else
	{
		send_text_message_to_friend(tox, friend_number, "ERROR getting GPU temp");
	}
	// --- temp ---

    char tox_id_hex[TOX_ADDRESS_SIZE*2 + 1];
	get_my_toxid(tox, tox_id_hex);

	send_text_message_to_friend(tox, friend_number, "tox:%s", tox_id_hex);
}

void cmd_kamft(Tox *tox, uint32_t friend_number)
{
	send_text_message_to_friend(tox, friend_number, "killing all filetransfers to you ...");
	kill_all_file_transfers_friend(tox, friend_number);
}

void cmd_snap(Tox *tox, uint32_t friend_number)
{
	send_text_message_to_friend(tox, friend_number, "capture single shot, and send to all friends ...");

	char output_str[1000];
	run_cmd_return_output(shell_cmd__single_shot, output_str, 1);

#if 0
	if (strlen(output_str) > 0)
	{
		// send_text_message_to_friend(tox, friend_number, "doorspy:%s", output_str);
	}
	else
	{
		send_text_message_to_friend(tox, friend_number, "ERROR running snap command");
	}
#endif

	send_text_message_to_friend(tox, friend_number, "... capture single shot, ready!");
}

void cmd_friends(Tox *tox, uint32_t friend_number)
{
	size_t i;
	// TODO
    size_t numfriends = tox_self_get_friend_list_size(tox);
	int j = -1;

    for (i = 0; i < numfriends; ++i)
    {
		j = find_friend_in_friendlist((uint32_t) i);
		if (j > -1)
		{
			send_text_message_to_friend(tox, friend_number, "%d:friend", j);
			send_text_message_to_friend(tox, friend_number, "%d tox:%s", j, (const char*)Friends.list[j].pubkey_string);
			send_text_message_to_friend(tox, friend_number, "%d:last online (in client local time):%s", j, (const char*)Friends.list[j].last_online.hour_min_str);

			switch (Friends.list[j].connection_status)
			{
				case TOX_CONNECTION_NONE:
					send_text_message_to_friend(tox, friend_number, "%d:%s", j, "status:offline");
					break;
				case TOX_CONNECTION_TCP:
					send_text_message_to_friend(tox, friend_number, "%d:%s", j, "status:Online, using TCP");
					break;
				case TOX_CONNECTION_UDP:
					send_text_message_to_friend(tox, friend_number, "%d:%s", j, "status:Online, using UDP");
					break;
				default:
					send_text_message_to_friend(tox, friend_number, "%d:%s", j, "status:*unknown*");
					break;
			}
		}
    }
}

void cmd_restart(Tox *tox, uint32_t friend_number)
{
	send_text_message_to_friend(tox, friend_number, "doorspy services will restart ...");

	global_want_restart = 1;
}


void cmd_vcm(Tox *tox, uint32_t friend_number)
{
	// send_text_message_to_friend(tox, friend_number, "video-call-me not yet implemented!");

	dbg(9, "cmd_vcm:001\n");
	send_text_message_to_friend(tox, friend_number, "i am trying to send my video ...");

	if (mytox_av != NULL)
	{
		dbg(9, "cmd_vcm:002\n");
		if (global_video_bit_rate == 0)
		{
			global_video_bit_rate = DEFAULT_GLOBAL_VID_BITRATE;
			dbg(9, "cmd_vcm:003\n");
		}
		friend_to_send_video_to = friend_number;
		dbg(9, "cmd_vcm:004\n");

		TOXAV_ERR_CALL error = 0;
		toxav_call(mytox_av, friend_number, global_audio_bit_rate, global_video_bit_rate, &error);
		// toxav_call(mytox_av, friend_number, 0, 40, &error);
		dbg(9, "cmd_vcm:005\n");

		if (error != TOXAV_ERR_CALL_OK)
		{
			switch (error)
			{
				case TOXAV_ERR_CALL_MALLOC:
					dbg(0, "toxav_call (1):TOXAV_ERR_CALL_MALLOC\n");
					break;

				case TOXAV_ERR_CALL_SYNC:
					dbg(0, "toxav_call (1):TOXAV_ERR_CALL_SYNC\n");
					break;

				case TOXAV_ERR_CALL_FRIEND_NOT_FOUND:
					dbg(0, "toxav_call (1):TOXAV_ERR_CALL_FRIEND_NOT_FOUND\n");
					break;

				case TOXAV_ERR_CALL_FRIEND_NOT_CONNECTED:
					dbg(0, "toxav_call (1):TOXAV_ERR_CALL_FRIEND_NOT_CONNECTED\n");
					break;

				case TOXAV_ERR_CALL_FRIEND_ALREADY_IN_CALL:
					dbg(0, "toxav_call (1):TOXAV_ERR_CALL_FRIEND_ALREADY_IN_CALL\n");
					break;

				case TOXAV_ERR_CALL_INVALID_BIT_RATE:
					dbg(0, "toxav_call (1):TOXAV_ERR_CALL_INVALID_BIT_RATE\n");
					break;

				default:
					dbg(0, "toxav_call (1):*unknown error*\n");
					break;
			}
		}
	}
	else
	{
		dbg(9, "cmd_vcm:006\n");
		send_text_message_to_friend(tox, friend_number, "sending video failed:toxav==NULL");
	}

	dbg(9, "cmd_vcm:099\n");
}

void send_help_to_friend(Tox *tox, uint32_t friend_number)
{
	send_text_message_to_friend(tox, friend_number, "=========================\nDoorSpy version:%s\n=========================", global_version_string);
	// send_text_message_to_friend(tox, friend_number, " commands are:");
	send_text_message_to_friend(tox, friend_number, " .stats    --> show DoorSpy status");
	send_text_message_to_friend(tox, friend_number, " .friends  --> show DoorSpy Friends");
	send_text_message_to_friend(tox, friend_number, " .kamft    --> kill all my filetransfers");
	send_text_message_to_friend(tox, friend_number, " .snap     --> snap a single still image");
	send_text_message_to_friend(tox, friend_number, " .restart  --> restart DoorSpy system");
	send_text_message_to_friend(tox, friend_number, " .vcm      --> videocall me");
}

void start_zipfile(mz_zip_archive *pZip, size_t size_pZip, const char* zip_file_full_path)
{
	memset(pZip, 0, size_pZip);
	pZip->m_file_offset_alignment = 4; // align to 4 bytes?

	mz_zip_writer_init_file(pZip, zip_file_full_path, (unsigned long long)(1024));
}

void add_file_to_zipfile(mz_zip_archive *pZip, const char* file_to_add_full_path, const char* filename_in_zipfile)
{
	const char *comment = "_";
	mz_zip_writer_add_file(pZip, filename_in_zipfile, file_to_add_full_path, comment, (unsigned short)strlen(comment), MZ_DEFAULT_COMPRESSION);
}

void finish_zipfile(mz_zip_archive *pZip)
{
	mz_zip_writer_finalize_archive(pZip);
	mz_zip_writer_end(pZip);
}

void friend_message_cb(Tox *tox, uint32_t friend_number, TOX_MESSAGE_TYPE type, const uint8_t *message,
                                   size_t length, void *user_data)
{
	int j;
	int send_back = 0;

    if (type == TOX_MESSAGE_TYPE_NORMAL)
    {
		if (message != NULL)
		{
			j = find_friend_in_friendlist(friend_number);
			dbg(2, "message from friend:%d msg:%s\n", (int)friend_number, (char*)message);

			if (strncmp((char*)message, ".help", strlen((char*)".help")) == 0)
			{
				send_help_to_friend(tox, friend_number);
			}
			else if (strncmp((char*)message, ".stats", strlen((char*)".stats")) == 0)
			{
				cmd_stats(tox, friend_number);
			}
			else if (strncmp((char*)message, ".friends", strlen((char*)".friends")) == 0)
			{
				cmd_friends(tox, friend_number);
			}
			else if (strncmp((char*)message, ".kamft", strlen((char*)".kamft")) == 0)
			{
				cmd_kamft(tox, friend_number);
			}
			else if (strncmp((char*)message, ".snap", strlen((char*)".snap")) == 0)
			{
				cmd_snap(tox, friend_number);
			}
			else if (strncmp((char*)message, ".restart", strlen((char*)".restart")) == 0) // restart doorspy processes (no reboot)
			{
				cmd_restart(tox, friend_number);
			}
			else if (strncmp((char*)message, ".vcm", strlen((char*)".vcm")) == 0) // video call me!
			{
				cmd_vcm(tox, friend_number);
			}
			else
			{
				if (Friends.list[j].waiting_for_answer == 1)
				{
					// we want to get user feedback
					snprintf(Friends.list[j].last_answer, 99, (char*)message);
					Friends.list[j].waiting_for_answer = 2;

					if (Friends.list[j].last_answer)
					{
						dbg(2, "got answer from friend:%d answer:%s\n", (int)friend_number, Friends.list[j].last_answer);
					}
					else
					{
						dbg(2, "got answer from friend:%d answer:NULL\n", (int)friend_number);
					}
				}
				else
				{
					// send_back = 1;
					// unknown command, just send "help / usage"
					send_help_to_friend(tox, friend_number);
				}
			}
		}
		else
		{
			dbg(2, "message from friend:%d msg:NULL\n", (int)friend_number);
		}
    }
    else
    {
		dbg(2, "message from friend:%d\n", (int)friend_number);
    }

	if (send_back == 1)
	{
		tox_friend_send_message(tox, friend_number, type, message, length, NULL);
	}
}



void on_file_recv_chunk(Tox *m, uint32_t friendnumber, uint32_t filenumber, uint64_t position,
                        const uint8_t *data, size_t length, void *user_data)
{
    struct FileTransfer *ft = get_file_transfer_struct(friendnumber, filenumber);

    if (!ft)
	{
        return;
	}
}


void on_file_recv(Tox *m, uint32_t friendnumber, uint32_t filenumber, uint32_t kind, uint64_t file_size,
                  const uint8_t *filename, size_t filename_length, void *userdata)
{
    /* We don't care about receiving avatars */
    if (kind != TOX_FILE_KIND_DATA)
    {
        tox_file_control(m, friendnumber, filenumber, TOX_FILE_CONTROL_CANCEL, NULL);
        dbg(9, "on_file_recv:002:cancel incoming avatar\n");
        return;
    }
    else
    {
        // cancel all filetransfers. we don't want to receive files
        tox_file_control(m, friendnumber, filenumber, TOX_FILE_CONTROL_CANCEL, NULL);
        dbg(9, "on_file_recv:003:cancel incoming file\n");
        return;
    }
}

void save_resumable_fts(Tox *m, uint32_t friendnum)
{
	size_t i;
	int friendlistnum = find_friend_in_friendlist(friendnum);
	for (i = 0; i < MAX_FILES; ++i)
	{
		// for now save only sending FTs
		struct FileTransfer *ft = &Friends.list[friendlistnum].file_sender[i];
		if (ft->state != FILE_TRANSFER_INACTIVE)
		{
			dbg(9, "save_resumable_fts:saving sender FT i=%d ftnum=%d for friendnum:#%d pos=%d filesize=%d\n", i, (int)ft->filenum, (int)friendnum, (int)ft->position, (int)ft->file_size);
			ll_push(&resumable_filetransfers, sizeof(struct FileTransfer), ft);
			dbg(9, "save_resumable_fts:pushed struct=%p\n", resumable_filetransfers->val);
		}
	}

	Friends.list[friendlistnum].have_resumed_fts = 0;
}



void resume_resumable_fts(Tox *m, uint32_t friendnum)
{
	dbg(9, "resume_resumable_fts:001\n");

    ll_node_t* saved_ft_list = resumable_filetransfers;
    int i = 0;
    while (saved_ft_list != NULL)
	{
		dbg(9, "resume_resumable_fts:element #%d=%p\n", i, saved_ft_list->val);
		if (saved_ft_list->val != NULL)
		{
			struct FileTransfer *ft = (struct FileTransfer*)saved_ft_list->val;
			if (ft->friendnum == friendnum)
			{
				dbg(9, "resume_resumable_fts:**found element #%d=%p\n", i, saved_ft_list->val);
				resume_file_to_friend(m, ft->filenum, ft);
				// now remove element, and start loop again
				ll_remove_by_index(&resumable_filetransfers, i);
				saved_ft_list = resumable_filetransfers;
				i = 0;
				continue;
			}
		}

		i++;
		saved_ft_list = saved_ft_list->next;
	}

	int j = find_friend_in_friendlist(friendnum);
	if (j > -1)
	{
		Friends.list[j].have_resumed_fts = 1;
	}
}



void on_file_chunk_request(Tox *tox, uint32_t friendnumber, uint32_t filenumber, uint64_t position,
                           size_t length, void *userdata)
{
    // dbg(9, "on_file_chunk_request:001:friendnum=%d filenum=%d position=%ld len=%d\n", (int)friendnumber, (int)filenumber, (long)position, (int)length);
    struct FileTransfer *ft = get_file_transfer_struct(friendnumber, filenumber);

    if (!ft)
    {
        dbg(0, "on_file_chunk_request:003 ft=NULL\n");
        return;
    }

    if (ft->file_type == TOX_FILE_KIND_AVATAR)
    {
        on_avatar_chunk_request(tox, ft, position, length);
        return;
    }


    if (ft->state != FILE_TRANSFER_STARTED)
    {
        dbg(0, "on_file_chunk_request:005 !FILE_TRANSFER_STARTED\n");
        return;
    }

    if (length == 0)
    {
        dbg(2, "File '%s' successfully sent, ft->state=%d\n", ft->file_name, (int)ft->state);

        char origname[300];
        snprintf(origname, 299, "%s", (const char*)ft->file_name);

        close_file_transfer(tox, ft, -1);
		// also remove the file from disk

		int friendlist_num = find_friend_in_friendlist(friendnumber);
        char longname[300];
        snprintf(longname, 299, "%s/%s", (const char*)Friends.list[friendlist_num].worksubdir, origname);
        dbg(2, "delete file %s\n", longname);
		unlink(longname);

        return;
    }

    if (ft->file == NULL)
    {
        dbg(0, "File transfer for '%s' failed: Null file pointer\n", ft->file_name);
        close_file_transfer(tox, ft, TOX_FILE_CONTROL_CANCEL);
        return;
    }

    if (ft->position != position)
    {
        if (fseek(ft->file, position, SEEK_SET) == -1)
        {
            dbg(0, "File transfer for '%s' failed: Seek fail\n", ft->file_name);
            close_file_transfer(tox, ft, TOX_FILE_CONTROL_CANCEL);
            return;
        }

        ft->position = position;
    }

    uint8_t send_data[length];
    size_t send_length = fread(send_data, 1, sizeof(send_data), ft->file);

    if (send_length != length)
    {
        dbg(0, "File transfer for '%s' failed: Read fail\n", ft->file_name);
        close_file_transfer(tox, ft, TOX_FILE_CONTROL_CANCEL);
        return;
    }

    TOX_ERR_FILE_SEND_CHUNK err;
    tox_file_send_chunk(tox, friendnumber, filenumber, position, send_data, send_length, &err);

    if (err != TOX_ERR_FILE_SEND_CHUNK_OK)
    {
        dbg(0, "tox_file_send_chunk failed in chat callback (error %d)\n", err);
    }

    ft->position += send_length;
    ft->bps += send_length;
    ft->last_keep_alive = get_unix_time();

}


void on_avatar_file_control(Tox *m, struct FileTransfer *ft, TOX_FILE_CONTROL control)
{
    switch (control)
	{
        case TOX_FILE_CONTROL_RESUME:
            if (ft->state == FILE_TRANSFER_PENDING)
			{
                ft->state = FILE_TRANSFER_STARTED;
            }
			else if (ft->state == FILE_TRANSFER_PAUSED)
			{
                ft->state = FILE_TRANSFER_STARTED;
            }

            break;

        case TOX_FILE_CONTROL_PAUSE:
            ft->state = FILE_TRANSFER_PAUSED;
            break;

        case TOX_FILE_CONTROL_CANCEL:
            close_file_transfer(m, ft, -1);
            break;
    }
}


void on_file_control(Tox *m, uint32_t friendnumber, uint32_t filenumber, TOX_FILE_CONTROL control,
                     void *userdata)
{
    struct FileTransfer *ft = get_file_transfer_struct(friendnumber, filenumber);

    if (!ft)
    {
        return;
    }

    if (ft->file_type == TOX_FILE_KIND_AVATAR)
    {
        on_avatar_file_control(m, ft, control);
        return;
    }

    dbg(9, "on_file_control:002:file in/out\n");



	switch (control)
	{
		case TOX_FILE_CONTROL_RESUME:
		{
			dbg(9, "on_file_control:003:TOX_FILE_CONTROL_RESUME\n");

			ft->last_keep_alive = get_unix_time();

			/* transfer is accepted */
			if (ft->state == FILE_TRANSFER_PENDING)
			{
				ft->state = FILE_TRANSFER_STARTED;
				dbg(9, "on_file_control:004:pending -> started\n");
			}
			else if (ft->state == FILE_TRANSFER_PAUSED)
			{    /* transfer is resumed */
				ft->state = FILE_TRANSFER_STARTED;
				dbg(9, "on_file_control:005:paused -> started\n");
			}

			break;
		}

		case TOX_FILE_CONTROL_PAUSE:
		{
			dbg(9, "on_file_control:006:TOX_FILE_CONTROL_PAUSE\n");
			ft->state = FILE_TRANSFER_PAUSED;
			break;
		}

		case TOX_FILE_CONTROL_CANCEL:
		{
			dbg(1, "File transfer for '%s' was aborted\n", ft->file_name);
			close_file_transfer(m, ft, -1);
			break;
		}
	}

}



void on_avatar_chunk_request(Tox *m, struct FileTransfer *ft, uint64_t position, size_t length)
{
    dbg(9, "on_avatar_chunk_request:001\n");

    if (ft->state != FILE_TRANSFER_STARTED)
    {
        dbg(0, "on_avatar_chunk_request:001a:!FILE_TRANSFER_STARTED\n");
        return;
    }

    if (length == 0)
    {
        close_file_transfer(m, ft, -1);
        return;
    }

    if (ft->file == NULL)
	{
        close_file_transfer(m, ft, TOX_FILE_CONTROL_CANCEL);
        return;
    }

    if (ft->position != position)
	{
        if (fseek(ft->file, position, SEEK_SET) == -1)
		{
            close_file_transfer(m, ft, TOX_FILE_CONTROL_CANCEL);
            return;
        }

        ft->position = position;
    }

    uint8_t send_data[length];
    size_t send_length = fread(send_data, 1, sizeof(send_data), ft->file);

    if (send_length != length)
    {
        close_file_transfer(m, ft, TOX_FILE_CONTROL_CANCEL);
        return;
    }

    TOX_ERR_FILE_SEND_CHUNK err;
    tox_file_send_chunk(m, ft->friendnum, ft->filenum, position, send_data, send_length, &err);

    if (err != TOX_ERR_FILE_SEND_CHUNK_OK)
    {
        dbg(0, "tox_file_send_chunk failed in avatar callback (error %d)\n", err);
    }

    ft->position += send_length;
    ft->last_keep_alive = get_unix_time();
}


void self_connection_status_cb(Tox *tox, TOX_CONNECTION connection_status, void *user_data)
{
    switch (connection_status)
	{
        case TOX_CONNECTION_NONE:
            dbg(2, "Offline\n");
			my_connection_status = TOX_CONNECTION_NONE;
            break;
        case TOX_CONNECTION_TCP:
            dbg(2, "Online, using TCP\n");
			my_connection_status = TOX_CONNECTION_TCP;
            break;
        case TOX_CONNECTION_UDP:
            dbg(2, "Online, using UDP\n");
			my_connection_status = TOX_CONNECTION_UDP;
            break;
    }
}


static struct FileTransfer *new_file_sender(uint32_t friendnum, uint32_t filenum, uint8_t type)
{
    size_t i;

    dbg(9, "new_file_sender:001 friendnum=%d filenum=%d type=%d\n", (int)friendnum, (int) filenum, (int) type);
	int friendlistnum = find_friend_in_friendlist(friendnum);

    for (i = 0; i < MAX_FILES; ++i)
    {
        struct FileTransfer *ft = &Friends.list[friendlistnum].file_sender[i];
        dbg(9, "new_file_sender:002 i=%d\n", (int)i);

        if (ft->state == FILE_TRANSFER_INACTIVE)
        {
			dbg(9, "new_file_sender:003:reusing sender i=%d\n", (int)i);

            memset(ft, 0, sizeof(struct FileTransfer));
			// ft->state = FILE_TRANSFER_INACTIVE; // == 0

            ft->index = i;
            ft->friendnum = friendnum;
            ft->filenum = filenum;
            ft->file_type = type;
            ft->last_keep_alive = get_unix_time();
            ft->state = FILE_TRANSFER_PENDING;
            ft->direction = FILE_TRANSFER_SEND;

            dbg(9, "new_file_sender:003 i=%d\n", (int)i);

            return ft;
        }
    }

    return NULL;
}



static struct FileTransfer *new_file_receiver(uint32_t friendnum, uint32_t filenum, uint8_t type)
{
    size_t i;
	int friendlistnum = find_friend_in_friendlist(friendnum);

    for (i = 0; i < MAX_FILES; ++i)
    {
        struct FileTransfer *ft = &Friends.list[friendlistnum].file_receiver[i];

        if (ft->state == FILE_TRANSFER_INACTIVE) {
            memset(ft, 0, sizeof(struct FileTransfer));
			// ft->state = FILE_TRANSFER_INACTIVE; // == 0

            ft->index = i;
            ft->friendnum = friendnum;
            ft->filenum = filenum;
            ft->file_type = type;
            ft->last_keep_alive = get_unix_time();
            ft->state = FILE_TRANSFER_PENDING;
            ft->direction = FILE_TRANSFER_RECV;
            return ft;
        }
    }

    return NULL;
}


struct FileTransfer *new_file_transfer(uint32_t friendnum, uint32_t filenum,
                                       FILE_TRANSFER_DIRECTION direction, uint8_t type)
{
    if (direction == FILE_TRANSFER_RECV)
    {
        return new_file_receiver(friendnum, filenum, type);
    }

    if (direction == FILE_TRANSFER_SEND)
    {
        return new_file_sender(friendnum, filenum, type);
    }

    return NULL;
}


int avatar_send(Tox *m, uint32_t friendnum)
{
    dbg(2, "avatar_send:001 friendnum=%d\n", (int)friendnum);
    dbg(2, "avatar_send:002 %d %s %d\n", (int)Avatar.size, Avatar.name, (int)Avatar.name_len);

    TOX_ERR_FILE_SEND err;
    uint32_t filenum = tox_file_send(m, friendnum, TOX_FILE_KIND_AVATAR, (size_t) Avatar.size,
                                     NULL, (uint8_t *) Avatar.name, Avatar.name_len, &err);
	dbg(2, "avatar_send:tox_file_send=%s filenum=%d\n", (const char*)Avatar.name, (int)filenum);

    if (Avatar.size == 0)
    {
        return 0;
    }

    if (err != TOX_ERR_FILE_SEND_OK)
    {
        dbg(0, "avatar_send:tox_file_send failed for _friendnumber %d (error %d)\n", friendnum, err);
        return -1;
    }

	dbg(2, "avatar_send(1):tox_file_send=%s filenum=%d\n", (const char*)Avatar.name, (int)filenum);
    struct FileTransfer *ft = new_file_transfer(friendnum, filenum, FILE_TRANSFER_SEND, TOX_FILE_KIND_AVATAR);
	dbg(2, "avatar_send(2):tox_file_send=%s filenum=%d\n", (const char*)Avatar.name, (int)filenum);

    if (!ft)
    {
        dbg(0, "avatar_send:003:ft=NULL\n");
        return -1;
    }

    ft->file = fopen(Avatar.path, "r");

    if (ft->file == NULL)
    {
        dbg(0, "avatar_send:004:ft->file=NULL\n");
        return -1;
    }

    snprintf(ft->file_name, sizeof(ft->file_name), "%s", Avatar.name);
    ft->file_size = Avatar.size;

    return 0;
}


int check_file_signature(const char *signature, size_t size, FILE *fp)
{
    char buf[size];
    if (fread(buf, size, 1, fp) != 1)
    {
        return -1;
    }
    int ret = memcmp(signature, buf, size);
    if (fseek(fp, 0L, SEEK_SET) == -1)
    {
        return -1;
    }
    return ret == 0 ? 0 : 1;
}


void kill_all_file_transfers_friend(Tox *m, uint32_t friendnum)
{
    size_t i;
	int friendlistnum = find_friend_in_friendlist(friendnum);

    for (i = 0; i < MAX_FILES; ++i)
    {
        close_file_transfer(m, &Friends.list[friendlistnum].file_sender[i], TOX_FILE_CONTROL_CANCEL);
        close_file_transfer(m, &Friends.list[friendlistnum].file_receiver[i], TOX_FILE_CONTROL_CANCEL);
    }
}

void kill_all_file_transfers(Tox *m)
{
    size_t i;

    for (i = 0; i < Friends.max_idx; ++i)
    {
        kill_all_file_transfers_friend(m, Friends.list[i].num);
    }
}


int avatar_set(Tox *m, const char *path, size_t path_len)
{
    dbg(2, "avatar_set:001\n");

    if (path_len == 0 || path_len >= sizeof(Avatar.path))
    {
        return -1;
    }

    dbg(9, "avatar_set:002\n");
    FILE *fp = fopen(path, "rb");

    if (fp == NULL)
    {
        return -1;
    }

    char PNG_signature[8] = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};

    if (check_file_signature(PNG_signature, sizeof(PNG_signature), fp) != 0)
    {
        fclose(fp);
        return -1;
    }
    fclose(fp);

    dbg(9, "avatar_set:003\n");

    off_t size = file_size(path);

    if (size == 0 || size > MAX_AVATAR_FILE_SIZE)
    {
        return -1;
    }

    dbg(9, "avatar_set:004\n");

    get_file_name(Avatar.name, sizeof(Avatar.name), path);
    Avatar.name_len = strlen(Avatar.name);
    snprintf(Avatar.path, sizeof(Avatar.path), "%s", path);
    Avatar.path_len = path_len;
    Avatar.size = size;

    dbg(9, "avatar_set:099\n");

    return 0;
}

static void avatar_clear(void)
{
    memset(&Avatar, 0, sizeof(struct Avatar));
}

void avatar_unset(Tox *m)
{
    avatar_clear();
}

int check_number_of_files_to_resend_to_friend(Tox *m, uint32_t friendnum, int friendlistnum)
{
	int ret = 0;

	DIR *d;
	struct dirent *dir;
	// dbg(2, "checking friend subdir=%s\n", Friends.list[friendlistnum].worksubdir);

	d = opendir(Friends.list[friendlistnum].worksubdir);
	if (d)
	{
		while ((dir = readdir(d)) != NULL)
		{
			if (dir->d_type == DT_REG)
			{
				const char *ext = strrchr(dir->d_name,'.');
				if((!ext) || (ext == dir->d_name))
				{
						// wrong fileextension
				}
				else
				{
					if (strcmp(ext, motion_capture_file_extension) == 0)
					{
						// pictures
						if (get_file_transfer_from_filename_struct(friendnum, dir->d_name) == NULL)
						{
							ret++;
						}
					}
					else if (strcmp(ext, motion_capture_file_extension_mov) == 0)
					{
						// videos
						if (get_file_transfer_from_filename_struct(friendnum, dir->d_name) == NULL)
						{
							ret++;
						}
					}
				}
			}
		}

		closedir(d);
	}

	return ret;
}

void resend_zip_files_and_send(Tox *m, uint32_t friendnum, int friendlistnum)
{

		struct dirent **namelist;
		int n = 0;
		int i;

		dbg(0, "resend_zip_files_and_send:001\n");

		i = scandir(Friends.list[friendlistnum].worksubdir, &namelist, NULL, alphasort);
		if (i > 0)
		{
			struct tm *tm;
			time_t t;
			char str_datetime[100];
			t = time(NULL);
			tm = localtime(&t);

			strftime(str_datetime, sizeof(str_datetime), "%Y%m%d_%H_%M_%S", tm);
			char zipfilename[300];
			snprintf(zipfilename, sizeof(zipfilename), "%s/files_%s%s", Friends.list[friendlistnum].worksubdir, str_datetime, ".zip");

			dbg(0, "resend_zip_files_and_send:start_zipfile\n");
			start_zipfile(&Friends.list[friendlistnum].zip_archive, (size_t)(sizeof(Friends.list[friendlistnum].zip_archive)), zipfilename);

			while (n < i)
			{
				if (namelist[n]->d_type == DT_REG)
				{
					const char *ext = strrchr(namelist[n]->d_name,'.');
					if((!ext) || (ext == namelist[n]->d_name))
					{
							// wrong fileextension
					}
					else
					{
						if (strcmp(ext, motion_capture_file_extension) == 0)
						{
							// images only
							// dbg(9, "checking image:%s\n", namelist[n]->d_name);

							struct stat foo;
							time_t mtime;
							time_t time_now = time(NULL);

							char newname[300];
							snprintf(newname, sizeof(newname), "%s/%s", Friends.list[friendlistnum].worksubdir, namelist[n]->d_name);
							// dbg(9, "subdir=%s\n", newname);

							stat(newname, &foo);
							mtime = foo.st_mtime; /* seconds since the epoch */

							// see if we have reached max filetransfers
							if (has_reached_max_file_transfer_for_friend(friendnum) == 0)
							{
								// see if file is in use
								if ((mtime + seconds_since_last_mod) < time_now)
								{
									// now see if this file is somewhere in outgoing ft
									if (get_file_transfer_from_filename_struct(friendnum, namelist[n]->d_name) == NULL)
									{
										dbg(2, "add file %s to zipfile %s\n", namelist[n]->d_name, zipfilename);
										//char cwd[2048];
										//getcwd(cwd, sizeof(cwd));
										//chdir(Friends.list[friendlistnum].worksubdir);
										add_file_to_zipfile(&Friends.list[friendlistnum].zip_archive, newname, namelist[n]->d_name);
										//chdir(cwd);
										unlink(newname);
									}
								}
								else
								{
									// dbg(9, "new image:%s (still in use ...)\n", namelist[n]->d_name);
								}

							}
						}
						else if (strcmp(ext, motion_capture_file_extension_mov) == 0)
						{
							// avi videos only
							// dbg(9, "checking video:%s\n", namelist[n]->d_name);

							struct stat foo;
							time_t mtime;
							time_t time_now = time(NULL);

							char newname[300];
							snprintf(newname, sizeof(newname), "%s/%s", Friends.list[friendlistnum].worksubdir, namelist[n]->d_name);
							// dbg(9, "subdir=%s\n", newname);

							stat(newname, &foo);
							mtime = foo.st_mtime; /* seconds since the epoch */

							// see if we have reached max filetransfers
							if (has_reached_max_file_transfer_for_friend(friendnum) == 0)
							{
								// see if file is in use
								if ((mtime + seconds_since_last_mod) < time_now)
								{
									// now see if this file is somewhere in outgoing ft
									if (get_file_transfer_from_filename_struct(friendnum, namelist[n]->d_name) == NULL)
									{
										dbg(2, "add file %s to zipfile %s\n", newname, zipfilename);
										//char cwd[2048];
										//getcwd(cwd, sizeof(cwd));
										//chdir(Friends.list[friendlistnum].worksubdir);
										add_file_to_zipfile(&Friends.list[friendlistnum].zip_archive, newname, namelist[n]->d_name);
										//chdir(cwd);
										unlink(newname);
									}
								}
								else
								{
									// dbg(9, "new image:%s (still in use ...)\n", namelist[n]->d_name);
								}

							}
						}

					}
				}

				free(namelist[n]);
				++n;

			}

			dbg(0, "resend_zip_files_and_send:finish_zipfile\n");
			finish_zipfile(&Friends.list[friendlistnum].zip_archive);
			send_file_to_friend(m, friendnum, zipfilename);
			free(namelist);
		}
}

void process_friends_dir(Tox *m, uint32_t friendnum, int friendlistnum)
{
	int resend_files_once = 0;

	// now check if friend is online
	if (is_friend_online(m, friendnum) == 1)
	{

		int number_of_files_to_resend = check_number_of_files_to_resend_to_friend(m, friendnum, friendlistnum);
		if (number_of_files_to_resend > MAX_RESEND_FILE_BEFORE_ASK)
		{
			if ((time(NULL) - Friends.list[friendlistnum].auto_resend_start_time) < (time_t)AUTO_RESEND_SECONDS)
			{
				// ok keep sending until specified time runs out
				resend_files_once = 1;
			}
			else
			{
				// dbg(9, "number_of_files_to_resend > MAX_RESEND_FILE_BEFORE_ASK\n");

				if (Friends.list[friendlistnum].waiting_for_answer == 2)
				{
					dbg(9, "waiting_for_answer == 2\n");

					if ((Friends.list[friendlistnum].last_answer) && (strncmp(Friends.list[friendlistnum].last_answer, "y", 1) == 0))
					{
						dbg(9, "process_friends_dir:resend:got answer:y\n");

						Friends.list[friendlistnum].last_answer[0] = '\0';
						Friends.list[friendlistnum].waiting_for_answer = 0;
						Friends.list[friendlistnum].auto_resend_start_time = time(NULL);

						resend_files_once = 1;
					}
					else if ((Friends.list[friendlistnum].last_answer) && (strncmp(Friends.list[friendlistnum].last_answer, "n", 1) == 0))
					{
						Friends.list[friendlistnum].last_answer[0] = '\0';
						Friends.list[friendlistnum].waiting_for_answer = 0;
						resend_files_once = 0;

						dbg(9, "process_friends_dir:resend:got answer:*n*\n");

						// zip the files and then send zipfile to friend
						resend_zip_files_and_send(m, friendnum, friendlistnum);
					}
					else
					{
						if (Friends.list[friendlistnum].last_answer)
						{
							dbg(9, "process_friends_dir:resend:ask again:waiting_for_answer=%d last_answer=%s\n", Friends.list[friendlistnum].waiting_for_answer, Friends.list[friendlistnum].last_answer);
						}
						else
						{
							dbg(9, "process_friends_dir:resend:ask again:waiting_for_answer=%d last_answer=NULL\n", Friends.list[friendlistnum].waiting_for_answer);
						}

						send_text_message_to_friend(m, friendnum, "resend %d files? [y/n]", number_of_files_to_resend);
						Friends.list[friendlistnum].last_answer[0] = '\0';
						Friends.list[friendlistnum].waiting_for_answer = 1; // set to "waiting for answer"
						return;
					}
				}
				else
				{
					if (Friends.list[friendlistnum].waiting_for_answer != 1)
					{
						if (Friends.list[friendlistnum].last_answer)
						{
							dbg(9, "process_friends_dir:resend:ask?:waiting_for_answer=%d last_answer=%s\n", Friends.list[friendlistnum].waiting_for_answer, Friends.list[friendlistnum].last_answer);
						}
						else
						{
							dbg(9, "process_friends_dir:resend:ask?:waiting_for_answer=%d last_answer=NULL\n", Friends.list[friendlistnum].waiting_for_answer);
						}
						send_text_message_to_friend(m, friendnum, "resend %d files? [y/n]", number_of_files_to_resend);
						Friends.list[friendlistnum].waiting_for_answer = 1; // set to "waiting for answer"
					}
					return;
				}
			}

			if (resend_files_once != 1)
			{
				return;
			}
		}
		else
		{
			resend_files_once = 1;
		}

		// dbg(9, "resending ...\n");


		struct dirent **namelist;
		int n = 0;
		int i;

		i = scandir(Friends.list[friendlistnum].worksubdir, &namelist, NULL, alphasort);
		if (i > 0)
		{
			while (n < i)
			{
				if (namelist[n]->d_type == DT_REG)
				{
					const char *ext = strrchr(namelist[n]->d_name,'.');
					if((!ext) || (ext == namelist[n]->d_name))
					{
							// wrong fileextension
					}
					else
					{
						if (strcmp(ext, motion_capture_file_extension) == 0)
						{
							// images only
							// dbg(9, "checking image:%s\n", namelist[n]->d_name);

							struct stat foo;
							time_t mtime;
							time_t time_now = time(NULL);

							char newname[300];
							snprintf(newname, sizeof(newname), "%s/%s", Friends.list[friendlistnum].worksubdir, namelist[n]->d_name);
							// dbg(9, "subdir=%s\n", newname);

							stat(newname, &foo);
							mtime = foo.st_mtime; /* seconds since the epoch */

							// see if we have reached max filetransfers
							if (has_reached_max_file_transfer_for_friend(friendnum) == 0)
							{
								// see if file is in use
								if ((mtime + seconds_since_last_mod) < time_now)
								{
									// now see if this file is somewhere in outgoing ft
									if (get_file_transfer_from_filename_struct(friendnum, namelist[n]->d_name) == NULL)
									{
										dbg(2, "resending file %s to friend %d\n", newname, friendnum);
										send_file_to_friend(m, friendnum, newname);
									}
								}
								else
								{
									// dbg(9, "new image:%s (still in use ...)\n", namelist[n]->d_name);
								}

							}
						}
						else if (strcmp(ext, file_extension_archive) == 0)
						{
							// zipfiles only
							// dbg(9, "checking zipfile:%s\n", namelist[n]->d_name);

							struct stat foo;
							time_t mtime;
							time_t time_now = time(NULL);

							char newname[300];
							snprintf(newname, sizeof(newname), "%s/%s", Friends.list[friendlistnum].worksubdir, namelist[n]->d_name);
							// dbg(9, "subdir=%s\n", newname);

							stat(newname, &foo);
							mtime = foo.st_mtime; /* seconds since the epoch */

							// see if we have reached max filetransfers
							if (has_reached_max_file_transfer_for_friend(friendnum) == 0)
							{
								// see if file is in use
								if ((mtime + seconds_since_last_mod) < time_now)
								{
									// now see if this file is somewhere in outgoing ft
									if (get_file_transfer_from_filename_struct(friendnum, namelist[n]->d_name) == NULL)
									{
										dbg(2, "resending file %s to friend %d\n", newname, friendnum);
										send_file_to_friend(m, friendnum, newname);
									}
								}
								else
								{
									// dbg(9, "new zipfile:%s (still in use ...)\n", namelist[n]->d_name);
								}

							}
						}
						else if (strcmp(ext, motion_capture_file_extension_mov) == 0)
						{
							// avi videos only
							// dbg(9, "checking video:%s\n", namelist[n]->d_name);

							struct stat foo;
							time_t mtime;
							time_t time_now = time(NULL);

							char newname[300];
							snprintf(newname, sizeof(newname), "%s/%s", Friends.list[friendlistnum].worksubdir, namelist[n]->d_name);
							// dbg(9, "subdir=%s\n", newname);

							stat(newname, &foo);
							mtime = foo.st_mtime; /* seconds since the epoch */

							// see if we have reached max filetransfers
							if (has_reached_max_file_transfer_for_friend(friendnum) == 0)
							{
								// see if file is in use
								if ((mtime + seconds_since_last_mod) < time_now)
								{
									// now see if this file is somewhere in outgoing ft
									if (get_file_transfer_from_filename_struct(friendnum, namelist[n]->d_name) == NULL)
									{
										dbg(2, "resending file %s to friend %d\n", newname, friendnum);
										send_file_to_friend(m, friendnum, newname);
									}
								}
								else
								{
									// dbg(9, "new image:%s (still in use ...)\n", namelist[n]->d_name);
								}

							}
						}

					}
				}

				free(namelist[n]);
				++n;

			}

			free(namelist);
		}
	}
}

void check_friends_dir(Tox *m)
{
    size_t i;
	// TODO
    size_t numfriends = tox_self_get_friend_list_size(m);
	int j = -1;

    for (i = 0; i < numfriends; ++i)
    {
        // dbg(2, "checking friend %d subdir\n", (int)i);

		j = find_friend_in_friendlist((uint32_t) i);
		if (j > -1)
		{
			process_friends_dir(m, i, j);
		}
	}
}


void check_dir(Tox *m)
{

	struct dirent **namelist;
	int n = 0;
	int i;

	i = scandir(motion_pics_dir, &namelist, NULL, alphasort);

	if (i > 0)
	{
		while (n < i)
		{
			if (namelist[n]->d_type == DT_REG)
			{
				const char *ext = strrchr(namelist[n]->d_name,'.');
				if((!ext) || (ext == namelist[n]->d_name))
				{
						// wrong fileextension
				}
				else
				{
					if(strcmp(ext, motion_capture_file_extension) == 0)
					{
						// dbg(9, "new image:%s\n", namelist[n]->d_name);

						// move file to work dir
						char oldname[300];
						snprintf(oldname, sizeof(oldname), "%s/%s", motion_pics_dir, namelist[n]->d_name);


						struct stat foo;
						time_t mtime;
						time_t time_now = time(NULL);

						stat(oldname, &foo);
						mtime = foo.st_mtime; /* seconds since the epoch */

						if ((mtime + seconds_since_last_mod) < time_now)
						{
								char newname[300];
								snprintf(newname, sizeof(newname), "%s/%s", motion_pics_work_dir, namelist[n]->d_name);

								dbg(2, "new image:%s\n", namelist[n]->d_name);
								dbg(2, "move %s -> %s\n", oldname, newname);
								int renname_err = rename(oldname, newname);
								dbg(2, "res=%d\n", renname_err);

								send_file_to_all_friends(m, newname, namelist[n]->d_name);
						}
						else
						{
								// dbg(9, "new image:%s (still in use ...)\n", namelist[n]->d_name);
						}
					}
					else if(strcmp(ext, motion_capture_file_extension_mov) == 0)
					{
						// dbg(9, "new image:%s\n", namelist[n]->d_name);

						// move file to work dir
						char oldname[300];
						snprintf(oldname, sizeof(oldname), "%s/%s", motion_pics_dir, namelist[n]->d_name);


						struct stat foo;
						time_t mtime;
						time_t time_now = time(NULL);

						stat(oldname, &foo);
						mtime = foo.st_mtime; /* seconds since the epoch */

						if ((mtime + seconds_since_last_mod) < time_now)
						{
								char newname[300];
								snprintf(newname, sizeof(newname), "%s/%s", motion_pics_work_dir, namelist[n]->d_name);

								dbg(2, "new movie:%s\n", namelist[n]->d_name);
								dbg(2, "move %s -> %s\n", oldname, newname);
								int renname_err = rename(oldname, newname);
								dbg(2, "res=%d\n", renname_err);

								send_file_to_all_friends(m, newname, namelist[n]->d_name);
						}
						else
						{
								// dbg(9, "new image:%s (still in use ...)\n", namelist[n]->d_name);
						}
					}
				}
			}

			free(namelist[n]);
			++n;
		}

		free(namelist);
	}
}

// ------------------- V4L2 stuff ---------------------
// ------------------- V4L2 stuff ---------------------
// ------------------- V4L2 stuff ---------------------


static int xioctl(int fh, unsigned long request, void *arg)
{
    int r;

    do
	{
        r = ioctl(fh, request, arg);
    } while (-1 == r && EINTR == errno);

    return r;
}



int init_cam()
{
	int fd;

	if ((fd = open(v4l2_device, O_RDWR)) < 0)
	{
		dbg(0, "error opening video device\n");
	}

	struct v4l2_capability cap;
	struct v4l2_cropcap    cropcap;
    // struct v4l2_crop       crop;

	if (ioctl(fd, VIDIOC_QUERYCAP, &cap) < 0)
	{
		dbg(0, "VIDIOC_QUERYCAP\n");
	}

	if (!(cap.capabilities & V4L2_CAP_VIDEO_CAPTURE))
	{
		dbg(0, "The device does not handle single-planar video capture.\n");
	}

	if (!(cap.capabilities & V4L2_CAP_STREAMING))
	{
		dbg(0, "The device does not support streaming i/o.\n");
	}


    /* Select video input, video standard and tune here. */
    CLEAR(cropcap);

    cropcap.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;

    if (0 == xioctl(fd, VIDIOC_CROPCAP, &cropcap))
	{
#if 0
        crop.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
        crop.c    = cropcap.defrect; /* reset to full area */
		/* Scale the width and height to 50 % of their original size and center the output. */
		crop.c.width = crop.c.width / 2;
		crop.c.height = crop.c.height / 2;
		crop.c.left = crop.c.left + crop.c.width / 2;
		crop.c.top = crop.c.top + crop.c.height / 2;

        if (-1 == xioctl(fd, VIDIOC_S_CROP, &crop))
		{
            switch (errno)
			{
                case EINVAL:
					dbg(0, "Cropping not supported (1)\n");
                    break;
                default:
					dbg(0, "some error on croping setup\n");
                    break;
            }
        }
#endif
    }
	else
	{
		dbg(0, "Cropping not supported (2)\n");
    }


#ifndef NO_V4LCONVERT
    v4lconvert_data = v4lconvert_create(fd);
#endif

    CLEAR(format);
    CLEAR(dest_format);

	format.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	format.fmt.pix.pixelformat = V4L2_PIX_FMT_YUV420;

	format.fmt.pix.width = 1920;
	format.fmt.pix.height = 1080;

	dest_format.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	dest_format.fmt.pix.pixelformat = V4L2_PIX_FMT_YUV420;

	dest_format.fmt.pix.width = format.fmt.pix.width;
	dest_format.fmt.pix.height = format.fmt.pix.height;

	// Get <-> Set ??
	if (-1 == xioctl(fd, VIDIOC_G_FMT, &format))
	{
		dbg(0, "VIDIOC_G_FMT\n");
	}

    video_width             = format.fmt.pix.width;
    video_height            = format.fmt.pix.height;
	dbg(2, "Video size(1): %u %u\n", video_width, video_height);

	format.fmt.pix.width = 1280;
	format.fmt.pix.height = 720;

	if (-1 == xioctl(fd, VIDIOC_S_FMT, &format))
	{
		dbg(0, "VIDIOC_S_FMT\n");
	}

	if (-1 == xioctl(fd, VIDIOC_G_FMT, &format))
	{
		dbg(0, "VIDIOC_G_FMT\n");
	}

    video_width             = format.fmt.pix.width;
    video_height            = format.fmt.pix.height;
	dbg(2, "Video size(2): %u %u\n", video_width, video_height);

	dest_format.fmt.pix.width = format.fmt.pix.width;
	dest_format.fmt.pix.height = format.fmt.pix.height;


    /* Buggy driver paranoia. */
/*
    min = fmt.fmt.pix.width * 2;
    if (fmt.fmt.pix.bytesperline < min)
        fmt.fmt.pix.bytesperline = min;
    min                          = fmt.fmt.pix.bytesperline * fmt.fmt.pix.height;
    if (fmt.fmt.pix.sizeimage < min)
        fmt.fmt.pix.sizeimage = min;
*/


	struct v4l2_requestbuffers bufrequest;

	CLEAR(bufrequest);

	bufrequest.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	bufrequest.memory = V4L2_MEMORY_MMAP;
	bufrequest.count = VIDEO_BUFFER_COUNT;

	dbg(0, "VIDIOC_REQBUFS want type=%d\n", (int)bufrequest.type);

    if (-1 == xioctl(fd, VIDIOC_REQBUFS, &bufrequest))
	{
        if (EINVAL == errno)
		{
            dbg(0, "%s does not support x i/o\n", v4l2_device);
        }
		else
		{
            dbg(0, "VIDIOC_REQBUFS error %d, %s\n", errno, strerror(errno));
        }
    }

	dbg(0, "VIDIOC_REQBUFS got type=%d\n", (int)bufrequest.type);

    if (bufrequest.count < 2)
	{
        dbg(0, "Insufficient buffer memory on %s\n", v4l2_device);
    }


	buffers = calloc(bufrequest.count, sizeof(*buffers));

	for (n_buffers = 0; n_buffers < bufrequest.count; ++n_buffers)
	{
		struct v4l2_buffer bufferinfo;

		CLEAR(bufferinfo);

		bufferinfo.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
		bufferinfo.memory = V4L2_MEMORY_MMAP;
		bufferinfo.index = n_buffers;

        if (-1 == xioctl(fd, VIDIOC_QUERYBUF, &bufferinfo))
		{
            dbg(9, "VIDIOC_QUERYBUF (2) error %d, %s\n", errno, strerror(errno));
        }

/*
		if (ioctl(fd, VIDIOC_QUERYBUF, &bufferinfo) < 0)
		{
			dbg(0, "VIDIOC_QUERYBUF %d %s\n", errno, strerror(errno));
		}
*/

        buffers[n_buffers].length = bufferinfo.length;
        buffers[n_buffers].start  = mmap(NULL /* start anywhere */, bufferinfo.length, PROT_READ | PROT_WRITE /* required */,
                                        MAP_SHARED /* recommended */, fd, bufferinfo.m.offset);

        if (MAP_FAILED == buffers[n_buffers].start)
		{
            dbg(0, "mmap error %d, %s\n", errno, strerror(errno));
        }

	}

	return fd;
}


int v4l_startread()
{
    dbg(9, "start cam\n");
    size_t i;
    enum v4l2_buf_type type;

    for (i = 0; i < n_buffers; ++i)
	{
		struct v4l2_buffer buf;

		dbg(9, "buffer (1) %d of %d\n", i, n_buffers);

        CLEAR(buf);
        buf.type   = V4L2_BUF_TYPE_VIDEO_CAPTURE;
        buf.memory = V4L2_MEMORY_MMAP;
        buf.index  = i;

        if (-1 == xioctl(global_cam_device_fd, VIDIOC_QBUF, &buf))
		{
            dbg(9, "VIDIOC_QBUF (3) error %d, %s\n", errno, strerror(errno));
            return 0;
        }
    }

    type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    if (-1 == xioctl(global_cam_device_fd, VIDIOC_STREAMON, &type))
	{
        dbg(9, "VIDIOC_STREAMON error %d, %s\n", errno, strerror(errno));
        return 0;
    }

    return 1;
}


int v4l_endread()
{
    dbg(9, "stop webcam\n");
    enum v4l2_buf_type type;
    type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    if (-1 == xioctl(global_cam_device_fd, VIDIOC_STREAMOFF, &type))
	{
        dbg(9, "VIDIOC_STREAMOFF error %d, %s\n", errno, strerror(errno));
        return 0;
    }

    return 1;
}


void yuv422to420(uint8_t *plane_y, uint8_t *plane_u, uint8_t *plane_v, uint8_t *input, uint16_t width, uint16_t height)
{
    uint8_t *end = input + width * height * 2;
    while (input != end)
	{
        uint8_t *line_end = input + width * 2;
        while (input != line_end)
		{
            *plane_y++ = *input++;
            *plane_v++ = *input++;
            *plane_y++ = *input++;
            *plane_u++ = *input++;
        }

        line_end = input + width * 2;
        while (input != line_end)
		{
            *plane_y++ = *input++;
            input++; // u
            *plane_y++ = *input++;
            input++; // v
        }
    }
}


int v4l_getframe(uint8_t *y, uint8_t *u, uint8_t *v, uint16_t width, uint16_t height)
{
    if (width != video_width || height != video_height)
	{
        dbg(9, "V4L:\twidth/height mismatch %u %u != %u %u\n", width, height, video_width, video_height);
        return 0;
    }

    struct v4l2_buffer buf;

    CLEAR(buf);

    buf.type   = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    buf.memory = V4L2_MEMORY_MMAP; // V4L2_MEMORY_USERPTR;

    if (-1 == ioctl(global_cam_device_fd, VIDIOC_DQBUF, &buf))
	{
        switch (errno)
		{
            case EINTR:
            case EAGAIN: return 0;

            case EIO:
            /* Could ignore EIO, see spec. */

            /* fall through */

            default: dbg(9, "VIDIOC_DQBUF error %d, %s\n", errno, strerror(errno)); return -1;

        }
    }

    /*for (i = 0; i < n_buffers; ++i)
        if (buf.m.userptr == (unsigned long)buffers[i].start
                && buf.length == buffers[i].length)
            break;

    if(i >= n_buffers) {
        dbg(9, "fatal error\n");
        return 0;
    }*/

	// dbg(9, "buf.index=%d\n", (int)buf.index);

    void *data = (void *)buffers[buf.index].start; // length = buf.bytesused //(void*)buf.m.userptr

/* assumes planes are continuous memory */
#ifndef NO_V4LCONVERT
    int result = v4lconvert_convert(v4lconvert_data, &format, &dest_format, data, buf.bytesused, y,
                                    (video_width * video_height * 3) / 2);

    if (result == -1)
	{
        dbg(0, "v4lconvert_convert error %s\n", v4lconvert_get_error_message(v4lconvert_data));
    }
#else
    if (format.fmt.pix.pixelformat == V4L2_PIX_FMT_YUYV)
	{
        yuv422to420(y, u, v, data, video_width, video_height);
    }
	else
	{
    }
#endif

    if (-1 == xioctl(global_cam_device_fd, VIDIOC_QBUF, &buf))
	{
        dbg(9, "VIDIOC_QBUF (1) error %d, %s\n", errno, strerror(errno));
    }

#ifndef NO_V4LCONVERT
    return (result == -1 ? 0 : 1);
#else
    return 1;
#endif
}


void close_cam()
{
#ifndef NO_V4LCONVERT
	v4lconvert_destroy(v4lconvert_data);
#endif

    size_t i;
    for (i = 0; i < n_buffers; ++i)
	{
        if (-1 == munmap(buffers[i].start, buffers[i].length))
		{
            dbg(9, "munmap error\n");
        }
    }

    close(global_cam_device_fd);
}

// ------------------- V4L2 stuff ---------------------
// ------------------- V4L2 stuff ---------------------
// ------------------- V4L2 stuff ---------------------



// ------------------ Tox AV stuff --------------------
// ------------------ Tox AV stuff --------------------
// ------------------ Tox AV stuff --------------------

static void t_toxav_call_cb(ToxAV *av, uint32_t friend_number, bool audio_enabled, bool video_enabled, void *user_data)
{
    dbg(9, "Handling CALL callback friendnum=%d audio_enabled=%d video_enabled=%d\n", (int)friend_number, (int)audio_enabled, (int)video_enabled);
    ((CallControl *)user_data)->incoming = true;
}

static void t_toxav_call_state_cb(ToxAV *av, uint32_t friend_number, uint32_t state, void *user_data)
{
    dbg(9, "Handling CALL STATE callback: %d friend_number=%d\n", state, (int)friend_number);
    ((CallControl *)user_data)->state = state;

	if (state & TOXAV_FRIEND_CALL_STATE_FINISHED)
	{
		dbg(9, "Call with friend %d finished\n", friend_number);
		global_video_active = 0;
		return;
	}
	else if (state & TOXAV_FRIEND_CALL_STATE_ERROR)
	{
		dbg(9, "Call with friend %d errored\n", friend_number);
		global_video_active = 0;
		return;
	}
	else if (state & TOXAV_FRIEND_CALL_STATE_SENDING_A)
	{
		dbg(9, "Call with friend state:TOXAV_FRIEND_CALL_STATE_SENDING_A\n");
	}
	else if (state & TOXAV_FRIEND_CALL_STATE_SENDING_V)
	{
		dbg(9, "Call with friend state:TOXAV_FRIEND_CALL_STATE_SENDING_V\n");
	}
	else if (state & TOXAV_FRIEND_CALL_STATE_ACCEPTING_A)
	{
		dbg(9, "Call with friend state:TOXAV_FRIEND_CALL_STATE_ACCEPTING_A\n");
	}
	else if (state & TOXAV_FRIEND_CALL_STATE_ACCEPTING_V)
	{
		dbg(9, "Call with friend state:TOXAV_FRIEND_CALL_STATE_ACCEPTING_V\n");
	}

	dbg(9, "t_toxav_call_state_cb:002\n");
	int send_audio = (state & TOXAV_FRIEND_CALL_STATE_SENDING_A) && (state & TOXAV_FRIEND_CALL_STATE_ACCEPTING_A);
	int send_video = state & TOXAV_FRIEND_CALL_STATE_SENDING_V && (state & TOXAV_FRIEND_CALL_STATE_ACCEPTING_V);
	dbg(9, "t_toxav_call_state_cb:002a send_audio=%d send_video=%d global_video_bit_rate=%d\n", send_audio, send_video, (int)global_video_bit_rate);
	TOXAV_ERR_BIT_RATE_SET bitrate_err = 0;
	toxav_bit_rate_set(av, friend_number, 0, send_video ? global_video_bit_rate : 0, &bitrate_err);
	dbg(9, "t_toxav_call_state_cb:004\n");

	if (bitrate_err)
	{
		dbg(9, "ToxAV:Error setting/changing video bitrate\n");
	}

	if (send_video == 1)
	{
		dbg(9, "t_toxav_call_state_cb:004\n");
		global_video_active = 1;
	}
	else
	{
		dbg(9, "t_toxav_call_state_cb:005\n");
		global_video_active = 0;
	}

	dbg(9, "Call state for friend %d changed to %d, audio=%d, video=%d\n", friend_number, state, send_audio, send_video);
}

static void t_toxav_bit_rate_status_cb(ToxAV *av, uint32_t friend_number,
                                       uint32_t audio_bit_rate, uint32_t video_bit_rate,
                                       void *user_data)
{
	dbg(0, "t_toxav_bit_rate_status_cb:001 video_bit_rate=%d\n", (int)video_bit_rate);

	((CallControl *)user_data)->video_bit_rate = video_bit_rate;
 
   /* Just accept what toxav wants the bitrate to be... */
	TOXAV_ERR_BIT_RATE_SET error = 0;
	toxav_bit_rate_set(av, friend_number, 0, video_bit_rate, &error);

	if (error)
	{
		dbg(0, "ToxAV:Setting new Video bitrate has failed with error #%u\n", error);
	}
	else
	{
		// global_audio_bit_rate = audio_bit_rate;
		if (video_bit_rate == -1)
		{
		}
		else
		{
			global_video_bit_rate = video_bit_rate;
		}
		dbg(0, "ToxAV:Video bitrate changed to %u\n", video_bit_rate);
	}

    dbg(2, "suggested bit rates: audio: %d video: %d\n", audio_bit_rate, video_bit_rate);
    dbg(2, "actual    bit rates: audio: %d video: %d\n", global_audio_bit_rate, global_video_bit_rate);

}


static void t_toxav_receive_audio_frame_cb(ToxAV *av, uint32_t friend_number,
        int16_t const *pcm,
        size_t sample_count,
        uint8_t channels,
        uint32_t sampling_rate,
        void *user_data)
{
    // CallControl *cc = (CallControl *)user_data;
    // frame *f = (frame *)malloc(sizeof(uint16_t) + sample_count * sizeof(int16_t) * channels);
    // memcpy(f->data, pcm, sample_count * sizeof(int16_t) * channels);
    // f->size = sample_count;

    // pthread_mutex_lock(cc->arb_mutex);
    // free(rb_write(cc->arb, f));
    // pthread_mutex_unlock(cc->arb_mutex);
}


static void t_toxav_receive_video_frame_cb(ToxAV *av, uint32_t friend_number,
        uint16_t width, uint16_t height,
        uint8_t const *y, uint8_t const *u, uint8_t const *v,
        int32_t ystride, int32_t ustride, int32_t vstride,
        void *user_data)
{
    // ystride = abs(ystride);
    // ustride = abs(ustride);
    // vstride = abs(vstride);

    // uint16_t *img_data = (uint16_t *)malloc(height * width * 6);

    // unsigned long int i, j;

    // for (i = 0; i < height; ++i)
	// {
        // for (j = 0; j < width; ++j)
		// {
            // uint8_t *point = (uint8_t *) img_data + 3 * ((i * width) + j);
            // int yx = y[(i * ystride) + j];
            // int ux = u[((i / 2) * ustride) + (j / 2)];
            // int vx = v[((i / 2) * vstride) + (j / 2)];

            // point[0] = YUV2R(yx, ux, vx);
            // point[1] = YUV2G(yx, ux, vx);
            // point[2] = YUV2B(yx, ux, vx);
        // }
    // }


    // CvMat mat = cvMat(height, width, CV_8UC3, img_data);

    // CvSize sz;
    // sz.height = height;
    // sz.width = width;

    // IplImage *header = cvCreateImageHeader(sz, 1, 3);
    // IplImage *img = cvGetImage(&mat, header);
    // cvShowImage(vdout, img);
    // free(img_data);
}

void set_av_video_frame()
{
    vpx_img_alloc(&input, VPX_IMG_FMT_I420, video_width, video_height, 1);
    av_video_frame.y = input.planes[0];
    av_video_frame.u = input.planes[1];
    av_video_frame.v = input.planes[2];
    av_video_frame.w = input.d_w;
    av_video_frame.h = input.d_h;

    dbg(2,"ToxVideo:av_video_frame set\n");
}

void *thread_av(void *data)
{
    ToxAV *av = (ToxAV *) data;
	pthread_t id = pthread_self();
	pthread_mutex_t av_thread_lock;

	if (pthread_mutex_init(&av_thread_lock, NULL) != 0)
	{
		dbg(0, "Error creating av_thread_lock\n");
	}
	else
	{
		dbg(2, "av_thread_lock created successfully\n");
	}

	dbg(2, "AV Thread #%d: starting\n", (int) id);

	if (video_call_enabled == 1)
	{
		global_cam_device_fd = init_cam();
		dbg(2, "AV Thread #%d: init cam\n", (int) id);

		set_av_video_frame();

		// start streaming
		v4l_startread();
	}

    while (true)
	{
		if (global_video_active == 1)
		{
			pthread_mutex_lock(&av_thread_lock);

			// dbg(9, "AV Thread #%d:get frame\n", (int) id);

            // capturing is enabled, capture frames
            int r = v4l_getframe(av_video_frame.y, av_video_frame.u, av_video_frame.v,
					av_video_frame.w, av_video_frame.h);

			if (r == 1)
			{
				// dbg(9, "AV Thread #%d:send frame to friend\n", (int) id);

				TOXAV_ERR_SEND_FRAME error = 0;
				toxav_video_send_frame(av, friend_to_send_video_to, av_video_frame.w, av_video_frame.h,
									   av_video_frame.y, av_video_frame.u, av_video_frame.v, &error);

				if (error)
				{
					if (error == TOXAV_ERR_SEND_FRAME_SYNC)
					{
						//debug_notice("uToxVideo:\tVid Frame sync error: w=%u h=%u\n", av_video_frame.w,
						//			 av_video_frame.h);
						dbg(0, "TOXAV_ERR_SEND_FRAME_SYNC\n");
					}
					else if (error == TOXAV_ERR_SEND_FRAME_PAYLOAD_TYPE_DISABLED)
					{
						//debug_error("uToxVideo:\tToxAV disagrees with our AV state for friend %lu, self %u, friend %u\n",
						//	i, friend[i].call_state_self, friend[i].call_state_friend);
						dbg(0, "TOXAV_ERR_SEND_FRAME_PAYLOAD_TYPE_DISABLED\n");
					}
					else
					{
						//debug_error("uToxVideo:\ttoxav_send_video error friend: %i error: %u\n",
						//			friend[i].number, error);
						dbg(0, "ToxVideo:toxav_send_video error %u\n", error);

						// *TODO* if these keep piling up --> just disconnect the call!!
						// *TODO* if these keep piling up --> just disconnect the call!!
						// *TODO* if these keep piling up --> just disconnect the call!!
					}
				}

            }
			else if (r == -1)
			{
                // debug_error("uToxVideo:\tErr... something really bad happened trying to get this frame, I'm just going "
                //            "to plots now!\n");
                //video_device_stop();
                //close_video_device(video_device);
				dbg(0, "ToxVideo:something really bad happened trying to get this frame\n");
            }

            pthread_mutex_unlock(&av_thread_lock);
			// yieldcpu(1000); // 1 frame every 1 seconds!!
            yieldcpu(DEFAULT_FPS_SLEEP_MS); /* ~6 frames per second */
            // yieldcpu(80); /* ~12 frames per second */
            // yieldcpu(40); /* 60fps = 16.666ms || 25 fps = 40ms || the data quality is SO much better at 25... */
            continue;     /* We're running video, so don't sleep for and extra 100 */
		}
		else
		{
			pthread_mutex_lock(&av_thread_lock);
			toxav_iterate(av);
			// dbg(9, "AV Thread #%d running ...\n", (int) id);
			pthread_mutex_unlock(&av_thread_lock);

		}

		// dbg(9, "AV Thread #%d:normal sleep\n", (int) id);

        usleep(toxav_iteration_interval(av) * 1000);
		yieldcpu(1000);
    }

	if (video_call_enabled == 1)
	{
		// end streaming
		v4l_endread();
	}


	// unreachable code
	dbg(2, "ToxVideo:Clean thread exit!\n");
}

void av_local_disconnect(ToxAV *av, uint32_t num)
{
	dbg(9, "av_local_disconnect\n");
    TOXAV_ERR_CALL_CONTROL error = 0;
    toxav_call_control(av, num, TOXAV_CALL_CONTROL_CANCEL, &error);
}



// ------------------ Tox AV stuff --------------------
// ------------------ Tox AV stuff --------------------
// ------------------ Tox AV stuff --------------------


void sigint_handler(int signo)
{
    if (signo == SIGINT)
    {
    	printf("received SIGINT, pid=%d\n", getpid());
    	tox_loop_running = 0;
    }
}

int main(int argc, char *argv[])
{
	global_want_restart = 0;
	global_video_active = 0;

	// valid audio bitrates: [ bit_rate < 6 || bit_rate > 510 ]
	global_audio_bit_rate = 0;
	global_video_bit_rate = DEFAULT_GLOBAL_VID_BITRATE;

    logfile = fopen(log_filename, "wb");
    setvbuf(logfile, NULL, _IONBF, 0);

	
	
	
	
	
  v4l2_device = malloc(400);
  snprintf(v4l2_device, 399, "%s", "/dev/video1");

  int aflag = 0;
  char *cvalue = NULL;
  int index;
  int opt;

   const char     *short_opt = "hvd:";
   struct option   long_opt[] =
   {
      {"help",          no_argument,       NULL, 'h'},
      {"version",       no_argument,       NULL, 'v'},
      {"videodevice",   required_argument, NULL, 'd'},
      {NULL,            0,                 NULL, 0  }
   };

  while((opt = getopt_long(argc, argv, short_opt, long_opt, NULL)) != -1)
  {
    switch (opt)
      {
      case -1:       /* no more arguments */
      case 0:        /* long options toggles */
        break;
      case 'a':
        aflag = 1;
        break;
      case 'd':
        snprintf(v4l2_device, 399, "%s", optarg);
        printf("Using Videodevice: %s\n", v4l2_device);
        dbg(3, "Using Videodevice: %s\n", v4l2_device);
        break;
      case 'v':
         printf("DoorSpy version: %s\n", global_version_string);
            if (logfile)
            {
                fclose(logfile);
                logfile = NULL;
            }
         return(0);
        break;

      case 'h':
         printf("Usage: %s [OPTIONS]\n", argv[0]);
         printf("  -v, --videodevice devicefile         file\n");
         printf("  -h, --help                           print this help and exit\n");
         printf("\n");
            if (logfile)
            {
                fclose(logfile);
                logfile = NULL;
            }
         return(0);

      case ':':
      case '?':
         fprintf(stderr, "Try `%s --help' for more information.\n", argv[0]);
            if (logfile)
            {
                fclose(logfile);
                logfile = NULL;
            }
         return(-2);

      default:
         fprintf(stderr, "%s: invalid option -- %c\n", argv[0], opt);
         fprintf(stderr, "Try `%s --help' for more information.\n", argv[0]);
            if (logfile)
            {
                fclose(logfile);
                logfile = NULL;
            }
         return(-2);
      }
  }


	Tox *tox = create_tox();
	global_start_time = time(NULL);

    // create motion-capture-dir of not already there
    mkdir(motion_pics_dir, S_IRWXU | S_IRWXG); // og+rwx

    // create workdir of not already there
    mkdir(motion_pics_work_dir, S_IRWXU | S_IRWXG); // og+rwx

    const char *name = "Door";
    tox_self_set_name(tox, (uint8_t *)name, strlen(name), NULL);

    const char *status_message = "This is your Door";
    tox_self_set_status_message(tox, (uint8_t *)status_message, strlen(status_message), NULL);

    Friends.max_idx = 0;

    bootstrap(tox);

    print_tox_id(tox);

    // init callbacks ----------------------------------
    tox_callback_friend_request(tox, friend_request_cb);
    tox_callback_friend_message(tox, friend_message_cb);
    tox_callback_friend_connection_status(tox, friendlist_onConnectionChange);
	tox_callback_friend_status(tox, on_tox_friend_status);

    tox_callback_self_connection_status(tox, self_connection_status_cb);

    tox_callback_file_chunk_request(tox, on_file_chunk_request);
    tox_callback_file_recv_control(tox, on_file_control);
    tox_callback_file_recv(tox, on_file_recv);
    tox_callback_file_recv_chunk(tox, on_file_recv_chunk);
    // init callbacks ----------------------------------


    update_savedata_file(tox);
    load_friendlist(tox);

    char path[300];
    snprintf(path, sizeof(path), "%s", my_avatar_filename);
    int len = strlen(path) - 1;
    avatar_set(tox, path, len);

	long long unsigned int cur_time = time(NULL);
	uint8_t off = 1;
	while (1)
	{
        tox_iterate(tox, NULL);
        usleep(tox_iteration_interval(tox) * 1000);
        if (tox_self_get_connection_status(tox) && off)
		{
            dbg(2, "Tox online, took %llu seconds\n", time(NULL) - cur_time);
            off = 0;
			break;
        }
        c_sleep(20);
    }


    TOXAV_ERR_NEW rc;
	dbg(2, "new Tox AV\n");
    mytox_av = toxav_new(tox, &rc);
	if (rc != TOXAV_ERR_NEW_OK)
	{
		dbg(0, "Error at toxav_new: %d\n", rc);
	}

	CallControl mytox_CC;
	memset(&mytox_CC, 0, sizeof(CallControl));

    // init AV callbacks -------------------------------
    toxav_callback_call(mytox_av, t_toxav_call_cb, &mytox_CC);
    toxav_callback_call_state(mytox_av, t_toxav_call_state_cb, &mytox_CC);
    toxav_callback_bit_rate_status(mytox_av, t_toxav_bit_rate_status_cb, &mytox_CC);
    toxav_callback_video_receive_frame(mytox_av, t_toxav_receive_video_frame_cb, &mytox_CC);
    toxav_callback_audio_receive_frame(mytox_av, t_toxav_receive_audio_frame_cb, &mytox_CC);
    // init AV callbacks -------------------------------


	// start toxav thread ------------------------------
	pthread_t tid[1];
    if (pthread_create(&(tid[0]), NULL, thread_av, (void *) mytox_av) != 0)
	{
        dbg(0, "AV Thread create failed\n");
	}
	else
	{
        dbg(2, "AV Thread successfully created\n");
	}

	// start toxav thread ------------------------------

    tox_loop_running = 1;
    signal(SIGINT, sigint_handler);
	
    while (tox_loop_running)
    {
        tox_iterate(tox, NULL);
        usleep(tox_iteration_interval(tox) * 1000);

		if (global_want_restart == 1)
		{
			// need to restart me!
			break;
		}
		else
		{
			check_dir(tox);
			check_friends_dir(tox);
		}
    }


    kill_all_file_transfers(tox);
	close_cam();
	toxav_kill(mytox_av);
    tox_kill(tox);

    if (logfile)
    {
        fclose(logfile);
        logfile = NULL;
    }

    return 0;
}
