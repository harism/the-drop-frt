#import "appdelegate.h"
#import <Cocoa/Cocoa.h>
#import "renderview.h"

@implementation AppDelegate
{
    NSWindow* _window;
    RenderView* _renderView;
}

-(id) init
{
    if (self = [super init])
    {
        CGRect contentSize = NSMakeRect(0, 0, 1920, 1080);
        NSUInteger windowStyleMask = NSWindowStyleMaskTitled |
                                     NSWindowStyleMaskClosable |
                                     NSWindowStyleMaskMiniaturizable |
                                     NSWindowStyleMaskResizable |
                                     NSWindowStyleMaskTexturedBackground;

        _window = [[NSWindow alloc] initWithContentRect:contentSize
                                     styleMask:windowStyleMask
                                     backing:NSBackingStoreBuffered
                                     defer:YES];
        _window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
        _window.contentAspectRatio = NSMakeSize(2, 1);
        _window.minSize = NSMakeSize(300, 150);
        _window.title = @"The Digi Bounce by Failright";
        _renderView = [[RenderView alloc] frameRect:contentSize];
    }
    return self;
}

-(void) dealloc
{
    [_window release];
    [_renderView release];
    [super dealloc];
}

-(void)applicationWillFinishLaunching:(NSNotification*)pNotification
{
    [[_window standardWindowButton:NSWindowZoomButton] setEnabled:NO];
    [_window setContentView:_renderView];
    [_window center];
}

-(void)applicationDidFinishLaunching:(NSNotification*)pNotification
{
    [_window makeKeyAndOrderFront:self];
}

-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)pSender
{
    return YES;
}

@end

