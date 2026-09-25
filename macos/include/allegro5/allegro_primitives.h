#ifndef IT_ALLEGRO_PRIMITIVES_H
#define IT_ALLEGRO_PRIMITIVES_H

#include "allegro.h"

#ifdef __cplusplus
extern "C" {
#endif

void al_draw_filled_rectangle(float x1, float y1, float x2, float y2, ALLEGRO_COLOR color);
void al_draw_line(float x1, float y1, float x2, float y2, ALLEGRO_COLOR color, float thickness);

#ifdef __cplusplus
}
#endif

#endif // IT_ALLEGRO_PRIMITIVES_H
