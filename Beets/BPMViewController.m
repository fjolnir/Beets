#import "BPMViewController.h"
#import "BPMDetector.h"

@implementation BPMViewController {
    BPMDetector *_detector;
    CATextLayer *_bpmLayer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSError *err;
    AVCaptureDevice *device = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] lastObject];
    if(!device)
        return;

    AVCaptureDeviceInput *input = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&err];
    if(!input)
        return;

    _detector = [BPMDetector bpmDetectorWithCaptureInput:input];

    _bpmLayer = [CATextLayer new];
    _bpmLayer.fontSize = 60;
    _bpmLayer.font = CGFontCreateWithFontName(CFSTR("HelveticaNeue-Bold"));
    _bpmLayer.foregroundColor = [[UIColor whiteColor] CGColor];
    _bpmLayer.frame = self.view.bounds;
    _bpmLayer.alignmentMode = kCAAlignmentCenter;
    _bpmLayer.wrapped = NO;
    _bpmLayer.contentsScale = [[UIScreen mainScreen] scale];
    [self.view.layer addSublayer:_bpmLayer];
}

- (void)viewWillAppear:(BOOL const)aAnimated
{
    [super viewWillAppear:aAnimated];

    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        [_detector listenWithBlock:^(double bpm, double confidence) {
            NSLog(@">> %.3f BPM @ %.2f confidence", bpm, confidence);
            if(confidence < 0.2) {
                _bpmLayer.string = @"...";
                [self.view setNeedsLayout];
                return;
            }

            _bpmLayer.string = [NSString stringWithFormat:@"%.2f", bpm];

            CABasicAnimation *bgAnim = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
            bgAnim.toValue = (__bridge id)[[UIColor whiteColor] CGColor];
            bgAnim.duration = 0.1;
            bgAnim.autoreverses = YES;
            [self.view.layer addAnimation:bgAnim forKey:@"bpmFlash"];

            CABasicAnimation *labelAnim = [CABasicAnimation animationWithKeyPath:@"foregroundColor"];
            labelAnim.toValue = (__bridge id)[[UIColor blackColor] CGColor];
            labelAnim.duration = 0.1;
            labelAnim.autoreverses = YES;
            [_bpmLayer addAnimation:labelAnim forKey:@"bpmFlash"];

            [self.view setNeedsLayout];
        }];
    }];
}
- (void)viewDidDisappear:(BOOL const)aAnimated
{
    [super viewDidDisappear:aAnimated];
    [_detector stopListening];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    _bpmLayer.position = (CGPoint) {
        CGRectGetMidX(self.view.bounds),
        CGRectGetMidY(self.view.bounds)
    };
    _bpmLayer.bounds = (CGRect) {
        0, 0,
        self.view.bounds.size.width,
        [_bpmLayer.string sizeWithAttributes:@{
            NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold" size:60]
        }].height
    };
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
