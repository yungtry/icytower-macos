#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ITFPSPosition) {
    ITFPSPositionTopRight = 0,
    ITFPSPositionTopLeft,
    ITFPSPositionBottomRight,
    ITFPSPositionBottomLeft
};

@interface ITGameView : MTKView <MTKViewDelegate>

@property (nonatomic, assign) BOOL showFPS;
@property (nonatomic, assign) BOOL showFrameTime;
@property (nonatomic, assign) BOOL showFPSInTitle;
@property (nonatomic, assign) ITFPSPosition fpsPosition;
@property (nonatomic, readonly) double currentFPS;
@property (nonatomic, readonly) double currentFrameTime;

- (void)start;
- (void)toggleShowFPS;
- (void)toggleShowFrameTime;
- (void)toggleShowFPSInTitle;
- (void)setTargetFPS:(NSInteger)fps;

@end

NS_ASSUME_NONNULL_END
