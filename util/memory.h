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

#include <stdio.h>

enum mallocStatus {
    MS_NULL = 0,
    MS_MALLOC,
    MS_REALLOC,
    MS_FREE
};

/*!
	\brief Data used to track a memory allocation, only used when memory 
	debugging is enabled.
*/

struct slMallocData {
    void *pointer;
    int size;

    char status;
};

void *slMalloc(int n);
void *slRealloc(void *p, int n);
void slFree(void *p);

int slMallocHash(void *hash, void *p, slMallocData *d);
slMallocData *slMallocLookup(void *hash, void *p);
slMallocData *slNewUtilMallocData(void *p, int size);

int slUtilMemoryUnfreed();
void slUtilMemoryFreeAll();

void slMessage(int level, char *format, ...);
char *slDequeueMessage();
int slCheckMessageQueue();

void slFatal(char *format, ...);
void utilPause();
double randomDouble();

void slMemoryReport();
int slMemoryAllocated();

void slDebugMatrix(int level, double m[3][3]);

slHash *slInitUtilMallocHash();

void slPrintIfString(char *pointer, int length, int maxlen);

unsigned int slUtilPointerCompare(void *a, void *b);
unsigned int slUtilPointerHash(void *a, unsigned int n);