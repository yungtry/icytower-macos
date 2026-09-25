#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#include "allegro5/allegro.h"
#include "allegro5/allegro_audio.h"

NS_ASSUME_NONNULL_BEGIN

@interface ITAudioSample : NSObject
@property (nonatomic, strong) NSData *audioData;
@property (nonatomic, copy) NSString *name;
@end

@interface ITAudioEngine : NSObject

+ (instancetype)sharedEngine;

- (nullable ITAudioSample *)loadSampleAtPath:(NSString *)path;
- (nullable ITAudioSample *)loadSampleFromData:(NSData *)data ident:(NSString *)ident;

- (BOOL)playSample:(nullable ITAudioSample *)sample
              gain:(float)gain
               pan:(float)pan
             speed:(float)speed
              loop:(int)loop
          sampleId:(nullable ALLEGRO_SAMPLE_ID *)sampleId;

- (void)stopSampleWithId:(ALLEGRO_SAMPLE_ID)sampleId;
- (void)stopAllSamples;
- (void)setGain:(float)gain forSampleId:(ALLEGRO_SAMPLE_ID)sampleId;

@end

NS_ASSUME_NONNULL_END
