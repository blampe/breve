#ifndef _STEVE_H
#define _STEVE_H

#define STINSTANCE(x)	((stInstance *)(BRPOINTER(x)))

#include "util.h"
#include "kernel.h"

#include "steveTypedefs.h"

#include "object.h"

#include "gc.h"

#include "stringexp.h"
#include "dataObject.h"
#include "genetic.h"

#include "steveFrontend.h"
#include "interactive.h"

#include "evalListSort.h"
#include "evalListCopyGC.h"

#include "steveparse.h"

#endif 
