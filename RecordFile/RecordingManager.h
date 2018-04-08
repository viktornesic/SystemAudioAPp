//
//  RecordingManager.h
//  RecordFile
//
//  Created by Viktor on 2/27/18.
//  Copyright © 2018 Mac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZAudio.h"
#import "EZAudioDevice.h"

@protocol RecordingManagerDelegate <NSObject>
    
@optional
- (void) didStartRecordingToOutputFileAt:(NSURL*) outputURL;
- (void) didFinishRecordingToOutputFileAt:(NSURL*) outputURL;
- (void) updateAudioPlotBuffer:(float *)buffer withBufferSize:(UInt32)bufferSize;
- (void) recorderUpdatedCurrentTime:(NSString *) formattedCurrentTime;
    
@end

@interface RecordingManager : NSObject <EZAudioPlayerDelegate, EZMicrophoneDelegate, EZRecorderDelegate> {
    NSURL* recordingPath;
}

@property (assign, nonatomic)           id<RecordingManagerDelegate> delegate;
//
// A flag indicating whether we are recording or not
//
@property (nonatomic, assign) BOOL isRecording;
//
// The microphone component
//
@property (nonatomic, strong) EZMicrophone *microphone;
@property (nonatomic, strong) EZAudioDevice *defaultOutput;

//
// The recorder component
//
@property (nonatomic, strong) EZRecorder *recorder;

#pragma MARK Public methods

- (void) startRecordingAtPath:(NSString *)filePath;
- (void) stopRecordingCompletionBlock:(void (^)(void))completionBlock ;
- (void) controlVolume:(Float32) volume;

@end
