package treemapgviz{

import flash.display.*;

public class TreeItem {
		
	public var label:String;
	public var weight:Number;
	public var colorValue:Number;
	public var color:Color = null;

	public var childCount:int;	
	public var descendantCount:int;
	public var depth:int;
	public var level:int;
	
	public var child:TreeItem = null;
	public var sibling:TreeItem = null; 

	public function TreeItem(weight:Number, colorValue:Number, label:String){
		this.weight = weight;
		this.label = label;
		this.colorValue = colorValue;
	}

	public function reset(weight:Number, colorValue:Number, label:String):void{
		this.label = label;
		this.weight = weight;
		this.colorValue = colorValue;
		this.child = null;
		this.sibling = null;
	}

	public function clone():TreeItem{
		var c:TreeItem = new TreeItem(this.weight, this.colorValue, this.label);
		c.child = this.child;
		c.sibling = this.sibling;
		return c; 
	}
	
	public function traceStructure(depth:int):void{
	
		var indentation:String = '';
		for (var i:int=0; i<depth; i++){
			indentation += '-';
		} 
		Log.trace(indentation+this.label+':'+this.descendantCount+','+this.depth+','+this.level);
		var n:TreeItem = child;
		while (n != null){
			n.traceStructure(depth+1);
			n = n.sibling;
		}
	
	}
	
}
}