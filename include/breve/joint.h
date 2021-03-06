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

#include "ode/ode.h"
#include "link.h"
#include "multibody.h"

enum jointTypes {
	JT_REVOLUTE = 1,
	JT_PRISMATIC,
	JT_BALL,
	JT_UNIVERSAL,
	JT_FIX
};

class slLink;

/*!
	\brief A joint connecting two links.
*/

class slJoint {
	public:
		slJoint() {
			_isMbJoint = false;
			_repositionAll = false;

			_parent = NULL;
			_child = NULL;
			
			_odeJointID = NULL; 
			_odeMotorID = NULL;

			_kDamp = 0.0;
			_kSpring = 0.0;
			_sMax = 0.0;
			_sMin = 0.0;
			_torque = 0.0;
			_targetSpeed = 0.0;

			_userData = NULL;
		}

		~slJoint();
	
		/*!
		 * Updates the link points and relative rotation between two joined objects.
		 */

		void setLinkPoints(slVector *plinkPoint, slVector *clinkPoint, double rotation[3][3], int first);

		/*!
		 * Sets the normal vector of a prismatic or revolute joint.
		 */

		void setNormal(slVector *normal);

		/*!
		 * Sets the min and max limits of the joint.  Depending on the joint 
		 * type, these may be 1, 2 or 3 values.
		 */

		void setLimits(slVector *min, slVector *max);

		/*!
		 * Gets the velocity of the joint.  Depending on the joint type, this may be 1, 2 or 3 values.
		 */

		void getVelocity(slVector *velocity);

		/*!
		 * Sets the velocity of the joint.  Depending on the joint type, this may be 1, 2 or 3 values.
		 */

		void setVelocity(slVector *velocity);

		/*!
		 * Gets the position of the joint.  Depending on the joint type, this may be 1, 2 or 3 values.
		 */

		void getPosition(slVector *v);

		/*
		 * Sets the maximum torque for this joint.  Depending on the joint type, this may be 1, 2 or 3 values.
		 */

		void setMaxTorque(double max);

		/* 
		 * Breaks (but does not destroy) the joint.
		 */

		void breakJoint();

		/*
		 * Applies force to the joint's DOFs.  Depending on the joint type, this may be force or torque 
		 * for 1, 2 or 3 DOFs.
		 */
	
		void applyJointForce(slVector *torque);

		/*
		 * Sets the _repositionAll flag of the joint.
		 */

		void setRepositionAll( bool r) { _repositionAll = r; }

		void *getCallbackData() { return _userData; }

		slLink *_parent;
		slLink *_child;
		dJointID _odeJointID;
		dJointID _odeMotorID;

		double _kDamp;
		double _kSpring;
		double _sMax;
		double _sMin;
		double _torque;
		double _targetSpeed;
	
		unsigned char _type;

		bool _isMbJoint;

		/**
		 * This flag indicates whether child links should be repositioned when
		 * a joint is created or moved.
		 */

		bool _repositionAll;
	
		void *_userData;

		dJointFeedback _feedback;
};
