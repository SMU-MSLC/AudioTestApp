//
//  SMUViewController.m
//  NovocaineExample
//
//  Created by Eric Larson on 12/12/13.
//  Copyright (c) 2013 Eric Larson. All rights reserved.
//

#define kBufferLength 1024*4

#import "SMUViewController.h"
#import <mach/mach_time.h>

@interface SMUViewController ()

@end

@implementation SMUViewController

// these arguments are global
float FrequencyGlobal;
float *InputAudioDataBufferGlobal;
unsigned int InputAudioBufferIdx;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc{
    // ARC handles everything else, just clean up what we used c++ for
    free(InputAudioDataBufferGlobal);
}

-(void)viewWillAppear:(BOOL)animated{
    //overloading this function
    [super viewWillAppear:animated];
    
    ringBuffer = new RingBuffer(32768,2);
    audioManager = [Novocaine audioManager];
    
    // allocate some space for the copied samples
    InputAudioDataBufferGlobal  = (float *)calloc(kBufferLength, sizeof(float));
    memset(InputAudioDataBufferGlobal, 0, kBufferLength*sizeof(float)); // set everything to zero for now
    InputAudioBufferIdx = 0;//index for filling circular buffer
    
    NSLog(@"Current Buffer Size = %.4f ms",kBufferLength/audioManager.samplingRate*1000);
    
    //===================================================
    // Just copy over the data into a temporary buffer
    // ==================================================
    [audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels) {
        // copy over the bytes for use in our analysis later
        // fill the buffer if not already filled
        if((numFrames*numChannels+InputAudioBufferIdx) <= kBufferLength){
            // okay to just fill buffer in one place
            memcpy(&InputAudioDataBufferGlobal[InputAudioBufferIdx],data,numFrames*numChannels*sizeof(float));
            InputAudioBufferIdx += numFrames*numChannels;
        }
        else{
            // need to circularly fill the buffer
            // fill the end of the buffer
            UInt32 numSamplesToCopyFirst = kBufferLength-InputAudioBufferIdx;
            UInt32 numSamplesToCopyRemainder = numFrames*numChannels-(kBufferLength- InputAudioBufferIdx);
            memcpy(&InputAudioDataBufferGlobal[InputAudioBufferIdx],data,numSamplesToCopyFirst*sizeof(float));
            
            // fill the beginning of the buffer with remainder of samples
            InputAudioBufferIdx = 0;
            memcpy(InputAudioDataBufferGlobal,&data[numFrames*numChannels-numSamplesToCopyRemainder],numSamplesToCopyRemainder*sizeof(float));
            InputAudioBufferIdx += numFrames*numChannels;
        }
        
    }];
    
    
// Measure dBs
// ==================================================
//    __block float dbVal = 0.0;
//    [audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels) {
//    
//        // square the vector
//        vDSP_vsq(data, 1, data, 1, numFrames*numChannels);
//        
//        // take the mean
//        float meanVal = 0.0;
//        vDSP_meanv(data, 1, &meanVal, numFrames*numChannels);
//    
//        float one = 1.0;
//        vDSP_vdbcon(&meanVal, 1, &one, &meanVal, 1, 1, 0);
//        dbVal = dbVal + 0.2*(meanVal - dbVal);
//        printf("Decibel level: %f\n", dbVal);
//        
//    }];

    //===================================================
    // Get Max
    // ==================================================
//    [audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels) {
//        
//        // get the max
//        float maxVal = 0.0;
//        vDSP_maxv(data, 1, &maxVal, numFrames*numChannels);
//
//        printf("Max Audio Value: %f\n", maxVal);
//        
//    }];

//    FrequencyGlobal = 600.0;
//    __block float phase = 0.0;
//    __block float samplingRate = audioManager.samplingRate;
//    //__block double phaseIncrement = frequency / samplingRate;
//    [audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
//     {
//         double phaseIncrement = FrequencyGlobal / samplingRate;
//         for (int i=0; i < numFrames; ++i)
//         {
//             for (int iChannel = 0; iChannel < numChannels; ++iChannel)
//             {
//                 float theta = phase * M_PI * 2;
//                 data[i*numChannels + iChannel] = sin(theta);
//             }
//             phase += phaseIncrement;
//             if (phase > 1.0) phase = -1;
//         }
//     }];
    
    
    // Basic playthru example
