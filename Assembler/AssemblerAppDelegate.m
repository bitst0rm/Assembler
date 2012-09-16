//
//  AssemblerAppDelegate.m
//  Assembler
//
//  Created by ████
//

#if defined __i386__
NSString *architecture = @"i386";
#elif defined __x86_64__
NSString *architecture = @"x86_64";
#elif defined __ppc__ || defined __ppc64__
NSString *architecture = @"PPC";
#else
NSString *architecture = @"unknownArchitecture";
#endif

#import "AssemblerAppDelegate.h"
#import "JumpCalculator.h"
#import "Command.h"
#import <CoreServices/CoreServices.h>

@implementation AssemblerAppDelegate

@synthesize window;

-(void)awakeFromNib
{
	[architecturePopUpButton selectItemWithTitle:architecture];
	[[architecturePopUpButton itemWithTitle:architecture] setState:NSOnState];
	
    [syntaxPopUpButton selectItemWithTitle:@"AT&T"];
    [[syntaxPopUpButton itemWithTitle:@"AT&T"] setState:NSOnState];
    [[syntaxPopUpButton itemWithTitle:@"ARM"] setHidden:YES]; // defaults to arch we're running in
    [[syntaxPopUpButton itemWithTitle:@"Thumb"] setHidden:YES]; // so we wont need these at start
    
	NSView *docView = [scrollView documentView];
	[docView addSubview:assemblyTextView];
	[docView addSubview:hexTextView];
	
	[assemblyTextView setVerticallyResizable:TRUE];
	[hexTextView setEditable:FALSE];

	NSMutableDictionary *typingAttributes = [[assemblyTextView typingAttributes] mutableCopy];
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragraphStyle setMinimumLineHeight:25];
    [paragraphStyle setMaximumLineHeight:25];
    [typingAttributes setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
    [assemblyTextView setTypingAttributes:typingAttributes];
	[hexTextView setTypingAttributes:typingAttributes];

	NSFont *font = [NSFont fontWithName:@"Lucida Grande" size:14];
	[assemblyTextView setFont:font];
	[assemblyTextView setTextContainerInset:NSMakeSize(8,4)];
	[hexTextView setFont:font];
	[hexTextView setTextContainerInset:NSMakeSize(8,4)];
	
	[hexTextView setBackgroundColor:[NSColor colorWithCalibratedHue:0.6209 saturation:0.0686
                                                         brightness:0.9804 alpha:1.0000]];
	[scrollView setBackgroundColor:[NSColor colorWithCalibratedHue:0.2889 saturation:0.0002
                                                            brightness:0.5595 alpha:1.0000]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewChangedFrame:)
                                                 name:NSViewFrameDidChangeNotification object:assemblyTextView];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewChangedFrame:)
                                                 name:NSViewFrameDidChangeNotification object:hexTextView];
		
	[architectureTextField setStringValue:[NSString stringWithFormat:
                                           [architectureTextField stringValue], architecture]];
	[window setContentBorderThickness:24 forEdge:NSMinYEdge];    
}

// same thing as at&t intel, just here for readability's sake
-(NSString *)hexCodeForPPCInstruction:(NSString *)instr
{
    SInt32 minor;
    Gestalt(gestaltSystemVersionMinor, &minor);
    if (minor == 7) // if lion, no ppc here :(
    {
        return @"OS X Lion has no PPC support\n";
    }
    else
    {
        char code[255];
        fgets((char *)&code, 255, popen([[NSString stringWithFormat:@"%@ %@ '%@'",
                                          [[NSBundle mainBundle] pathForResource:@"asm2hex" ofType:@"sh"],
                                          [[architecturePopUpButton titleOfSelectedItem] lowercaseString],
                                          instr] UTF8String], "r"));
        return [NSString stringWithFormat:@"%s", code];
    }
}

-(NSString *)hexCodeForATTAssemblyInstruction:(NSString *)instr
{
	char code[255];
	fgets((char *)&code, 255, popen([[NSString stringWithFormat:@"%@ %@ '%@'",
                                      [[NSBundle mainBundle] pathForResource:@"asm2hex" ofType:@"sh"],
                                      [[architecturePopUpButton titleOfSelectedItem] lowercaseString],
                                      instr] UTF8String], "r"));
	return [NSString stringWithFormat:@"%s", code];
}

