/**
 * Modified MIT License
 *
 * Copyright 2019 OneSignal
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * 1. The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * 2. All copies of substantial portions of the Software may only be used in connection
 * with services provided by OneSignal.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "OSFocusTimeProcessorFactory.h"
#import "OneSignalCommonDefines.h"
#import "OSAttributedFocusTimeProcessor.h"
#import "OSUnattributedFocusTimeProcessor.h"
#import "OneSignalHelper.h"
#import "OSOutcomesUtils.h"

@implementation OSFocusTimeProcessorFactory

static NSDictionary<NSString*, OSBaseFocusTimeProcessor*> *_focusTimeProcessors;
+ (NSDictionary<NSString*, OSBaseFocusTimeProcessor*>*)focusTimeProcessors {
    if (!_focusTimeProcessors)
        _focusTimeProcessors = [NSMutableDictionary new];
    return _focusTimeProcessors;
}

+ (void)cancelFocusCall {
    for (NSString* key in self.focusTimeProcessors) {
        let timeProcesor = [self.focusTimeProcessors objectForKey:key];
        [timeProcesor cancelDelayedJob];
    }
    [OneSignal onesignal_Log:ONE_S_LL_VERBOSE message:[NSString stringWithFormat:@"cancelFocusCall of %@", self.focusTimeProcessors]];
}

+ (void)resetUnsentActiveTime {
    for (NSString *key in self.focusTimeProcessors) {
        let timeProcesor = [self.focusTimeProcessors objectForKey:key];
        [timeProcesor resetUnsentActiveTime];
    }
    
    [OneSignal onesignal_Log:ONE_S_LL_VERBOSE message:[NSString stringWithFormat:@"resetUnsentActiveTime of %@", self.focusTimeProcessors]];
}

+ (OSBaseFocusTimeProcessor *)createTimeProcessorWithSessionResult:(OSSessionResult *)result focusEventType:(FocusEventType)focusEventType {
    let isAttributed = [OSOutcomesUtils isAttributedSession:result.session];
    let attributionState = isAttributed ? ATTRIBUTED : NOATTRIBUTED;
    NSString *key = focusAttributionStateString(attributionState);
    
    var timeProcesor = [self.focusTimeProcessors objectForKey:key];
    if (!timeProcesor) {
        switch (attributionState) {
            case ATTRIBUTED:
                timeProcesor = [OSAttributedFocusTimeProcessor new];
                break;
             case NOATTRIBUTED:
                // TODO: This looks like a bug in the following case;
                // 1. Background the app
                // 2. Wait 30 secounds
                // 3. Resume app
                // 4. END_SESSION will be triggered and we would send time for this sonner than we should
                //    However maybe not an issue but this creates a flow that changes besed state that isn't related.
                if (focusEventType == END_SESSION)
                    // We only need to send unattributed focus time when the app goes out of focus.
                    break;
                timeProcesor = [OSUnattributedFocusTimeProcessor new];
                break;
        }
        
        [self.focusTimeProcessors setValue:timeProcesor forKey:key];
    }
    
    [OneSignal onesignal_Log:ONE_S_LL_VERBOSE
                     message:[NSString stringWithFormat:@"TimeProcessor %@ for session attributed %d",timeProcesor, isAttributed]];
    
    return timeProcesor;
}

@end
