#import "Overlay.h"
#import <UIKit/UIKit.h>

BOOL ModFly = NO;
BOOL ModSpeed = NO;
BOOL ModNoclip = NO;
BOOL ModESP = NO;
BOOL ModFreeCamera = NO;
float ModFlySpeed = 5.0f;
float ModMoveSpeed = 2.0f;

@interface YeepsOverlay ()
@property (nonatomic, strong) UIWindow *win;
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, strong) UIButton *fab;
@property (nonatomic, assign) BOOL expanded;
@property (nonatomic, strong) NSMutableArray *toggleButtons;
// Fly controls
@property (nonatomic, strong) UIButton *flyUp;
@property (nonatomic, strong) UIButton *flyDown;
@end

@implementation YeepsOverlay

+ (void)show {
    static YeepsOverlay *inst;
    if (inst) return;
    inst = [YeepsOverlay new];
    [inst setup];
}

- (void)setup {
    self.toggleButtons = [NSMutableArray new];
    self.expanded = NO;

    // Window
    self.win = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.win.windowLevel = UIWindowLevelAlert + 999;
    self.win.backgroundColor = [UIColor clearColor];
    self.win.hidden = NO;
    self.win.rootViewController = self;
    if (@available(iOS 13,*)) {
        for (UIWindowScene *s in UIApplication.sharedApplication.connectedScenes) {
            if ([s isKindOfClass:UIWindowScene.class]) {
                self.win.windowScene = (UIWindowScene*)s; break;
            }
        }
    }
    [self.win makeKeyAndVisible];

    [self buildFAB];
    [self buildPanel];
    [self buildFlyControls];
}

// ─── Colors ───────────────────────────────────────────
- (UIColor*)c_bg    { return [UIColor colorWithRed:0.08 green:0.08 blue:0.12 alpha:0.96]; }
- (UIColor*)c_card  { return [UIColor colorWithRed:0.12 green:0.12 blue:0.18 alpha:1]; }
- (UIColor*)c_accent{ return [UIColor colorWithRed:0.4  green:0.2  blue:1.0  alpha:1]; }
- (UIColor*)c_on    { return [UIColor colorWithRed:0.3  green:0.85 blue:0.5  alpha:1]; }
- (UIColor*)c_off   { return [UIColor colorWithRed:0.25 green:0.25 blue:0.35 alpha:1]; }
- (UIColor*)c_text  { return [UIColor colorWithWhite:0.95 alpha:1]; }
- (UIColor*)c_muted { return [UIColor colorWithWhite:0.5 alpha:1]; }

// ─── FAB ──────────────────────────────────────────────
- (void)buildFAB {
    self.fab = [UIButton buttonWithType:UIButtonTypeCustom];
    self.fab.frame = CGRectMake(16, 120, 50, 50);
    self.fab.backgroundColor = self.c_accent;
    self.fab.layer.cornerRadius = 25;
    self.fab.layer.shadowColor = self.c_accent.CGColor;
    self.fab.layer.shadowRadius = 10;
    self.fab.layer.shadowOpacity = 0.6;
    self.fab.layer.shadowOffset = CGSizeZero;
    [self.fab setTitle:@"Y+" forState:UIControlStateNormal];
    self.fab.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.fab setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [self.fab addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragFAB:)];
    [self.fab addGestureRecognizer:pan];
    [self.view addSubview:self.fab];
}

- (void)dragFAB:(UIPanGestureRecognizer*)g {
    CGPoint d = [g translationInView:self.view];
    CGRect f = self.fab.frame;
    CGFloat sw = UIScreen.mainScreen.bounds.size.width;
    CGFloat sh = UIScreen.mainScreen.bounds.size.height;
    f.origin.x = MAX(0, MIN(f.origin.x+d.x, sw-f.size.width));
    f.origin.y = MAX(60, MIN(f.origin.y+d.y, sh-100));
    self.fab.frame = f;
    [g setTranslation:CGPointZero inView:self.view];
}

