#import <Foundation/Foundation.h>
#import "ITMetalRenderer.h"
#import "ITAudioEngine.h"
#include "allegro5/allegro.h"
#include "allegro5/allegro_primitives.h"
#include "allegro5/allegro_font.h"
#include "allegro5/allegro_audio.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <dirent.h>

// Forward declarations
static ALLEGRO_BITMAP *g_target_bitmap = NULL;
static int g_new_bitmap_flags = 0;

void al_set_blender(int op, int src, int dst) {
    // Metal renderer handles default alpha blending
}

// ==========================================
// Config system (Simple INI parser)
// ==========================================
struct ConfigEntry {
    char *key;
    char *val;
    struct ConfigEntry *next;
};

struct ConfigSection {
    char *name;
    struct ConfigEntry *entries;
    struct ConfigSection *next;
};

struct ALLEGRO_CONFIG {
    struct ConfigSection *sections;
};

ALLEGRO_CONFIG *al_create_config(void) {
    ALLEGRO_CONFIG *cfg = (ALLEGRO_CONFIG *)calloc(1, sizeof(ALLEGRO_CONFIG));
    return cfg;
}

void al_destroy_config(ALLEGRO_CONFIG *config) {
    if (!config) return;
    struct ConfigSection *s = config->sections;
    while (s) {
        struct ConfigSection *s_next = s->next;
        struct ConfigEntry *e = s->entries;
        while (e) {
            struct ConfigEntry *e_next = e->next;
            free(e->key);
            free(e->val);
            free(e);
            e = e_next;
        }
        free(s->name);
        free(s);
        s = s_next;
    }
    free(config);
}

const char *al_get_config_value(const ALLEGRO_CONFIG *config, const char *section, const char *key) {
    if (!config || !key) return NULL;
    const char *sec_name = section ? section : "";
    for (struct ConfigSection *s = config->sections; s; s = s->next) {
        if (strcmp(s->name, sec_name) == 0) {
            for (struct ConfigEntry *e = s->entries; e; e = e->next) {
                if (strcmp(e->key, key) == 0) return e->val;
            }
        }
    }
    return NULL;
}

void al_set_config_value(ALLEGRO_CONFIG *config, const char *section, const char *key, const char *value) {
    if (!config || !key) return;
    const char *sec_name = section ? section : "";
    struct ConfigSection *target_sec = NULL;
    for (struct ConfigSection *s = config->sections; s; s = s->next) {
        if (strcmp(s->name, sec_name) == 0) {
            target_sec = s;
            break;
        }
    }
    if (!target_sec) {
        target_sec = (struct ConfigSection *)calloc(1, sizeof(struct ConfigSection));
        target_sec->name = strdup(sec_name);
        target_sec->next = config->sections;
        config->sections = target_sec;
    }
    for (struct ConfigEntry *e = target_sec->entries; e; e = e->next) {
        if (strcmp(e->key, key) == 0) {
            free(e->val);
            e->val = value ? strdup(value) : strdup("");
            return;
        }
    }
    struct ConfigEntry *entry = (struct ConfigEntry *)calloc(1, sizeof(struct ConfigEntry));
    entry->key = strdup(key);
    entry->val = value ? strdup(value) : strdup("");
    entry->next = target_sec->entries;
    target_sec->entries = entry;
}

ALLEGRO_CONFIG *al_load_config_file_f(ALLEGRO_FILE *file) {
    ALLEGRO_CONFIG *cfg = al_create_config();
    if (!file) return cfg;
    FILE *fp = (FILE *)file;
    char line[512];
    char current_sec[128] = "";
    while (fgets(line, sizeof(line), fp)) {
        char *p = line;
        while (*p == ' ' || *p == '\t') p++;
        if (*p == '#' || *p == ';' || *p == '\n' || *p == '\r' || *p == '\0') continue;
        if (*p == '[') {
            char *end = strchr(p, ']');
            if (end) {
                *end = '\0';
                strncpy(current_sec, p + 1, sizeof(current_sec) - 1);
            }
            continue;
        }
        char *eq = strchr(p, '=');
        if (eq) {
            *eq = '\0';
            char *k = p;
            char *v = eq + 1;
            char *k_end = k + strlen(k) - 1;
            while (k_end > k && (*k_end == ' ' || *k_end == '\t')) *k_end-- = '\0';
            while (*v == ' ' || *v == '\t') v++;
            char *v_end = v + strlen(v) - 1;
            while (v_end >= v && (*v_end == ' ' || *v_end == '\t' || *v_end == '\r' || *v_end == '\n')) *v_end-- = '\0';
            al_set_config_value(cfg, current_sec, k, v);
        }
    }
    return cfg;
}

