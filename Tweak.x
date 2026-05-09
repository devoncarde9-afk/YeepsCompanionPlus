#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "Overlay.h"

// ─────────────────────────────────────────────────────
// Hook SceneKit / Unity position updates for fly mode
// ─────────────────────────────────────────────────────

static id _playerNode = nil;
static CGPoint _lastFlyTouch = CGPointZero;
static BOOL _flyUpHeld = NO;
static BOOL _flyDownHeld = NO;

// Hook SCNNode position to intercept player movement
%hook SCNNode

- (void)setPosition:(SCNVector3)pos {
    // Tag our player node by name
    NSString *name = self.name ?: @"";
    if ([name containsString:@"Player"] || [name containsString:@"player"] || 
        [name containsString:@"Character"] || [name containsString:@"Avatar"]) {
        _playerNode = self;
        
        if (ModFly) {
            // Allow Y-axis changes from fly controls but keep X/Z from game
            SCNVector3 current = self.position;
            static float flyY = 0;
            if (_flyUpHeld)   flyY += ModFlySpeed * 0.016f;
            if (_flyDownHeld) flyY -= ModFlySpeed * 0.016f;
            pos.y = current.y + flyY;
            flyY *= 0.85f; // damping
        }
        
        if (ModSpeed) {
            // Amplify horizontal movement
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

// ─────────────────────────────────────────────────────
// Hook SCNView to intercept touch for fly controls  
// ─────────────────────────────────────────────────────

%hook SCNView

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
    if (ModFly && _playerNode) {
        UITouch *t = touches.anyObject;
        CGPoint p = [t locationInView:self];
        // Swipe up/down to fly
        CGPoint prev = [t previousLocationInView:self];
        float dy = prev.y - p.y; // positive = swipe up
        if (fabsf(dy) > 2.0f) {
            if (SCNNode *node = (SCNNode*)_playerNode) {
                SCNVector3 pos = node.position;
                pos.y += dy * 0.02f * ModFlySpeed;
                node.position = pos;
            }
        }
    }
    %orig(touches, event);
}

%end

// ─────────────────────────────────────────────────────
// Hook camera for free cam
// ─────────────────────────────────────────────────────

%hook SCNCamera

- (void)setFieldOfView:(CGFloat)fov {
    if (ModFreeCamera) {
        %orig(90); // wider FOV in free cam
    } else {
        %orig(fov);
    }
}

%end

// ─────────────────────────────────────────────────────  
// Hook SCNRenderer for ESP (draw boxes over players)
// ─────────────────────────────────────────────────────

%hook SCNRenderer

- (void)renderAtTime:(NSTimeInterval)time {
    %orig(time);
    // ESP overlay is handled via SCNNode name labels shown above
}

%end

// ─────────────────────────────────────────────────────
// Hook UIApplication to catch button presses
// ─────────────────────────────────────────────────────

%hook UIApplication

- (void)sendEvent:(UIEvent*)event {
    %orig(event);
    
    if (!ModFly) return;
    
    for (UITouch *t in event.allTouches) {
        UIView *v = t.view;
        if (!v) continue;
        
        // Check if fly up/down buttons are pressed
        if ([v isKindOfClass:[UIButton class]]) {
            UIButton *btn = (UIButton*)v;
            NSString *title = [btn titleForState:UIControlStateNormal];
            if ([title isEqualToString:@"↑"]) {
                _flyUpHeld = (t.phase == UITouchPhaseBegan || t.phase == UITouchPhaseMoved);
                _flyDownHeld = NO;
            } else if ([title isEqualToString:@"↓"]) {
                _flyDownHeld = (t.phase == UITouchPhaseBegan || t.phase == UITouchPhaseMoved);
                _flyUpHeld = NO;
            }
        }
    }
}

%end

// ─────────────────────────────────────────────────────
// Init
// ─────────────────────────────────────────────────────

%ctor {
    NSLog(@"[YeepsPlus] Loaded! Made by Angel");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [YeepsOverlay show];
    });
}