-(NSString *)hexCodeForIntelAssemblyInstruction:(NSString *)instr
{
    NSMutableString *instruction = [NSMutableString string];
    if ([[[architecturePopUpButton selectedItem] title] isEqualToString:@"x86_64"])
    {
        // need BITS 64 at top of file for 64 bit in nasm
        instruction = [NSString stringWithFormat:@"BITS 64\n%@", instr];
    }
    else if ([[[architecturePopUpButton selectedItem] title] isEqualToString:@"i386"])
    {
        instruction = [NSString stringWithFormat:@"BITS 32\n%@", instr];
    }
    
    NSData *instructionData = [instruction dataUsingEncoding:NSASCIIStringEncoding];
    NSFileManager *file = [[NSFileManager alloc] init];
    [file createFileAtPath:@"/tmp/instruction" contents:instructionData attributes:nil];
    [file createFileAtPath:@"/tmp/asm2hex" contents:nil attributes:nil];
    NSArray *args = [[NSArray alloc] initWithObjects:@"/tmp/instruction", @"-f", @"bin", @"-o", @"/tmp/asm2hex", nil];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"nasm" ofType:@"bin"];
    NSTask *nasm = [NSTask launchedTaskWithLaunchPath:path arguments:args];
    [nasm waitUntilExit];
    
    NSData *opcode = [file contentsAtPath:@"/tmp/asm2hex"];
    NSCharacterSet *junkSet = [NSCharacterSet characterSetWithCharactersInString:@"<> "];
    NSString *out = [NSString stringWithFormat:@"%@\n", [[opcode description]
                                                         stringByTrimmingCharactersInSet:junkSet]];
    out = [out stringByReplacingOccurrencesOfString:@" " withString:@""];
    [file removeItemAtPath:@"/tmp/asm2hex" error:nil];
    [file removeItemAtPath:@"/tmp/instruction" error:nil];
    return out;
}

-(NSString *)hexcodeForARMAssemblerInstruction:(NSString *)instr
{
	char code[255];
	fgets((char *)&code, 255, popen([[NSString stringWithFormat:@"%@ %@ '%@'",
                                      [[NSBundle mainBundle] pathForResource:@"asm2hex" ofType:@"sh"],
                                      @"armv7", [instr lowercaseString]] UTF8String], "r"));
	return [NSString stringWithFormat:@"%s", code];
}

