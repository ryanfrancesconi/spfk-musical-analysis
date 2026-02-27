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

    MusicalKeyValue value = parse(samples, numberOfSamples, sampleRate);

    _stringValue = value.stringValue;
    _index = value.identifier;

    return self;
}

MusicalKeyValue parse(const float *samples, double numberOfSamples,
                      float sampleRate) {
    int blockLength = 4096;
    int hopLength = 2048;
    int keyIndex = -1;

    CKey *cKey = new CKey();

    if (!cKey)
        return; // error

    cKey->init(samples, numberOfSamples, sampleRate);

    clock_t time = clock();

    cout << "Computing key..." << endl;

    keyIndex = cKey->compKey();

    std::string stringValue =
        cKey->getKeyString(static_cast<CKey::Keys_t>(keyIndex));

    cout << "Key computation done in: \t"
         << (clock() - time) * 1.F / CLOCKS_PER_SEC << " seconds." << endl;
    cout << "Result: " << stringValue << endl;

    NSString *nsString = [NSString stringWithUTF8String:stringValue.c_str()];

    return MusicalKeyValue{keyIndex, nsString};
}

@end

NS_ASSUME_NONNULL_END
