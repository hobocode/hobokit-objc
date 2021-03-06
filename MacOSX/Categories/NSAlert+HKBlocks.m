//  Copyright (c) 2011 HoboCode
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import "NSAlert+HKBlocks.h"

@implementation NSAlert (HKBlocks)

- (void)beginSheetModalForWindow:(NSWindow *)window didEndBlock:(void (^)(NSInteger returnCode))block
{
    id bl = nil;
    if ( block )
    {
        bl = [block copy];
        CFRetain( bl );
    }

    [self beginSheetModalForWindow:window
                     modalDelegate:self
                    didEndSelector:@selector(hk_alertDidEnd:returnCode:contextInfo:)
                       contextInfo:bl];
}

- (void)hk_alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if ( contextInfo )
    {
        void (^block)( NSInteger returnCode ) = contextInfo;
        block( returnCode );
        CFRelease( block );
        [block release];
    }
}

@end