-(BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{
	BOOL w = FALSE;
	if (aSelector == @selector(insertNewline:))
    {
		[hexTextView setEditable:TRUE];
		NSString *instruction = [[[assemblyTextView string] componentsSeparatedByString:@"\n"] lastObject];
        NSDictionary *commandDict = [Command commandDict];
        NSString *command = [[instruction componentsSeparatedByString:@" "] objectAtIndex:0];
        NSMutableArray *args = [[instruction componentsSeparatedByString:@" "] mutableCopy];
        [args removeObjectAtIndex:0];
		NSArray *jumpInstructions = [NSArray arrayWithObjects:@"jmpl", @"jnel", @"jel", @"jmp", @"jne",
                                     @"je", @"b", @"bne", @"beq", nil];
		NSString *hexCode = @"";
		BOOL possibleError = FALSE;
        
		if ([instruction isEqualToString:@""])
        {
			w = TRUE;
		}
        
		else if ([jumpInstructions containsObject:[[instruction componentsSeparatedByString:@" "]
                objectAtIndex:0]] == TRUE && [[instruction componentsSeparatedByString:@" "] count] == 3)
        {
			hexCode = [hexCode doJump:[[instruction componentsSeparatedByString:@" "] objectAtIndex:0]
                                 from:[[instruction componentsSeparatedByString:@" "] objectAtIndex:1]
                                   to:[[instruction componentsSeparatedByString:@" "] objectAtIndex:2]];
			possibleError = TRUE;
		}
        
        else if ([commandDict valueForKey:command] != nil)
        {
            SEL method = NSSelectorFromString([commandDict valueForKey:command]);
            hexCode = [Command performSelector:method withObject:args];
        }
        
		else if ([instruction isEqualToString:@"clear"])
        {
			[self deleteText];
			[assemblyTextView scrollRangeToVisible:NSMakeRange([[assemblyTextView string] length], 0)];
			[hexTextView scrollRangeToVisible:NSMakeRange([[hexTextView string] length], 0)];
			w = TRUE;
		}
        
		else if ([instruction isEqualToString:@"copy"])
        {
			if ([[hexTextView string] isEqualToString:@""] == FALSE)
            {
				[self copyToClipboard:self];
				hexCode = [NSString stringWithFormat:@"Copied '%@' to the clipboard.\n", 
                           [[[hexTextView string] componentsSeparatedByString:@"\n"]
                            objectAtIndex:([[[hexTextView string] componentsSeparatedByString:@"\n"] count] - 2)]];
			}
			else
            {
				[self clean:self];
				w = TRUE;
			}
		}
        
		else if ([instruction isEqualToString:@"ppc"])
        {
			[self popUpButtonSelectArchitecture:@"PPC"];
			hexCode = @"Switched to PPC\n";
		}
        
		else if ([instruction isEqualToString:@"i386"])
        {
			[self popUpButtonSelectArchitecture:@"i386"];
			hexCode = @"Switched to i386\n";
		}
        
		else if ([instruction isEqualToString:@"x86_64"])
        {
			[self popUpButtonSelectArchitecture:@"x86_64"];
			hexCode = @"Switched to x86_64\n";
		}
        
        else if ([instruction isEqualToString:@"arm"])
        {
            [self popUpButtonSelectArchitecture:@"ARMv7"];
            hexCode = @"Switched to ARMv7\n";
        }
        
        else if ([instruction isEqualToString:@"intel"])
        {
            if ([[[architecturePopUpButton selectedItem] title] isEqualToString:@"PPC"])
            {
                [self popUpButtonSelectSyntax:@"Intel"];
                hexCode = @"\n";
            }
            
            else if ([[[architecturePopUpButton selectedItem] title] isEqualToString:@"ARMv7"])
            {
                hexCode = @"\n";
            }
            
            else
            {
                [self popUpButtonSelectSyntax:@"Intel"];
                hexCode = @"Switched to intel syntax\n";
            }
        }
        
        else if ([instruction isEqualToString:@"att"])
        {
            if ([[[architecturePopUpButton selectedItem] title] isEqualToString:@"PPC"])
            {
                [self popUpButtonSelectSyntax:@"AT&T"];
                hexCode = @"\n";
            }
            
            else if ([[[architecturePopUpButton selectedItem] title] isEqualToString:@"ARMv7"])
            {
                hexCode = @"\n";
            }
            
            else
            {
                [self popUpButtonSelectSyntax:@"AT&T"];
                hexCode = @"Switched to AT&T syntax\n";
            }
        }
                
        else if ([instruction isEqualToString:@"exit"])
        {
            exit(0);
        }
        
		else // we havent defined it as a command, so it's gotta be an assembly instruction
        {
            if ([[[architecturePopUpButton selectedItem] title] isEqualToString:@"PPC"])
            {
                hexCode = [self hexCodeForPPCInstruction:instruction];
                possibleError = TRUE;
            }
            
            else if ([[[architecturePopUpButton selectedItem] title] isEqualToString:@"i386"] || 
                [[[architecturePopUpButton selectedItem] title] isEqualToString:@"x86_64"])
            {
                if ([[[syntaxPopUpButton selectedItem] title] isEqualToString:@"AT&T"])
                {
                    hexCode = [self hexCodeForATTAssemblyInstruction:instruction];
                    possibleError = TRUE;
                }
                
                else if ([[[syntaxPopUpButton selectedItem] title] isEqualToString:@"Intel"])
                {
                    hexCode = [self hexCodeForIntelAssemblyInstruction:instruction];
                    possibleError = TRUE;
                }
            }
            
            else if ([[[architecturePopUpButton selectedItem] title] isEqualToString:@"ARMv7"])
            {
                hexCode = [self hexcodeForARMAssemblerInstruction:instruction];
                possibleError = TRUE;
            }
        }
		
		if ([[hexCode componentsSeparatedByString:@" "] count] > 1 && possibleError == TRUE)
        {
			hexCode = [hexCode stringByReplacingOccurrencesOfString:@"/tmp/instruction:1:" withString:@""];
			hexCode = [hexCode stringByReplacingOccurrencesOfString:@"`" withString:@"'"];
		}
		
		[hexTextView insertText:hexCode replacementRange:NSMakeRange([[hexTextView string] length],0)];
		
		[self synchronizeLines];
		[hexTextView setEditable:FALSE];
	}
    
	else if (aSelector == @selector(deleteBackward:))
    {
		if ([self areLinesInSync] == TRUE)
        {
			w = TRUE;
		}
	}
	return w;
}

-(IBAction)changeArchitecture:(id)sender
{
	[[sender itemAtIndex:1] setState:NSOffState];
	[[sender itemAtIndex:2] setState:NSOffState];
	[[sender itemAtIndex:3] setState:NSOffState];
    [[sender itemAtIndex:4] setState:NSOffState];
    NSMenuItem *selectedItem = [sender selectedItem];
	[selectedItem setState:NSOnState];
    
    if ([[selectedItem title] isEqualToString:@"PPC"])
    {
        for (NSMenuItem *i in [syntaxPopUpButton itemArray])
        {
            [i setHidden:YES]; // we're on PPC so there's only one syntax anyways
        }
    }
    
    else if ([[selectedItem title] isEqualToString:@"i386"] || [[selectedItem title] isEqualToString:@"x86_64"])
    {
        for (NSMenuItem *i in [syntaxPopUpButton itemArray])
        {
            if ([[i title] isEqualToString:@"AT&T"] || [[i title] isEqualToString:@"Intel"])
            {
                [i setHidden:NO]; // undo hiding from switching to PPC or ARM
            }
            else
            {
                [i setHidden:YES];
            }
        }
        // for some reason it feels it needs to add the icon as an item <_<
        [[syntaxPopUpButton itemWithTitle:@""] setHidden:YES];
        [self popUpButtonSelectSyntax:@"AT&T"];
    }
    
    else if ([[selectedItem title] isEqualToString:@"ARMv7"])
    {
        for (NSMenuItem *i in [syntaxPopUpButton itemArray])
        {
            [i setHidden:YES];
        }        
    }
}

-(IBAction)changeSyntax:(id)sender
{
    [[sender itemAtIndex:1] setState:NSOffState];
    [[sender itemAtIndex:2] setState:NSOffState];
    [[sender selectedItem] setState:NSOnState];
}

// kinda redundant but whatever
-(void)popUpButtonSelectArchitecture:(NSString *)arch
{
	[[architecturePopUpButton itemAtIndex:1] setState:NSOffState];
	[[architecturePopUpButton itemAtIndex:2] setState:NSOffState];
	[[architecturePopUpButton itemAtIndex:3] setState:NSOffState];
    [[architecturePopUpButton itemAtIndex:4] setState:NSOffState];
    [architecturePopUpButton selectItemWithTitle:arch];
	[[architecturePopUpButton itemWithTitle:arch] setState:NSOnState];
    NSMenuItem *selectedItem = [architecturePopUpButton selectedItem];
	[selectedItem setState:NSOnState];
    
    if ([[selectedItem title] isEqualToString:@"PPC"])
    {
        for (NSMenuItem *i in [syntaxPopUpButton itemArray])
        {
            [i setHidden:YES]; // we're on PPC so there's only one syntax anyways
        }
    }
    
    else if ([[selectedItem title] isEqualToString:@"i386"] || [[selectedItem title] isEqualToString:@"x86_64"])
    {
        for (NSMenuItem *i in [syntaxPopUpButton itemArray])
        {
            if ([[i title] isEqualToString:@"AT&T"] || [[i title] isEqualToString:@"Intel"])
            {
                [i setHidden:NO]; // undo hiding from switching to PPC or ARM
            }
            else
            {
                [i setHidden:YES];
            }
        }
        // for some reason it feels it needs to add the icon as an item <_<
        [[syntaxPopUpButton itemWithTitle:@""] setHidden:YES];
        [self popUpButtonSelectSyntax:@"AT&T"];
    }
    
    else if ([[selectedItem title] isEqualToString:@"ARMv7"])
    {
        for (NSMenuItem *i in [syntaxPopUpButton itemArray])
        {
            [i setHidden:YES];
        }
    }
}

-(void)popUpButtonSelectSyntax:(NSString *)syntax
{
    [[syntaxPopUpButton itemAtIndex:1] setState:NSOffState];
    [[syntaxPopUpButton itemAtIndex:2] setState:NSOffState];
    [syntaxPopUpButton selectItemWithTitle:syntax];
    [[syntaxPopUpButton itemWithTitle:syntax] setState:NSOnState];
}

-(IBAction)clean:(id)sender
{
	[self deleteText];
}

-(IBAction)copyToClipboard:(id)sender
{
	if ([[hexTextView string] isEqualToString:@""] == FALSE)
    {
		NSPasteboard *pb = [NSPasteboard generalPasteboard];
		[pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
		[pb setString:[[[hexTextView string] componentsSeparatedByString:@"\n"]
                    objectAtIndex:([[[hexTextView string] componentsSeparatedByString:@"\n"] count] - 2)]
                    forType:NSStringPboardType];
	}
}

-(BOOL)hasText
{
	if ([[assemblyTextView string] isEqualToString:@""] && [[hexTextView string] isEqualToString:@""])
    {
		return FALSE;
	}
	else
    {
		return TRUE;
	}
}

-(void)synchronizeLines
{
	int assemblyTextViewNumberOfLines, hexTextViewNumberOfLines;
	
	NSLayoutManager *assemblyTextViewLayoutManager = [assemblyTextView layoutManager];
	NSLayoutManager *hexTextViewLayoutManager = [hexTextView layoutManager];
	
	unsigned numberOfLines, index, numberOfGlyphs = (unsigned)[assemblyTextViewLayoutManager numberOfGlyphs];
	NSRange lineRange;
	for (numberOfLines = 0, index = 0; index < numberOfGlyphs; numberOfLines++)
    {
		(void)[assemblyTextViewLayoutManager lineFragmentRectForGlyphAtIndex:index effectiveRange:&lineRange];
		index = (unsigned int)NSMaxRange(lineRange);
	}
	assemblyTextViewNumberOfLines = numberOfLines;
	
	numberOfGlyphs = (unsigned int)[hexTextViewLayoutManager numberOfGlyphs];
	NSRange lineRange2;
	for (numberOfLines = 0, index = 0; index < numberOfGlyphs; numberOfLines++)
    {
		(void)[hexTextViewLayoutManager lineFragmentRectForGlyphAtIndex:index effectiveRange:&lineRange2];
		index = (unsigned int)NSMaxRange(lineRange2);
	}
	hexTextViewNumberOfLines = numberOfLines;
	
	if (assemblyTextViewNumberOfLines < hexTextViewNumberOfLines)
    {
		while (assemblyTextViewNumberOfLines < hexTextViewNumberOfLines)
        {
			[assemblyTextView insertText:@"\n"];
			assemblyTextViewNumberOfLines++;
		}
	}
	else if (assemblyTextViewNumberOfLines > hexTextViewNumberOfLines)
    {
		while (assemblyTextViewNumberOfLines > hexTextViewNumberOfLines)
        {
			[hexTextView insertText:@"\n"];
			hexTextViewNumberOfLines++;
		}
	}
}

-(BOOL)areLinesInSync
{
	BOOL s;
	int assemblyTextViewNumberOfLines, hexTextViewNumberOfLines;
	
	NSLayoutManager *assemblyTextViewLayoutManager = [assemblyTextView layoutManager];
	NSLayoutManager *hexTextViewLayoutManager = [hexTextView layoutManager];
	
	unsigned numberOfLines, index, numberOfGlyphs = (unsigned)[assemblyTextViewLayoutManager numberOfGlyphs];
	NSRange lineRange;
	for (numberOfLines = 0, index = 0; index < numberOfGlyphs; numberOfLines++)
    {
		(void)[assemblyTextViewLayoutManager lineFragmentRectForGlyphAtIndex:index effectiveRange:&lineRange];
		index = (unsigned int)NSMaxRange(lineRange);
	}
	assemblyTextViewNumberOfLines = numberOfLines;
	
	numberOfGlyphs = (unsigned int)[hexTextViewLayoutManager numberOfGlyphs];
	NSRange lineRange2;
	for (numberOfLines = 0, index = 0; index < numberOfGlyphs; numberOfLines++)
    {
		(void)[hexTextViewLayoutManager lineFragmentRectForGlyphAtIndex:index effectiveRange:&lineRange2];
		index = (unsigned int)NSMaxRange(lineRange2);
	}
	hexTextViewNumberOfLines = numberOfLines;
	
	if (assemblyTextViewNumberOfLines == hexTextViewNumberOfLines)
    {
		s = TRUE;
	}
	else
    {
		s = FALSE;
	}
	return s;
}

-(void)deleteText
{
	[assemblyTextView setString:@""];
	[hexTextView setString:@""];
}

-(void)textViewChangedFrame:(NSNotification *)note
{
	NSRect assemblyTextViewFrame = [assemblyTextView frame];
	NSRect hexTextViewFrame = [hexTextView frame];
	CGFloat maxHeight = NSHeight(assemblyTextViewFrame);
	if (NSHeight(hexTextViewFrame) > maxHeight) maxHeight = NSHeight(hexTextViewFrame);
	assemblyTextViewFrame.origin.y = 0;
	assemblyTextViewFrame.size.height = maxHeight;
	hexTextViewFrame.origin.y = 0;
	hexTextViewFrame.size.height = maxHeight;
	NSView *docView = [scrollView documentView];
	NSRect docViewFrame = [docView frame];
	docViewFrame.size.height = maxHeight;
	[docView setFrame:docViewFrame];
	[assemblyTextView setFrame:assemblyTextViewFrame];
	[hexTextView setFrame:hexTextViewFrame];
}

@end