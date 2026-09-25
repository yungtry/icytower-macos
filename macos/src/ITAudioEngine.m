#import "ITAudioEngine.h"

@implementation ITAudioSample
@end

@interface ITAudioEngine () <AVAudioPlayerDelegate>
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, AVAudioPlayer *> *activePlayers;
@property (nonatomic, assign) int64_t nextSampleId;
@end

@implementation ITAudioEngine

+ (instancetype)sharedEngine {
    static ITAudioEngine *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[ITAudioEngine alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _activePlayers = [[NSMutableDictionary alloc] init];
        _nextSampleId = 1;
    }
    return self;
}

- (nullable ITAudioSample *)loadSampleAtPath:(NSString *)path {
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data) {
        if ([path hasSuffix:@".ogg"]) {
            NSString *wavPath = [[path stringByDeletingPathExtension] stringByAppendingPathExtension:@"wav"];
            data = [NSData dataWithContentsOfFile:wavPath];
        }
    }
    if (!data) return nil;
    
    ITAudioSample *sample = [[ITAudioSample alloc] init];
    sample.audioData = data;
    sample.name = [path lastPathComponent];
    return sample;
}

- (nullable ITAudioSample *)loadSampleFromData:(NSData *)data ident:(NSString *)ident {
    if (!data || data.length == 0) return nil;
    ITAudioSample *sample = [[ITAudioSample alloc] init];
    sample.audioData = data;
    sample.name = ident ?: @"sample";
    return sample;
}

- (BOOL)playSample:(nullable ITAudioSample *)sample
              gain:(float)gain
               pan:(float)pan
             speed:(float)speed
              loop:(int)loop
          sampleId:(nullable ALLEGRO_SAMPLE_ID *)sampleId {
    if (!sample || !sample.audioData) return NO;
    
    NSError *error = nil;
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithData:sample.audioData error:&error];
    if (!player) {
        NSLog(@"Failed to create audio player for %@: %@", sample.name, error);
        return NO;
    }
    
    player.delegate = self;
    player.volume = fmaxf(0.0f, fminf(1.0f, gain));
    player.pan = fmaxf(-1.0f, fminf(1.0f, pan));
    player.enableRate = YES;
    player.rate = fmaxf(0.5f, fminf(2.0f, speed));
    player.numberOfLoops = (loop == ALLEGRO_PLAYMODE_LOOP) ? -1 : 0;
    
    [player prepareToPlay];
    [player play];
    
    @synchronized (self) {
        int64_t currentId = self.nextSampleId++;
        [self.activePlayers setObject:player forKey:@(currentId)];
        if (sampleId) {
            *sampleId = currentId;
        }
    }
    
    return YES;
}

- (void)stopSampleWithId:(ALLEGRO_SAMPLE_ID)sampleId {
    @synchronized (self) {
        AVAudioPlayer *player = [self.activePlayers objectForKey:@(sampleId)];
        if (player) {
            [player stop];
            [self.activePlayers removeObjectForKey:@(sampleId)];
        }
    }
}

- (void)setGain:(float)gain forSampleId:(ALLEGRO_SAMPLE_ID)sampleId {
    @synchronized (self) {
        AVAudioPlayer *player = [self.activePlayers objectForKey:@(sampleId)];
        if (player) {
            player.volume = fmaxf(0.0f, fminf(1.0f, gain));
        }
    }
}

- (void)stopAllSamples {
    @synchronized (self) {
        for (AVAudioPlayer *player in self.activePlayers.allValues) {
            [player stop];
        }
        [self.activePlayers removeAllObjects];
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    @synchronized (self) {
        NSNumber *foundKey = nil;
        for (NSNumber *key in self.activePlayers) {
            if ([self.activePlayers objectForKey:key] == player) {
                foundKey = key;
                break;
            }
        }
        if (foundKey) {
            [self.activePlayers removeObjectForKey:foundKey];
        }
    }
}

@end