// ─── PANEL ────────────────────────────────────────────
- (void)buildPanel {
    CGFloat pw = 280, ph = 440;
    self.panel = [[UIView alloc] initWithFrame:CGRectMake(76, 100, pw, ph)];
    self.panel.backgroundColor = self.c_bg;
    self.panel.layer.cornerRadius = 16;
    self.panel.layer.borderColor = [UIColor colorWithWhite:0.2 alpha:0.4].CGColor;
    self.panel.layer.borderWidth = 1;
    self.panel.layer.shadowColor = UIColor.blackColor.CGColor;
    self.panel.layer.shadowRadius = 20;
    self.panel.layer.shadowOpacity = 0.5;
    self.panel.hidden = YES;
    self.panel.alpha = 0;
    [self.view addSubview:self.panel];

    // Header
    UIView *hdr = [[UIView alloc] initWithFrame:CGRectMake(0,0,pw,48)];
    hdr.backgroundColor = self.c_card;
    UIBezierPath *bp = [UIBezierPath bezierPathWithRoundedRect:hdr.bounds byRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight cornerRadii:CGSizeMake(16,16)];
    CAShapeLayer *mask = [CAShapeLayer layer]; mask.path = bp.CGPath; hdr.layer.mask = mask;
    [self.panel addSubview:hdr];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(14,0,pw-80,48)];
    title.text = @"Yeeps+ Mods";
    title.textColor = self.c_text;
    title.font = [UIFont boldSystemFontOfSize:15];
    [hdr addSubview:title];

    UILabel *sub = [[UILabel alloc] initWithFrame:CGRectMake(14,0,pw-80,48)];
    sub.text = @"by Angel";
    sub.textColor = self.c_muted;
    sub.font = [UIFont systemFontOfSize:10];
    sub.textAlignment = NSTextAlignmentRight;
    sub.frame = CGRectMake(0,0,pw-12,48);
    [hdr addSubview:sub];

    // Accent line
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0,47,pw,2)];
    line.backgroundColor = self.c_accent;
    [hdr addSubview:line];

    // Close button
    UIButton *close = [UIButton buttonWithType:UIButtonTypeCustom];
    close.frame = CGRectMake(pw-40,10,28,28);
    close.backgroundColor = [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:0.8];
    close.layer.cornerRadius = 6;
    [close setTitle:@"✕" forState:UIControlStateNormal];
    close.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    [close addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];
    [hdr addSubview:close];

    // Scroll content
    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0,50,pw,ph-50)];
    scroll.showsVerticalScrollIndicator = NO;
    [self.panel addSubview:scroll];

    CGFloat y = 10;
    CGFloat padX = 12;
    CGFloat rowH = 50;

    // Section header
    y = [self addSection:@"MOVEMENT" scroll:scroll y:y pw:pw padX:padX];
    y = [self addToggle:@"Fly Mode" sub:@"Float around freely" key:@"fly" scroll:scroll y:y pw:pw padX:padX rowH:rowH];
    y = [self addToggle:@"Speed Boost" sub:@"Move faster" key:@"speed" scroll:scroll y:y pw:pw padX:padX rowH:rowH];
    y = [self addToggle:@"Noclip" sub:@"Phase through objects" key:@"noclip" scroll:scroll y:y pw:pw padX:padX rowH:rowH];

    y = [self addSection:@"CAMERA" scroll:scroll y:y pw:pw padX:padX];
    y = [self addToggle:@"Free Camera" sub:@"Unlock camera movement" key:@"freecam" scroll:scroll y:y pw:pw padX:padX rowH:rowH];
    y = [self addToggle:@"ESP" sub:@"See players through walls" key:@"esp" scroll:scroll y:y pw:pw padX:padX rowH:rowH];

    y = [self addSection:@"MISC" scroll:scroll y:y pw:pw padX:padX];
    y = [self addAction:@"Teleport to Origin" sub:@"Go to 0,0,0" scroll:scroll y:y pw:pw padX:padX rowH:rowH action:@selector(tpOrigin)];
    y = [self addAction:@"Reset Position" sub:@"Return to spawn" scroll:scroll y:y pw:pw padX:padX rowH:rowH action:@selector(resetPos)];

    scroll.contentSize = CGSizeMake(pw, y+20);
}

