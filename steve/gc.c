/*****************************************************************************
 *                                                                           *
 * The breve Simulation Environment                                          *
 * Copyright (C) 2000-2004 Jonathan Klein                                    *
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

/*!
	The GC system in steve is an under the hood retain-count
	system.  The collectable data types are hash, list, object
	and data.  GC can be turned on/off on a per-object basis, 
	since objects can sometimes be "revived" (because of physical
	interaction or an "all" statement) even if they are not 
	referenced in memory.

	Any time new collectable data is allocated, it is given a 
	retain count of 0 and is added to a local variable collection 
	pool.  The collection pool is traversed at the end of the 
	local method.  If the retain count is still at 0, the data 
	is released.

	When any kind of variable assignment occurs, the retain count 
	is incremented.  When any kind of variable overwrite or release
	is preformed, the retain count is decremented.  If a variable
	overwrite causes a retain count to reach 0, the data is 
	released.


	Strings are a bit of a special case.  They piggy-back on the
	GC system, but do not work like the other types.  When a string 
	is set, it is always copied.  When it is unretained, it does
	not have a retain count--it is simply freed.  This system relies
	on the fact that a string will never be referenced by more than
	one memory location.


	all variable sets require a retain (hash, simple, list):
		- hash set 
		- simple set
		- list set
		- list push

	all variable overwrites or releases require immediate unretain and 
	collection:
		- hash set 
		- simple set
		- list set
		- method arguments at end of method call
		- local variables at end of method call

	creation of new collectable variables requires marking for collection:
		- new Object
		- new list
		- C-style function calls

	special treatment is needed for list operators which remove objects 
	and return them -- they are unretained and marked, but not immediately 
	collected.
		- list pop
*/

#include "steve.h"

/*!
	\brief Increments the retain count of a brEval.

	Calls type-specific retain functions.
*/

void stGCRetain(brEval *e) {
	stGCRetainPointer(e->values.pointerValue, e->type);
}

/*!
	\brief Increments the retain count of a pointer of a given type.

	Calls type-specific retain functions.
*/

inline void stGCRetainPointer(void *pointer, int type) {
	switch(type) {
		case AT_INSTANCE:
			stInstanceRetain(pointer);
			break;
		case AT_LIST:
			brEvalListRetain(pointer);
			break; 
		case AT_HASH: 
			brEvalHashRetain(pointer);
			break;
		case AT_DATA:
			brDataRetain(pointer);
			break;
		default:
			break;
	} 
}

/*!
	\brief Decrements the retain count of a brEval.

	Calls \ref stGCUnretainPointer.
*/

inline void stGCUnretain(brEval *e) {
	stGCUnretainPointer(BRPOINTER(e), e->type);
}

/*!
	\brief Decrements the retain count of a pointer of a given type.

	Calls type-specific unretain functions.
*/

inline void stGCUnretainPointer(void *pointer, int type) {
	if(!pointer) return;

	switch(type) {
		case AT_INSTANCE:
			stInstanceUnretain(pointer);
			break;
		case AT_LIST:
			brEvalListUnretain(pointer);
			break;
		case AT_HASH:
			brEvalHashUnretain(pointer);
			break;
		case AT_DATA:
			brDataUnretain(pointer);
			break;
		case AT_STRING:
			// slFree(pointer);
			break;
		default:
			break;
	}
}

/*!
	\brief Collects memory if the retain count of an eval is 0.
*/

void stGCCollect(brEval *e) {
	stGCCollectPointer(e->values.pointerValue, e->type);
}

/*!
	\brief Collects memory if the retain count of a pointer is 0.
*/

inline void stGCCollectPointer(void *pointer, int type) {
	if(!pointer) return;

	switch(type) {
		case AT_INSTANCE:
			stInstanceCollect(pointer);
			break;
		case AT_LIST:
			brEvalListCollect(pointer);
			break;
		case AT_STRING:
			slFree(pointer);
			break;
		case AT_HASH:
			brEvalHashCollect(pointer);
			break;
		case AT_DATA:
			brDataCollect(pointer);
			break;
		default:
			break;
	}
}

/*!
	\brief Decrements the retain count and collects memory if the retain
	count is 0.

	calls \ref stGCUnretain and \ref stGCCollect.
*/

void stGCUnretainAndCollect(brEval *e) {
	stGCUnretainAndCollectPointer(e->values.pointerValue, e->type);	
}

