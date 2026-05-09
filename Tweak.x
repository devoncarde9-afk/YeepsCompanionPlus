#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>
#import "Overlay.h"

static id _playerNode = nil;
static BOOL _flyUpHeld = NO;
static BOOL _flyDownHeld = NO;
static float _flyY = 0.0f;

%hook SCNNode

- (void)setPosition:(SCNVector3)pos {
    NSString *name = self.name ?: @"";
    if ([name containsString:@"Player"] || [name containsString:@"player"] ||
        [name containsString:@"Character"] || [name containsString:@"Avatar"]) {
        _playerNode = self;

        if (ModFly) {
            if (_flyUpHeld)   _flyY += ModFlySpeed * 0.016f;
            if (_flyDownHeld) _flyY -= ModFlySpeed * 0.016f;
            SCNVector3 current = self.position;
            pos.y = current.y + _flyY;
            _flyY *= 0.85f;
        }

        if (ModSpeed) {
            SCNVector3 current = self.position;
            float dx = pos.x - current.x;
            float dz = pos.z - current.z;
            pos.x = current.x + dx * ModMoveSpeed;
            pos.z = current.z + dz * ModMoveSpeed;
        }
    }
    %orig(pos);
}

%end

%hook SCNView

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (ModFly && _playerNode) {
        UITouch *t = touches.anyObject;
        UIView *v = self;
        CGPoint p = [t locationInView:v];
        CGPoint prev = [t previousLocationInView:v];
        float dy = prev.y - p.y;
        if (fabsf(dy) > 2.0f) {
            SCNNode *node = (SCNNode *)_playerNode;
            SCNVector3 pos = node.position;
            pos.y += dy * 0.02f * ModFlySpeed;
            node.position = pos;
        }
    }
    %orig(touches, event);
}

%end

%hook SCNCamera

- (void)setFieldOfView:(CGFloat)fov {
    if (ModFreeCamera) {
        %orig(90);
    } else {
        %orig(fov);
    }
}

%end

%hook UIApplication

- (void)sendEvent:(UIEvent *)event {
    %orig(event);
    if (!ModFly) return;
    for (UITouch *t in event.allTouches) {
        UIView *v = t.view;
        if (!v) continue;
        if ([v isKindOfClass:[UIButton class]]) {
            UIButton *btn = (UIButton *)v;
            NSString *title = [btn titleForState:UIControlStateNormal];
            if ([title isEqualToString:@"↑"]) {
                _flyUpHeld = (t.phase == UITouchPhaseBegan || t.phase == UITouchPhaseMoved);
                if (t.phase == UITouchPhaseEnded) _flyUpHeld = NO;
            } else if ([title isEqualToString:@"↓"]) {
                _flyDownHeld = (t.phase == UITouchPhaseBegan || t.phase == UITouchPhaseMoved);
                if (t.phase == UITouchPhaseEnded) _flyDownHeld = NO;
            }
        }
    }
}

%end

%ctor {
    NSLog(@"[YeepsPlus] Loaded! Made by Angel");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [YeepsOverlay show];
    });
}
