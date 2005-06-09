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

#include "kernel.h"
#include "joint.h"

/*! \addtogroup InternalFunctions */
/*@{*/

#define BRJOINTPOINTER(p)	((slJoint*)BRPOINTER(p))
#define BRLINKPOINTER(p)	((slLink*)BRPOINTER(p))

/*!
	\brief Applies torque to a joint.

	void jointApplyTorque(slJoint pointer joint, vector torque).

	Since the joint may be 1, 2 or 3 DOF, only some elements of 
	the torque vector may be used.
*/

int brIJointApplyTorque(brEval args[], brEval *target, brInstance *i) {
	slJoint *j = BRJOINTPOINTER(&args[0]);

	// I think this is somewhat broken.

	if (!j) {
		slMessage(DEBUG_ALL, "jointApplyTorque failed\n");
		return EC_ERROR;
	}

	j->applyTorque(&BRVECTOR(&args[1]));

	return EC_OK;
}

/*!
	\brief Create a revolute joint between two bodies.

	slJoint pointer jointLinkRevolute(slLink pointer parent, slLink pointer child
									vector normal, vector parentLinkPoint,
									vector childLinkPoint).
*/

int brJointILinkRevolute(brEval args[], brEval *target, brInstance *i) {
	slLink *parent = BRLINKPOINTER(&args[0]);
	slLink *child = BRLINKPOINTER(&args[1]);
	slVector *normal = &BRVECTOR(&args[2]);
	slVector *ppoint = &BRVECTOR(&args[3]);
	slVector *cpoint = &BRVECTOR(&args[4]);
	slJoint *joint;

	if (!child) {
		slMessage(DEBUG_ALL, "NULL pointer passed to jointLinkRevolute\n");
		return EC_ERROR;
	}

	if (!(joint = slLinkLinks(i->engine->world, parent, child, JT_REVOLUTE, normal, ppoint, cpoint, BRMATRIX(&args[5])))) {
		slMessage(DEBUG_ALL, "error creating joint: jointLinkRevolute failed\n");
		return EC_ERROR;
	}

	joint->userData = i;

	slWorldSetUninitialized(i->engine->world);

	BRPOINTER(target) = joint;
	target->type = AT_POINTER;
	
	return EC_OK;
}   

/*!
	\brief Modify the normal vector for a joint.

	void jointSetNormal(slJoint pointer joint, vector normal).
*/

int brIJointSetNormal(brEval args[], brEval *target, brInstance *i) {
	slJoint *j = BRJOINTPOINTER(&args[0]);
	slVector *n = &BRVECTOR(&args[1]);

	if (!j) {
		slMessage(DEBUG_ALL, "jointSetNormal called with uninitialized joint\n");
		return EC_ERROR;
	}

	j->setNormal(n);

	return EC_OK;
}

/*!
	\brief Modify the link points for a joint.

	void jointSetLinkPoints(slJoint pointer joint, vector parentPoint, vector childPoint).
*/

int brIJointSetLinkPoints(brEval args[], brEval *target, brInstance *i) {
	slJoint *j = BRJOINTPOINTER(&args[0]);
	slVector *n1 = &BRVECTOR(&args[1]);
	slVector *n2 = &BRVECTOR(&args[2]);
	double rot[3][3];


	slMatrixCopy(BRMATRIX(&args[3]), rot);
	j->setLinkPoints(n1, n2, rot);

	return EC_OK;
}

/*!
	\brief Create a revolute joint between two bodies.

	slJoint pointer jointLinkRevolute(slLink pointer parent, 
									slLink pointer child
									vector normal,
									vector parentLinkPoint,
									vector childLinkPoint).
*/

int brJointILinkPrismatic(brEval args[], brEval *target, brInstance *i) {
	slLink *parent = BRLINKPOINTER(&args[0]);
	slLink *child = BRLINKPOINTER(&args[1]);
	slVector *normal = &BRVECTOR(&args[2]);
	slVector *ppoint = &BRVECTOR(&args[3]);
	slVector *cpoint = &BRVECTOR(&args[4]);
	slJoint *joint;

	if (!child) {
		slMessage(DEBUG_ALL, "NULL pointer passed to jointLinkPrismatic\n");
		return EC_ERROR;
	}
 
	if (!(joint = slLinkLinks(i->engine->world, parent, child, JT_PRISMATIC, normal, ppoint, cpoint, BRMATRIX(&args[5])))) {
		slMessage(DEBUG_ALL, "error creating joint: jointLinkPrismatic failed\n");
		return EC_ERROR;
	}

	slWorldSetUninitialized(i->engine->world);

	BRPOINTER(target) = joint;
	target->type = AT_POINTER;
	
	return EC_OK;
}

/*!
	\brief Create a ball joint between two bodies.

	slJoint pointer jointLinkBall(slLink pointer parent, slLink pointer child
									vector normal, vector parentLinkPoint,
									vector childLinkPoint).
*/

