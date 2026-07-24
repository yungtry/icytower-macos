/*
 * Unlock-related routines
 */

#include <allegro5/allegro.h>
#include <allegro5/allegro_primitives.h>

#include "fonts.h"
#include "gfx.h"
#include "keyboard.h"
#include "music.h"
#include "scene.h"
#include "shared_state.h"
#include "sound.h"
#include "unlock.h"

/**
 * @brief Initialize the unlock scene
 */
void initialize_unlock() {
}

/**
 * @brief Finalize the unlock scene
 */
void finalize_unlock() {
    play_sound("aight.ogg", false, false, NULL);
}

/**
 * @brief Update the unlock scene one tick
 */
void update_unlock() {
    if (is_key_pressed(ALLEGRO_KEY_ESCAPE) || is_key_pressed(ALLEGRO_KEY_ENTER) || is_key_pressed(ALLEGRO_KEY_SPACE)) {
        stop_music();
        transition_scene(GAMEOVER_SCENE, 64);
    }
}

/**
 * @brief Draw the unlock scene
 */
void draw_unlock(const struct shared_state *shared_state) {
    ALLEGRO_BITMAP *title_bg = get_gfx_bitmap("title_bg.bmp");
    ALLEGRO_BITMAP *heroface = get_gfx_bitmap("heroface000.bmp");
    al_draw_bitmap(title_bg, 0, 0, 0);
    al_set_blender(ALLEGRO_ADD, ALLEGRO_ZERO, ALLEGRO_ALPHA);
    al_draw_filled_rectangle(0, 0, 640, 480, al_map_rgba(0, 0, 0, 100));
    al_set_blender(ALLEGRO_ADD, ALLEGRO_ONE, ALLEGRO_INVERSE_ALPHA);
    al_draw_bitmap(heroface, 320 - al_get_bitmap_width(heroface) / 2, 20, 0);
    al_draw_text(g_font1, al_map_rgb(255, 255, 255),
        320, 300, ALLEGRO_ALIGN_CENTER,
        "A new start floor");
    al_draw_text(g_font1, al_map_rgb(255, 255, 255),
        320, 350, ALLEGRO_ALIGN_CENTER,
        "has been unlocked!");
    al_draw_text(g_font2, al_map_rgb(255, 255, 255),
        320, 440, ALLEGRO_ALIGN_CENTER,
        "(Get it in the options menu)");
}
