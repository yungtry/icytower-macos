#pragma once

#include <stdbool.h>

#include "shared_state.h"

void initialize_unlock();
void finalize_unlock();
void update_unlock();
void draw_unlock(const struct shared_state *shared_state);
