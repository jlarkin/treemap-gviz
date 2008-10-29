package treemapgviz{

import flash.display.*;
import flash.text.*;
import flash.events.*;

public class TreeRect extends Sprite {

	public var item:TreeItem;	

	public function TreeRect(item:TreeItem, x:Number,y:Number,w:Number,h:Number,c:Color,extrudeAmount:Number, border:Number, borderColor:Color){

		this.item = item;

	      var g:Graphics = this.graphics;
      		g.beginFill(c.toInt(), 1);
	      	if (extrudeAmount != 0)
		      	g.lineStyle();
	      	else
	      		g.lineStyle(border,borderColor.toInt());
	      g.drawRect(0,0,w,h);
	      g.endFill();
	      if (border > 0 && extrudeAmount != 0){
	        var b2:Number = border/2;
	      	g.lineStyle(border,c.multiply(1+extrudeAmount).toInt());
	      	g.moveTo(w-b2,b2);
	      	g.lineTo(b2,b2);
			g.lineTo(b2,h-b2);
	      	g.lineStyle(border,c.multiply(1-extrudeAmount).toInt());
			g.moveTo(w-b2,b2);
	      	g.lineTo(w-b2,h-b2);
	      	g.lineTo(b2,h-b2);
	      }
	      this.x = x;
	      this.y = y;
	
	      this.useHandCursor = true;
	      this.mouseEnabled = true;
		
	}
	
	public function toText():String{
		var res:String = "";
		if (item.label != null)
			res+=item.label+": ";
		res+=item.weight;
		if (!isNaN(item.colorValue))
			res+=" ("+item.colorValue+")";
		return res;
	}

	public function getItem():TreeItem{
		return this.item;
	}		
}
}