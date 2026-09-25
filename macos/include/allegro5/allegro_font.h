#ifndef IT_ALLEGRO_FONT_H
#define IT_ALLEGRO_FONT_H

#include "allegro.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct ALLEGRO_FONT ALLEGRO_FONT;

ALLEGRO_FONT *al_grab_font_from_bitmap(ALLEGRO_BITMAP *bmp, int n_ranges, const int ranges[]);
void al_destroy_font(ALLEGRO_FONT *f);
void al_draw_text(const ALLEGRO_FONT *font, ALLEGRO_COLOR color, float x, float y, int flags, const char *text);
void al_draw_textf(const ALLEGRO_FONT *font, ALLEGRO_COLOR color, float x, float y, int flags, const char *format, ...);
int al_get_font_line_height(const ALLEGRO_FONT *f);
int al_get_text_width(const ALLEGRO_FONT *f, const char *str);

#ifdef __cplusplus
}
#endif

#endif // IT_ALLEGRO_FONT_H
