#include "kernel.h"

/*!
	\brief Creates a breveFrontend structure containing a valid \ref brEngine.

	This function is called to setup the breveFrontend structure and to create 
	a brEngine.  If this breve frontend is being run from the command line,
	the calling function should provide the input argument count (argc) and
	the input argument pointers (argv).  If this information is not 
	available, argc should be 0, and argv should be NULL.
*/

breveFrontend *breveFrontendInit(int argc, char ** argv) {
	breveFrontend *frontend = slMalloc(sizeof(breveFrontend));

	frontend->engine = brEngineNew();
	frontend->engine->argc = argc;
	frontend->engine->argv = argv;

	// initialize frontend languages below:

#ifdef HAVE_LIBJAVA
    // brJavaInit(frontend->engine);
#endif

	return frontend;
}