ALLEGRO_CONFIG *al_load_config_file(const char *filename) {
    FILE *fp = fopen(filename, "r");
    if (!fp) return NULL;
    ALLEGRO_CONFIG *cfg = al_load_config_file_f((ALLEGRO_FILE *)fp);
    fclose(fp);
    return cfg;
}

bool al_save_config_file(const char *filename, const ALLEGRO_CONFIG *config) {
    if (!config || !filename) return false;
    FILE *fp = fopen(filename, "w");
    if (!fp) return false;
    for (struct ConfigSection *s = config->sections; s; s = s->next) {
        if (strlen(s->name) > 0) {
            fprintf(fp, "[%s]\n", s->name);
        }
        for (struct ConfigEntry *e = s->entries; e; e = e->next) {
            fprintf(fp, "%s=%s\n", e->key, e->val ? e->val : "");
        }
        fprintf(fp, "\n");
    }
    fclose(fp);
    return true;
}

// ==========================================
// Path and File Helpers
// ==========================================
struct ALLEGRO_PATH {
    char str[1024];
};

ALLEGRO_PATH *al_create_path(const char *str) {
    ALLEGRO_PATH *p = (ALLEGRO_PATH *)calloc(1, sizeof(ALLEGRO_PATH));
    if (str) strncpy(p->str, str, sizeof(p->str) - 1);
    return p;
}

ALLEGRO_PATH *al_create_path_for_directory(const char *str) {
    ALLEGRO_PATH *p = al_create_path(str);
    size_t len = strlen(p->str);
    if (len > 0 && p->str[len - 1] != '/') {
        if (len + 1 < sizeof(p->str)) {
            p->str[len] = '/';
            p->str[len + 1] = '\0';
        }
    }
    return p;
}

void al_destroy_path(ALLEGRO_PATH *p) {
    if (p) free(p);
}

ALLEGRO_PATH *al_clone_path(const ALLEGRO_PATH *p) {
    return p ? al_create_path(p->str) : NULL;
}

bool al_make_path_canonical(ALLEGRO_PATH *p) {
    return true;
}

int al_get_path_num_components(const ALLEGRO_PATH *p) {
    if (!p) return 0;
    int count = 0;
    const char *s = p->str;
    while (*s) {
        if (*s == '/') count++;
        s++;
    }
    return count;
}

const char *al_get_path_component(const ALLEGRO_PATH *p, int i) {
    static char comp[256];
    comp[0] = '\0';
    if (!p) return comp;
    const char *s = p->str;
    int cur = 0;
    while (*s) {
        if (*s == '/') {
            if (cur == i) return comp;
            cur++;
            comp[0] = '\0';
        } else {
            size_t l = strlen(comp);
            if (l + 1 < sizeof(comp)) {
                comp[l] = *s;
                comp[l + 1] = '\0';
            }
        }
        s++;
    }
    return comp;
}

void al_remove_path_component(ALLEGRO_PATH *p, int i) {
    if (!p) return;
    if (i == 0 && p->str[0] == '/') {
        memmove(p->str, p->str + 1, strlen(p->str) + 1);
    }
}

const char *al_path_cstr(const ALLEGRO_PATH *p, char delim) {
    return p ? p->str : "";
}

const char *al_get_path_extension(const ALLEGRO_PATH *p) {
    if (!p) return "";
    const char *dot = strrchr(p->str, '.');
    return dot ? dot : "";
}

void al_set_path_filename(ALLEGRO_PATH *p, const char *filename) {
    if (!p) return;
    char *last_slash = strrchr(p->str, '/');
    if (last_slash) {
        if (filename && strlen(filename) > 0) {
            *(last_slash + 1) = '\0';
            strncat(p->str, filename, sizeof(p->str) - strlen(p->str) - 1);
        } else {
            *last_slash = '\0';
        }
    }
}

