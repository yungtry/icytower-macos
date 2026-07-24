#pragma once

#include <stdbool.h>

#define NUM_FLOORS  11

struct floor {
    const char *left;
    const char *mid;
    const char *right;
    const char *sign;
};

extern int g_start_floor;
extern int g_best_floor;

extern struct floor g_floors[NUM_FLOORS];

bool read_floor_options();
void write_floor_options();
