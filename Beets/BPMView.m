#import "BPMView.h"

@implementation BPMView {
    UILabel *_bpmLabel;
    CAShapeLayer *_circleLayer, *_labelBackground;
}

- (id)initWithCoder:(NSCoder * const)aDecoder
{
    if((self = [super initWithCoder:aDecoder])) {
        _bpmLabel = [UILabel new];
        _bpmLabel.textColor = [UIColor whiteColor];
        _bpmLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:70];
        _bpmLabel.textAlignment = NSTextAlignmentCenter;
        _bpmLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin
                                   | UIViewAutoresizingFlexibleLeftMargin
                                   | UIViewAutoresizingFlexibleBottomMargin
                                   | UIViewAutoresizingFlexibleRightMargin;

        _circleLayer = [CAShapeLayer new];
        _circleLayer.fillColor = [[UIColor whiteColor] CGColor];
        _circleLayer.path = [[UIBezierPath bezierPathWithOvalInRect:(CGRect) {
            -124, -124,
            248, 248
        }] CGPath];

        _labelBackground = [CAShapeLayer new];
        _labelBackground.fillColor = [[UIColor blackColor] CGColor];
        _labelBackground.strokeColor = [[UIColor whiteColor] CGColor];
        _labelBackground.lineWidth = 1;
        _labelBackground.path = [[UIBezierPath bezierPathWithOvalInRect:(CGRect) {
            -125, -125,
            250, 250
        }] CGPath];

        [self.layer addSublayer:_circleLayer];
        [self.layer addSublayer:_labelBackground];
        [self addSubview:_bpmLabel];

        self.bpm = 0;
    }
    return self;
}

- (void)setBpm:(float const)aBPM
{
    [self willChangeValueForKey:@"bpm"];
    _bpm = aBPM;
    _bpmLabel.text = aBPM > 0 ? [NSString stringWithFormat:@"%.1f", aBPM] : @"?";
    if(aBPM > 0)
        _labelBackground.strokeColor = [[UIColor whiteColor] CGColor];
    else
        _labelBackground.strokeColor = nil;
    [_bpmLabel sizeToFit];
    [self setNeedsLayout];
    [self didChangeValueForKey:@"bpm"];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGPoint const center = {
        CGRectGetMidX(self.bounds),
        CGRectGetMidY(self.bounds)
    };
    _bpmLabel.center          = center;
    _circleLayer.position     = center;
    _labelBackground.position = center;
}
- (void)pulsate
{
    CABasicAnimation * const pulseXAnim = [CABasicAnimation animationWithKeyPath:@"transform.scale.x"];
    pulseXAnim.toValue = @(1.1 + (rand()/(double)RAND_MAX)*0.1);
    CABasicAnimation * const pulseYAnim = [CABasicAnimation animationWithKeyPath:@"transform.scale.y"];
    pulseYAnim.toValue = @([pulseXAnim.toValue doubleValue] + ((rand()/(double)RAND_MAX)*0.1 - 0.05));

    CAAnimationGroup * const pulseAnims = [CAAnimationGroup new];
    pulseAnims.animations     = @[pulseXAnim, pulseYAnim];
    pulseAnims.autoreverses   = YES;
    pulseAnims.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.12 :0.81 :0.68 :0.85];
    pulseAnims.duration       = 0.2;
    [_circleLayer addAnimation:pulseAnims forKey:@"pulse"];
}

@end
