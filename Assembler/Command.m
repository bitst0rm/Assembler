//
//  Command.m
//  Assembler
//
//  Created by ████
//

#import "Command.h"

@implementation Command

+(NSDictionary *)commandDict
{
    // the command name is the key and the selector/method name is the value.
    // anything entered that matches the key before the first space will cause the method to be called
    return [NSDictionary dictionaryWithObjectsAndKeys:@"helpCommand:", @"help", @"jumpHelp:", @"jumphelp",
            @"commandList:", @"cmd", @"swapEndian:", @"endian", @"calcBase:",
            @"base", @"KITTEH:", @"kitten", @"yarly:", @"orly", nil];
}

+(NSString *)helpCommand:(NSArray *)args
{
    return @"Assembles any common instruction to opcodes, calculates jumps and helps with number conversion.\nTo get to"
        " know more about jumps type in 'jumphelp'.\n'cmd' lists all commands.\n";
}

+(NSString *)jumpHelp:(NSArray *)args
{
    return @"<type> <from> <to>\ne.g. 'jmpl 0x0000cd48 0x0000cf8c'\nAvailable: jmpl jnel jel jmp jne je b bne beq\n"
        "jumps aren't supported with ARMv7.\n";
}

+(NSString *)commandList:(NSArray *)args
{
    NSString *ret = [NSString stringWithFormat:@"All commands:\n%@\n",
                     [[[Command commandDict] allKeys] componentsJoinedByString:@", "]];
    return ret;
}

+(NSString *)swapEndian:(NSArray *)args
{
    if ([args count] != 1 || [[args objectAtIndex:0] isEqualToString:@"help"])
    {
        return @"Usage: endian number\nSwaps the specified number's endian.\n";
    }
    else
    {
        NSCharacterSet *hexadecimal = [NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF"];
        NSArray *invalidChars = [[[args objectAtIndex:0] stringByReplacingOccurrencesOfString:@"0x" withString:@""]
                                componentsSeparatedByCharactersInSet:[hexadecimal invertedSet]];
        NSString *number = [invalidChars componentsJoinedByString:@""];
    
        if ([number length] < 1)
        {
            return @"No valid hex value entered\n";
        }
        
        NSMutableString *buffer = [NSMutableString string];
        for (unsigned i = 0; i < number.length-1; i+=2)
        {
            unsigned byte;
            NSScanner *scanner = [NSScanner scannerWithString:[number substringWithRange:NSMakeRange(i,2)]];
            [scanner scanHexInt:&byte];
            [buffer insertString:[NSString stringWithFormat:@"%02X", byte] atIndex:0];
        }
        if ([buffer hasPrefix:@"0"])
            buffer = (NSMutableString *)[buffer substringFromIndex:1];
        
        return [NSString stringWithFormat:@"%@\n", buffer];
    }
}

+(NSString *)calcBase:(NSArray *)args
{
    if ([args count] != 1 || [[args objectAtIndex:0] isEqualToString:@"help"])
    {
        return @"Usage: base (hex or decimal number)\nConverts the number to hex or decimal accordingly\n";
    }
    else
    {
        NSString *number = [args objectAtIndex:0];

        // check for 0x, convert to dec, or convert dec to hex etc
        if ([number rangeOfString:@"0x"].location == NSNotFound)
        {
            return [NSString stringWithFormat:@"0x%x\n", [number intValue]];
        }
        else
        {
            unsigned int decimal;
            NSScanner *scan = [NSScanner scannerWithString:number];
            [scan scanHexInt:&decimal];
            return [NSString stringWithFormat:@"%u\n", decimal];
        }
    }
}

+(NSString *)KITTEH:(NSArray *)args
{
    return @"=^_^=\n";
}

+(NSString *)yarly:(NSArray *)args
{
    return @"yarly\n";
}

@end
