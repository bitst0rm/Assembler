//
//  Command.h
//  Assembler
//
//  Created by ████
//

#import <Foundation/Foundation.h>

@interface Command : NSObject

+(NSDictionary *)commandDict;

// all commands need to be class methods that take
// one NSArray arg (even if it doesnt need them)
// and returns an NSString (the output)
+(NSString *)helpCommand:(NSArray *)args;
+(NSString *)jumpHelp:(NSArray *)args;
+(NSString *)commandList:(NSArray *)args;
+(NSString *)swapEndian:(NSArray *)args;
+(NSString *)calcBase:(NSArray *)args;
+(NSString *)KITTEH:(NSArray *)args;
+(NSString *)yarly:(NSArray *)args;

@end
