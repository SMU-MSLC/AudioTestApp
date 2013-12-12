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

@interface SMUViewController : UIViewController
{
    RingBuffer *ringBuffer;
    Novocaine *audioManager;
    AudioFileReader *fileReader;
    AudioFileWriter *fileWriter;
}

@end