bool al_join_paths(ALLEGRO_PATH *p1, const ALLEGRO_PATH *p2) {
    if (!p1 || !p2) return false;
    size_t l1 = strlen(p1->str);
    if (l1 > 0 && p1->str[l1 - 1] != '/' && p2->str[0] != '/') {
        strncat(p1->str, "/", sizeof(p1->str) - l1 - 1);
    }
    strncat(p1->str, p2->str, sizeof(p1->str) - strlen(p1->str) - 1);
    return true;
}

bool al_append_path_component(ALLEGRO_PATH *p, const char *s) {
    if (!p || !s) return false;
    size_t l = strlen(p->str);
    if (l > 0 && p->str[l - 1] != '/') {
        strncat(p->str, "/", sizeof(p->str) - l - 1);
    }
    strncat(p->str, s, sizeof(p->str) - strlen(p->str) - 1);
    return true;
}

ALLEGRO_PATH *al_get_standard_path(int id) {
    @autoreleasepool {
        if (id == ALLEGRO_RESOURCES_PATH) {
            NSString *res = [[NSBundle mainBundle] resourcePath];
            if (!res || [res isEqualToString:@""]) {
                res = @"/Users/kacperpowichrowski/Documents/GitHub/Xcode/icytower-ng/src/misc";
            }
            return al_create_path_for_directory([res UTF8String]);
        } else if (id == ALLEGRO_USER_SETTINGS_PATH) {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
            NSString *appSupport = [paths firstObject];
            NSString *appDir = [appSupport stringByAppendingPathComponent:@"IcyTower"];
            [[NSFileManager defaultManager] createDirectoryAtPath:appDir withIntermediateDirectories:YES attributes:nil error:nil];
            return al_create_path_for_directory([appDir UTF8String]);
        }
        return al_create_path("./");
    }
}

bool al_filename_exists(const char *path) {
    return access(path, F_OK) == 0;
}

bool al_make_directory(const char *path) {
    return mkdir(path, 0755) == 0;
}

// FS entries
struct ALLEGRO_FS_ENTRY {
    char path[1024];
    uint32_t mode;
};

ALLEGRO_FS_ENTRY *al_create_fs_entry(const char *path) {
    ALLEGRO_FS_ENTRY *e = (ALLEGRO_FS_ENTRY *)calloc(1, sizeof(ALLEGRO_FS_ENTRY));
    if (path) strncpy(e->path, path, sizeof(e->path) - 1);
    struct stat st;
    if (stat(e->path, &st) == 0) {
        if (S_ISDIR(st.st_mode)) e->mode = ALLEGRO_FILEMODE_ISDIR;
        else e->mode = ALLEGRO_FILEMODE_ISFILE;
    }
    return e;
}

void al_destroy_fs_entry(ALLEGRO_FS_ENTRY *e) {
    if (e) free(e);
}

uint32_t al_get_fs_entry_mode(ALLEGRO_FS_ENTRY *e) {
    return e ? e->mode : 0;
}

const char *al_get_fs_entry_name(ALLEGRO_FS_ENTRY *e) {
    return e ? e->path : "";
}

int al_for_each_fs_entry(ALLEGRO_FS_ENTRY *dir, int (*cb)(ALLEGRO_FS_ENTRY *entry, void *extra), void *extra) {
    if (!dir) return ALLEGRO_FOR_EACH_FS_ENTRY_ERROR;
    DIR *d = opendir(dir->path);
    if (!d) return ALLEGRO_FOR_EACH_FS_ENTRY_ERROR;
    struct dirent *de;
    size_t dir_len = strlen(dir->path);
    bool trailing_slash = (dir_len > 0 && dir->path[dir_len - 1] == '/');
    
    while ((de = readdir(d))) {
        if (strcmp(de->d_name, ".") == 0 || strcmp(de->d_name, "..") == 0) continue;
        char subpath[1024];
        if (trailing_slash) {
            snprintf(subpath, sizeof(subpath), "%s%s", dir->path, de->d_name);
        } else {
            snprintf(subpath, sizeof(subpath), "%s/%s", dir->path, de->d_name);
        }
        ALLEGRO_FS_ENTRY *entry = al_create_fs_entry(subpath);
        if (entry->mode == ALLEGRO_FILEMODE_ISDIR) {
            al_for_each_fs_entry(entry, cb, extra);
        } else {
            cb(entry, extra);
        }
        al_destroy_fs_entry(entry);
    }
    closedir(d);
    return ALLEGRO_FOR_EACH_FS_ENTRY_OK;
}