- (CGFloat)addSection:(NSString*)title scroll:(UIScrollView*)s y:(CGFloat)y pw:(CGFloat)pw padX:(CGFloat)padX {
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(padX,y,pw-padX*2,20)];
    l.text = title;
    l.textColor = self.c_accent;
    l.font = [UIFont boldSystemFontOfSize:10];
    [s addSubview:l];
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(padX,y+20,pw-padX*2,1)];
    line.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.5];
    [s addSubview:line];
    return y+28;
}

- (CGFloat)addToggle:(NSString*)name sub:(NSString*)sub key:(NSString*)key scroll:(UIScrollView*)s y:(CGFloat)y pw:(CGFloat)pw padX:(CGFloat)padX rowH:(CGFloat)rowH {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(padX,y,pw-padX*2,rowH)];
    row.backgroundColor = self.c_card;
    row.layer.cornerRadius = 10;
    [s addSubview:row];

    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(12,6,pw-100,20)];
    lbl.text = name; lbl.textColor = self.c_text;
    lbl.font = [UIFont boldSystemFontOfSize:13];
    [row addSubview:lbl];

    UILabel *slbl = [[UILabel alloc] initWithFrame:CGRectMake(12,24,pw-100,16)];
    slbl.text = sub; slbl.textColor = self.c_muted;
    slbl.font = [UIFont systemFontOfSize:10];
    [row addSubview:slbl];

    // Toggle switch
    UIButton *tog = [UIButton buttonWithType:UIButtonTypeCustom];
    tog.frame = CGRectMake(pw-padX*2-56, rowH/2-14, 48, 28);
    tog.backgroundColor = self.c_off;
    tog.layer.cornerRadius = 14;
    [tog setTitle:@"" forState:UIControlStateNormal];
    tog.tag = [self tagForKey:key];
    [tog addTarget:self action:@selector(toggleMod:) forControlEvents:UIControlEventTouchUpInside];

    UIView *knob = [[UIView alloc] initWithFrame:CGRectMake(3,3,22,22)];
    knob.backgroundColor = UIColor.whiteColor;
    knob.layer.cornerRadius = 11;
    knob.tag = 999;
    [tog addSubview:knob];
    [row addSubview:tog];
    [self.toggleButtons addObject:tog];

    return y + rowH + 8;
}

- (CGFloat)addAction:(NSString*)name sub:(NSString*)sub scroll:(UIScrollView*)s y:(CGFloat)y pw:(CGFloat)pw padX:(CGFloat)padX rowH:(CGFloat)rowH action:(SEL)action {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(padX,y,pw-padX*2,rowH)];
    row.backgroundColor = self.c_card;
    row.layer.cornerRadius = 10;
    [s addSubview:row];

    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(12,6,pw-120,20)];
    lbl.text = name; lbl.textColor = self.c_text;
    lbl.font = [UIFont boldSystemFontOfSize:13];
    [row addSubview:lbl];
    UILabel *slbl = [[UILabel alloc] initWithFrame:CGRectMake(12,24,pw-120,16)];
    slbl.text = sub; slbl.textColor = self.c_muted;
    slbl.font = [UIFont systemFontOfSize:10];
    [row addSubview:slbl];

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(pw-padX*2-72,rowH/2-14,68,28);
    btn.backgroundColor = self.c_accent;
    btn.layer.cornerRadius = 8;
    [btn setTitle:@"Run" forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [row addSubview:btn];

    return y + rowH + 8;
}

