// Copyright Ryan Francesconi. All Rights Reserved. Revision History at
// https://github.com/ryanfrancesconi/spfk-audio-content-analysis

#include <ctime>
#include <fstream>
#include <iostream>

#include "Key.h"
#import "MusicalKey.h"

NS_ASSUME_NONNULL_BEGIN

using std::cout;
using std::endl;

@implementation MusicalKey

- (instancetype)initWithData:(const float *)samples
             numberOfSamples:(int)numberOfSamples
                  sampleRate:(float)sampleRate {
    self = [super init];

    CMusicalKeyResult value = parse(samples, numberOfSamples, sampleRate);

    _stringValue = value.stringValue;
    _keyIndex = value.keyIndex;

    return self;
}

CMusicalKeyResult parse(const float *samples, double numberOfSamples,
                        float sampleRate) {
    int keyIndex = -1;

    CKey *cKey = new CKey();

    cKey->init(samples, numberOfSamples, sampleRate);

    keyIndex = cKey->compKey();

    if (keyIndex == -1) {
        return CMusicalKeyResult{keyIndex, @""};
    }

    std::string stringValue =
        cKey->getKeyString(static_cast<CKey::Keys_t>(keyIndex));

    NSString *nsString = [NSString stringWithUTF8String:stringValue.c_str()];

    return CMusicalKeyResult{keyIndex, nsString};
}

@end

NS_ASSUME_NONNULL_END
