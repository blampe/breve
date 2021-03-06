#ifndef _BREVEOBJECTAPI_H
#define _BREVEOBJECTAPI_H

#include <vector>

enum allocStatus { 
	AS_RELEASED = -1,	// still allocated, but ready to be freed
	AS_FREED,		// all memory freed--don't try to use 
	AS_ACTIVE		// active object
};

typedef struct brObjectType brObjectType;
typedef struct brMethod brMethod;
typedef struct brCollisionHandler brCollisionHandler;

class brEngine;
class brEval;

/** \addtogroup breveObjectAPI */
/*@{*/

/**
 * \brief A type of object, required for each frontend language.
 *
 * brObjectType is an interface that allows breve to preform common tasks
 * for a variety of frontend languages.  It contains function pointers 
 * that allow breve to create and destroy instances, call methods, etc.
 *
 * If you create a new frontend, you'll need to create a brObjectType and
 * provide it with functions to do the various tasks.
 */

struct brObjectType {
	brObjectType() {
		findMethod 			= NULL;
		findObject			= NULL;
		instantiate			= NULL;
		callMethod			= NULL;
		isSubclass			= NULL;
		destroyObject			= NULL;
		destroyMethod			= NULL;
		destroyInstance 		= NULL;
		destroyObjectType		= NULL;
		userData			= NULL;
		_typeSignature 			= 0;
	}

	~brObjectType() {
		if( destroyObjectType && userData )
			destroyObjectType( userData );
	}

	/**
	 * Finds an object class in the given language frontend
	 */
	void					*(*findObject)( void *inObjectTypeUserData, const char *inName );

	/**
	 * Finds a method in a given class
	 */
	void					*(*findMethod)( void *inObjectUserData, const char *inName, unsigned char *inTypes, int inTypeCount );

	/**
	 * Creates a new instance of the given class.  The constructor arguments are currently unused.
	 */
	brInstance			  	*(*instantiate)( brEngine *inEngine, brObject *inObject, const brEval **inArguments, int inArgCount );

	/**
	 * Calls a method in the language frontend
	 */
	int					 (*callMethod)( void *inInstanceUserData, void *inMethodUserData, const brEval **inArguments, brEval *inResult );

	/**
	 * Returns 1 if parent is a subclass of parent.
	 */
	int					 (*isSubclass)( void *inChild, void *inParent );

	/**
	 * Destroys an instance of a language object previously created with instantiate.
	 */
	void					(*destroyObject)( void *inObject );

	/**
	 * Destroys an instance of a language method previously created with findMethod.
	 */
	void					(*destroyMethod)( void *inMethod );

	/**
	 * Destroys an instance of a language instance previously created with instantiate.
	 */
	void					(*destroyInstance)( void *inInstance );

	/**
	 * Frees any leftover memory associated with the frontend, typically _userData.
	 */
	void					(*destroyObjectType)( void *inObjectType );

	/**
	 * A function to determine whether or not the given code can be loaded based on the file extension
	 */
	int					(*canLoad)( void *inObjectTypeUserData, const char *inFileExtension );

	/**
	 * A function to execute code in this frontend language.
	 */
	int					(*load)( brEngine *inEngine, void *inObjectTypeUserData, const char *inFilename, const char *inFiletext );

	/**
	 * A function to execute code in this frontend language.
	 */
	int					(*loadWithArchive)( brEngine *inEngine, void *inObjectTypeUserData, const char *inFilename, const char *inFiletext, const char *inArchive );

	/**
	 * A user-data callback pointer.
	 */
	void					*userData;

	/**
	 * A unique identifier which will be set for all objects of this object type.  This
	 * identifier can be used to determine whether an instance or object is native to 
	 * a certain object type.
	 */

	long					_typeSignature;
};

/**
 * \brief An object class.
 *
 * An object class, of any language.
 */

struct brObject {
	void *userData;

	brObjectType *type;

	char *name;

	std::vector< brCollisionHandler* > collisionHandlers;
};

/**
 * \brief A breve instance, of any language.
 *
 * brInstance is an object instance in the breve engine, though the 
 * object could be part of any language, steve, java, SmallTalk, etc.
 * Note: the "object" field was previously named "class".  This has been
 * changed to avoid conflicts with C++ compilers.
 */

