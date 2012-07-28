/*****************************************************************************
 *                                                                           *
 * The breve Simulation Environment                                          *
 * Copyright (C) 2000, 2001, 2002, 2003 Jonathan Klein                       *
 *                                                                           *
 * This program is free software; you can redistribute it and/or modify      *
 * it under the terms of the GNU General Public License as published by      *
 * the Free Software Foundation; either version 2 of the License, or         *
 * (at your option) any later version.                                       *
 *                                                                           *
 * This program is distributed in the hope that it will be useful,           *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of            *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             *
 * GNU General Public License for more details.                              *
 *                                                                           *
 * You should have received a copy of the GNU General Public License         *
 * along with this program; if not, write to the Free Software               *
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA *
 *****************************************************************************/

#import "slBreveSuperDuperWalker.h"
#import <unistd.h>

@implementation slBreveSuperDuperWalker

- (brInstance *) simulationState {
  brEval result;
  brMethodCallByNameWithArgs(viewEngine->controller, "get-state", NULL, 0, &result);
  brInstance *state = (brInstance *)result.getPointer();
  return state;
}

- (NSDictionary *) integerMapping {
  NSDictionary *integerMap = [NSDictionary dictionaryWithObjectsAndKeys:
                              _mutationWaveCompression, @"mwaveCompression",
                              _mutationPhaseShifts, @"mphaseShifts",
                              _mutationAmplitudeShifts, @"mampShifts",
                              _mutationLimbLengths, @"mlimbLengths",
                              _mutationNumberOfLimbs, @"mnumLimbs",
                              _mutationNumberOfSegments, @"mnumSegments",
                              _mutationWidth, @"mwidth",
                              _mutationLength, @"mlength",
                              _mutationLimbMountPoints, @"mlimbPoints",
                              _initialPopulation, @"total-monkeys",
                              _maxLimbs, @"maxlimbs",
                              _maxSegments, @"maxsegments",
                              _maxWidth, @"maxwidth",
                              _maxLength, @"maxlength",
                              nil];
  return integerMap;
}

- (NSDictionary *) doubleMapping {
  NSDictionary *floatMap = [NSDictionary dictionaryWithObjectsAndKeys:
                            _mutationRate, @"mutationrate",
                            _fitnessTestTime, @"driver-time",
                            nil];
  return floatMap;
}

- (id) subviewWithTag:(int)tag {
  NSView *view = [configWindow contentView];
  id result = [view viewWithTag:tag];
  NSLog(@"%s %i => %@", __PRETTY_FUNCTION__, tag, result);
  return result;
}

- (id) pairedObjectOf:(id)object {
  int tag = [object tag];
  return [self subviewWithTag:tag+100];
}

- (void)loadSettings {
	if(!viewEngine) return;
	
  NSDictionary *integerMap = [self integerMapping];
  NSDictionary *floatMap = [self doubleMapping];

  brInstance *state = [self simulationState];
  
  for (NSString *integerName in integerMap) {
    brEval result;
    NSString *selector = [NSString stringWithFormat:@"get-%@", integerName];
    brMethodCallByNameWithArgs(state, [selector cStringUsingEncoding:NSUTF8StringEncoding], NULL, 0, &result);
    int size = result.getInt();
    NSLog(@"%@ => %i", selector, size);
    id object = [integerMap objectForKey:integerName];
    [object setIntValue:size];
    [[self pairedObjectOf:object] setIntValue:size];
  }
  
  for (NSString *floatName in floatMap) {
    brEval result;
    NSString *selector = [NSString stringWithFormat:@"get-%@", floatName];
    brMethodCallByNameWithArgs(state, [selector cStringUsingEncoding:NSUTF8StringEncoding], NULL, 0, &result);
    double size = result.getDouble();
    NSLog(@"%@ => %f", selector, size);
    id object = [floatMap objectForKey:floatName];
    [object setDoubleValue:size];
    [[self pairedObjectOf:object] setDoubleValue:size];
  }
}

- (const char*)getSimName {
  return "SuperDuperWalker.tz";
}

- (const char*)getDefaultsName {
	return "breveSuperDuperWalker";
}

- (void) setIntegerValue:(int)value
                  forKey:(NSString *)key
{
  brInstance *state = [self simulationState];
  const brEval *args[2];
  brEval eval[2];
  brEval result;
  
  eval[0].set(value);
  args[0] = &eval[0];
  args[1] = &eval[1];
  
  NSString *selectorName = [NSString stringWithFormat:@"set-%@", key];
  NSLog(@"%@ %i", selectorName, value);
	brMethodCallByNameWithArgs(state, [selectorName cStringUsingEncoding:NSUTF8StringEncoding], args, 1, &result);
}

- (void) setDoubleValue:(double)value
                 forKey:(NSString *)key
{
  brInstance *state = [self simulationState];
  const brEval *args[2];
  brEval eval[2];
  brEval result;
  
  eval[0].set(value);
  args[0] = &eval[0];
  args[1] = &eval[1];
  
  NSString *selectorName = [NSString stringWithFormat:@"set-%@", key];
  NSLog(@"%@ %f", selectorName, value);
	brMethodCallByNameWithArgs(state, [selectorName cStringUsingEncoding:NSUTF8StringEncoding], args, 1, &result);
}

- (IBAction)preferenceChanged:(id)sender {
  if(!viewEngine->controller) return;
  NSLog(@"%s %@", __PRETTY_FUNCTION__, sender);
  
  NSDictionary *intMap = [self integerMapping];
  for (NSString *aKey in intMap) {
    id object = [intMap objectForKey:aKey];
    if (object == sender) {
      [self setIntegerValue:[sender intValue]
                     forKey:aKey];
      [[self pairedObjectOf:object] setIntValue:[sender intValue]];
      return;
    }
  }
  NSDictionary *doubleMap = [self doubleMapping];
  for (NSString *aKey in doubleMap) {
    id object = [doubleMap objectForKey:aKey];
    if (object == sender) {
      [self setDoubleValue:[sender doubleValue]
                    forKey:aKey];
      [[self pairedObjectOf:object] setDoubleValue:[sender doubleValue]];
      return;
    }
  }
}

- (IBAction)resetEvolution:(id)sender {
  char *str;
  
  str = (char*)[[NSString stringWithFormat: @"%@/SuperDuperWalkerState.xml", outputDirectory] cString];
  
  if(str) unlink(str);
  
	// make sure that the XML file does not get recreated.
  
	[self callControllerMethod: @"disable-save"];
}

- (NSString*)getNibName {
  return @"breveSuperDuperWalker.nib";
}   

@end
