//
//  SMUViewController.m
//  NovocaineExample
//
//  Copyright (c) 2013 Eric Larson. All rights reserved.
//

#define kBufferLength 1024*4

#import "SMUViewController.h"
#import <mach/mach_time.h>
#import "SMUGraphHelper.h"
#import "SMUFFTHelper.h"

@interface SMUViewController ()
@property (weak, nonatomic) IBOutlet UILabel *f2Label;
@property (weak, nonatomic) IBOutlet UILabel *f1Label;
@property (weak, nonatomic) IBOutlet UISwitch *audioSwitch;
@end

@implementation SMUViewController

RingBuffer      *ringBuffer;
Novocaine       *audioManager;

// global variables can be placed here, these are not properties of self
// thus referring to them does not create an instance of self (important for blocks)
float           *inputAudioDataBuffer;
unsigned int    inputAudioBufferIdx;
float           frequency1;
float           frequency2;
float           *fftMagnitudeBuffer;
float           *fftPhaseBuffer;
SMUFFTHelper    *fftHelper;
GraphHelper     *graphHelper;
BOOL            isPulsing;
int            onPulse;
NSTimer         *myTimer;
int             numTicks;


//  override the GLKView draw function, from OpenGLES
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    graphHelper->draw(); // draw the graph
}


//  override the GLKViewController update function, from OpenGLES
- (void)update{
    
    // take FFT of the data
    ringBuffer->FetchInterleavedData(inputAudioDataBuffer, kBufferLength, 1);
    fftHelper->forward(0,inputAudioDataBuffer, fftMagnitudeBuffer, fftPhaseBuffer);
    graphHelper->setGraphData(2,                    //channel index
                              inputAudioDataBuffer,   //data
                              kBufferLength,    //data length
                              1.0, 0.0);                // max value to normalize (==1 if not set)
    
    // now also plot the decibel value FFT
    float one = 1.0;
    vDSP_vdbcon(fftMagnitudeBuffer,1,&one,fftMagnitudeBuffer,1,kBufferLength/2,0);
    //graphHelper->setGraphData(1,fftMagnitudeBuffer,kBufferLength/2, 10.0, -30.0); // set graph channel, max=10, min=-30
    
//    for(int i=0;i<kBufferLength/2;i++){
//        fftMagnitudeBuffer[i] = 20*logb(fftMagnitudeBuffer[i]);
//    }
    
    // just plot the audio stream
    //graphHelper->setGraphData(0,&fftMagnitudeBuffer[0],kBufferLength/15, 10.0, -30.0); // set graph channel
    
    graphHelper->update(); // update the graph
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    //================================================
    // setup the audio instances for novocaine
    //================================================
    // get new instances
    
    isPulsing = NO;
    onPulse = YES;
    ringBuffer = new RingBuffer(kBufferLength,1);
    audioManager = [Novocaine audioManager];
    
    NSLog(@"Current Buffer Size = %.4f ms",kBufferLength/audioManager.samplingRate*1000);
    
    // allocate some space for the copied audio samples
    inputAudioDataBuffer  = (float *)calloc(kBufferLength, sizeof(float));
    memset(inputAudioDataBuffer, 0, kBufferLength*sizeof(float)); // set everything to zero for now
    inputAudioBufferIdx = 0;//index for filling circular buffer
    
    //setup the fft
    fftHelper = new SMUFFTHelper(kBufferLength,kBufferLength,WindowTypeRect);
    fftMagnitudeBuffer = (float *)calloc(kBufferLength/2,sizeof(float));
    fftPhaseBuffer     = (float *)calloc(kBufferLength/2,sizeof(float));
    
    // start animating the graph
    int framesPerSecond = 15;
    int numDataArraysToGraph = 3;
    graphHelper = new GraphHelper(self,
                                  framesPerSecond,
                                  numDataArraysToGraph,
                                  PlotStyleSeparated);//drawing starts immediately after call
    
    graphHelper->SetBounds(-0.9,0.5,-0.9,0.9); // bottom, top, left, right, full screen==(-1,1,-1,1)
    
    
}

-(void) viewDidDisappear:(BOOL)animated{
    // stop opengl from running
    graphHelper->tearDownGL();
}



-(void)dealloc{
    graphHelper->tearDownGL();
    
    // ARC handles everything else, just clean up what we used c++ for (calloc, malloc, new)
    free(inputAudioDataBuffer);
    free(fftMagnitudeBuffer);
    free(fftPhaseBuffer);
    
    delete fftHelper;
    delete ringBuffer;
    
}

-(void)viewWillAppear:(BOOL)animated{
    //overloading this function, call to get functiionality
    [super viewWillAppear:animated];
    
    //===================================================
    // copy over the data into a temporary buffer
    // ==================================================
//    __weak typeof(self) weakSelf = self;
    [audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels) {
        // copy over the bytes for use in our analysis later
        // fill the buffer if not already filled
        ringBuffer->AddNewInterleavedFloatData(data, numFrames, numChannels);
//        if((numFrames*numChannels+inputAudioBufferIdx) <= kBufferLength){
//            // okay to just fill buffer in one place
//            memcpy(&inputAudioDataBuffer[inputAudioBufferIdx],data,numFrames*numChannels*sizeof(float));
//            inputAudioBufferIdx += numFrames*numChannels;
//        }
//        else{
//            // need to circularly fill the buffer
//            // fill the end of the buffer
//            UInt32 numSamplesToCopyFirst = kBufferLength-inputAudioBufferIdx;
//            UInt32 numSamplesToCopyRemainder = numFrames*numChannels - (kBufferLength - inputAudioBufferIdx);
//            memcpy(&inputAudioDataBuffer[inputAudioBufferIdx],data,numSamplesToCopyFirst*sizeof(float));
//            
//            // fill the beginning of the buffer with remainder of samples
//            inputAudioBufferIdx = 0;
//            memcpy(inputAudioDataBuffer,&data[numFrames*numChannels-numSamplesToCopyRemainder],numSamplesToCopyRemainder*sizeof(float));
//            inputAudioBufferIdx += numFrames*numChannels;
//        }
        
    }];