//    [audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels) {
//        float volume = 0.5;
//        vDSP_vsmul(data, 1, &volume, data, 1, numFrames*numChannels);
//        ringBuffer->AddNewInterleavedFloatData(data, numFrames, numChannels);
//    }];
//    
//    
//    [audioManager setOutputBlock:^(float *outData, UInt32 numFrames, UInt32 numChannels) {
//        ringBuffer->FetchInterleavedData(outData, numFrames, numChannels);
//    }];
    
    
    // MAKE SOME NOOOOO OIIIISSSEEE
    // ==================================================
    //     [audioManager setOutputBlock:^(float *newdata, UInt32 numFrames, UInt32 thisNumChannels)
    //         {
    //             for (int i = 0; i < numFrames * thisNumChannels; i++) {
    //                 newdata[i] = (rand() % 100) / 100.0f / 2;
    //         }
    //     }];
    

// MEASURE SOME DECIBELS!
// ==================================================
//    __block float dbVal = 0.0;
//    [audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels) {
//
//        vDSP_vsq(data, 1, data, 1, numFrames*numChannels);
//        float meanVal = 0.0;
//        vDSP_meanv(data, 1, &meanVal, numFrames*numChannels);
//
//        float one = 1.0;
//        vDSP_vdbcon(&meanVal, 1, &one, &meanVal, 1, 1, 0);
//        dbVal = dbVal + 0.2*(meanVal - dbVal);
//        printf("Decibel level: %f\n", dbVal);
//
//    }];

// SIGNAL GENERATOR!
//    __block float frequency = 600.0;
//    __block float phase = 0.0;
//    [audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
//     {
//
//         float samplingRate = audioManager.samplingRate;
//         for (int i=0; i < numFrames; ++i)
//         {
//             for (int iChannel = 0; iChannel < numChannels; ++iChannel)
//             {
//                 float theta = phase * M_PI * 2;
//                 data[i*numChannels + iChannel] = sin(theta);
//             }
//             phase += 1.0 / (samplingRate / frequency);
//             if (phase > 1.0) phase = -1;
//         }
//     }];


// DALEK VOICE!
// (aka Ring Modulator)

//    [audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
//     {
//         ringBuffer->AddNewInterleavedFloatData(data, numFrames, numChannels);
//     }];
//
//    __block float frequency = 100.0;
//    __block float phase = 0.0;
//    [audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
//     {
//         ringBuffer->FetchInterleavedData(data, numFrames, numChannels);
//
//         float samplingRate = audioManager.samplingRate;
//         for (int i=0; i < numFrames; ++i)
//         {
//             for (int iChannel = 0; iChannel < numChannels; ++iChannel)
//             {
//                 float theta = phase * M_PI * 2;
//                 data[i*numChannels + iChannel] *= sin(theta);
//             }
//             phase += 1.0 / (samplingRate / frequency);
//             if (phase > 1.0) phase = -1;
//         }
//     }];


// VOICE-MODULATED OSCILLATOR

//    __block float magnitude = 0.0;
//    [audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
//     {
//         vDSP_rmsqv(data, 1, &magnitude, numFrames*numChannels);
//     }];
//
//    __block float frequency = 100.0;
//    __block float phase = 0.0;
//    [audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
//     {
//
//         printf("Magnitude: %f\n", magnitude);
//         float samplingRate = audioManager.samplingRate;
//         for (int i=0; i < numFrames; ++i)
//         {
//             for (int iChannel = 0; iChannel < numChannels; ++iChannel)
//             {
//                 float theta = phase * M_PI * 2;
//                 data[i*numChannels + iChannel] = magnitude*sin(theta);
//             }
//             phase += 1.0 / (samplingRate / (frequency));
//             if (phase > 1.0) phase = -1;
//         }
//     }];


// AUDIO FILE READING OHHH YEAHHHH
// ========================================
//    NSURL *inputFileURL = [[NSBundle mainBundle] URLForResource:@"TLC" withExtension:@"mp3"];
//
//    fileReader = [[AudioFileReader alloc]
//                  initWithAudioFileURL:inputFileURL
//                  samplingRate:audioManager.samplingRate
//                  numChannels:audioManager.numOutputChannels];
//
//    [fileReader play];
//    fileReader.currentTime = 30.0;
//
//    [audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
//     {
//         [fileReader retrieveFreshAudio:data numFrames:numFrames numChannels:numChannels];
//         NSLog(@"Time: %f", fileReader.currentTime);
//     }];


