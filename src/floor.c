/*
 * Floor-related routines
 */

#include <allegro5/allegro.h>
#include <assert.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

#include "config.h"
#include "floor.h"

#define GAME    "game"
#define START_FLOOR "start_floor"
#define BEST_FLOOR  "best_floor"

int g_start_floor = -1;
int g_best_floor = -1;

struct floor g_floors[] = {
    {
        .left = "floor01.bmp",
        .mid = "floor02.bmp",
        .right = "floor03.bmp",
        .sign = "sign01.bmp",
    },
    {
        .left = "floor04.bmp",
        .mid = "floor05.bmp",
        .right = "floor06.bmp",
        .sign = "sign02.bmp",
    },
    {
        .left = "floor07.bmp",
        .mid = "floor08.bmp",
        .right = "floor09.bmp",
        .sign = "sign03.bmp",
    },
    {
        .left = "floor10.bmp",
        .mid = "floor11.bmp",
        .right = "floor12.bmp",
        .sign = "sign04.bmp",
    },
    {
        .left = "floor12a.bmp",
        .mid = "floor12b.bmp",
        .right = "floor12c.bmp",
        .sign = "sign04a.bmp",
    },
    {
        .left = "floor13.bmp",
        .mid = "floor14.bmp",
        .right = "floor15.bmp",
        .sign = "sign05.bmp",
    },
    {
        .left = "floor16.bmp",
        .mid = "floor17.bmp",
        .right = "floor18.bmp",
        .sign = "sign06.bmp",
    },
    {
        .left = "floor18a.bmp",
        .mid = "floor18b.bmp",
        .right = "floor18c.bmp",
        .sign = "sign06a.bmp",
    },
    {
        .left = "floor19.bmp",
        .mid = "floor20.bmp",
        .right = "floor21.bmp",
        .sign = "sign07.bmp",
    },
    {
        .left = "floor22.bmp",
        .mid = "floor23.bmp",
        .right = "floor24.bmp",
        .sign = "sign08.bmp",
    },
    {
        .left = "floor25.bmp",
        .mid = "floor26.bmp",
        .right = "floor27.bmp",
        .sign = "sign09.bmp",
    },
};

static bool read_best_floor_option() {
    const char *str = al_get_config_value(g_config, GAME, BEST_FLOOR);
    if (str != NULL) {
        int n = atoi(str);
        if (n >= 0 && n < NUM_FLOORS - 1)
            g_best_floor = n;
        else
            return false;
    } else {
        g_best_floor = 0;
    }
    return true;
}

static bool read_start_floor_option() {
    const char *str = al_get_config_value(g_config, GAME, START_FLOOR);
    if (str != NULL) {
        int n = atoi(str);
        if (n >= 0 && n <= g_best_floor)
            g_start_floor = n;
        else
            return false;
    } else {
        g_start_floor = 0;
    }
    return true;
}

bool read_floor_options() {
    return read_best_floor_option() && read_start_floor_option();
}

static void write_best_floor_option() {
    if (g_best_floor != -1) {
        char str[3];
        assert(g_best_floor >= 0 && g_best_floor < NUM_FLOORS - 1);
        assert(g_best_floor < 100);
        if (sprintf(str, "%d", g_best_floor) > 0)
            al_set_config_value(g_config, GAME, BEST_FLOOR, str);
    }
}

static void write_start_floor_option() {
    if (g_start_floor != -1) {
        char str[3];
        assert(g_start_floor >= 0 && g_start_floor <= g_best_floor);
        assert(g_start_floor < 100);
        if (sprintf(str, "%d", g_start_floor) > 0)
            al_set_config_value(g_config, GAME, START_FLOOR, str);
    }
}

void write_floor_options() {
    write_best_floor_option();
    write_start_floor_option();
}
