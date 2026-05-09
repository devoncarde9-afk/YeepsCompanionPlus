#import "Overlay.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

// ─── Mod flags ────────────────────────────────────────
BOOL ModFly = NO;
BOOL ModSpeed = NO;
BOOL ModNoclip = NO;
BOOL ModESP = NO;
BOOL ModFreeCamera = NO;
float ModFlySpeed = 5.0f;
float ModMoveSpeed = 2.0f;

// ─── Audio engine ─────────────────────────────────────
static AVAudioEngine *_engine = nil;
static AVAudioPlayerNode *_player = nil;
static BOOL _inOnEnable = NO;

void YeepsPlaySound(NSString *filePath, float volume) {
    if (!_engine || !filePath || filePath.length == 0) return;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @try {
            NSURL *url = [NSURL fileURLWithPath:filePath];
            NSError *err = nil;
            AVAudioFile *file = [[AVAudioFile alloc] initForReading:url error:&err];
            if (err || !file) { NSLog(@"[YeepsPlus] sound load error: %@", err); return; }
            AVAudioPCMBuffer *buf = [[AVAudioPCMBuffer alloc]
                initWithPCMFormat:file.processingFormat
                    frameCapacity:(AVAudioFrameCount)file.length];
            [file readIntoBuffer:buf error:&err];
            if (err) return;
            _player.volume = volume;
            [_player stop];
            [_player play];
            [_player scheduleBuffer:buf completionHandler:nil];
        } @catch(NSException *e) { NSLog(@"[YeepsPlus] play error: %@", e); }
    });
}

void YeepsStopSound(void) {
    if (_player) { [_player stop]; [_player play]; }
}

static void InitAudio(void) {
    if (_engine) return;
    @try {
        _engine = [[AVAudioEngine alloc] init];
        _player = [[AVAudioPlayerNode alloc] init];
        [_engine attachNode:_player];
        AVAudioFormat *fmt = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100 channels:1];
        [_engine connect:_player to:_engine.mainMixerNode format:fmt];
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
            withOptions:AVAudioSessionCategoryOptionMixWithOthers |
                        AVAudioSessionCategoryOptionAllowBluetooth |
                        AVAudioSessionCategoryOptionDefaultToSpeaker
            error:nil];
        NSError *err = nil;
        [_engine startAndReturnError:&err];
        if (!err) [_player play];
        NSLog(@"[YeepsPlus] audio engine started");
    } @catch(NSException *e) { NSLog(@"[YeepsPlus] audio init error: %@", e); }
}

// ─── Overlay ──────────────────────────────────────────
@interface YeepsOverlay ()
@property (nonatomic, strong) UIWindow *win;
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, strong) UIButton *fab;
@property (nonatomic, assign) BOOL expanded;
@property (nonatomic, assign) NSInteger activeTab; // 0=Mods 1=Sounds
@property (nonatomic, strong) UIView *modsView;
@property (nonatomic, strong) UIView *soundsView;
@property (nonatomic, strong) UIButton *flyUp;
@property (nonatomic, strong) UIButton *flyDown;
@property (nonatomic, strong) NSArray<NSString*> *soundPaths;
@property (nonatomic, strong) NSArray<NSString*> *soundNames;
@end

@implementation YeepsOverlay

+ (void)show {
    static YeepsOverlay *inst;
    if (inst) return;
    inst = [YeepsOverlay new];
    [inst setup];
}

- (void)setup {
    InitAudio();
    self.expanded = NO;
    self.activeTab = 0;
    [self loadSounds];

    self.win = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.win.windowLevel = UIWindowLevelAlert + 999;
    self.win.backgroundColor = [UIColor clearColor];
    self.win.hidden = NO;
    self.win.rootViewController = self;
    if (@available(iOS 13,*)) {
        for (UIWindowScene *s in UIApplication.sharedApplication.connectedScenes) {
            if ([s isKindOfClass:UIWindowScene.class]) { self.win.windowScene=(UIWindowScene*)s; break; }
        }
    }
    [self.win makeKeyAndVisible];
    [self buildFAB];
    [self buildPanel];
    [self buildFlyControls];
}

