#import "ITGameView.h"
#import "ITMetalRenderer.h"
#import "ITAudioEngine.h"

#include "allegro5/allegro.h"
#include "allegro5/allegro_primitives.h"
#include "allegro5/allegro_audio.h"

#include "game.h"
#include "gfx.h"
#include "sfx.h"
#include "fonts.h"
#include "background.h"
#include "keyboard.h"
#include "scene.h"
#include "shared_state.h"

#define MASK_COLOR al_map_rgb(154, 20, 146)

static bool convert_mask_to_alpha_cb(ALLEGRO_BITMAP *bitmap) {
    al_convert_mask_to_alpha(bitmap, MASK_COLOR);
    return true;
}

@interface ITGameView () {
    struct shared_state _sharedState;
    BOOL _initialized;
    NSTimeInterval _lastTime;
    NSTimeInterval _accumulator;
    
    // FPS tracking
    NSTimeInterval _lastFPSUpdateTime;
    NSUInteger _fpsFrameCount;
    double _currentFPS;
    double _currentFrameTime;
}
@end

@implementation ITGameView

- (instancetype)initWithFrame:(NSRect)frameRect device:(id<MTLDevice>)device {
    self = [super initWithFrame:frameRect device:device];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.device = MTLCreateSystemDefaultDevice();
    self.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    self.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
    self.delegate = self;
    
    // Load preferences from NSUserDefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _showFPS = [defaults boolForKey:@"ITDebugShowFPS"];
    _showFrameTime = [defaults boolForKey:@"ITDebugShowFrameTime"];
    _showFPSInTitle = [defaults boolForKey:@"ITDebugShowFPSInTitle"];
    _fpsPosition = (ITFPSPosition)[defaults integerForKey:@"ITDebugFPSPosition"];
    
    NSInteger targetFPS = [defaults integerForKey:@"ITDebugTargetFPS"];
    if (targetFPS == 0 && ![defaults objectForKey:@"ITDebugTargetFPS"]) {
        targetFPS = 60;
    }
    self.preferredFramesPerSecond = targetFPS;
    
    _lastFPSUpdateTime = [NSDate timeIntervalSinceReferenceDate];
    _currentFPS = 60.0;
    _currentFrameTime = 16.6;
    
    [[ITMetalRenderer sharedRenderer] setupWithDevice:self.device pixelFormat:self.colorPixelFormat];
}

- (double)currentFPS {
    return _currentFPS;
}

- (double)currentFrameTime {
    return _currentFrameTime;
}

- (void)setShowFPS:(BOOL)showFPS {
    _showFPS = showFPS;
    [[NSUserDefaults standardUserDefaults] setBool:showFPS forKey:@"ITDebugShowFPS"];
}

- (void)setShowFrameTime:(BOOL)showFrameTime {
    _showFrameTime = showFrameTime;
    [[NSUserDefaults standardUserDefaults] setBool:showFrameTime forKey:@"ITDebugShowFrameTime"];
}

- (void)setShowFPSInTitle:(BOOL)showFPSInTitle {
    _showFPSInTitle = showFPSInTitle;
    [[NSUserDefaults standardUserDefaults] setBool:showFPSInTitle forKey:@"ITDebugShowFPSInTitle"];
    if (!showFPSInTitle && self.window) {
        self.window.title = @"Icy Tower";
    }
}

- (void)setFpsPosition:(ITFPSPosition)fpsPosition {
    _fpsPosition = fpsPosition;
    [[NSUserDefaults standardUserDefaults] setInteger:fpsPosition forKey:@"ITDebugFPSPosition"];
}

- (void)setTargetFPS:(NSInteger)fps {
    self.preferredFramesPerSecond = fps;
    [[NSUserDefaults standardUserDefaults] setInteger:fps forKey:@"ITDebugTargetFPS"];
}

- (void)toggleShowFPS {
    self.showFPS = !self.showFPS;
}

- (void)toggleShowFrameTime {
    self.showFrameTime = !self.showFrameTime;
}

- (void)toggleShowFPSInTitle {
    self.showFPSInTitle = !self.showFPSInTitle;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)start {
    if (_initialized) return;
    
    // Initialize audio
    al_install_audio();
    
    // Core game setup (loads config, options, SFX)
    if (!game_setup()) {
        NSLog(@"game_setup() failed!");
    }
    
    // Load graphics assets
    if (!load_gfx_bitmaps("gfx")) {
        NSLog(@"load_gfx_bitmaps() failed!");
    }
    
    iterate_gfx_bitmaps(convert_mask_to_alpha_cb);
    
    // Load fonts and curved background
    if (!create_fonts()) {
        NSLog(@"create_fonts() failed!");
    }
    
    if (!create_background_bitmap()) {
        NSLog(@"create_background_bitmap() failed!");
    }
    
    al_set_target_bitmap(NULL);
    
    _initialized = YES;
    _lastTime = [NSDate timeIntervalSinceReferenceDate];
    _accumulator = 0.0;
}

