//
//  JumpCalculator.h
//  Assembler
//
//  Created by ████
//

#import <Cocoa/Cocoa.h>

@interface NSString (JumpCalculator)

-(NSString *)doJump:(NSString *)jumpType from:(NSString *)from to:(NSString *)to;

int xstrtoi(char *hex);
int HextoDec(char *hex);
char xtod(char c);

@end