- (void)loadSounds {
    NSString *dir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/YeepsPlus/Sounds"];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:nil];
    NSMutableArray *paths = [NSMutableArray array];
    NSMutableArray *names = [NSMutableArray array];
    for (NSString *f in files) {
        if ([f hasSuffix:@".mp3"] || [f hasSuffix:@".wav"] || [f hasSuffix:@".m4a"]) {
            [paths addObject:[dir stringByAppendingPathComponent:f]];
            NSString *n = [f stringByDeletingPathExtension];
            [names addObject:n.length > 12 ? [n substringToIndex:12] : n];
        }
    }
    if (paths.count == 0) {
        [names addObjectsFromArray:@[@"Bruh",@"Oof",@"Wow",@"GG",@"LOL",@"Noooo"]];
        for (int i=0;i<6;i++) [paths addObject:@""];
    }
    self.soundPaths = paths;
    self.soundNames = names;
}

// ─── Colors ───
- (UIColor*)cBG     { return [UIColor colorWithRed:0.07 green:0.07 blue:0.12 alpha:0.97]; }
- (UIColor*)cCard   { return [UIColor colorWithRed:0.12 green:0.12 blue:0.18 alpha:1]; }
- (UIColor*)cAccent { return [UIColor colorWithRed:0.4  green:0.2  blue:1.0  alpha:1]; }
- (UIColor*)cOn     { return [UIColor colorWithRed:0.3  green:0.85 blue:0.5  alpha:1]; }
- (UIColor*)cOff    { return [UIColor colorWithRed:0.2  green:0.2  blue:0.3  alpha:1]; }
- (UIColor*)cText   { return [UIColor colorWithWhite:0.95 alpha:1]; }
- (UIColor*)cMuted  { return [UIColor colorWithWhite:0.45 alpha:1]; }
- (UIColor*)cSound  { return [UIColor colorWithRed:0.15 green:0.6  blue:0.9  alpha:1]; }

// ─── FAB ───
- (void)buildFAB {
    self.fab = [UIButton buttonWithType:UIButtonTypeCustom];
    self.fab.frame = CGRectMake(16, 120, 50, 50);
    self.fab.backgroundColor = self.cAccent;
    self.fab.layer.cornerRadius = 25;
    self.fab.layer.shadowColor = self.cAccent.CGColor;
    self.fab.layer.shadowRadius = 10;
    self.fab.layer.shadowOpacity = 0.6;
    self.fab.layer.shadowOffset = CGSizeZero;
    [self.fab setTitle:@"Y+" forState:UIControlStateNormal];
    self.fab.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [self.fab addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragFAB:)];
    [self.fab addGestureRecognizer:pan];
    [self.view addSubview:self.fab];
}

- (void)dragFAB:(UIPanGestureRecognizer*)g {
    CGPoint d = [g translationInView:self.view];
    CGRect f = self.fab.frame;
    CGFloat sw=UIScreen.mainScreen.bounds.size.width, sh=UIScreen.mainScreen.bounds.size.height;
    f.origin.x = MAX(0, MIN(f.origin.x+d.x, sw-f.size.width));
    f.origin.y = MAX(60, MIN(f.origin.y+d.y, sh-100));
    self.fab.frame = f;
    [g setTranslation:CGPointZero inView:self.view];
}

