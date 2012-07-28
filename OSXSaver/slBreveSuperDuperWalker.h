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

#import <Cocoa/Cocoa.h>
#import "slBreveSaver.h"

@interface slBreveSuperDuperWalker : slBreveSaver
{
  IBOutlet id _initialPopulation;
  IBOutlet id _fitnessTestTime;
  IBOutlet id _maxLimbs;
  IBOutlet id _maxSegments;
  IBOutlet id _maxWidth;
  IBOutlet id _maxLength;
  IBOutlet id _mutationRate;

  IBOutlet id _mutationWaveCompression;
  IBOutlet id _mutationPhaseShifts;
  IBOutlet id _mutationAmplitudeShifts;
  IBOutlet id _mutationLimbLengths;
  IBOutlet id _mutationNumberOfLimbs;
  IBOutlet id _mutationNumberOfSegments;
  IBOutlet id _mutationWidth;
  IBOutlet id _mutationLength;
  IBOutlet id _mutationLimbMountPoints;
}

- (IBAction)resetEvolution:(id)sender;
- (IBAction)preferenceChanged:(id)sender;

@end
