#import <UIKit/UIKit.h>

@interface YeepsOverlay : UIViewController
+ (void)show;
@end

// Mod state flags
extern BOOL ModFly;
extern BOOL ModSpeed;
extern BOOL ModNoclip;
extern BOOL ModESP;
extern BOOL ModFreeCamera;
extern float ModFlySpeed;
extern float ModMoveSpeed;
