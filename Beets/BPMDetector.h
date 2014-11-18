#import <Foundation/Foundation.h>

@class AEAudioController;

typedef void(^BPMDetectionBlock)(double bpm, double confidence);

@interface BPMDetector : NSObject
@property(nonatomic, readonly, getter=isRunning) BOOL running;

+ (instancetype)bpmDetectorWithAudioController:(AEAudioController *)aController;

- (void)listenWithBlock:(BPMDetectionBlock)aHandler;
- (void)stopListening;
@end