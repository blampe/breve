
# Note: this file was automatically converted to Python from the
# original steve-language source code.  Please see the original
# file for more detailed comments and documentation.


import breve

class Swarm( breve.Control ):
	def __init__( self ):
		breve.Control.__init__( self )
		self.birds = breve.objectList()
		self.cloudTexture = None
		self.dizzyMenu = None
		self.normalMenu = None
		self.obedientMenu = None
		self.selection = None
		self.useDizzyCameraControl = 0
		self.wackyMenu = None
		Swarm.init( self )

	def click( self, item ):
		if self.selection:
			self.selection.hideNeighborLines()

		if item:
			item.showNeighborLines()

		self.selection = item
		breve.Control.click( self , item )

	def flockNormally( self ):
		item = None

		for item in self.birds:
			item.flockNormally()

		self.normalMenu.check()
		self.obedientMenu.uncheck()
		self.wackyMenu.uncheck()

	def flockObediently( self ):
		item = None

		for item in self.birds:
			item.flockObediently()

		self.normalMenu.uncheck()
		self.obedientMenu.check()
		self.wackyMenu.uncheck()

	def flockWackily( self ):
		item = None

		for item in self.birds:
			item.flockWackily()

		self.normalMenu.uncheck()
		self.obedientMenu.uncheck()
		self.wackyMenu.check()

	def init( self ):
		floor = None

		self.addMenu( '''Smoosh The Birdies''', 'squish' )
		self.addMenuSeparator()
		self.obedientMenu = self.addMenu( '''Flock Obediently''', 'flockObediently' )
		self.normalMenu = self.addMenu( '''Flock Normally''', 'flockNormally' )
		self.wackyMenu = self.addMenu( '''Flock Wackily''', 'flockWackily' )
		self.addMenuSeparator()
		self.dizzyMenu = self.addMenu( '''Use Dizzy Camera Control''', 'toggleDizzy' )
		self.enableLighting()
		self.moveLight( breve.vector( 0, 20, 20 ) )
		self.cloudTexture = breve.createInstances( breve.Image, 1 ).load( 'images/clouds.png' )
		floor = breve.createInstances( breve.Floor, 1 )
		floor.catchShadows()
		self.birds = breve.createInstances( breve.Birds, 60 )
		self.flockNormally()
		self.setBackgroundTextureImage( self.cloudTexture )
		self.offsetCamera( breve.vector( 5, 1.500000, 6 ) )
		self.enableShadows()

	def iterate( self ):
		item = None
		location = breve.vector()
		topDiff = 0

		self.updateNeighbors()
		for item in self.birds:
			item.fly()
			location = ( location + item.getLocation() )


		location = ( location / breve.length( self.birds ) )
		topDiff = 0.000000
		for item in self.birds:
			if ( topDiff < breve.length( ( location - item.getLocation() ) ) ):
				topDiff = breve.length( ( location - item.getLocation() ) )



		self.aimCamera( location )
		if self.useDizzyCameraControl:
			self.setCameraRotation( breve.length( location ), 0.000000 )

		breve.Control.iterate( self )

	def squish( self ):
		item = None

		for item in self.birds:
			item.move( breve.vector( 0, 0, 0 ) )


	def toggleDizzy( self ):
		self.useDizzyCameraControl = ( not self.useDizzyCameraControl )
		if self.useDizzyCameraControl:
			self.dizzyMenu.check()
		else:
			self.dizzyMenu.uncheck()



