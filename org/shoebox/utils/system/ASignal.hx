/**
*  HomeMade by shoe[box]
*
*  Redistribution and use in source and binary forms, with or without
*  modification, are permitted provided that the following conditions are
*  met:
*
* Redistributions of source code must retain the above copyright notice,
*   this list of conditions and the following disclaimer.
*
* Redistributions in binary form must reproduce the above copyright
*    notice, this list of conditions and the following disclaimer in the
*    documentation and/or other materials provided with the distribution.
*
* Neither the name of shoe[box] nor the names of its
* contributors may be used to endorse or promote products derived from
* this software without specific prior written permission.
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
* IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
* THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
* PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
* CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
* EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
* PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
* LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
* NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
package org.shoebox.utils.system;

import org.shoebox.collections.PriorityQueue;

/**
 * ...
 * @author shoe[box]
 */

class ASignal<T>{

	public var enabled( default , set_enabled ) : Bool;

	private var _oQueue : PriorityQueue<SignalListener<T>>;

	// -------o constructor

		/**
		* constructor
		*
		* @param
		* @return	void
		*/
		public function new( ) {
			_oQueue = new PriorityQueue<SignalListener<T>>( );
			enabled = true;
		}

	// -------o public

		/**
		*
		*
		* @public
		* @return	void
		*/
		public function connect( f : T , iPrio : Int = 0 , iCount : Int = -1 ) : Void {

			if( _exist( f , iPrio ) )
				return;

			_oQueue.add( new SignalListener( f , iCount , iPrio ) , iPrio );

		}

		/**
		*
		*
		* @public
		* @return	void
		*/
		public function disconnect( f : T , prio : Int = 0 ) : Void {

			var content = _oQueue.getContent( );
			for( o in content ){

				if( o.content.fListener == f && o.prio == prio ){
					content.remove( o );
					_oQueue.remove( o.content );
					break;
				}
			}

		}

		/**
		*
		*
		* @public
		* @return	void
		*/
		public function dispose( ) : Void {
			_oQueue = null;
		}

		/**
		*
		*
		* @public
		* @return	void
		*/
		public function hasListener( ) : Bool {
			return _oQueue.length > 0;
		}

		/**
		*
		*
		* @public
		* @return	void
		*/
		public function exists( f : T , prio : Int = 0 ) : Bool {
			return _exist( f , prio );
		}

	// -------o protected

		/**
		*
		*
		* @private
		* @return	void
		*/
		private function _exist( f : T , prio : Int = 0 ) : Bool{

			var b : Bool = false;
			var content = _oQueue.getContent( );
			for( o in content ){
				if( o.content.fListener == f && o.prio == prio ){
					b = true;
					break;
				}
			}
			return b;

		}

		/**
		*
		*
		* @private
		* @return	void
		*/
		private function _check( l : SignalListener<T> ) : Void{

			if( l.iCount != -1 ){
				l.iCount--;
			}

			if( l.iCount == 0 )
				disconnect( l.fListener , l.iPrio );

		}

		/**
		*
		*
		* @private
		* @return	void
		*/
		private function set_enabled( b : Bool ) : Bool{
			this.enabled = b;
			return b;
		}

	// -------o misc

}


/**
 * ...
 * @author shoe[box]
 */

class SignalListener<T>{

	public var fListener : T;
	public var iCount    : Int;
	public var iPrio     : Int;

	// -------o constructor

		/**
		* constructor
		*
		* @param
		* @return	void
		*/
		public function new( f : T , iCount : Int , iPrio : Int ) {
			this.fListener = f;
			this.iCount    = iCount;
			this.iPrio     = iPrio;
		}

	// -------o public



	// -------o protected



	// -------o misc

}