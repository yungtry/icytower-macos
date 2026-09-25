#ifndef IT_ALLEGRO_AUDIO_H
#define IT_ALLEGRO_AUDIO_H

#include "allegro.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct ALLEGRO_SAMPLE ALLEGRO_SAMPLE;
typedef int64_t ALLEGRO_SAMPLE_ID;
typedef struct ALLEGRO_SAMPLE_INSTANCE ALLEGRO_SAMPLE_INSTANCE;

enum {
    ALLEGRO_PLAYMODE_ONCE = 0x100,
    ALLEGRO_PLAYMODE_LOOP = 0x101,
    ALLEGRO_PLAYMODE_BIDIR = 0x102
};

ALLEGRO_SAMPLE *al_load_sample_f(ALLEGRO_FILE *fp, const char *ident);
void al_destroy_sample(ALLEGRO_SAMPLE *spl);
bool al_play_sample(ALLEGRO_SAMPLE *spl, float gain, float pan, float speed, int loop, ALLEGRO_SAMPLE_ID *ret_id);
void al_stop_sample(ALLEGRO_SAMPLE_ID *spl_id);
void al_stop_samples(void);
bool al_reserve_samples(int reserve_samples);
bool al_install_audio(void);
void al_uninstall_audio(void);

ALLEGRO_SAMPLE_INSTANCE *al_lock_sample_id(ALLEGRO_SAMPLE_ID *id);
void al_unlock_sample_id(ALLEGRO_SAMPLE_ID *id);
bool al_set_sample_instance_gain(ALLEGRO_SAMPLE_INSTANCE *instance, float val);

#ifdef __cplusplus
}
#endif

#endif // IT_ALLEGRO_AUDIO_H
