
#include <ctime>
#include <fstream>
#include <iostream>

// #include "AcaAll.h"

// #include "AudioFileIf.h"
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
    int iBlockLength = 4096;
    int iHopLength = 2048;
    int keyIndex = -1;

    clock_t time = 0;
    CKey *cKey = 0;
    cKey = new CKey();

    if (!cKey)
        return; // error

    cKey->init(samples, numberOfSamples, sampleRate);

    time = clock();

    // compute key
    cout << "\n1. computing key..." << endl;
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