int brJointILinkBall(brEval args[], brEval *target, brInstance *i) {
	slLink *parent = BRLINKPOINTER(&args[0]);
	slLink *child = BRLINKPOINTER(&args[1]);
	slVector *normal = &BRVECTOR(&args[2]);
	slVector *ppoint = &BRVECTOR(&args[3]);
	slVector *cpoint = &BRVECTOR(&args[4]);
	slJoint *joint;

	if (!child) {
		slMessage(DEBUG_ALL, "NULL pointer passed to jointLinkBall\n");
		return EC_ERROR;
	}
 
	if (!(joint = slLinkLinks(i->engine->world, parent, child, JT_BALL, normal, ppoint, cpoint, BRMATRIX(&args[5])))) {
		slMessage(DEBUG_ALL, "error creating joint: jointLinkBall failed\n");
		return EC_ERROR;
	}

	slWorldSetUninitialized(i->engine->world);

	BRPOINTER(target) = joint;
	target->type = AT_POINTER;
	
	return EC_OK;
}

/*!
	\brief Create a universal joint between two bodies.

	slJoint pointer jointLinkUniversal(slLink pointer parent, slLink pointer child
									vector normal, vector parentLinkPoint,
									vector childLinkPoint).
*/

int brJointILinkUniversal(brEval args[], brEval *target, brInstance *i) {
	slLink *parent = BRLINKPOINTER(&args[0]);
	slLink *child = BRLINKPOINTER(&args[1]);
	slVector *normal = &BRVECTOR(&args[2]);
	slVector *ppoint = &BRVECTOR(&args[3]);
	slVector *cpoint = &BRVECTOR(&args[4]);
	slJoint *joint;

	if (!child) {
		slMessage(DEBUG_ALL, "NULL pointer passed to jointLinkUniversal\n");
		return EC_ERROR;
	}
 
	if (!(joint = slLinkLinks(i->engine->world, parent, child, JT_UNIVERSAL, normal, ppoint, cpoint, BRMATRIX(&args[5])))) {
		slMessage(DEBUG_ALL, "error creating joint: jointLinkUniversal\n");
		return EC_ERROR;
	}

	slWorldSetUninitialized(i->engine->world);

	BRPOINTER(target) = joint;
	target->type = AT_POINTER;
	
	return EC_OK;
}

/*!
	\brief Create a static joint between two bodies.

	slJoint pointer jointLinkStatic(slLink pointer parent, slLink pointer child
									vector normal, vector parentLinkPoint,
									vector childLinkPoint).

	The normal vector is currently unused.
*/

int brJointILinkStatic(brEval args[], brEval *target, brInstance *i) {
	slLink *parent = BRLINKPOINTER(&args[0]);
	slLink *child = BRLINKPOINTER(&args[1]);
	slVector *normal = &BRVECTOR(&args[2]);
	slVector *ppoint = &BRVECTOR(&args[3]);
	slVector *cpoint = &BRVECTOR(&args[4]);
	slJoint *joint;

	if (!(joint = slLinkLinks(i->engine->world, parent, child, JT_FIX, normal, ppoint, cpoint, BRMATRIX(&args[5])))) {
		slMessage(DEBUG_ALL, "error creating joint: jointLinkStatic failed\n");
		return EC_ERROR;
	}

	slWorldSetUninitialized(i->engine->world);

	BRPOINTER(target) = joint;
	target->type = AT_POINTER;
	
	return EC_OK;
}

/*!
	\brief Break a joint.

	void jointBreak(slJoint pointer).
*/

int brIJointBreak(brEval args[], brEval *target, brInstance *i) {
	slJoint *joint = BRJOINTPOINTER(&args[0]);

	delete joint;

	slWorldSetUninitialized(i->engine->world);

	return EC_OK;
}

/*!
	\brief Return the distance of this joint from its natural position.

	vector getJointPosition(slJoint pointer).

	Since the joint may be 1, 2 or 3 DOF, not all of the vector components may be filled in.
*/

int brIJointGetPosition(brEval args[], brEval *target, brInstance *i) {
	slJoint *j = BRJOINTPOINTER(&args[0]);

	j->getPosition(&BRVECTOR(target));

	return EC_OK;
}

/*!
	\brief Sets the velocity of this joint.

	void jointSetVelocity(slJoint pointer joint, vector velocity).

	Since the joint may be 1, 2 or 3 DOF, some of the elements of velocity
	may not be used.
*/

int brIJointSetVelocity(brEval args[], brEval *target, brInstance *i) {
	slJoint *j = BRJOINTPOINTER(&args[0]);
	slVector *velocity = &BRVECTOR(&args[1]);

	j->setVelocity(velocity);

	return EC_OK;
}

/*!
	\brief Gets the velocity of this joint.

	vector jointGetVelocity(slJoint pointer joint).

	Since the joint may be 1, 2 or 3 DOF, some of the elements of velocity
	may not be set.
*/

int brIJointGetVelocity(brEval args[], brEval *target, brInstance *i) {
	slJoint *j = BRJOINTPOINTER(&args[0]);

	j->getVelocity(&BRVECTOR(target));

	return EC_OK;
}

