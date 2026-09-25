#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSRect screenRect = [[NSScreen mainScreen] visibleFrame];
    NSRect windowRect = NSMakeRect(screenRect.origin.x + (screenRect.size.width - 640) * 0.5,
                                   screenRect.origin.y + (screenRect.size.height - 480) * 0.5,
                                   640, 480);
    
    self.window = [[NSWindow alloc] initWithContentRect:windowRect
                                              styleMask:(NSWindowStyleMaskTitled |
                                                         NSWindowStyleMaskClosable |
                                                         NSWindowStyleMaskMiniaturizable |
                                                         NSWindowStyleMaskResizable)
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    self.window.title = @"Icy Tower";
    self.window.delegate = self;
    self.window.minSize = NSMakeSize(320, 240);
    self.window.aspectRatio = NSMakeSize(4, 3);
    self.window.collectionBehavior = NSWindowCollectionBehaviorFullScreenPrimary;
    
    self.gameView = [[ITGameView alloc] initWithFrame:self.window.contentView.bounds
                                               device:MTLCreateSystemDefaultDevice()];
    self.gameView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.window.contentView = self.gameView;
    
    [self setupMainMenu];
    
    [self.window makeKeyAndOrderFront:nil];
    [self.window makeFirstResponder:self.gameView];
    
    [self.gameView start];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (void)setupMainMenu {
    NSMenu *mainMenu = [[NSMenu alloc] initWithTitle:@"MainMenu"];
    
    // Application (Apple) Menu
    NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"Icy Tower"];
    [appMenu addItemWithTitle:@"About Icy Tower" action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Hide Icy Tower" action:@selector(hide:) keyEquivalent:@"h"];
    NSMenuItem *hideOthers = [appMenu addItemWithTitle:@"Hide Others" action:@selector(hideOtherApplications:) keyEquivalent:@"h"];
    hideOthers.keyEquivalentModifierMask = NSEventModifierFlagOption | NSEventModifierFlagCommand;
    [appMenu addItemWithTitle:@"Show All" action:@selector(unhideAllApplications:) keyEquivalent:@""];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Quit Icy Tower" action:@selector(terminate:) keyEquivalent:@"q"];
    appMenuItem.submenu = appMenu;
    [mainMenu addItem:appMenuItem];
    
    // View Menu
    NSMenuItem *viewMenuItem = [[NSMenuItem alloc] init];
    NSMenu *viewMenu = [[NSMenu alloc] initWithTitle:@"View"];
    NSMenuItem *fsItem = [viewMenu addItemWithTitle:@"Toggle Full Screen" action:@selector(toggleFullScreen:) keyEquivalent:@"f"];
    fsItem.keyEquivalentModifierMask = NSEventModifierFlagControl | NSEventModifierFlagCommand;
    [viewMenu addItem:[NSMenuItem separatorItem]];
    [viewMenu addItemWithTitle:@"Actual Size (640×480)" action:@selector(setWindowScale1x:) keyEquivalent:@"1"];
    [viewMenu addItemWithTitle:@"2x Scale (1280×960)" action:@selector(setWindowScale2x:) keyEquivalent:@"2"];
    [viewMenu addItemWithTitle:@"3x Scale (1920×1440)" action:@selector(setWindowScale3x:) keyEquivalent:@"3"];
    viewMenuItem.submenu = viewMenu;
    [mainMenu addItem:viewMenuItem];
    
    // Debug Menu
    NSMenuItem *debugMenuItem = [[NSMenuItem alloc] init];
    NSMenu *debugMenu = [[NSMenu alloc] initWithTitle:@"Debug"];
    
    [debugMenu addItemWithTitle:@"Show FPS Counter" action:@selector(toggleShowFPS:) keyEquivalent:@"d"];
    [debugMenu addItemWithTitle:@"Show Frame Time" action:@selector(toggleShowFrameTime:) keyEquivalent:@""];
    [debugMenu addItemWithTitle:@"Show FPS in Title Bar" action:@selector(toggleShowFPSInTitle:) keyEquivalent:@""];
    [debugMenu addItem:[NSMenuItem separatorItem]];
    
    // FPS Position submenu
    NSMenuItem *posItem = [[NSMenuItem alloc] initWithTitle:@"FPS Position" action:nil keyEquivalent:@""];
    NSMenu *posMenu = [[NSMenu alloc] initWithTitle:@"FPS Position"];
    NSMenuItem *itemTR = [posMenu addItemWithTitle:@"Top-Right" action:@selector(setFPSPositionFromMenuItem:) keyEquivalent:@""];
    itemTR.tag = ITFPSPositionTopRight;
    NSMenuItem *itemTL = [posMenu addItemWithTitle:@"Top-Left" action:@selector(setFPSPositionFromMenuItem:) keyEquivalent:@""];
    itemTL.tag = ITFPSPositionTopLeft;
    NSMenuItem *itemBR = [posMenu addItemWithTitle:@"Bottom-Right" action:@selector(setFPSPositionFromMenuItem:) keyEquivalent:@""];
    itemBR.tag = ITFPSPositionBottomRight;
    NSMenuItem *itemBL = [posMenu addItemWithTitle:@"Bottom-Left" action:@selector(setFPSPositionFromMenuItem:) keyEquivalent:@""];
    itemBL.tag = ITFPSPositionBottomLeft;
    posItem.submenu = posMenu;
    [debugMenu addItem:posItem];
    
    [debugMenu addItem:[NSMenuItem separatorItem]];
    
    // Target Frame Rate submenu
    NSMenuItem *targetFPSItem = [[NSMenuItem alloc] initWithTitle:@"Target Frame Rate" action:nil keyEquivalent:@""];
    NSMenu *targetFPSMenu = [[NSMenu alloc] initWithTitle:@"Target Frame Rate"];
    NSMenuItem *fps60 = [targetFPSMenu addItemWithTitle:@"60 FPS" action:@selector(setTargetFPSFromMenuItem:) keyEquivalent:@""];
    fps60.tag = 60;
    NSMenuItem *fps120 = [targetFPSMenu addItemWithTitle:@"120 FPS (ProMotion)" action:@selector(setTargetFPSFromMenuItem:) keyEquivalent:@""];
    fps120.tag = 120;
    NSMenuItem *fpsMax = [targetFPSMenu addItemWithTitle:@"Display Maximum" action:@selector(setTargetFPSFromMenuItem:) keyEquivalent:@""];
    fpsMax.tag = 0;
    targetFPSItem.submenu = targetFPSMenu;
    [debugMenu addItem:targetFPSItem];
    
    debugMenuItem.submenu = debugMenu;
    [mainMenu addItem:debugMenuItem];
    
    // Window Menu
    NSMenuItem *windowMenuItem = [[NSMenuItem alloc] init];
    NSMenu *windowMenu = [[NSMenu alloc] initWithTitle:@"Window"];
    [windowMenu addItemWithTitle:@"Minimize" action:@selector(performMiniaturize:) keyEquivalent:@"m"];
    [windowMenu addItemWithTitle:@"Zoom" action:@selector(performZoom:) keyEquivalent:@""];
    [windowMenu addItem:[NSMenuItem separatorItem]];
    [windowMenu addItemWithTitle:@"Bring All to Front" action:@selector(arrangeInFront:) keyEquivalent:@""];
    windowMenuItem.submenu = windowMenu;
    [mainMenu addItem:windowMenuItem];
    [NSApp setWindowsMenu:windowMenu];
    
    [NSApp setMainMenu:mainMenu];
}

- (void)toggleShowFPS:(id)sender {
    [self.gameView toggleShowFPS];
}

- (void)toggleShowFrameTime:(id)sender {
    [self.gameView toggleShowFrameTime];
}

- (void)toggleShowFPSInTitle:(id)sender {
    [self.gameView toggleShowFPSInTitle];
}

- (void)setFPSPositionFromMenuItem:(NSMenuItem *)sender {
    self.gameView.fpsPosition = (ITFPSPosition)sender.tag;
}

- (void)setTargetFPSFromMenuItem:(NSMenuItem *)sender {
    [self.gameView setTargetFPS:sender.tag];
}

- (void)setWindowScale:(CGFloat)scale {
    CGFloat w = 640.0 * scale;
    CGFloat h = 480.0 * scale;
    NSRect curFrame = self.window.frame;
    NSRect contentRect = NSMakeRect(curFrame.origin.x, NSMaxY(curFrame) - h, w, h);
    NSRect newFrame = [self.window frameRectForContentRect:contentRect];
    [self.window setFrame:newFrame display:YES animate:YES];
}

- (void)setWindowScale1x:(id)sender {
    [self setWindowScale:1.0];
}

- (void)setWindowScale2x:(id)sender {
    [self setWindowScale:2.0];
}

- (void)setWindowScale3x:(id)sender {
    [self setWindowScale:3.0];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL action = menuItem.action;
    if (action == @selector(toggleShowFPS:)) {
        menuItem.state = self.gameView.showFPS ? NSControlStateValueOn : NSControlStateValueOff;
        return YES;
    }
    if (action == @selector(toggleShowFrameTime:)) {
        menuItem.state = self.gameView.showFrameTime ? NSControlStateValueOn : NSControlStateValueOff;
        menuItem.enabled = self.gameView.showFPS || self.gameView.showFPSInTitle;
        return YES;
    }
    if (action == @selector(toggleShowFPSInTitle:)) {
        menuItem.state = self.gameView.showFPSInTitle ? NSControlStateValueOn : NSControlStateValueOff;
        return YES;
    }
    if (action == @selector(setFPSPositionFromMenuItem:)) {
        menuItem.state = (self.gameView.fpsPosition == (ITFPSPosition)menuItem.tag) ? NSControlStateValueOn : NSControlStateValueOff;
        menuItem.enabled = self.gameView.showFPS;
        return YES;
    }
    if (action == @selector(setTargetFPSFromMenuItem:)) {
        menuItem.state = (self.gameView.preferredFramesPerSecond == menuItem.tag) ? NSControlStateValueOn : NSControlStateValueOff;
        return YES;
    }
    return YES;
}

@end