ALLEGRO_FILE *al_fopen(const char *path, const char *mode) {
    return (ALLEGRO_FILE *)fopen(path, mode);
}

void al_fclose(ALLEGRO_FILE *f) {
    if (f) fclose((FILE *)f);
}

// ==========================================
// Bitmap & Rendering Shim
// ==========================================
int al_get_new_bitmap_flags(void) {
    return g_new_bitmap_flags;
}

void al_set_new_bitmap_flags(int flags) {
    g_new_bitmap_flags = flags;
}

ALLEGRO_BITMAP *al_create_bitmap(int w, int h) {
    ALLEGRO_BITMAP *bmp = (ALLEGRO_BITMAP *)calloc(1, sizeof(ALLEGRO_BITMAP));
    bmp->w = w;
    bmp->h = h;
    bmp->flags = g_new_bitmap_flags;
    bmp->pixels = (uint32_t *)calloc(w * h, sizeof(uint32_t));
    bmp->is_texture_dirty = true;
    return bmp;
}

void al_destroy_bitmap(ALLEGRO_BITMAP *bitmap) {
    if (!bitmap) return;
    if (bitmap->metal_texture) {
        CFBridgingRelease(bitmap->metal_texture);
        bitmap->metal_texture = NULL;
    }
    if (bitmap->pixels) {
        free(bitmap->pixels);
        bitmap->pixels = NULL;
    }
    free(bitmap);
}

int al_get_bitmap_width(ALLEGRO_BITMAP *bitmap) {
    return bitmap ? bitmap->w : 0;
}

int al_get_bitmap_height(ALLEGRO_BITMAP *bitmap) {
    return bitmap ? bitmap->h : 0;
}

void al_set_target_bitmap(ALLEGRO_BITMAP *bitmap) {
    g_target_bitmap = bitmap;
}

ALLEGRO_BITMAP *al_get_target_bitmap(void) {
    return g_target_bitmap;
}

void al_convert_bitmap(ALLEGRO_BITMAP *bitmap) {
    if (bitmap) bitmap->is_texture_dirty = true;
}

ALLEGRO_BITMAP *al_clone_bitmap(ALLEGRO_BITMAP *bitmap) {
    if (!bitmap) return NULL;
    ALLEGRO_BITMAP *clone = al_create_bitmap(bitmap->w, bitmap->h);
    if (bitmap->pixels && clone->pixels) {
        memcpy(clone->pixels, bitmap->pixels, bitmap->w * bitmap->h * 4);
    }
    return clone;
}

ALLEGRO_LOCKED_REGION *al_lock_bitmap(ALLEGRO_BITMAP *bitmap, int format, int flags) {
    static ALLEGRO_LOCKED_REGION r;
    if (!bitmap) return NULL;
    r.data = bitmap->pixels;
    r.format = format;
    r.pitch = bitmap->w * 4;
    r.pixel_size = 4;
    return &r;
}

void al_unlock_bitmap(ALLEGRO_BITMAP *bitmap) {
    if (bitmap) bitmap->is_texture_dirty = true;
}

ALLEGRO_COLOR al_get_pixel(ALLEGRO_BITMAP *bitmap, int x, int y) {
    if (!bitmap || x < 0 || x >= bitmap->w || y < 0 || y >= bitmap->h) {
        return al_map_rgba_f(0, 0, 0, 0);
    }
    uint32_t px = bitmap->pixels[y * bitmap->w + x];
    float r = (px & 0xFF) / 255.0f;
    float g = ((px >> 8) & 0xFF) / 255.0f;
    float b = ((px >> 16) & 0xFF) / 255.0f;
    float a = ((px >> 24) & 0xFF) / 255.0f;
    return al_map_rgba_f(r, g, b, a);
}

void al_put_pixel(int x, int y, ALLEGRO_COLOR color) {
    ALLEGRO_BITMAP *bmp = g_target_bitmap;
    if (!bmp || x < 0 || x >= bmp->w || y < 0 || y >= bmp->h) return;
    unsigned char r, g, b, a;
    al_unmap_rgba(color, &r, &g, &b, &a);
    bmp->pixels[y * bmp->w + x] = (a << 24) | (b << 16) | (g << 8) | r;
    bmp->is_texture_dirty = true;
}

