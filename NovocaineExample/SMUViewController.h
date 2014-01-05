//
//  SMUViewController.h
//  NovocaineExample
//
//  Created by Eric Larson on 12/12/13.
//  Copyright (c) 2013 Eric Larson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Novocaine.h"
#import "RingBuffer.h"
#import "AudioFileReader.h"
#import "AudioFileWriter.h"
#import <GLKit/GLKit.h>

@interface SMUViewController : GLKViewController // notice that this inherits from GLKViewController, must use for GraphHelper
{
    // audio class variables
    RingBuffer      *ringBuffer;
    Novocaine       *audioManager;
    AudioFileReader *fileReader;
    AudioFileWriter *fileWriter;
    
}

- (IBAction)frequencyChanged:(id)sender;
- (IBAction)testAsyncAnalysis:(id)sender;

@end
