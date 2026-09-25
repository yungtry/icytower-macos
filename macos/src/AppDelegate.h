#import <Cocoa/Cocoa.h>
#import "ITGameView.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, NSMenuItemValidation>

@property (nonatomic, strong) NSWindow *window;
@property (nonatomic, strong) ITGameView *gameView;

- (void)toggleShowFPS:(id)sender;
- (void)toggleShowFrameTime:(id)sender;
- (void)toggleShowFPSInTitle:(id)sender;
- (void)setFPSPositionFromMenuItem:(NSMenuItem *)sender;
- (void)setTargetFPSFromMenuItem:(NSMenuItem *)sender;

- (void)setWindowScale1x:(id)sender;
- (void)setWindowScale2x:(id)sender;
- (void)setWindowScale3x:(id)sender;

@end

NS_ASSUME_NONNULL_END