void al_convert_mask_to_alpha(ALLEGRO_BITMAP *bitmap, ALLEGRO_COLOR mask_color) {
    if (!bitmap || !bitmap->pixels) return;
    unsigned char mr, mg, mb;
    al_unmap_rgb(mask_color, &mr, &mg, &mb);
    int total = bitmap->w * bitmap->h;
    for (int i = 0; i < total; i++) {
        uint32_t px = bitmap->pixels[i];
        unsigned char r = px & 0xFF;
        unsigned char g = (px >> 8) & 0xFF;
        unsigned char b = (px >> 16) & 0xFF;
        if (r == mr && g == mg && b == mb) {
            bitmap->pixels[i] = (px & 0x00FFFFFF); // alpha = 0, keep RGB
        }
    }
    bitmap->is_texture_dirty = true;
}

// 8-bit BMP Loader
ALLEGRO_BITMAP *al_load_bitmap_f(ALLEGRO_FILE *file, const char *ext) {
    if (!file) return NULL;
    FILE *fp = (FILE *)file;
    uint8_t header[54];
    if (fread(header, 1, 54, fp) != 54) return NULL;
    if (header[0] != 'B' || header[1] != 'M') return NULL;
    
    uint32_t offset = *(uint32_t *)(header + 10);
    int32_t w = *(int32_t *)(header + 18);
    int32_t h = *(int32_t *)(header + 22);
    uint16_t bpp = *(uint16_t *)(header + 28);
    
    if (w <= 0 || h == 0) return NULL;
    bool top_down = h < 0;
    int abs_h = abs(h);
    
    ALLEGRO_BITMAP *bmp = al_create_bitmap(w, abs_h);
    
    if (bpp == 8) {
        uint8_t pal[1024];
        fseek(fp, 54, SEEK_SET);
        if (fread(pal, 1, 1024, fp) != 1024) {
            al_destroy_bitmap(bmp);
            return NULL;
        }
        
        fseek(fp, offset, SEEK_SET);
        int stride = ((w + 3) / 4) * 4;
        uint8_t *row = (uint8_t *)malloc(stride);
        
        for (int y = 0; y < abs_h; y++) {
            if (fread(row, 1, stride, fp) != (size_t)stride) break;
            int dest_y = top_down ? y : (abs_h - 1 - y);
            for (int x = 0; x < w; x++) {
                uint8_t idx = row[x];
                uint8_t b = pal[idx * 4 + 0];
                uint8_t g = pal[idx * 4 + 1];
                uint8_t r = pal[idx * 4 + 2];
                uint8_t a = 255;
                bmp->pixels[dest_y * w + x] = (a << 24) | (b << 16) | (g << 8) | r;
            }
        }
        free(row);
    }
    
    bmp->is_texture_dirty = true;
    return bmp;
}

ALLEGRO_BITMAP *al_load_bitmap(const char *filename) {
    FILE *fp = fopen(filename, "rb");
    if (!fp) return NULL;
    ALLEGRO_BITMAP *bmp = al_load_bitmap_f((ALLEGRO_FILE *)fp, ".bmp");
    fclose(fp);
    return bmp;
}

void al_draw_bitmap(ALLEGRO_BITMAP *bitmap, float dx, float dy, int flags) {
    if (g_target_bitmap && g_target_bitmap != bitmap) {
        if (!bitmap || !bitmap->pixels || !g_target_bitmap->pixels) return;
        int sw = bitmap->w;
        int sh = bitmap->h;
        for (int y = 0; y < sh; y++) {
            int ty = (int)dy + y;
            if (ty < 0 || ty >= g_target_bitmap->h) continue;
            for (int x = 0; x < sw; x++) {
                int tx = (int)dx + x;
                if (tx < 0 || tx >= g_target_bitmap->w) continue;
                uint32_t px = bitmap->pixels[y * sw + x];
                if ((px >> 24) != 0) {
                    g_target_bitmap->pixels[ty * g_target_bitmap->w + tx] = px;
                }
            }
        }
        g_target_bitmap->is_texture_dirty = true;
        return;
    }
    [[ITMetalRenderer sharedRenderer] drawBitmap:bitmap dx:dx dy:dy flags:flags];
}

