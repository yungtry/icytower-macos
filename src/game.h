#pragma once

#include <allegro5/allegro.h>
#include <stdbool.h>

struct shared_state;

extern ALLEGRO_EVENT_QUEUE *g_event_queue;
extern ALLEGRO_TIMER *g_timer;

bool game_setup();
void update_frame(struct shared_state *shared_state);
void game_loop();
void game_cleanup();