/*!
	\brief Decrements the retain count and collect memory if the retain
	count is 0.
*/

inline void stGCUnretainAndCollectPointer(void *pointer, int type) {
	stGCUnretainPointer(pointer, type);
	stGCCollectPointer(pointer, type);
}

/*!
	\brief Collects multiple expressions in an slStack structure.

	Uses \ref stGCCollect.
*/

void stGCCollectStack(slStack *gc) {
	int n;

	for(n=0;n<gc->count;n++) {
		stGCRecord *r = gc->data[n];

		stGCCollectPointer(r->pointer, r->type);
		slFree(gc->data[n]);
	}

	gc->count = 0;
}

/*!
	\brief Marks a brEval for collection, by adding it to an instance's
	collection stack.
*/

void stGCMark(stInstance *i, brEval *collect) {
	stGCMarkPointer(i, collect->values.pointerValue, collect->type);
}

/*!
	\brief Marks a pointer for collect by adding it to an instance's
	collection stack.
*/

inline void stGCMarkPointer(stInstance *i, void *pointer, int type) {
	stGCRecord *r;

	switch(type) {
		case AT_HASH:
		case AT_STRING:
		case AT_DATA:
		case AT_LIST:
			break;
		case AT_INSTANCE:
			if(!i->gc) return;
			break;
		default:
			return;
			break;
	}

	r = slMalloc(sizeof(stGCRecord));
	r->pointer = pointer;
	r->type = type;
	
	slStackPush(i->gcStack, r);
}

/*!
	\brief Unmark a brEval for collection, by removing it from an instance's
	collection stack.
*/

void stGCUnmark(stInstance *i, brEval *collect) {
	int n;
	stGCRecord *r;

	if(!i->gcStack || !collect->values.pointerValue) return;

	for(n=0;n<i->gcStack->count;n++) {
		r = i->gcStack->data[n];
	
		if(r->pointer == collect->values.pointerValue) {
			r->pointer = NULL;
		}
	}
}

/*!
	\brief Increments the reference count of an eval-list.
 
	This is so that several structures can reference the same list.
*/
	
void brEvalListRetain(brEvalListHead *lh) {
	if(!lh) return;

	lh->retainCount++;
}
	
/*!
	\brief Decrements the retain list count.
	
	If the count is then zero, the list is freed with brEvalListFree.
*/
	
void brEvalListUnretain(brEvalListHead *lh) {
	if(!lh) return;

	lh->retainCount--;
}	   
		
/*! 
	\brief Collects an evalList, if it's ready for GC.
	
	Frees the list if the retainCount is less than 1.
*/  

void brEvalListCollect(brEvalListHead *lh) {
	if(lh->retainCount < 1) brEvalListFreeGC(lh);
}

/*!
	\brief Garbage-collects and frees a brEvalList.

	Unretains and collects all list members, and then preforms a 
	regular dealocation.	
*/

void brEvalListFreeGC(brEvalListHead *lh) {
	brEvalList *list = lh->start;

	while(list) {
		stGCUnretainAndCollect(&list->eval);
		list = list->next;
	}

	brEvalListFree(lh);
}

/*!
	\brief Increments the retain count of the eval hash.
*/

void brEvalHashRetain(brEvalHash *h) {
	h->retainCount++;
}

/*!
	\brief Decrements the retain count of the eval hash.
*/

void brEvalHashUnretain(brEvalHash *h) {
	h->retainCount--;
}

/*!
	\brief Garbage-collects a brEvalHash.

	If the retain count is less than 1, all keys and values are
	unretained, and the hash table is freed.
*/

void brEvalHashCollect(brEvalHash *h) {
	if(h->retainCount < 1) brEvalHashFreeGC(h);
}

/*!
	\brief Garbage-collects and frees a brEvalHash.

	Unretains and collects all hash keys and value, then 
	preforms a regular dealocation.	
*/

void brEvalHashFreeGC(brEvalHash *h) {
	slList *all, *start;

	start = all = slHashValues(h->table);

	while(all) {
		stGCUnretainAndCollect(all->data);
		all = all->next;
	}

	slListFree(start);

	start = all = slHashKeys(h->table);

	while(all) {
		stGCUnretainAndCollect(all->data);
		all = all->next;
	}

	slListFree(start);

	brEvalHashFree(h);
}