// ─── FLY CONTROLS ─────────────────────────────────────
- (void)buildFlyControls {
    CGFloat sh = UIScreen.mainScreen.bounds.size.height;
    CGFloat sw = UIScreen.mainScreen.bounds.size.width;

    self.flyUp = [UIButton buttonWithType:UIButtonTypeCustom];
    self.flyUp.frame = CGRectMake(sw-70, sh-160, 56, 56);
    self.flyUp.backgroundColor = [UIColor colorWithRed:0.4 green:0.2 blue:1.0 alpha:0.85];
    self.flyUp.layer.cornerRadius = 28;
    [self.flyUp setTitle:@"↑" forState:UIControlStateNormal];
    self.flyUp.titleLabel.font = [UIFont boldSystemFontOfSize:24];
    self.flyUp.hidden = YES;
    [self.view addSubview:self.flyUp];

    self.flyDown = [UIButton buttonWithType:UIButtonTypeCustom];
    self.flyDown.frame = CGRectMake(sw-70, sh-96, 56, 56);
    self.flyDown.backgroundColor = [UIColor colorWithRed:0.4 green:0.2 blue:1.0 alpha:0.85];
    self.flyDown.layer.cornerRadius = 28;
    [self.flyDown setTitle:@"↓" forState:UIControlStateNormal];
    self.flyDown.titleLabel.font = [UIFont boldSystemFontOfSize:24];
    self.flyDown.hidden = YES;
    [self.view addSubview:self.flyDown];
}

// ─── TOGGLE LOGIC ─────────────────────────────────────
- (NSInteger)tagForKey:(NSString*)key {
    NSDictionary *map = @{@"fly":@1, @"speed":@2, @"noclip":@3, @"freecam":@4, @"esp":@5};
    return [map[key] integerValue];
}

- (void)toggleMod:(UIButton*)btn {
    NSInteger tag = btn.tag;
    BOOL newState = NO;

    if (tag==1) { ModFly = !ModFly; newState=ModFly; self.flyUp.hidden=!ModFly; self.flyDown.hidden=!ModFly; }
    else if (tag==2) { ModSpeed = !ModSpeed; newState=ModSpeed; }
    else if (tag==3) { ModNoclip = !ModNoclip; newState=ModNoclip; }
    else if (tag==4) { ModFreeCamera = !ModFreeCamera; newState=ModFreeCamera; }
    else if (tag==5) { ModESP = !ModESP; newState=ModESP; }

    UIView *knob = [btn viewWithTag:999];
    [UIView animateWithDuration:0.2 animations:^{
        btn.backgroundColor = newState ? self.c_on : self.c_off;
        knob.frame = newState ? CGRectMake(23,3,22,22) : CGRectMake(3,3,22,22);
    }];
}

- (void)tpOrigin {
    NSLog(@"[YeepsPlus] TP to origin requested");
}
- (void)resetPos {
    NSLog(@"[YeepsPlus] Reset position requested");
}

// ─── PANEL TOGGLE ─────────────────────────────────────
- (void)togglePanel {
    self.expanded = !self.expanded;
    if (self.expanded) {
        CGRect fab = self.fab.frame;
        self.panel.frame = CGRectMake(fab.origin.x+60, fab.origin.y-20, 280, 440);
        CGFloat sw=UIScreen.mainScreen.bounds.size.width, sh=UIScreen.mainScreen.bounds.size.height;
        if (self.panel.frame.origin.x+280>sw-10) self.panel.frame=CGRectMake(sw-292,self.panel.frame.origin.y,280,440);
        if (self.panel.frame.origin.y+440>sh-20) self.panel.frame=CGRectMake(self.panel.frame.origin.x,sh-460,280,440);
        self.panel.hidden=NO;
        [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:0.5 options:0 animations:^{
            self.panel.alpha=1;
        } completion:nil];
    } else {
        [UIView animateWithDuration:0.2 animations:^{self.panel.alpha=0;} completion:^(BOOL d){self.panel.hidden=YES;}];
    }
}

@end