/*!
	\brief Set joint damping.

	jointSetDamping(slJoint pointer joint, double damping).
*/

int brIJointSetDamping(brEval args[], brEval *target, brInstance *i) {
	slJoint *j = BRJOINTPOINTER(&args[0]);
	double value = BRDOUBLE(&args[1]);

	if (!j) {
		slMessage(DEBUG_ALL, "NULL pointer passed to jointSetDamping\n");
		return EC_ERROR;
	}

	j->_kDamp = value;

	return EC_OK;
}

/*!
	\brief Set the joint spring.

	void jointSetSpring(slJoint pointer joint, double strength, double min, double max).
*/

int brIJointSetSpring(brEval args[], brEval *target, brInstance *i) {
	slJoint *j = BRJOINTPOINTER(&args[0]);
	double strength = BRDOUBLE(&args[1]);
	double min = BRDOUBLE(&args[2]);
	double max = BRDOUBLE(&args[3]);

	j->_kSpring = strength;
	j->_sMin = min;
	j->_sMax = max;

	return EC_OK;
}

/*!
	\brief Sets the motion limits for this joint.

	void jointSetLimits(slJoint pointer joint, vector min, vector max).

	Since the joint may be 1, 2 or 3 DOF, some of the elements of velocity
	may not be used.
*/

int brIJointSetLimits(brEval args[], brEval *target, brInstance *i) {
	slJoint *j = BRJOINTPOINTER(&args[0]);
	slVector *min = &BRVECTOR(&args[1]);
	slVector *max = &BRVECTOR(&args[2]);

	j->setLimits(min, max);

	return EC_OK;
}

/*!
	\brief Sets the maximum strength for this joint.

	jointSetMaxStrength(slJoint pointer joint, double max torque).
*/

int brIJointSetMaxStrength(brEval args[], brEval *target, brInstance *i) {
	slJoint *j = BRJOINTPOINTER(&args[0]);
	double strength = BRDOUBLE(&args[1]);
	
	j->setMaxTorque(strength);

	return EC_OK;
}

/*@}*/

void breveInitJointFunctions(brNamespace *n) {
	brNewBreveCall(n, "jointApplyTorque", brIJointApplyTorque, AT_NULL, AT_POINTER, AT_DOUBLE, 0);
	brNewBreveCall(n, "jointLinkRevolute", brJointILinkRevolute, AT_POINTER, AT_POINTER, AT_POINTER, AT_VECTOR, AT_VECTOR, AT_VECTOR, AT_MATRIX, 0);
	brNewBreveCall(n, "jointLinkPrismatic", brJointILinkPrismatic, AT_POINTER, AT_POINTER, AT_POINTER, AT_VECTOR, AT_VECTOR, AT_VECTOR, AT_MATRIX, 0);
	brNewBreveCall(n, "jointLinkBall", brJointILinkBall, AT_POINTER, AT_POINTER, AT_POINTER, AT_VECTOR, AT_VECTOR, AT_VECTOR, AT_MATRIX, 0);
	brNewBreveCall(n, "jointLinkStatic", brJointILinkStatic, AT_POINTER, AT_POINTER, AT_POINTER, AT_VECTOR, AT_VECTOR, AT_VECTOR, AT_MATRIX, 0);
	brNewBreveCall(n, "jointLinkUniversal", brJointILinkUniversal, AT_POINTER, AT_POINTER, AT_POINTER, AT_VECTOR, AT_VECTOR, AT_VECTOR, AT_MATRIX, 0);

	brNewBreveCall(n, "jointBreak", brIJointBreak, AT_NULL, AT_POINTER, 0);
	brNewBreveCall(n, "jointSetVelocity", brIJointSetVelocity, AT_NULL, AT_POINTER, AT_VECTOR, 0);
	brNewBreveCall(n, "jointSetDamping", brIJointSetDamping, AT_NULL, AT_POINTER, AT_DOUBLE, 0);
	brNewBreveCall(n, "jointSetLimits", brIJointSetLimits, AT_NULL, AT_POINTER, AT_VECTOR, AT_VECTOR, 0);
	brNewBreveCall(n, "jointSetSpring", brIJointSetSpring, AT_NULL, AT_POINTER, AT_DOUBLE, AT_DOUBLE, AT_DOUBLE, 0);
	brNewBreveCall(n, "jointSetMaxStrength", brIJointSetMaxStrength, AT_NULL, AT_POINTER, AT_DOUBLE, 0);
	brNewBreveCall(n, "jointSetLinkPoints", brIJointSetLinkPoints, AT_NULL, AT_POINTER, AT_VECTOR, AT_VECTOR, AT_MATRIX, 0);
	brNewBreveCall(n, "jointSetNormal", brIJointSetNormal, AT_NULL, AT_POINTER, AT_VECTOR, 0);

	brNewBreveCall(n, "jointGetPosition", brIJointGetPosition, AT_VECTOR, AT_POINTER, 0);
	brNewBreveCall(n, "jointGetVelocity", brIJointGetVelocity, AT_VECTOR, AT_POINTER, 0);
}