- (int)allegroKeyForMacKeyCode:(unsigned short)keyCode {
    switch (keyCode) {
        case 0x00: return ALLEGRO_KEY_A;
        case 0x0B: return ALLEGRO_KEY_B;
        case 0x08: return ALLEGRO_KEY_C;
        case 0x02: return ALLEGRO_KEY_D;
        case 0x0E: return ALLEGRO_KEY_E;
        case 0x03: return ALLEGRO_KEY_F;
        case 0x05: return ALLEGRO_KEY_G;
        case 0x04: return ALLEGRO_KEY_H;
        case 0x22: return ALLEGRO_KEY_I;
        case 0x26: return ALLEGRO_KEY_J;
        case 0x28: return ALLEGRO_KEY_K;
        case 0x25: return ALLEGRO_KEY_L;
        case 0x2E: return ALLEGRO_KEY_M;
        case 0x2D: return ALLEGRO_KEY_N;
        case 0x1F: return ALLEGRO_KEY_O;
        case 0x23: return ALLEGRO_KEY_P;
        case 0x0C: return ALLEGRO_KEY_Q;
        case 0x0F: return ALLEGRO_KEY_R;
        case 0x01: return ALLEGRO_KEY_S;
        case 0x11: return ALLEGRO_KEY_T;
        case 0x20: return ALLEGRO_KEY_U;
        case 0x09: return ALLEGRO_KEY_V;
        case 0x0D: return ALLEGRO_KEY_W;
        case 0x07: return ALLEGRO_KEY_X;
        case 0x10: return ALLEGRO_KEY_Y;
        case 0x06: return ALLEGRO_KEY_Z;
        case 0x1D: return ALLEGRO_KEY_0;
        case 0x12: return ALLEGRO_KEY_1;
        case 0x13: return ALLEGRO_KEY_2;
        case 0x14: return ALLEGRO_KEY_3;
        case 0x15: return ALLEGRO_KEY_4;
        case 0x17: return ALLEGRO_KEY_5;
        case 0x16: return ALLEGRO_KEY_6;
        case 0x1A: return ALLEGRO_KEY_7;
        case 0x1C: return ALLEGRO_KEY_8;
        case 0x19: return ALLEGRO_KEY_9;
        case 0x24: return ALLEGRO_KEY_ENTER;
        case 0x30: return ALLEGRO_KEY_TAB;
        case 0x31: return ALLEGRO_KEY_SPACE;
        case 0x33: return ALLEGRO_KEY_BACKSPACE;
        case 0x35: return ALLEGRO_KEY_ESCAPE;
        case 0x7B: return ALLEGRO_KEY_LEFT;
        case 0x7C: return ALLEGRO_KEY_RIGHT;
        case 0x7D: return ALLEGRO_KEY_DOWN;
        case 0x7E: return ALLEGRO_KEY_UP;
        default: return 0;
    }
}

- (void)keyDown:(NSEvent *)event {
    // If Command key is pressed, let macOS handle menu key equivalents (e.g. Cmd+D, Cmd+Q)
    if (event.modifierFlags & NSEventModifierFlagCommand) {
        [super keyDown:event];
        return;
    }
    
    // F3 shortcut (Mac keyCode 0x63) toggles FPS overlay
    if (event.keyCode == 0x63) {
        [self toggleShowFPS];
        return;
    }
    
    int key = [self allegroKeyForMacKeyCode:event.keyCode];
    if (key > 0) {
        ALLEGRO_KEYBOARD_EVENT ev = {
            .type = ALLEGRO_EVENT_KEY_DOWN,
            .keycode = key,
            .unichar = 0
        };
        handle_keyboard_event(&ev);
    } else {
        [super keyDown:event];
    }
}

- (void)keyUp:(NSEvent *)event {
    if (event.modifierFlags & NSEventModifierFlagCommand) {
        [super keyUp:event];
        return;
    }
    int key = [self allegroKeyForMacKeyCode:event.keyCode];
    if (key > 0) {
        ALLEGRO_KEYBOARD_EVENT ev = {
            .type = ALLEGRO_EVENT_KEY_UP,
            .keycode = key,
            .unichar = 0
        };
        handle_keyboard_event(&ev);
    } else {
        [super keyUp:event];
    }
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
}

