// Copyright Ryan Francesconi. All Rights Reserved. Revision History at
// https://github.com/ryanfrancesconi/spfk-audio-content-analysis

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct {
    int32_t identifier;
    NSString *stringValue;
} MusicalKeyValue;

@interface MusicalKey : NSObject

@property(nonatomic, nonnull) NSString *stringValue;
@property(nonatomic) int index;

- (instancetype)initWithData:(const float *)samples
             numberOfSamples:(int)numberOfSamples
                  sampleRate:(float)sampleRate;

@end

NS_ASSUME_NONNULL_END
