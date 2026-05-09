#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface YeepsOverlay : UIViewController
+ (void)show;
@end

#ifdef __cplusplus
extern "C" {
#endif

void YeepsPlaySound(NSString *filePath, float volume);
void YeepsStopSound(void);

#ifdef __cplusplus
}
#endif

// Mod flags
extern BOOL ModFly;
extern BOOL ModSpeed;
extern BOOL ModNoclip;
extern BOOL ModESP;
extern BOOL ModFreeCamera;
extern float ModFlySpeed;
extern float ModMoveSpeed;