// ─── PANEL ───
- (void)buildPanel {
    CGFloat pw=300, ph=460;
    self.panel = [[UIView alloc] initWithFrame:CGRectMake(76,100,pw,ph)];
    self.panel.backgroundColor = self.cBG;
    self.panel.layer.cornerRadius = 16;
    self.panel.layer.borderColor = [UIColor colorWithWhite:0.2 alpha:0.3].CGColor;
    self.panel.layer.borderWidth = 1;
    self.panel.layer.shadowColor = UIColor.blackColor.CGColor;
    self.panel.layer.shadowRadius = 20;
    self.panel.layer.shadowOpacity = 0.5;
    self.panel.hidden = YES;
    self.panel.alpha = 0;
    [self.view addSubview:self.panel];

    // Header
    UIView *hdr = [[UIView alloc] initWithFrame:CGRectMake(0,0,pw,44)];
    hdr.backgroundColor = self.cCard;
    UIBezierPath *bp = [UIBezierPath bezierPathWithRoundedRect:hdr.bounds byRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight cornerRadii:CGSizeMake(16,16)];
    CAShapeLayer *mask = [CAShapeLayer layer]; mask.path=bp.CGPath; hdr.layer.mask=mask;
    [self.panel addSubview:hdr];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(12,0,pw-90,44)];
    title.text = @"Yeeps+ by Angel";
    title.textColor = self.cText;
    title.font = [UIFont boldSystemFontOfSize:14];
    [hdr addSubview:title];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeCustom];
    close.frame = CGRectMake(pw-38,8,28,28);
    close.backgroundColor = [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:0.9];
    close.layer.cornerRadius = 6;
    [close setTitle:@"✕" forState:UIControlStateNormal];
    close.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    [close addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];
    [hdr addSubview:close];

    // Accent line
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0,43,pw,1)];
    line.backgroundColor = self.cAccent;
    [hdr addSubview:line];

    // Tab bar
    UIView *tabBar = [[UIView alloc] initWithFrame:CGRectMake(0,44,pw,36)];
    tabBar.backgroundColor = self.cCard;
    [self.panel addSubview:tabBar];

    NSArray *tabTitles = @[@"🎮 Mods", @"🔊 Sounds"];
    for (int i=0; i<2; i++) {
        UIButton *tb = [UIButton buttonWithType:UIButtonTypeCustom];
        tb.frame = CGRectMake(i*(pw/2), 0, pw/2, 36);
        tb.backgroundColor = i==0 ? self.cAccent : [UIColor clearColor];
        tb.layer.cornerRadius = 0;
        [tb setTitle:tabTitles[i] forState:UIControlStateNormal];
        tb.titleLabel.font = [UIFont boldSystemFontOfSize:12];
        [tb setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        tb.tag = i;
        [tb addTarget:self action:@selector(switchTab:) forControlEvents:UIControlEventTouchUpInside];
        [tabBar addSubview:tb];
    }
    UIView *tabLine = [[UIView alloc] initWithFrame:CGRectMake(0,35,pw,1)];
    tabLine.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1];
    [tabBar addSubview:tabLine];

    // Content area
    CGRect contentFrame = CGRectMake(0, 81, pw, ph-81);

    // MODS VIEW
    self.modsView = [[UIView alloc] initWithFrame:contentFrame];
    self.modsView.backgroundColor = [UIColor clearColor];
    [self.panel addSubview:self.modsView];
    [self buildModsList:self.modsView pw:pw];

    // SOUNDS VIEW
    self.soundsView = [[UIView alloc] initWithFrame:contentFrame];
    self.soundsView.backgroundColor = [UIColor clearColor];
    self.soundsView.hidden = YES;
    [self.panel addSubview:self.soundsView];
    [self buildSoundBoard:self.soundsView pw:pw ph:ph-81];
}

// ─── MODS LIST ───
- (void)buildModsList:(UIView*)parent pw:(CGFloat)pw {
    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:parent.bounds];
    scroll.showsVerticalScrollIndicator = NO;
    [parent addSubview:scroll];

    CGFloat y=10, padX=12, rowH=50;

    y = [self addSection:@"MOVEMENT" scroll:scroll y:y pw:pw padX:padX];
    y = [self addToggle:@"Fly Mode"     sub:@"Float around freely"       key:1 scroll:scroll y:y pw:pw padX:padX rowH:rowH];
    y = [self addToggle:@"Speed Boost"  sub:@"Move faster"               key:2 scroll:scroll y:y pw:pw padX:padX rowH:rowH];
    y = [self addToggle:@"Noclip"       sub:@"Phase through objects"     key:3 scroll:scroll y:y pw:pw padX:padX rowH:rowH];

    y = [self addSection:@"CAMERA" scroll:scroll y:y pw:pw padX:padX];
    y = [self addToggle:@"Free Camera"  sub:@"Unlock camera movement"    key:4 scroll:scroll y:y pw:pw padX:padX rowH:rowH];
    y = [self addToggle:@"ESP"          sub:@"See players through walls" key:5 scroll:scroll y:y pw:pw padX:padX rowH:rowH];

    scroll.contentSize = CGSizeMake(pw, y+20);
}

