package treemapgviz{
	public class Color {

		private var r:Number,g:Number,b:Number;

		private static var BLACK:Color = new Color(0,0,0);
		private static var WHITE:Color = new Color(1,1,1);

		private static var RAINBOW_COLORS:Array = [
			Color.fromInts(245,0,0),
			Color.fromInts(245,245,0),
			Color.fromInts(0,176,80),
			Color.fromInts(0,176,240),
			Color.fromInts(245,192,0),
			Color.fromInts(245,63,245),
			Color.fromInts(146,208,80),
			//Color.fromInts(0,32,96),
			Color.fromInts(0,112,192),
			Color.fromInts(192,0,0),
			Color.fromInts(112,48,160)];
		private static var CURRENT_RAINBOW_COLOR:int = 0;
		
		public function Color(r:Number,g:Number,b:Number){
			this.r = r;
			this.g = g;
			this.b = b;
		}

		public static function nextRainbowColor():Color{
			Log.trace('rainbow color '+CURRENT_RAINBOW_COLOR);
			var res:Color = RAINBOW_COLORS[CURRENT_RAINBOW_COLOR];
			CURRENT_RAINBOW_COLOR++;
			if (CURRENT_RAINBOW_COLOR >= RAINBOW_COLORS.length)
				CURRENT_RAINBOW_COLOR = 0; 
			return res; 
		} 
		
		public function pertrube(w:Number):Color{
			return new Color(
				limit(r+(Math.random()-0.5)*w),
				limit(g+(Math.random()-0.5)*w),
				limit(b+(Math.random()-0.5)*w));
		}
		
		public function multiply(w:Number):Color{
			return new Color(
				limit(r*w),
				limit(g*w),
				limit(b*w));
		}
		
		public function invert():Color{
			return new Color(1-r,1-g,1-b);
		}
		
		
		private static function limit(n:Number):Number{
			if (n<0) return 0;
			else
			if (n>1) return 1;
			else
			return n; 
		}
		
		public static function random():Color{
			return new Color(Math.random(), Math.random(), Math.random());
		}

		public static function parse(s:String):Color{
			if (s == null)
				return BLACK;
			if (s.length != 6)
				return BLACK;
				
			var x:int = parseInt(s,16);
			
			return fromInt(x);
		}

		public static function fromInt(x:int):Color{
			var r:Number = (x>>16)%256;
			var g:Number = (x>>8)%256;
			var b:Number = (x%256);
			return new Color(r/256,g/256,b/256);
		}

		public static function fromInts(r:int,g:int,b:int):Color{
			return new Color(r/256,g/256,b/256);
		}
		

		public static function mix(w1:Number,c1:Color,w2:Number,c2:Color):Color{
			return new Color(
					w1*c1.r+w2*c2.r,
					w1*c1.g+w2*c2.g,
					w1*c1.b+w2*c2.b);
		}


		public function toInt():int{
			return Math.floor(r*0xFF)*0x10000+Math.floor(g*0xFF)*0x100+Math.floor(b*0xFF);
		}
		
		public function toString():String{
			return '('+r+','+g+','+b+')';
		}
	}
}