void al_draw_bitmap_region(ALLEGRO_BITMAP *bitmap, float sx, float sy, float sw, float sh, float dx, float dy, int flags) {
    if (g_target_bitmap && g_target_bitmap != bitmap) {
        if (!bitmap || !bitmap->pixels || !g_target_bitmap->pixels) return;
        for (int y = 0; y < (int)sh; y++) {
            int sy_idx = (int)sy + y;
            int ty = (int)dy + y;
            if (sy_idx < 0 || sy_idx >= bitmap->h || ty < 0 || ty >= g_target_bitmap->h) continue;
            for (int x = 0; x < (int)sw; x++) {
                int sx_idx = (int)sx + x;
                int tx = (int)dx + x;
                if (sx_idx < 0 || sx_idx >= bitmap->w || tx < 0 || tx >= g_target_bitmap->w) continue;
                uint32_t px = bitmap->pixels[sy_idx * bitmap->w + sx_idx];
                if ((px >> 24) != 0) {
                    g_target_bitmap->pixels[ty * g_target_bitmap->w + tx] = px;
                }
            }
        }
        g_target_bitmap->is_texture_dirty = true;
        return;
    }
    [[ITMetalRenderer sharedRenderer] drawBitmapRegion:bitmap sx:sx sy:sy sw:sw sh:sh dx:dx dy:dy flags:flags];
}

void al_draw_scaled_bitmap(ALLEGRO_BITMAP *bitmap, float sx, float sy, float sw, float sh, float dx, float dy, float dw, float dh, int flags) {
    if (g_target_bitmap && g_target_bitmap != bitmap) {
        if (!bitmap || !bitmap->pixels || !g_target_bitmap->pixels || dw <= 0 || dh <= 0) return;
        for (int y = 0; y < (int)dh; y++) {
            int ty = (int)dy + y;
            if (ty < 0 || ty >= g_target_bitmap->h) continue;
            int src_y = (int)sy + (int)((float)y / dh * sh);
            if (src_y < 0 || src_y >= bitmap->h) continue;
            for (int x = 0; x < (int)dw; x++) {
                int tx = (int)dx + x;
                if (tx < 0 || tx >= g_target_bitmap->w) continue;
                int src_x = (int)sx + (int)((float)x / dw * sw);
                if (src_x < 0 || src_x >= bitmap->w) continue;
                uint32_t px = bitmap->pixels[src_y * bitmap->w + src_x];
                if ((px >> 24) != 0) {
                    g_target_bitmap->pixels[ty * g_target_bitmap->w + tx] = px;
                }
            }
        }
        g_target_bitmap->is_texture_dirty = true;
        return;
    }
    [[ITMetalRenderer sharedRenderer] drawScaledBitmap:bitmap sx:sx sy:sy sw:sw sh:sh dx:dx dy:dy dw:dw dh:dh flags:flags];
}

void al_draw_rotated_bitmap(ALLEGRO_BITMAP *bitmap, float cx, float cy, float dx, float dy, float angle, int flags) {
    [[ITMetalRenderer sharedRenderer] drawRotatedBitmap:bitmap cx:cx cy:cy dx:dx dy:dy angle:angle flags:flags];
}

void al_draw_scaled_rotated_bitmap(ALLEGRO_BITMAP *bitmap, float cx, float cy, float dx, float dy, float xscale, float yscale, float angle, int flags) {
    [[ITMetalRenderer sharedRenderer] drawScaledRotatedBitmap:bitmap cx:cx cy:cy dx:dx dy:dy xscale:xscale yscale:yscale angle:angle flags:flags];
}

void al_draw_filled_rectangle(float x1, float y1, float x2, float y2, ALLEGRO_COLOR color) {
    [[ITMetalRenderer sharedRenderer] drawFilledRectangleX1:x1 y1:y1 x2:x2 y2:y2 color:color];
}

void al_draw_line(float x1, float y1, float x2, float y2, ALLEGRO_COLOR color, float thickness) {
    [[ITMetalRenderer sharedRenderer] drawLineX1:x1 y1:y1 x2:x2 y2:y2 color:color thickness:thickness];
}

