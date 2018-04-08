//
//  RecordingManager.m
//  RecordFile
//
//  Created by Viktor on 2/27/18.
//  Copyright © 2018 Mac. All rights reserved.
//

#import "RecordingManager.h"

@implementation RecordingManager
    
- (instancetype) init {
    if(self == [super init]) {
        self.microphone = [EZMicrophone microphoneWithDelegate:self];
        [self.microphone startFetchingAudio];
        self.defaultOutput = [EZAudioDevice currentOutputSystem];
        NSUserDefaults* udf = [NSUserDefaults standardUserDefaults];
        [udf setInteger:self.defaultOutput.deviceID forKey:@"deviceID"];
        [udf synchronize];
    }
    return self;
}
    
- (void) startRecordingAtPath:(NSString *)filePath {
    self.isRecording = TRUE;
    [self selectMultiOutputDevice];
    [self.microphone startFetchingAudio];
    recordingPath = [NSURL fileURLWithPath:filePath];
    self.recorder = [EZRecorder recorderWithURL:recordingPath
                                   clientFormat:[self.microphone audioStreamBasicDescription]
                                       fileType:EZRecorderFileTypeWAV
                                       delegate:self];
    if([_delegate respondsToSelector:@selector(didStartRecordingToOutputFileAt:)]) {
        [_delegate didStartRecordingToOutputFileAt:recordingPath];
    }
    
}
    
- (void) stopRecordingCompletionBlock:(void (^)(void))completionBlock {
    
    self.isRecording = FALSE;
    [self performSelector:@selector(selectDefaultBuiltinOutput) withObject:nil afterDelay:0.1];
    [self.microphone stopFetchingAudio];
    if (self.recorder) {
        [self.recorder closeAudioFile];
    }
    if([_delegate respondsToSelector:@selector(didFinishRecordingToOutputFileAt:)]) {
        [_delegate didFinishRecordingToOutputFileAt:recordingPath];
    }
    completionBlock();
}
    
- (void)microphone:(EZMicrophone *)microphone changedPlayingState:(BOOL)isPlaying {
    
}

- (void)   microphone:(EZMicrophone *)microphone
     hasAudioReceived:(float **)buffer
       withBufferSize:(UInt32)bufferSize
 withNumberOfChannels:(UInt32)numberOfChannels{
    __weak typeof (self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if([weakSelf.delegate respondsToSelector:@selector(updateAudioPlotBuffer:withBufferSize:)]) {
            [weakSelf.delegate updateAudioPlotBuffer:buffer[0] withBufferSize:bufferSize];
        }
        
    });
    
}
    
- (void)   microphone:(EZMicrophone *)microphone
        hasBufferList:(AudioBufferList *)bufferList
       withBufferSize:(UInt32)bufferSize
 withNumberOfChannels:(UInt32)numberOfChannels {
        // Getting audio data as a buffer list that can be directly fed into the EZRecorder. This is happening on the audio thread - any UI updating needs a GCD main queue block. This will keep appending data to the tail of the audio file.
        if (self.isRecording) {
            [self.recorder appendDataFromBufferList:bufferList
                                     withBufferSize:bufferSize];
        }
}
    
#pragma mark - EZRecorderDelegate
    
- (void)recorderDidClose:(EZRecorder *)recorder {
        recorder.delegate = nil;
}
    
- (void)recorderUpdatedCurrentTime:(EZRecorder *)recorder{
    if (self.isRecording) {
        __weak typeof (self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            if([weakSelf.delegate respondsToSelector:@selector(recorderUpdatedCurrentTime:)]) {
                NSString *formattedCurrentTime = [recorder formattedCurrentTime];
                [weakSelf.delegate recorderUpdatedCurrentTime:formattedCurrentTime];
            }
        });
    }
}
    
#pragma mark - Helper methods
    
- (void) selectMultiOutputDevice {
    
    UInt32 propertySize = sizeof(UInt32);
    AudioDeviceID newDeviceID = [EZAudioDevice currentOutputDevice].deviceID;
    AudioHardwareSetProperty(kAudioHardwarePropertyDefaultOutputDevice, propertySize, &newDeviceID); 
    
}

- (void) controlVolume:(Float32) volume {

    AudioObjectPropertyAddress propertyAddress = {
    kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
    kAudioDevicePropertyScopeOutput,
    kAudioObjectPropertyElementMaster
    };
    //AudioDeviceID newDeviceID1 = [EZAudioDevice currentOutputDeviceDefault].deviceID;
    //NSUserDefaults* udf = [NSUserDefaults standardUserDefaults];
    UInt32 deviceid = self.defaultOutput.deviceID;//(UInt32)[udf integerForKey:@"deviceID"];
    if (deviceid > 0) {
        AudioHardwareServiceSetPropertyData(deviceid,
                                            &propertyAddress,
                                            0,
                                            NULL,
                                            sizeof(Float32),
                                            &volume);
    }
}

- (void) selectDefaultBuiltinOutput {
    
    UInt32 propertySize = sizeof(UInt32);
    //NSUserDefaults* udf = [NSUserDefaults standardUserDefaults];
    UInt32 deviceid = self.defaultOutput.deviceID;//(UInt32)[udf integerForKey:@"deviceID"];
    if(deviceid > 0) {
        AudioDeviceID newDeviceID = deviceid;
        AudioHardwareSetProperty(kAudioHardwarePropertyDefaultOutputDevice, propertySize, &newDeviceID);
    }
}
    

@end
