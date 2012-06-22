package fr.hyperfiction.events;

import nme.events.Event;

/**
 * ...
 * @author shoe[box]
 */

class GesturePanEvent extends Event{

	public var offsetX    : Float;
	public var offsetY    : Float;
	public var velocityX : Float;
	public var velocityY : Float;

	public static inline var PAN : String = 'GesturePanEvent_PAN';

	// -------o constructor
		
		/**
		* constructor
		*
		* @param	
		* @return	void
		*/
		public function new( fx : Float , fy : Float , vx : Float , vy : Float ) {
			super( PAN );
			this.offsetX   = fx;
			this.offsetY   = fy;
			this.velocityX = vx;
			this.velocityY = vy;
			
		}
	
	// -------o public
		
		/**
		* 
		* 
		* @public
		* @return	void
		*/
		override public function toString( ) : String {
			return '[ '+PAN+' offsetX : '+offsetX+' offsetY : '+offsetY+' ]';
		}

	// -------o protected
	
	// -------o misc
	
}