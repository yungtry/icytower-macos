#ifndef IT_ALLEGRO_H
#define IT_ALLEGRO_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <math.h>

#ifdef __cplusplus
extern "C" {
#endif

// Constants
#define ALLEGRO_PI 3.14159265358979323846
#define ALLEGRO_FLIP_HORIZONTAL 0x00001
#define ALLEGRO_FLIP_VERTICAL   0x00002

#define ALLEGRO_ALIGN_LEFT   0
#define ALLEGRO_ALIGN_CENTRE 1
#define ALLEGRO_ALIGN_CENTER 1
#define ALLEGRO_ALIGN_RIGHT  2

#define ALLEGRO_MEMORY_BITMAP 0x0001
#define ALLEGRO_PIXEL_FORMAT_ANY 0
#define ALLEGRO_LOCK_READWRITE 0

#define ALLEGRO_FILEMODE_ISFILE 1
#define ALLEGRO_FILEMODE_ISDIR  2
#define ALLEGRO_FOR_EACH_FS_ENTRY_OK 0
#define ALLEGRO_FOR_EACH_FS_ENTRY_ERROR -1

#define ALLEGRO_RESOURCES_PATH 1
#define ALLEGRO_USER_SETTINGS_PATH 2
#define ALLEGRO_NATIVE_PATH_SEP '/'

// Blender constants
enum {
    ALLEGRO_ADD = 0,
    ALLEGRO_ZERO = 0,
    ALLEGRO_ONE = 1,
    ALLEGRO_ALPHA = 2,
    ALLEGRO_INVERSE_ALPHA = 3
};

void al_set_blender(int op, int src, int dst);

// Allegro Keycodes
enum {
    ALLEGRO_KEY_A = 1,
    ALLEGRO_KEY_B, ALLEGRO_KEY_C, ALLEGRO_KEY_D, ALLEGRO_KEY_E, ALLEGRO_KEY_F,
    ALLEGRO_KEY_G, ALLEGRO_KEY_H, ALLEGRO_KEY_I, ALLEGRO_KEY_J, ALLEGRO_KEY_K,
    ALLEGRO_KEY_L, ALLEGRO_KEY_M, ALLEGRO_KEY_N, ALLEGRO_KEY_O, ALLEGRO_KEY_P,
    ALLEGRO_KEY_Q, ALLEGRO_KEY_R, ALLEGRO_KEY_S, ALLEGRO_KEY_T, ALLEGRO_KEY_U,
    ALLEGRO_KEY_V, ALLEGRO_KEY_W, ALLEGRO_KEY_X, ALLEGRO_KEY_Y, ALLEGRO_KEY_Z,
    ALLEGRO_KEY_0, ALLEGRO_KEY_1, ALLEGRO_KEY_2, ALLEGRO_KEY_3, ALLEGRO_KEY_4,
    ALLEGRO_KEY_5, ALLEGRO_KEY_6, ALLEGRO_KEY_7, ALLEGRO_KEY_8, ALLEGRO_KEY_9,
    ALLEGRO_KEY_PAD_0, ALLEGRO_KEY_PAD_1, ALLEGRO_KEY_PAD_2, ALLEGRO_KEY_PAD_3,
    ALLEGRO_KEY_PAD_4, ALLEGRO_KEY_PAD_5, ALLEGRO_KEY_PAD_6, ALLEGRO_KEY_PAD_7,
    ALLEGRO_KEY_PAD_8, ALLEGRO_KEY_PAD_9,
    ALLEGRO_KEY_F1, ALLEGRO_KEY_F2, ALLEGRO_KEY_F3, ALLEGRO_KEY_F4,
    ALLEGRO_KEY_F5, ALLEGRO_KEY_F6, ALLEGRO_KEY_F7, ALLEGRO_KEY_F8,
    ALLEGRO_KEY_F9, ALLEGRO_KEY_F10, ALLEGRO_KEY_F11, ALLEGRO_KEY_F12,
    ALLEGRO_KEY_ESCAPE, ALLEGRO_KEY_TILDE, ALLEGRO_KEY_MINUS, ALLEGRO_KEY_EQUALS,
    ALLEGRO_KEY_BACKSPACE, ALLEGRO_KEY_TAB, ALLEGRO_KEY_OPENBRACE, ALLEGRO_KEY_CLOSEBRACE,
    ALLEGRO_KEY_ENTER, ALLEGRO_KEY_SEMICOLON, ALLEGRO_KEY_QUOTE, ALLEGRO_KEY_BACKSLASH,
    ALLEGRO_KEY_BACKSLASH2, ALLEGRO_KEY_COMMA, ALLEGRO_KEY_FULLSTOP, ALLEGRO_KEY_SLASH,
    ALLEGRO_KEY_SPACE, ALLEGRO_KEY_INSERT, ALLEGRO_KEY_DELETE, ALLEGRO_KEY_HOME,
    ALLEGRO_KEY_END, ALLEGRO_KEY_PGUP, ALLEGRO_KEY_PGDN, ALLEGRO_KEY_LEFT,
    ALLEGRO_KEY_RIGHT, ALLEGRO_KEY_UP, ALLEGRO_KEY_DOWN,
    ALLEGRO_KEY_PAD_SLASH, ALLEGRO_KEY_PAD_ASTERISK, ALLEGRO_KEY_PAD_MINUS,
    ALLEGRO_KEY_PAD_PLUS, ALLEGRO_KEY_PAD_DELETE, ALLEGRO_KEY_PAD_ENTER,
    ALLEGRO_KEY_PRINTSCREEN, ALLEGRO_KEY_PAUSE,
    ALLEGRO_KEY_YEN, ALLEGRO_KEY_KANA,
    ALLEGRO_KEY_LSHIFT, ALLEGRO_KEY_RSHIFT,
    ALLEGRO_KEY_LCTRL, ALLEGRO_KEY_RCTRL,
    ALLEGRO_KEY_ALT, ALLEGRO_KEY_ALTGR,
    ALLEGRO_KEY_LWIN, ALLEGRO_KEY_RWIN,
    ALLEGRO_KEY_MENU, ALLEGRO_KEY_SCROLLLOCK,
    ALLEGRO_KEY_NUMLOCK, ALLEGRO_KEY_CAPSLOCK,
    ALLEGRO_KEY_COMMAND,
    ALLEGRO_KEY_MAX
};

enum {
    ALLEGRO_EVENT_KEY_DOWN = 10,
    ALLEGRO_EVENT_KEY_UP = 11,
    ALLEGRO_EVENT_KEY_CHAR = 12,
    ALLEGRO_EVENT_DISPLAY_CLOSE = 20,
    ALLEGRO_EVENT_DISPLAY_HALT_DRAWING = 21,
    ALLEGRO_EVENT_DISPLAY_RESUME_DRAWING = 22,
    ALLEGRO_EVENT_DISPLAY_SWITCH_OUT = 23,
    ALLEGRO_EVENT_DISPLAY_SWITCH_IN = 24,
    ALLEGRO_EVENT_TIMER = 30
};

typedef struct ALLEGRO_KEYBOARD_EVENT {
    int type;
    int keycode;
    int unichar;
} ALLEGRO_KEYBOARD_EVENT;

typedef struct ALLEGRO_EVENT {
    int type;
    ALLEGRO_KEYBOARD_EVENT keyboard;
} ALLEGRO_EVENT;

typedef struct ALLEGRO_EVENT_QUEUE ALLEGRO_EVENT_QUEUE;
typedef struct ALLEGRO_TIMER ALLEGRO_TIMER;
typedef struct ALLEGRO_THREAD ALLEGRO_THREAD;
typedef struct ALLEGRO_MUTEX ALLEGRO_MUTEX;
typedef struct ALLEGRO_COND ALLEGRO_COND;

// Types
typedef struct ALLEGRO_COLOR {
    float r, g, b, a;
} ALLEGRO_COLOR;

typedef struct ALLEGRO_BITMAP {
    int w, h;
    int flags;
    uint32_t *pixels;       // RGBA pixels for CPU access
    bool is_texture_dirty;  // upload needed to Metal
    void *metal_texture;    // id<MTLTexture>
} ALLEGRO_BITMAP;

typedef struct ALLEGRO_LOCKED_REGION {
    void *data;
    int format;
    int pitch;
    int pixel_size;
} ALLEGRO_LOCKED_REGION;

typedef struct ALLEGRO_CONFIG ALLEGRO_CONFIG;
typedef struct ALLEGRO_PATH ALLEGRO_PATH;
typedef struct ALLEGRO_FS_ENTRY ALLEGRO_FS_ENTRY;
typedef struct ALLEGRO_FILE ALLEGRO_FILE;

// Color Helpers
static inline ALLEGRO_COLOR al_map_rgba_f(float r, float g, float b, float a) {
    ALLEGRO_COLOR c = { r, g, b, a };
    return c;
}

static inline ALLEGRO_COLOR al_map_rgb_f(float r, float g, float b) {
    return al_map_rgba_f(r, g, b, 1.0f);
}

static inline ALLEGRO_COLOR al_map_rgba(unsigned char r, unsigned char g, unsigned char b, unsigned char a) {
    return al_map_rgba_f(r / 255.0f, g / 255.0f, b / 255.0f, a / 255.0f);
}

static inline ALLEGRO_COLOR al_map_rgb(unsigned char r, unsigned char g, unsigned char b) {
    return al_map_rgba(r, g, b, 255);
}

static inline void al_unmap_rgba(ALLEGRO_COLOR color, unsigned char *r, unsigned char *g, unsigned char *b, unsigned char *a) {
    if (r) *r = (unsigned char)roundf(color.r * 255.0f);
    if (g) *g = (unsigned char)roundf(color.g * 255.0f);
    if (b) *b = (unsigned char)roundf(color.b * 255.0f);
    if (a) *a = (unsigned char)roundf(color.a * 255.0f);
}

static inline void al_unmap_rgb(ALLEGRO_COLOR color, unsigned char *r, unsigned char *g, unsigned char *b) {
    al_unmap_rgba(color, r, g, b, NULL);
}

// Bitmap routines
ALLEGRO_BITMAP *al_create_bitmap(int w, int h);
void al_destroy_bitmap(ALLEGRO_BITMAP *bitmap);
int al_get_bitmap_width(ALLEGRO_BITMAP *bitmap);
int al_get_bitmap_height(ALLEGRO_BITMAP *bitmap);
int al_get_new_bitmap_flags(void);
void al_set_new_bitmap_flags(int flags);
void al_set_target_bitmap(ALLEGRO_BITMAP *bitmap);
ALLEGRO_BITMAP *al_get_target_bitmap(void);
void al_convert_bitmap(ALLEGRO_BITMAP *bitmap);
ALLEGRO_BITMAP *al_clone_bitmap(ALLEGRO_BITMAP *bitmap);
ALLEGRO_LOCKED_REGION *al_lock_bitmap(ALLEGRO_BITMAP *bitmap, int format, int flags);
void al_unlock_bitmap(ALLEGRO_BITMAP *bitmap);
ALLEGRO_COLOR al_get_pixel(ALLEGRO_BITMAP *bitmap, int x, int y);
void al_put_pixel(int x, int y, ALLEGRO_COLOR color);
void al_convert_mask_to_alpha(ALLEGRO_BITMAP *bitmap, ALLEGRO_COLOR mask_color);
ALLEGRO_BITMAP *al_load_bitmap_f(ALLEGRO_FILE *file, const char *ext);
ALLEGRO_BITMAP *al_load_bitmap(const char *filename);

// Drawing routines
void al_draw_bitmap(ALLEGRO_BITMAP *bitmap, float dx, float dy, int flags);
void al_draw_bitmap_region(ALLEGRO_BITMAP *bitmap, float sx, float sy, float sw, float sh, float dx, float dy, int flags);
void al_draw_scaled_bitmap(ALLEGRO_BITMAP *bitmap, float sx, float sy, float sw, float sh, float dx, float dy, float dw, float dh, int flags);
void al_draw_rotated_bitmap(ALLEGRO_BITMAP *bitmap, float cx, float cy, float dx, float dy, float angle, int flags);
void al_draw_scaled_rotated_bitmap(ALLEGRO_BITMAP *bitmap, float cx, float cy, float dx, float dy, float xscale, float yscale, float angle, int flags);
void al_clear_to_color(ALLEGRO_COLOR color);

// Fixed point helpers
typedef int32_t al_fixed;
#define al_fixtorad_r ((al_fixed)1608)
#define al_radtofix_r ((al_fixed)2670177)

static inline al_fixed al_itofix(int x) { return x << 16; }
static inline int al_fixtoi(al_fixed x) { return (x + 0x8000) >> 16; }
static inline al_fixed al_ftofix(double x) { return (al_fixed)(x * 65536.0); }
static inline double al_fixtof(al_fixed x) { return (double)x / 65536.0; }
static inline al_fixed al_fixmul(al_fixed x, al_fixed y) { return (al_fixed)(((int64_t)x * (int64_t)y) >> 16); }
static inline al_fixed al_fixcos(al_fixed x) { return al_ftofix(cos(al_fixtof(x) * 2.0 * ALLEGRO_PI / 256.0)); }
static inline al_fixed al_fixsin(al_fixed x) { return al_ftofix(sin(al_fixtof(x) * 2.0 * ALLEGRO_PI / 256.0)); }

// Config routines
ALLEGRO_CONFIG *al_load_config_file(const char *filename);
ALLEGRO_CONFIG *al_load_config_file_f(ALLEGRO_FILE *file);
bool al_save_config_file(const char *filename, const ALLEGRO_CONFIG *config);
void al_destroy_config(ALLEGRO_CONFIG *config);
ALLEGRO_CONFIG *al_create_config(void);
const char *al_get_config_value(const ALLEGRO_CONFIG *config, const char *section, const char *key);
void al_set_config_value(ALLEGRO_CONFIG *config, const char *section, const char *key, const char *value);

// Path / FS helpers
ALLEGRO_PATH *al_create_path(const char *str);
ALLEGRO_PATH *al_create_path_for_directory(const char *str);
void al_destroy_path(ALLEGRO_PATH *p);
ALLEGRO_PATH *al_clone_path(const ALLEGRO_PATH *p);
bool al_make_path_canonical(ALLEGRO_PATH *p);
int al_get_path_num_components(const ALLEGRO_PATH *p);
const char *al_get_path_component(const ALLEGRO_PATH *p, int i);
void al_remove_path_component(ALLEGRO_PATH *p, int i);
const char *al_path_cstr(const ALLEGRO_PATH *p, char delim);
const char *al_get_path_extension(const ALLEGRO_PATH *p);
void al_set_path_filename(ALLEGRO_PATH *p, const char *filename);
bool al_join_paths(ALLEGRO_PATH *p1, const ALLEGRO_PATH *p2);
bool al_append_path_component(ALLEGRO_PATH *p, const char *s);
ALLEGRO_PATH *al_get_standard_path(int id);
bool al_filename_exists(const char *path);
bool al_make_directory(const char *path);

ALLEGRO_FS_ENTRY *al_create_fs_entry(const char *path);
void al_destroy_fs_entry(ALLEGRO_FS_ENTRY *e);
uint32_t al_get_fs_entry_mode(ALLEGRO_FS_ENTRY *e);
const char *al_get_fs_entry_name(ALLEGRO_FS_ENTRY *e);
int al_for_each_fs_entry(ALLEGRO_FS_ENTRY *dir, int (*cb)(ALLEGRO_FS_ENTRY *entry, void *extra), void *extra);

ALLEGRO_FILE *al_fopen(const char *path, const char *mode);
void al_fclose(ALLEGRO_FILE *f);

// Event queue & timer stubs
static inline ALLEGRO_EVENT_QUEUE *al_create_event_queue(void) { return (ALLEGRO_EVENT_QUEUE *)1; }
static inline void al_destroy_event_queue(ALLEGRO_EVENT_QUEUE *q) {}
static inline ALLEGRO_TIMER *al_create_timer(double speed_secs) { return (ALLEGRO_TIMER *)1; }
static inline void al_destroy_timer(ALLEGRO_TIMER *t) {}
static inline void al_start_timer(ALLEGRO_TIMER *t) {}
static inline void al_stop_timer(ALLEGRO_TIMER *t) {}
static inline void al_wait_for_event(ALLEGRO_EVENT_QUEUE *queue, ALLEGRO_EVENT *ret_event) {}
static inline void al_clear_keyboard_state(void *display) {}
static inline void al_resume_timer(ALLEGRO_TIMER *timer) {}

#ifdef __cplusplus
}
#endif

#endif // IT_ALLEGRO_H