struct brInstance {
	brInstance( brEngine *inEngine, brObject *inObject ) {
		engine = inEngine;
		object = inObject;

		status = AS_ACTIVE; 
		
		iterate = NULL;
		postIterate = NULL;
	}

	void *userData;

	char status;

	brMethod *iterate;
	brMethod *postIterate;

	brObject *object;
	brEngine *engine;

	std::vector< brMenuEntry* > _menus;

	std::vector< brObserver* > observers;
	std::vector< brInstance* > observees;
};

/**
 * \brief A collision handler.
 *
 * Keeps track of what methods are used to handle collisions between objects.
 */

struct brCollisionHandler {
	brObject *object;
	brMethod *method;
	unsigned char ignore;
};

/**
 * \brief A reference to a native method.
 * 
 * A reference to a method of any language.
 *
 * Note: the "object" field was previously named "class".  This has been
 * changed to avoid conflicts with C++ compilers.
 */

struct brMethod {
	~brMethod() {
		if( name )
			slFree( name );

		if( object && object->type->destroyMethod && userData )
			object->type->destroyMethod( userData );
	}

	void *userData;

	char *name;
	brObject *object;
	int argumentCount;
};

/**
 * \brief An observer object.
 *
 * Contains information about one object watching another, waiting for 
 * a certain announcement.
 */

struct brObserver {
	brObserver( brInstance *obs, brMethod *meth, char *note ) {
		instance = obs;
		method = meth;
		notification = slStrdup( note );
	}

	~brObserver() {
		delete method;
		slFree( notification );
	}

	brInstance *instance;
	brMethod *method;
	char *notification;
};

/*@}*/

#ifdef __cplusplus
extern "C" {
#endif

DLLEXPORT void brEngineLock( brEngine * );
DLLEXPORT void brEngineUnlock( brEngine * );

// registering a new object type

DLLEXPORT void brEngineRegisterObjectType(brEngine *, brObjectType * );

// locating objects and methods within objects

DLLEXPORT brMethod *brMethodFind(brObject *, const char *, unsigned char *, int);
DLLEXPORT brMethod *brMethodFindWithArgRange(brObject *, const char *, unsigned char *, int, int);

DLLEXPORT brObject *brObjectFind(brEngine *, const char *);
DLLEXPORT brObject *brUnknownObjectFind(brEngine *, const char *);

// functions for getting user data

DLLEXPORT void *brInstanceGetUserData(brInstance *);
DLLEXPORT void *brObjectGetUserData(brInstance *);

// functions for calling methods with breve instances

DLLEXPORT int brMethodCall(brInstance *, brMethod *, const brEval **, brEval *);
DLLEXPORT int brMethodCallByName(brInstance *, const char *, brEval *);
DLLEXPORT int brMethodCallByNameWithArgs(brInstance *, const char *, const brEval **, int, brEval *);

// functions related to adding and removing classes and instances to the breve engine

DLLEXPORT brObject *brEngineAddObject(brEngine *, brObjectType *, const char *, void *);
DLLEXPORT void brEngineAddObjectAlias(brEngine *, char *, brObject *);

DLLEXPORT brInstance *brObjectInstantiate(brEngine *, brObject *, const brEval **, int);

DLLEXPORT brInstance *brEngineAddInstance(brEngine *, brObject *, void *);
DLLEXPORT brInstance *brEngineAddBreveInstance(brEngine *, brObject *, brInstance * );

DLLEXPORT void brEngineRemoveInstance(brEngine *, brInstance *);

DLLEXPORT int brObjectAddCollisionHandler(brObject *, brObject *, char *);
DLLEXPORT int brObjectSetIgnoreCollisionsWith(brObject *, brObject *, int);

// adding and removing dependencies and observers 

DLLEXPORT int brInstanceAddDependency(brInstance *i, brInstance *dependency);
DLLEXPORT int brInstanceAddObserver(brInstance *i, brInstance *observer, char *notification, char *mname);
DLLEXPORT int brEngineRemoveInstanceDependency(brInstance *i, brInstance *dependency);
DLLEXPORT void brEngineRemoveInstanceObserver(brInstance *i, brInstance *observerInstance, char *notification);

// cleaning up 

DLLEXPORT void brInstanceRelease(brInstance *i);

DLLEXPORT void brObjectFree(brObject *o);
DLLEXPORT void brInstanceFree(brInstance *i);
DLLEXPORT void brMethodFree(brMethod *i);

#ifdef __cplusplus
}
#endif

#endif
