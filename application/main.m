#import <Cocoa/Cocoa.h>
#import "appdelegate.h"

int main(int arc, char** argv)
{
    AppDelegate* appDelegate = [[AppDelegate alloc] init];
    [NSApplication sharedApplication];
    [NSApp setDelegate:appDelegate];
    [appDelegate release];
    [NSApp run];
}