// ─── SOUNDS BOARD ───
- (void)buildSoundBoard:(UIView*)parent pw:(CGFloat)pw ph:(CGFloat)ph {
    // Stop button
    UIButton *stopBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    stopBtn.frame = CGRectMake(12, 8, pw-24, 32);
    stopBtn.backgroundColor = [UIColor colorWithRed:0.8 green:0.1 blue:0.2 alpha:0.9];
    stopBtn.layer.cornerRadius = 8;
    [stopBtn setTitle:@"■  STOP SOUND" forState:UIControlStateNormal];
    stopBtn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    [stopBtn addTarget:self action:@selector(stopSound) forControlEvents:UIControlEventTouchUpInside];
    [parent addSubview:stopBtn];

    // Hint label
    UILabel *hint = [[UILabel alloc] initWithFrame:CGRectMake(12,44,pw-24,14)];
    hint.text = @"Add sounds to ~/Documents/YeepsPlus/Sounds/";
    hint.textColor = self.cMuted;
    hint.font = [UIFont systemFontOfSize:9];
    hint.textAlignment = NSTextAlignmentCenter;
    [parent addSubview:hint];

    // Scroll grid
    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0,62,pw,ph-62)];
    scroll.showsVerticalScrollIndicator = NO;
    [parent addSubview:scroll];

    int cols = 2;
    CGFloat gap = 8;
    CGFloat btnW = (pw - gap*3) / cols;
    CGFloat btnH = 52;
    int rows = (int)ceil((double)self.soundNames.count / cols);

    for (int i=0; i<(int)self.soundNames.count; i++) {
        int col = i % cols;
        int row = i / cols;
        CGFloat x = gap + col*(btnW+gap);
        CGFloat y = gap + row*(btnH+gap);

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(x, y, btnW, btnH);
        btn.backgroundColor = self.cCard;
        btn.layer.cornerRadius = 10;
        btn.layer.borderColor = [UIColor colorWithRed:0.15 green:0.6 blue:0.9 alpha:0.4].CGColor;
        btn.layer.borderWidth = 1;
        btn.tag = i;
        [btn setTitle:self.soundNames[i] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
        btn.titleLabel.numberOfLines = 2;
        btn.titleLabel.textAlignment = NSTextAlignmentCenter;
        [btn setTitleColor:self.cText forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(playSound:) forControlEvents:UIControlEventTouchUpInside];
        [btn addTarget:self action:@selector(btnDown:) forControlEvents:UIControlEventTouchDown];
        [btn addTarget:self action:@selector(btnUp:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
        [scroll addSubview:btn];
    }
    scroll.contentSize = CGSizeMake(pw, rows*(btnH+gap)+gap);
}

- (void)playSound:(UIButton*)btn {
    int i = (int)btn.tag;
    if (i >= (int)self.soundPaths.count) return;
    NSString *path = self.soundPaths[i];
    if (path.length == 0) return;
    YeepsPlaySound(path, 0.9f);
    [UIView animateWithDuration:0.1 animations:^{
        btn.backgroundColor = self.cSound;
    } completion:^(BOOL d){
        [UIView animateWithDuration:0.25 animations:^{ btn.backgroundColor = self.cCard; }];
    }];
}

- (void)stopSound { YeepsStopSound(); }

- (void)btnDown:(UIButton*)btn {
    [UIView animateWithDuration:0.08 animations:^{ btn.transform=CGAffineTransformMakeScale(0.93,0.93); }];
}
- (void)btnUp:(UIButton*)btn {
    [UIView animateWithDuration:0.12 animations:^{ btn.transform=CGAffineTransformIdentity; }];
}

// ─── TAB SWITCH ───
- (void)switchTab:(UIButton*)btn {
    self.activeTab = btn.tag;
    self.modsView.hidden = (self.activeTab != 0);
    self.soundsView.hidden = (self.activeTab != 1);
    // Update tab bar highlight
    UIView *tabBar = self.panel.subviews[2];
    for (UIButton *tb in tabBar.subviews) {
        if (![tb isKindOfClass:[UIButton class]]) continue;
        tb.backgroundColor = (tb.tag == self.activeTab) ? self.cAccent : [UIColor clearColor];
    }
}

// ─── SECTION / TOGGLE ───
- (CGFloat)addSection:(NSString*)title scroll:(UIScrollView*)s y:(CGFloat)y pw:(CGFloat)pw padX:(CGFloat)padX {
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(padX,y,pw-padX*2,18)];
    l.text = title; l.textColor = self.cAccent;
    l.font = [UIFont boldSystemFontOfSize:10];
    [s addSubview:l];
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(padX,y+18,pw-padX*2,1)];
    line.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1];
    [s addSubview:line];
    return y+26;
}