//    frequency = 18000.0;
//    __block float phase = 0.0;
//    __block float samplingRate = audioManager.samplingRate;
//    [audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
//     {
//         double phaseIncrement = frequency / samplingRate;
//         for (int i=0; i < numFrames; ++i)
//         {
//             for (int iChannel = 0; iChannel < numChannels; ++iChannel)
//             {
//                 float theta = phase * M_PI * 2;
//                 data[i*numChannels + iChannel] = 0.9*sin(theta);
//             }
//             phase += phaseIncrement;
//             if (phase >= 1.0) phase -= 2;
//         }
//     }];
    
    frequency1 = 1500.0; //starting frequency
    frequency2 = 1700.0; //starting frequency
    __block float phase1 = 0.0;
    __block float phase2 = 0.0;
    __block float samplingRate = audioManager.samplingRate;
    [audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {
         if(onPulse==1){
             double phaseIncrement1 = 2*M_PI*frequency1/samplingRate;
             double phaseIncrement2 = 2*M_PI*frequency2/samplingRate;
             double sineWavePeriod = 2*M_PI;
             for (int i=0; i < numFrames; ++i)
             {
                 for(int j=0;j<numChannels;j++)
                     data[i*numChannels+j] = 0.5*sin(phase1) + 0.5*sin(phase2);
                 
                 phase1 += phaseIncrement1;
                 if (phase1 >= sineWavePeriod) phase1 -= 2*M_PI;
                 phase2 += phaseIncrement2;
                 if (phase2 >= sineWavePeriod) phase2 -= 2*M_PI;
             }
         }
         else if(onPulse==2){
             double phaseIncrement1 = 2*M_PI*(frequency1+1000)/samplingRate;
             double phaseIncrement2 = 2*M_PI*(frequency2+1000)/samplingRate;
             double sineWavePeriod = 2*M_PI;
             for (int i=0; i < numFrames; ++i)
             {
                 for(int j=0;j<numChannels;j++)
                     data[i*numChannels+j] = 0.5*sin(phase1) + 0.5*sin(phase2);
                 
                 phase1 += phaseIncrement1;
                 if (phase1 >= sineWavePeriod) phase1 -= 2*M_PI;
                 phase2 += phaseIncrement2;
                 if (phase2 >= sineWavePeriod) phase2 -= 2*M_PI;
             }
         }
         else
         {
             for (int i=0; i < numFrames; ++i)
             {
                 for(int j=0;j<numChannels;j++)
                     data[i*numChannels+j] = 0;
             }
         }
     }];
    
    // Examples from the original Novocaine Example Project

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
- (IBAction)switchChanged:(UISwitch *)sender {
    if(!sender.isOn)
         onPulse=0;
    else
        onPulse=1;
}
- (IBAction)setFrequenciesClose:(UIButton *)sender {
    if (frequency1 != 2000){
        frequency1 = 2000;
        frequency2 = 2050;
    }
    else if (frequency1 == 2000){
        frequency1 = 2040;
        frequency2 = 2050;
    }
    self.f1Label.text = [NSString stringWithFormat:@"%.2f Hz",frequency1];
    self.f2Label.text = [NSString stringWithFormat:@"%.2f Hz",frequency2];
}

- (IBAction)frequencyChanged:(UISlider*)sender {
    frequency1 = sender.value;
    self.f1Label.text = [NSString stringWithFormat:@"%.2f Hz",frequency1];
}
- (IBAction)f2Changed:(UISlider *)sender {
    frequency2 = sender.value;
    self.f2Label.text = [NSString stringWithFormat:@"%.2f Hz",frequency2];
}

- (IBAction)testAsyncAnalysis:(UIButton*)sender {
//    uint64_t time_a, time_b;
//    time_a = mach_absolute_time();
//    
//    // get max of vector
//    float maxVal = 0.0;
//    vDSP_maxv(inputAudioDataBuffer, 1, &maxVal, kBufferLength);
//    printf("max value = %.2f\n",maxVal);
//    
//    time_b = mach_absolute_time();
//    [self logTime:(time_b-time_a) withText:@"Time to calcualte max: "];
    if(!isPulsing){
        //need to stop pulsing
        myTimer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(switchPulse:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:myTimer forMode: NSDefaultRunLoopMode];
        
    }else{
        [myTimer invalidate];
        myTimer = nil;
        onPulse = 1;
    }
    
    isPulsing = !isPulsing;
    
    
}

-(void)switchPulse:(NSTimer*)timer{
    if(self.audioSwitch.isOn){
        numTicks++;
        onPulse = 0;
        if(numTicks==10){
            onPulse = 1;
        }
        else if(numTicks>12){
            onPulse=2;
            numTicks=0;
        }
    }else
        onPulse=0;
}


- (void) logTime:(uint64_t)machTime withText:(NSString*)inputText {
    // I have used this function for a long time, got most elements from stack overflow
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
