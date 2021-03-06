#include "drawcommand.h"
#include "world.h"

slDrawCommandList::slDrawCommandList( slWorld *w ) {
	slVectorSet( &_origin, 0, 0, 0 );
	slMatrixIdentity( _rotation );
	_limit = 0;
	_drawingPolygon = 0;
	w->_drawings.push_back( this );
}

slDrawCommandList::~slDrawCommandList() {
	clear();
}

void slDrawCommandList::clear() {
	std::list<slDrawCommand*>::iterator di;

	for ( di = _commands.begin(); di != _commands.end(); di++ ) {
		delete *di;
	}

	_commands.clear();
}


void slDrawCommandList::addCommand( slDrawCommand *command ) {
	if ( _limit ) {
		if ( _commands.size() >= _limit ) _commands.pop_front();
	}

	_commands.push_back( command );
}

void slDrawCommandList::draw( slCamera *c ) {
	std::list<slDrawCommand*>::iterator di;

	glPushMatrix();

	glTranslatef( _origin.x, _origin.y, _origin.z );

	// glDisable( GL_BLEND );
	glDisable( GL_LINE_SMOOTH );
	glEnable( GL_DEPTH_TEST );
	glLineWidth( 1.2 );
	glDisable( GL_CULL_FACE );
	glColor4f( 0.0, 0.0, 0.0, 0.5 );
	glEnable( GL_LINE_STIPPLE );
	glLineStipple( 1, 0xffff );

	_drawingPolygon = 0;

	for ( di = _commands.begin(); di != _commands.end(); di++ ) {
		( *di )->execute( *this );
	}

	if ( _drawingPolygon ) glEnd();

	glPopMatrix();
}