- (CGFloat)addToggle:(NSString*)name sub:(NSString*)sub key:(NSInteger)key scroll:(UIScrollView*)s y:(CGFloat)y pw:(CGFloat)pw padX:(CGFloat)padX rowH:(CGFloat)rowH {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(padX,y,pw-padX*2,rowH)];
    row.backgroundColor = self.cCard;
    row.layer.cornerRadius = 10;
    [s addSubview:row];

    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(12,6,pw-100,20)];
    lbl.text=name; lbl.textColor=self.cText;
    lbl.font=[UIFont boldSystemFontOfSize:13];
    [row addSubview:lbl];

    UILabel *slbl = [[UILabel alloc] initWithFrame:CGRectMake(12,24,pw-100,16)];
    slbl.text=sub; slbl.textColor=self.cMuted;
    slbl.font=[UIFont systemFontOfSize:10];
    [row addSubview:slbl];

    UIButton *tog = [UIButton buttonWithType:UIButtonTypeCustom];
    tog.frame = CGRectMake(pw-padX*2-56,rowH/2-14,48,28);
    tog.backgroundColor = self.cOff;
    tog.layer.cornerRadius = 14;
    tog.tag = key;
    [tog addTarget:self action:@selector(toggleMod:) forControlEvents:UIControlEventTouchUpInside];
    UIView *knob = [[UIView alloc] initWithFrame:CGRectMake(3,3,22,22)];
    knob.backgroundColor = UIColor.whiteColor;
    knob.layer.cornerRadius = 11;
    knob.tag = 999;
    [tog addSubview:knob];
    [row addSubview:tog];
    return y+rowH+8;
}

- (void)toggleMod:(UIButton*)btn {
    BOOL newVal = NO;
    switch(btn.tag) {
        case 1: ModFly=!ModFly; newVal=ModFly; self.flyUp.hidden=!ModFly; self.flyDown.hidden=!ModFly; break;
        case 2: ModSpeed=!ModSpeed; newVal=ModSpeed; break;
        case 3: ModNoclip=!ModNoclip; newVal=ModNoclip; break;
        case 4: ModFreeCamera=!ModFreeCamera; newVal=ModFreeCamera; break;
        case 5: ModESP=!ModESP; newVal=ModESP; break;
    }
    UIView *knob = [btn viewWithTag:999];
    [UIView animateWithDuration:0.2 animations:^{
        btn.backgroundColor = newVal ? self.cOn : self.cOff;
        knob.frame = newVal ? CGRectMake(23,3,22,22) : CGRectMake(3,3,22,22);
    }];
}

// ─── FLY CONTROLS ───
- (void)buildFlyControls {
    CGFloat sh=UIScreen.mainScreen.bounds.size.height, sw=UIScreen.mainScreen.bounds.size.width;
    self.flyUp = [UIButton buttonWithType:UIButtonTypeCustom];
    self.flyUp.frame = CGRectMake(sw-70,sh-160,56,56);
    self.flyUp.backgroundColor = self.cAccent;
    self.flyUp.layer.cornerRadius = 28;
    [self.flyUp setTitle:@"↑" forState:UIControlStateNormal];
    self.flyUp.titleLabel.font = [UIFont boldSystemFontOfSize:24];
    self.flyUp.hidden = YES;
    [self.view addSubview:self.flyUp];

    self.flyDown = [UIButton buttonWithType:UIButtonTypeCustom];
    self.flyDown.frame = CGRectMake(sw-70,sh-96,56,56);
    self.flyDown.backgroundColor = self.cAccent;
    self.flyDown.layer.cornerRadius = 28;
    [self.flyDown setTitle:@"↓" forState:UIControlStateNormal];
    self.flyDown.titleLabel.font = [UIFont boldSystemFontOfSize:24];
    self.flyDown.hidden = YES;
    [self.view addSubview:self.flyDown];
}

// ─── PANEL TOGGLE ───
- (void)togglePanel {
    self.expanded = !self.expanded;
    if (self.expanded) {
        CGRect fab=self.fab.frame;
        self.panel.frame = CGRectMake(fab.origin.x+60, fab.origin.y-20, 300, 460);
        CGFloat sw=UIScreen.mainScreen.bounds.size.width, sh=UIScreen.mainScreen.bounds.size.height;
        if (self.panel.frame.origin.x+300>sw-10) self.panel.frame=CGRectMake(sw-312,self.panel.frame.origin.y,300,460);
        if (self.panel.frame.origin.y+460>sh-20) self.panel.frame=CGRectMake(self.panel.frame.origin.x,sh-480,300,460);
        self.panel.hidden=NO;
        [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:0.5 options:0 animations:^{
            self.panel.alpha=1;
        } completion:nil];
    } else {
        [UIView animateWithDuration:0.2 animations:^{self.panel.alpha=0;} completion:^(BOOL d){self.panel.hidden=YES;}];
    }
}

@end