breve.Swarm = Swarm
class Bird( breve.Mobile ):
	def __init__( self ):
		breve.Mobile.__init__( self )
		self.centerConstant = 0
		self.cruiseDistance = 0
		self.landed = 0
		self.maxAcceleration = 0
		self.maxVelocity = 0
		self.spacingConstant = 0
		self.velocityConstant = 0
		self.wanderConstant = 0
		self.worldCenterConstant = 0
		Bird.init( self )

	def checkLanded( self ):
		return self.landed

	def checkVisibility( self, item ):
		if ( item == self ):
			return 0

		if ( not item.isA( 'Bird' ) ):
			return 0

		if item.checkLanded():
			return 0

		if ( self.getAngle( item ) > 2.000000 ):
			return 0

		return 1

	def flockNormally( self ):
		self.wanderConstant = 4.000000
		self.worldCenterConstant = 5.000000
		self.centerConstant = 2.000000
		self.velocityConstant = 2.000000
		self.spacingConstant = 5.000000
		self.maxVelocity = 15
		self.maxAcceleration = 15
		self.cruiseDistance = 0.400000

	def flockObediently( self ):
		self.wanderConstant = 6.000000
		self.worldCenterConstant = 6.000000
		self.centerConstant = 2.000000
		self.velocityConstant = 3.000000
		self.spacingConstant = 4.000000
		self.maxVelocity = 16
		self.maxAcceleration = 20
		self.cruiseDistance = 1

	def flockWackily( self ):
		self.wanderConstant = 8.000000
		self.worldCenterConstant = 14.000000
		self.centerConstant = 1.000000
		self.velocityConstant = 3.000000
		self.spacingConstant = 4.000000
		self.maxVelocity = 20
		self.maxAcceleration = 30
		self.cruiseDistance = 0.500000

	def fly( self ):
		bird = None
		toNeighbor = breve.vector()
		centerUrge = breve.vector()
		worldCenterUrge = breve.vector()
		velocityUrge = breve.vector()
		spacingUrge = breve.vector()
		wanderUrge = breve.vector()
		acceleration = breve.vector()
		newVelocity = breve.vector()
		neighbors = breve.objectList()
		takeOff = 0

		for bird in self.getNeighbors():
			if self.checkVisibility( bird ):
				neighbors.append( bird )



		if self.landed:
			takeOff = breve.randomExpression( 40 )
			if ( takeOff == 1 ):
				self.landed = 0
				self.setVelocity( ( breve.randomExpression( breve.vector( 0.100000, 1.100000, 0.100000 ) ) - breve.vector( 0.050000, 0, 0.050000 ) ) )

			else:
				return




		centerUrge = self.getCenterUrge( neighbors )
		velocityUrge = self.getVelocityUrge( neighbors )
		for bird in neighbors:
			toNeighbor = ( self.getLocation() - bird.getLocation() )
			if ( breve.length( toNeighbor ) < self.cruiseDistance ):
				spacingUrge = ( spacingUrge + toNeighbor )



		if ( breve.length( self.getLocation() ) > 10 ):
			worldCenterUrge = ( -self.getLocation() )

		wanderUrge = ( breve.randomExpression( breve.vector( 2, 2, 2 ) ) - breve.vector( 1, 1, 1 ) )
		if breve.length( spacingUrge ):
			spacingUrge = ( spacingUrge / breve.length( spacingUrge ) )

		if breve.length( worldCenterUrge ):
			worldCenterUrge = ( worldCenterUrge / breve.length( worldCenterUrge ) )

		if breve.length( velocityUrge ):
			velocityUrge = ( velocityUrge / breve.length( velocityUrge ) )

		if breve.length( centerUrge ):
			centerUrge = ( centerUrge / breve.length( centerUrge ) )

		if breve.length( wanderUrge ):
			wanderUrge = ( wanderUrge / breve.length( wanderUrge ) )

		wanderUrge = ( wanderUrge * self.wanderConstant )
		worldCenterUrge = ( worldCenterUrge * self.worldCenterConstant )
		centerUrge = ( centerUrge * self.centerConstant )
		velocityUrge = ( velocityUrge * self.velocityConstant )
		spacingUrge = ( spacingUrge * self.spacingConstant )
		acceleration = ( ( ( ( worldCenterUrge + centerUrge ) + velocityUrge ) + spacingUrge ) + wanderUrge )
		if ( breve.length( acceleration ) != 0 ):
			acceleration = ( acceleration / breve.length( acceleration ) )

		self.setAcceleration( ( self.maxAcceleration * acceleration ) )
		newVelocity = self.getVelocity()
		if ( breve.length( newVelocity ) > self.maxVelocity ):
			newVelocity = ( ( self.maxVelocity * newVelocity ) / breve.length( newVelocity ) )

		self.setVelocity( newVelocity )
		self.point( breve.vector( 0, 1, 0 ), ( newVelocity / breve.length( newVelocity ) ) )

	def getAngle( self, otherMobile ):
		tempVector = breve.vector()

		if ( breve.length( self.getVelocity() ) == 0 ):
			return 0

		tempVector = ( otherMobile.getLocation() - self.getLocation() )
		return breve.breveInternalFunctionFinder.angle( self, self.getVelocity(), tempVector )

	def getCenterUrge( self, flock ):
		item = None
		count = 0
		center = breve.vector()

		for item in flock:
			count = ( count + 1 )
			center = ( center + item.getLocation() )


		if ( count == 0 ):
			return breve.vector( 0, 0, 0 )

		center = ( center / count )
		return ( center - self.getLocation() )

	def getVelocityUrge( self, flock ):
		item = None
		count = 0
		aveVelocity = breve.vector()

		for item in flock:
			count = ( count + 1 )
			aveVelocity = ( aveVelocity + item.getVelocity() )


		if ( count == 0 ):
			return breve.vector( 0, 0, 0 )

		aveVelocity = ( aveVelocity / count )
		return ( aveVelocity - self.getVelocity() )

	def init( self ):
		self.setShape( breve.createInstances( breve.PolygonCone, 1 ).initWith( 3, 0.500000, 0.060000 ) )
		self.move( ( breve.randomExpression( breve.vector( 10, 10, 10 ) ) - breve.vector( 5, -5, 5 ) ) )
		self.setVelocity( ( breve.randomExpression( breve.vector( 20, 20, 20 ) ) - breve.vector( 10, 10, 10 ) ) )
		self.setColor( breve.randomExpression( breve.vector( 1, 1, 1 ) ) )
		self.handleCollisions( 'Floor', 'land' )
		self.setNeighborhoodSize( 3.000000 )

	def land( self, ground ):
		self.setAcceleration( breve.vector( 0, 0, 0 ) )
		self.setVelocity( breve.vector( 0, 0, 0 ) )
		self.landed = 1
		self.offset( breve.vector( 0, 0.001000, 0 ) )


breve.Bird = Bird
# Add our newly created classes to the breve namespace

breve.Birds = Bird


# Create an instance of our controller object to initialize the simulation

Swarm()