- (void)drawInMTKView:(MTKView *)view {
    if (!_initialized) return;
    
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval dt = now - _lastTime;
    _lastTime = now;
    if (dt > 0.1) dt = 0.1; // clamp delta
    _accumulator += dt;
    
    const double tick = 1.0 / 50.0; // 50 Hz game physics tick
    while (_accumulator >= tick) {
        update_frame(&_sharedState);
        do_keyboard_tick();
        _accumulator -= tick;
    }
    
    // FPS tracking and window title update
    _fpsFrameCount++;
    NSTimeInterval fpsElapsed = now - _lastFPSUpdateTime;
    if (fpsElapsed >= 0.25) {
        _currentFPS = _fpsFrameCount / fpsElapsed;
        _currentFrameTime = (fpsElapsed / _fpsFrameCount) * 1000.0;
        _fpsFrameCount = 0;
        _lastFPSUpdateTime = now;
        
        if (_showFPSInTitle && self.window) {
            if (_showFrameTime) {
                self.window.title = [NSString stringWithFormat:@"Icy Tower - %.0f FPS (%.1f ms)", _currentFPS, _currentFrameTime];
            } else {
                self.window.title = [NSString stringWithFormat:@"Icy Tower - %.0f FPS", _currentFPS];
            }
        }
    }
    
    id<MTLCommandBuffer> cmdBuf = [[[ITMetalRenderer sharedRenderer] commandQueue] commandBuffer];
    MTLRenderPassDescriptor *rpd = view.currentRenderPassDescriptor;
    if (!rpd) return;
    
    [[ITMetalRenderer sharedRenderer] beginFrameWithCommandBuffer:cmdBuf
                                            renderPassDescriptor:rpd
                                                    drawableSize:view.drawableSize];
    
    al_set_target_bitmap(NULL);
    draw_scene(&_sharedState);
    
    // Render on-screen FPS Counter
    if (_showFPS && g_font1) {
        char fpsText[64];
        if (_showFrameTime) {
            snprintf(fpsText, sizeof(fpsText), "FPS: %.0f (%.1fms)", _currentFPS, _currentFrameTime);
        } else {
            snprintf(fpsText, sizeof(fpsText), "FPS: %.0f", _currentFPS);
        }
        
        int textW = al_get_text_width(g_font1, fpsText);
        int textH = al_get_font_line_height(g_font1);
        
        float padX = 6.0f;
        float padY = 4.0f;
        float boxW = textW + padX * 2.0f;
        float boxH = textH + padY * 2.0f;
        float posX = 0.0f;
        float posY = 0.0f;
        
        switch (_fpsPosition) {
            case ITFPSPositionTopLeft:
                posX = 8.0f;
                posY = 8.0f;
                break;
            case ITFPSPositionBottomLeft:
                posX = 8.0f;
                posY = 480.0f - boxH - 8.0f;
                break;
            case ITFPSPositionBottomRight:
                posX = 640.0f - boxW - 8.0f;
                posY = 480.0f - boxH - 8.0f;
                break;
            case ITFPSPositionTopRight:
            default:
                posX = 640.0f - boxW - 8.0f;
                posY = 8.0f;
                break;
        }
        
        // Draw background badge
        [[ITMetalRenderer sharedRenderer] drawFilledRectangleX1:posX
                                                            y1:posY
                                                            x2:posX + boxW
                                                            y2:posY + boxH
                                                         color:al_map_rgba(0, 0, 0, 180)];
        
        // Draw crisp border
        ALLEGRO_COLOR borderColor = al_map_rgba(255, 255, 255, 70);
        [[ITMetalRenderer sharedRenderer] drawLineX1:posX y1:posY x2:posX + boxW y2:posY color:borderColor thickness:1.0f];
        [[ITMetalRenderer sharedRenderer] drawLineX1:posX y1:posY + boxH x2:posX + boxW y2:posY + boxH color:borderColor thickness:1.0f];
        [[ITMetalRenderer sharedRenderer] drawLineX1:posX y1:posY x2:posX y2:posY + boxH color:borderColor thickness:1.0f];
        [[ITMetalRenderer sharedRenderer] drawLineX1:posX + boxW y1:posY x2:posX + boxW y2:posY + boxH color:borderColor thickness:1.0f];
        
        // Draw FPS text
        al_draw_text(g_font1, al_map_rgb(255, 255, 255), posX + padX, posY + padY, 0, fpsText);
    }
    
    [[ITMetalRenderer sharedRenderer] endFrame];
    
    id<CAMetalDrawable> drawable = view.currentDrawable;
    if (drawable) {
        [cmdBuf presentDrawable:drawable];
    }
    [cmdBuf commit];
}

@end