// AUDIO FILE WRITING YEAH!
// ========================================
//    NSArray *pathComponents = [NSArray arrayWithObjects:
//                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
//                               @"My Recording.m4a",
//                               nil];
//    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
//    NSLog(@"URL: %@", outputFileURL);
//
//    fileWriter = [[AudioFileWriter alloc]
//                  initWithAudioFileURL:outputFileURL
//                  samplingRate:audioManager.samplingRate
//                  numChannels:audioManager.numInputChannels];
//    
//    
//    __block int counter = 0;
//    audioManager.inputBlock = ^(float *data, UInt32 numFrames, UInt32 numChannels) {
//        [fileWriter writeNewAudio:data numFrames:numFrames numChannels:numChannels];
//        counter += 1;
//        if (counter > 400) { // roughly 5 seconds of audio
//            audioManager.inputBlock = nil;
//            [fileWriter release];
//        }
//    };
}

- (IBAction)frequencyChanged:(id)sender {
    UISlider *tmpSlider = (UISlider*)sender;
    FrequencyGlobal = tmpSlider.value;
    NSLog(@"Value Changed: %.2f Hz",FrequencyGlobal);
}

- (IBAction)testAsyncAnalysis:(id)sender {
    // get max of vector
    float maxVal = 0.0;
    vDSP_maxv(InputAudioDataBufferGlobal, 1, &maxVal, kBufferLength);
    
    UInt32 height = self.mainImageView.image.size.height;
    
    printf("Max Audio Value: %f, h=%d\n", maxVal, (unsigned int)height);
    
    uint64_t time_a, time_b;
    
    time_a = mach_absolute_time();
    UIImage* img = [self renderAudioToImageSlow:InputAudioDataBufferGlobal
                                   normalizeMax:1.0
                                    sampleCount:kBufferLength
                                   channelCount:1
                                    imageHeight:256
                                     imageWidth:320];
    self.mainImageView.image = img;
    time_b = mach_absolute_time();
    [self logTime:(time_b-time_a) withText:@"Slow Render Time"];
    
}

-(UIImage *) renderAudioToImageSlow:(float *) samples
                       normalizeMax:(float) normalizeMax
                        sampleCount:(NSInteger) sampleCount
                       channelCount:(NSInteger) channelCount
                        imageHeight:(float) imageHeight
                         imageWidth:(float) imageWidth{
    
    CGSize imageSize = CGSizeMake(imageWidth, imageHeight);
    UIGraphicsBeginImageContext(imageSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetAlpha(context,1.0);
    CGRect rect;
    rect.size = imageSize;
    rect.origin.x = 0;
    rect.origin.y = 0;
    
    CGColorRef leftcolor = [[UIColor whiteColor] CGColor];
    CGColorRef rightcolor = [[UIColor redColor] CGColor];
    
    CGContextFillRect(context, rect);
    
    CGContextSetLineWidth(context, 1.0);
    
    float halfGraphHeight = (imageHeight / 2) / (float) channelCount ;
    float centerLeft = halfGraphHeight;
    float centerRight = (halfGraphHeight*3) ;
    float sampleAdjustmentFactor = (imageHeight/ (float) channelCount) / (float) normalizeMax;
    int   sampleSkipValue = sampleCount/imageWidth;
    
    for (NSInteger intSample = 0, pixelIdx=0 ; intSample < sampleCount ; intSample += sampleSkipValue, ++pixelIdx ) {
        float channel1 = samples[intSample*channelCount];
        float pixels = (float) channel1;
        pixels *= sampleAdjustmentFactor;
        CGContextMoveToPoint(context, pixelIdx, centerLeft-pixels);
        CGContextAddLineToPoint(context, pixelIdx, centerLeft+pixels);
        CGContextSetStrokeColorWithColor(context, leftcolor);
        CGContextStrokePath(context);
        
        if (channelCount==2) {
            float channel2 = samples[intSample*channelCount+1];
            float pixels = (float) channel2;
            pixels *= sampleAdjustmentFactor;
            CGContextMoveToPoint(context, pixelIdx, centerRight - pixels);
            CGContextAddLineToPoint(context, pixelIdx, centerRight + pixels);
            CGContextSetStrokeColorWithColor(context, rightcolor);
            CGContextStrokePath(context);
        }
    }
    
    // Create new image
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // Tidy up
    UIGraphicsEndImageContext();
    
    return newImage;
}


- (void) logTime:(uint64_t)machTime withText:(NSString*)inputText {
    static double timeScaleSeconds = 0.0;
    if (timeScaleSeconds == 0.0) {
        mach_timebase_info_data_t timebaseInfo;
        if (mach_timebase_info(&timebaseInfo) == KERN_SUCCESS) {
            double timeScaleMicroSeconds = ((double) timebaseInfo.numer / (double) timebaseInfo.denom) / 1000;
            timeScaleSeconds = timeScaleMicroSeconds / 1000000;
        }
    }
    
    NSLog(@"%@:%g seconds", inputText, timeScaleSeconds*machTime);
}
@end