void al_clear_to_color(ALLEGRO_COLOR color) {
    if (g_target_bitmap && g_target_bitmap->pixels) {
        unsigned char r, g, b, a;
        al_unmap_rgba(color, &r, &g, &b, &a);
        uint32_t val = (a << 24) | (b << 16) | (g << 8) | r;
        int total = g_target_bitmap->w * g_target_bitmap->h;
        for (int i = 0; i < total; i++) {
            g_target_bitmap->pixels[i] = val;
        }
        g_target_bitmap->is_texture_dirty = true;
    } else {
        [[ITMetalRenderer sharedRenderer] drawFilledRectangleX1:0 y1:0 x2:640 y2:480 color:color];
    }
}

// ==========================================
// Font System
// ==========================================
struct Glyph {
    int x, y, w, h;
};

struct ALLEGRO_FONT {
    ALLEGRO_BITMAP *sheet;
    int line_height;
    int ranges[2];
    struct Glyph glyphs[128];
};

ALLEGRO_FONT *al_grab_font_from_bitmap(ALLEGRO_BITMAP *bmp, int n_ranges, const int ranges[]) {
    if (!bmp || !bmp->pixels) return NULL;
    ALLEGRO_FONT *font = (ALLEGRO_FONT *)calloc(1, sizeof(ALLEGRO_FONT));
    font->sheet = bmp;
    font->ranges[0] = ranges[0];
    font->ranges[1] = ranges[1];
    
    uint32_t bg = bmp->pixels[0] & 0x00FFFFFF;
    int w = bmp->w;
    int h = bmp->h;
    
    int y = 1;
    int glyph_idx = font->ranges[0];
    
    while (y < h && glyph_idx <= font->ranges[1]) {
        bool is_delim_line = true;
        for (int x = 0; x < w; x++) {
            if ((bmp->pixels[y * w + x] & 0x00FFFFFF) != bg) {
                is_delim_line = false;
                break;
            }
        }
        if (is_delim_line) {
            y++;
            continue;
        }
        
        int row_start_y = y;
        while (y < h) {
            bool row_delim = true;
            for (int x = 0; x < w; x++) {
                if ((bmp->pixels[y * w + x] & 0x00FFFFFF) != bg) {
                    row_delim = false;
                    break;
                }
            }
            if (row_delim) break;
            y++;
        }
        int row_h = y - row_start_y;
        if (font->line_height == 0) font->line_height = row_h;
        
        int x = 0;
        while (x < w && glyph_idx <= font->ranges[1]) {
            bool is_delim_col = true;
            for (int ry = row_start_y; ry < row_start_y + row_h; ry++) {
                if ((bmp->pixels[ry * w + x] & 0x00FFFFFF) != bg) {
                    is_delim_col = false;
                    break;
                }
            }
            if (is_delim_col) {
                x++;
                continue;
            }
            
            int col_start_x = x;
            while (x < w) {
                bool col_delim = true;
                for (int ry = row_start_y; ry < row_start_y + row_h; ry++) {
                    if ((bmp->pixels[ry * w + x] & 0x00FFFFFF) != bg) {
                        col_delim = false;
                        break;
                    }
                }
                if (col_delim) break;
                x++;
            }
            int col_w = x - col_start_x;
            if (glyph_idx < 128) {
                font->glyphs[glyph_idx].x = col_start_x;
                font->glyphs[glyph_idx].y = row_start_y;
                font->glyphs[glyph_idx].w = col_w;
                font->glyphs[glyph_idx].h = row_h;
            }
            glyph_idx++;
        }
    }
    
    // Convert delimiter pixels to transparent
    for (int i = 0; i < w * h; i++) {
        if ((bmp->pixels[i] & 0x00FFFFFF) == bg) {
            bmp->pixels[i] = 0;
        }
    }
    bmp->is_texture_dirty = true;
    return font;
}

void al_destroy_font(ALLEGRO_FONT *f) {
    if (f) free(f);
}

int al_get_font_line_height(const ALLEGRO_FONT *f) {
    return f ? f->line_height : 0;
}

int al_get_text_width(const ALLEGRO_FONT *f, const char *str) {
    if (!f || !str) return 0;
    int total_w = 0;
    while (*str) {
        unsigned char c = (unsigned char)*str++;
        if (c < 128) {
            total_w += f->glyphs[c].w;
        }
    }
    return total_w;
}

