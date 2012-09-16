//
//  AssemblerAppDelegate.h
//  Assembler
//
//  Created by ████
//

#import <Cocoa/Cocoa.h>

@interface AssemblerAppDelegate : NSObject
{
    NSWindow *window;
    
	IBOutlet NSPopUpButton *architecturePopUpButton;
	IBOutlet NSPopUpButton *syntaxPopUpButton;
    
	IBOutlet NSTextView *assemblyTextView;
	IBOutlet NSTextView *hexTextView;
	IBOutlet NSScrollView *scrollView;
	
	IBOutlet NSTextField *architectureTextField;
}

@property IBOutlet NSWindow *window;

-(IBAction)changeArchitecture:(id)sender;
-(IBAction)changeSyntax:(id)sender;
-(IBAction)clean:(id)sender;
-(IBAction)copyToClipboard:(id)sender;

-(NSString *)hexCodeForPPCInstruction:(NSString *)instr;
-(NSString *)hexCodeForATTAssemblyInstruction:(NSString *)instr;
-(NSString *)hexCodeForIntelAssemblyInstruction:(NSString *)instr;
-(NSString *)hexcodeForARMAssemblerInstruction:(NSString *)instr;


-(void)popUpButtonSelectArchitecture:(NSString *)arch;
-(void)popUpButtonSelectSyntax:(NSString *)syntax;

-(BOOL)hasText;
-(void)synchronizeLines;
-(BOOL)areLinesInSync;

-(void)deleteText;

@end