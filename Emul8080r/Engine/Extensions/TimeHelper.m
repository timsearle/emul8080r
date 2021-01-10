#import <Foundation/Foundation.h>
#import "TimeHelper.h"
#include <sys/time.h>

@implementation TimeHelper

+ (double)timeusec {
    struct timeval time;
    gettimeofday(&time, NULL);
    return ((double)time.tv_sec * 1E6) + ((double)time.tv_usec);
}

@end
