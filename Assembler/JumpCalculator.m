//
//  JumpCalculator.m
//  Assembler
//
//  Created by ████
//

#import "JumpCalculator.h"

@implementation NSString (JumpCalculator)

- (NSString *)doJump:(NSString *)jumpType from:(NSString *)from to:(NSString *)to
{
	if (jumpType && from && to)
    {
		int startOffset = xstrtoi((char *)[from UTF8String]);
		int endOffset = xstrtoi((char *)[to UTF8String]);
		
		if ([jumpType isEqualToString:@"jmpl"] == 1)
        {
			// jmpl 0x0000cd48 0x0000cf8c --> E93F020000
			int jumpLength = endOffset - startOffset - 5;
			int big = (((jumpLength & 0xff)<<8) | ((jumpLength & 0xff00)>>8));
			NSString *hex = [[NSString stringWithFormat:@"E9%-8X\n", big]
                             stringByReplacingOccurrencesOfString:@" " withString:@"0"];
			return hex;
		}
		else if ([jumpType isEqualToString:@"jnel"] == 1)
        {
			// jnel 0x00002991 0x00002b38 --> 0F85A1010000
			int jumpLength = endOffset - startOffset - 6;
			int big = (((jumpLength & 0xff)<<8) | ((jumpLength & 0xff00)>>8));
			NSString *hex = [[NSString stringWithFormat:@"0F85%-8X\n", big]
                             stringByReplacingOccurrencesOfString:@" " withString:@"0"];
			return hex;
		}
		else if ([jumpType isEqualToString:@"jel"] == 1)
        {
			// jel 0x000031cd 0x000032ad --> 0F84DA000000
			int jumpLength = endOffset - startOffset - 6;
			int big = (((jumpLength & 0xff)<<8) | ((jumpLength & 0xff00)>>8));
			NSString *hex = [[NSString stringWithFormat:@"0F84%-8X\n", big]
                             stringByReplacingOccurrencesOfString:@" " withString:@"0"];
			return hex;
		}
		else if ([jumpType isEqualToString:@"jmp"] == 1)
        {
			// jmp 0x0000391a 0x00003926 --> EB0A
			int jumpLength = endOffset - startOffset - 2;
			NSString *hex = [[NSString stringWithFormat:@"EB%2X\n", jumpLength]
                             stringByReplacingOccurrencesOfString:@" " withString:@"0"];
			return hex;
		}
		else if ([jumpType isEqualToString:@"jne"] == 1)
        {
			// jne 0x00003924 0x00003976 --> 7550
			int jumpLength = endOffset - startOffset - 2;
			NSString *hex = [[NSString stringWithFormat:@"75%2X\n", jumpLength]
                             stringByReplacingOccurrencesOfString:@" " withString:@"0"];
			return hex;
		}
		else if ([jumpType isEqualToString:@"je"] == 1)
        {
			// je 0x00003a88 0x00003aa2 --> 7418
			int jumpLength = endOffset - startOffset - 2;
			NSString *hex = [[NSString stringWithFormat:@"74%2X\n", jumpLength]
                             stringByReplacingOccurrencesOfString:@" " withString:@"0"];
			return hex;
		}
		else if ([jumpType isEqualToString:@"b"] == 1)
        {
			// b 0x0000218c 0x000021b8 --> 4800002c
			int jumpLength = endOffset - startOffset;
			NSString *hex = [[NSString stringWithFormat:@"48%6X\n", jumpLength]
                             stringByReplacingOccurrencesOfString:@" " withString:@"0"];
			return hex;
		}
		else if ([jumpType isEqualToString:@"bne"] == 1)
        {
			//  bne 0x0001a9a4 0x0001aa18 --> 40820074
			int jumpLength = (endOffset - startOffset);
			NSString *hex = [[NSString stringWithFormat:@"4082%.4X\n", jumpLength]
                             stringByReplacingOccurrencesOfString:@" " withString:@"0"];
			return hex;
		}
		else if ([jumpType isEqualToString:@"beq"] == 1)
        {
			//  beq 0x00090af8 0x00090b24 --> 4182002c
			int jumpLength = (endOffset - startOffset);
			NSString *hex = [[NSString stringWithFormat:@"4182%.4X\n", jumpLength]
                             stringByReplacingOccurrencesOfString:@" " withString:@"0"];
			return hex;
		}
	}
    else
    {
        return @"jumpcalculator: error";
    }
}

int xstrtoi(char *hex)
{
    return HextoDec(hex+strlen(hex)-1);
}

int HextoDec(char *hex)
{
    if (*hex==0)
        return 0;
    else
        return HextoDec(hex-1)*16 + xtod(*hex) ;
}

char xtod(char c)
{
	if (c>='0' && c<='9')
        return c-'0';
	else if (c>='A' && c<='F')
        return c-'A'+10;
	else if (c>='a' && c<='f')
        return c-'a'+10;
	else
        return c=0;
}

@end