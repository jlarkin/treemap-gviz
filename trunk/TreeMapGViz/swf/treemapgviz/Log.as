package treemapgviz{

import flash.display.*;
import flash.text.*;

public class Log {

	private static var myText:TextField = null;

	private static var traceEnabled:Boolean = true;
	private static var errorEnabled:Boolean = true;

	public static function init(parentSprite:Sprite):void{
		myText = new TextField();
		myText.x = 0;
		myText.y = 0;
		myText.textColor = 0x0;
		myText.multiline = true;
		myText.text = '';
		myText.width = 500;
		myText.height = 1000;
		//myText.width = parentSprite.stage.stageWidth;
		//myText.height = parentSprite.stage.stageHeight;
		parentSprite.addChild(myText);
//		Log.trace('log url='+this.loaderURL);
	}		

	private static function msg(s:String):void{
		if (myText == null)
			return;
		if (s == null)
			s = '{null}';
		myText.appendText(s);
		myText.appendText('\r\n');		
	} 

	public static function trace(s:String):void{
		if (!traceEnabled)
			return;
		msg(s);
	}
	
	public static function error(e:Error):void{
		if (!errorEnabled)
			return;
		msg('ERROR: '+e.toString());
	}
}
}