void al_draw_text(const ALLEGRO_FONT *font, ALLEGRO_COLOR color, float x, float y, int flags, const char *text) {
    if (!font || !text || !font->sheet) return;
    int str_w = al_get_text_width(font, text);
    float start_x = x;
    if (flags & ALLEGRO_ALIGN_CENTRE) {
        start_x = x - str_w * 0.5f;
    } else if (flags & ALLEGRO_ALIGN_RIGHT) {
        start_x = x - str_w;
    }
    
    float cur_x = start_x;
    const char *s = text;
    while (*s) {
        unsigned char c = (unsigned char)*s++;
        if (c < 128 && font->glyphs[c].w > 0) {
            struct Glyph g = font->glyphs[c];
            al_draw_bitmap_region(font->sheet, g.x, g.y, g.w, g.h, cur_x, y, 0);
            cur_x += g.w;
        }
    }
}

void al_draw_textf(const ALLEGRO_FONT *font, ALLEGRO_COLOR color, float x, float y, int flags, const char *format, ...) {
    char buf[1024];
    va_list args;
    va_start(args, format);
    vsnprintf(buf, sizeof(buf), format, args);
    va_end(args);
    al_draw_text(font, color, x, y, flags, buf);
}

// ==========================================
// Audio System Shim
// ==========================================
struct ALLEGRO_SAMPLE {
    ITAudioSample *sample;
};

struct ALLEGRO_SAMPLE_INSTANCE {
    ALLEGRO_SAMPLE_ID sample_id;
};

static struct ALLEGRO_SAMPLE_INSTANCE g_locked_instance;

ALLEGRO_SAMPLE *al_load_sample_f(ALLEGRO_FILE *fp, const char *ident) {
    if (!fp) return NULL;
    FILE *f = (FILE *)fp;
    fseek(f, 0, SEEK_END);
    long sz = ftell(f);
    fseek(f, 0, SEEK_SET);
    void *buf = malloc(sz);
    fread(buf, 1, sz, f);
    NSData *data = [NSData dataWithBytesNoCopy:buf length:sz freeWhenDone:YES];
    
    NSString *name = ident ? [NSString stringWithUTF8String:ident] : @"sample";
    ITAudioSample *spl = [[ITAudioEngine sharedEngine] loadSampleFromData:data ident:name];
    if (!spl) return NULL;
    
    ALLEGRO_SAMPLE *as = (ALLEGRO_SAMPLE *)calloc(1, sizeof(ALLEGRO_SAMPLE));
    as->sample = spl;
    return as;
}

void al_destroy_sample(ALLEGRO_SAMPLE *spl) {
    if (spl) free(spl);
}

bool al_play_sample(ALLEGRO_SAMPLE *spl, float gain, float pan, float speed, int loop, ALLEGRO_SAMPLE_ID *ret_id) {
    if (!spl || !spl->sample) return false;
    return [[ITAudioEngine sharedEngine] playSample:spl->sample gain:gain pan:pan speed:speed loop:loop sampleId:ret_id];
}

void al_stop_sample(ALLEGRO_SAMPLE_ID *spl_id) {
    if (spl_id) {
        [[ITAudioEngine sharedEngine] stopSampleWithId:*spl_id];
    }
}

void al_stop_samples(void) {
    [[ITAudioEngine sharedEngine] stopAllSamples];
}

bool al_reserve_samples(int reserve_samples) {
    return true;
}

bool al_install_audio(void) {
    [ITAudioEngine sharedEngine];
    return true;
}

void al_uninstall_audio(void) {
    [[ITAudioEngine sharedEngine] stopAllSamples];
}

ALLEGRO_SAMPLE_INSTANCE *al_lock_sample_id(ALLEGRO_SAMPLE_ID *id) {
    if (!id) return NULL;
    g_locked_instance.sample_id = *id;
    return &g_locked_instance;
}

void al_unlock_sample_id(ALLEGRO_SAMPLE_ID *id) {
}

bool al_set_sample_instance_gain(ALLEGRO_SAMPLE_INSTANCE *instance, float val) {
    if (!instance) return false;
    [[ITAudioEngine sharedEngine] setGain:val forSampleId:instance->sample_id];
    return true;
}
