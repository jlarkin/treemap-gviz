//
// Author: Yaar
// TreeMapGViz is a Google Visualization for Spreadsheets and the GViz API. 
// It was developed in the context of the Spreadsheet Gadgets Competition at
// Google during the summer of 2008 when yaar was an intern there.
package treemapgviz{

import flash.display.*;
import flash.text.*;
import flash.events.*;
import flash.external.ExternalInterface;
import flash.system.*;
import flash.errors.StackOverflowError;

/**
 * The top-level sprite for the Tree Map visualization.
 */  
public class TreeMapGViz extends Sprite {

    //Logger
    private var log:Log;

    //border drawing configurations:
    
    //border width (in pixels)  
    private var borderWidth:Number = 1;
    //increase border width each level
    private var increaseBorderWidthByLevel:Boolean = false;
    //controls the 3d effect by coloring the border with a (1+x) or (1-x) multiplication of the fill color.   
    private var extrudeAmount:Number = 0.0;
    //pixels between parent to child
    private var childPadding:Number = 3;
    //pixles between children
    private var siblingPadding:Number = 3;
    //color of border. When extrudeAmount>0, border color is the fill color
    private var borderColor:Color = new Color(0,0,0);

    //fill drawing configurations
    
    //the color of the root level
    private var rootColor:Color = new Color(0,0,0);
    //colors are pertrubed by this ammount every level to create visible differentiation between siblings
    private var colorPertrube:Number = 0.3;
    //by default, random coloring starts at a specific level, and pertrebutions are used in subsequent levels
    private var randomColorsStartLevel:int = 0;
    //min color for heat map coloring
    private var minColor:Color = new Color(1,0,0);
    //max color for heat map coloring 
    private var maxColor:Color = new Color(0,0,1);
    //use pre-configured rainbow colors instead of random colors 
    private var useRainbowColors:Boolean = true;

    //label drawing configuration
    
    //number of pixels to spare when drawing labels on top of rectangles
    private var labelsOnTopSize:int = 10;  
    //amount of alpha to use at bottom levels
    private var labelsAlphaStart:Number = 1;
    //use the inverted color of a rectangle as the color for the labels
    private var labelsInvert:Boolean = true;
    //instead of invert, multiply the rectangle color by this ammount
    private var labelsColorMultiply:Number = 20;
    //or just set a specific color
    private var labelColor:Color = null;

    //layout configuration
    
    //sort rectangles by label lexicographic order
    private var sort:Boolean = false;
    //render treemap by alternating between vertical and horizontal splits (0) or by best split (1, default)
    private var layoutMode:int = 1; //0 - alternating 1 - best split 
    
    //non conf
    
    //pointer to the root element of the tree
    private var treeRoot:TreeItem;
    //pointer to the element that is currently being focused on
    private var focusNode:TreeItem;

    //dirty flag used to indicate if new records have been added
    private var dirty:Boolean = true;
    //the minimum color value used for heat map coloring
    private var minColorValue:Number = Number.POSITIVE_INFINITY; 
    //the maximum color value used for heat map coloring
    private var maxColorValue:Number = Number.NEGATIVE_INFINITY;
    //the maximum number of levels found in the tree
    private var maxLevels:int = 0;
    //the number of records expected to be inserted into the tree
    private var maxRecords:int = 0;
    //the number of records currently in the tree
    private var currentRecords:int = 0;
    //progress indicator moves between 0 and 100
    private var progress:int = 0;
    
    //this array of sprites is used to easily delete all sprites in the tree when redrawing
    private var allSprites:Array = [];
    
    //a point to a text field sprite used for the tooltips
    private var toolTipTextField:TextField = null;

    /**
     * Constructs the TreeMapGViz top-level sprite. 
     * The sprite registers some ExternalInterface methods and waits for data from JS. 
     */  
    public function TreeMapGViz () {
    
    	//some drawing configurations 
        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;
	this.blendMode = BlendMode.LAYER;

	//initialize logging
	Log.init(this);
	
	//listen to resize events
	stage.addEventListener(Event.RESIZE, resizeHandler);

	try{
	    //create an empty root node
	    treeRoot = new TreeItem(0,Number.NaN,null);
	    //create ExternalInterface methods
	    createJSInterface();
    	}catch(e:Error){
            Log.error(e);		
    	}
    }

    /**
     * Perform rendering by recursing over tree 
     */
    private function render():void{
        Log.trace('rendering');
        try{
            //remove all old sprites
            for (var i:int=0;i<allSprites.length; i++)
	       	removeChild(allSprites[i]);
	    allSprites = [];

            //if tree is dirty, preprate it for rendering
	    if (this.dirty){
     		prepare(treeRoot,0,null);
      	        this.dirty = false;
      	    }
      	    
      	    //recurse over nodes
      	    renderRecurse(focusNode==null?treeRoot:focusNode, //node to begin at
      	                 100,0,  //x,y
      	                 stage.stageWidth-101,stage.stageHeight-1, //w,h 
      	                 true);
	}catch(e:Error){
		Log.error(e);
	}
    }

    /**
     * Method used to inject records into the tree map.
     *
     * @param {Number} weight - the weight of the record
     * @param {Number} colorValue - the heat map value of the record (can be null)
     * @param {labels} labels - an array of labels for the record used to determine its place in the tree
     */
    private function addRecord(weight:Number, colorValue:Number, labels:Array):void{
        //mark tree is dirty and update progress
	this.dirty = true;
	currentRecords++;
	if (maxRecords > 0){
		var prog:int = (currentRecords*100)/maxRecords;
		if (prog > this.progress){
			this.progress = prog;
			//Log.trace('%'+progress);
		}
	}
        
        //update heat map min and max color values
	if (!isNaN(colorValue)){
		if (colorValue < minColorValue)
			minColorValue = colorValue;
		if (colorValue > maxColorValue)
			maxColorValue = colorValue;
	}	
	
	//update the number of max levels
	if (labels.length > this.maxLevels)
		this.maxLevels = labels.length;
	
	//place the record in its correct place in the tree...
	
	//start at root
	var item:TreeItem = treeRoot;
	var depth:int = 0;
	
	while (depth < labels.length){
                
	        //is this the last step in the loop?	
		var lastStep:Boolean = (depth == labels.length -1);
		
		//update existing items weight by new weight added  
		item.weight += weight;
	       
	        //look at first child of node
		var child:TreeItem = item.child;
		//place holder for new child (if required)
		var n:TreeItem = null;
		
		//if there is no child, create one
		if (child == null){
			n = new TreeItem(lastStep?weight:0,colorValue,labels[depth]);
			item.child = n;
			item = n;
			depth++;
			continue;
		}
		
		//iterate over all children to determine where to insert
		while (child != null){
		        //this child has the same label as me so go into it
			if (child.label == labels[depth]){
				item = child;
				if (depth == labels.length - 1)
					item.weight += weight;
				break;
			}
			//sorting is enabled and my label is small (lexicogrohiccally) so insert me before this child
			else if (sort && child.label > labels[depth]){
			        //cloning is used to preserve linkage
				n = child.clone();
				//old node takes the values of me
				child.reset(lastStep?weight:0,colorValue,labels[depth]);
				//new node is inserted after old node with its cloned values 
				child.sibling = n;
				item = child;
				break;
			}
			//reached the end of the list, so add a new child there
			else if (child.sibling == null){
				n = new TreeItem(lastStep?weight:0,colorValue,labels[depth]);
				child.sibling = n;
				item = n;
				break;
			}
			//keep iterating
			else{
				child = child.sibling; 
			}
		}
		
		//increment depth
		depth++;		
	}
	
		
	
    }

    /**
     * Prepare the tree for rendering by recursing over it to make some precalculations.
     *
     * @param {TreeItem} item - item to prepare
     * @param {int} level - the level we are at
     * @param {Color} parentColor - the color of our parent
     */
    private function prepare(item:TreeItem, level:int, parentColor:Color):void{
    	
    	//count direct and indirect descendants 
    	item.childCount = 0;
    	item.descendantCount = 0;
    	//measure depth
    	item.depth = 1;
    	//item's current level
    	item.level = level;

        //determine item's color    	
    	if (!isNaN(item.colorValue) && this.minColorValue != this.maxColorValue){
    	        //heat map coloring
    		var w:Number = (item.colorValue-minColorValue)/(maxColorValue-minColorValue);
    		item.color = Color.mix(1-w,this.minColor,w,this.maxColor);
    	}else if (level == this.randomColorsStartLevel){
    	        //rainbow or random coloring
    		item.color = this.useRainbowColors ? Color.nextRainbowColor() : Color.random();
    	}else if (parentColor != null && colorPertrube > 0){
    	        //pertrubution coloring
    		item.color = parentColor.pertrube(colorPertrube);
    	}

        //recurse over children     	
    	var child:TreeItem = item.child;
    	var avgColorValue:Number = 0;
    	while (child != null){
    	        //recurse into next level
    		prepare(child,level+1,item.color);
    		//increment number of children and descenadants
    		item.descendantCount += child.descendantCount;
    		item.childCount++;
    		//update depth
    		if (child.depth > item.depth - 1)
    			item.depth = child.depth+1;
    	        //average colors into parent
    		if (!isNaN(child.colorValue))
    			avgColorValue += child.colorValue; 
    		child = child.sibling;
    		//TODO: should mix child colors by child weights
    	}
    	
        //use childrens' averaged color values to copmute this item's color    	
    	if (item.color == null && item.childCount > 0 && this.minColorValue != this.maxColorValue){
    		var ww:Number = ((avgColorValue/item.childCount)-minColorValue)/(maxColorValue-minColorValue);
    		item.color = Color.mix(1-ww,this.minColor,ww,this.maxColor);
    	}else if (level == 0){
    		item.color = this.rootColor;
    	}
    	
    }

    /**
     *  Renders rectangle sprites corresponding to the tree weights by recursive iteration over the tree
     *
     *  @param {TreeItem} item - current item to iterate over
     *  @param {Number} sx - coordinate of upper left corner of rectangle 
     *  @param {Number} sy - coordinate of upper right corner of rectangle
     *  @param {Number} w - width of rectangle
     *  @param {Number} h - height of rectangle
     *  @param {Boolean} vertical - used in alternating layout mode to signify vertical or horizontal split
     */    
    private function renderRecurse(item:TreeItem, sx:Number, sy:Number, w:Number, h:Number, vertical:Boolean):void{
	try{
	        //whether to draw labels on top or not 
		var doLabelsOnTop:Boolean = 
			this.labelsOnTopSize > 0 
			&& 
			(h > this.labelsOnTopSize) 
			&& 
			item.label != null;

                //termination condition - rectangle too small			
		if (w <= 0 || h <= 0)
			return;

                //determine fill color and lable color	
		var color:Color = item.color;
		if (color == null)
			color = new Color(0,0,0);
		var labelColor:Color = this.labelColor;
		if (labelColor == null){
			if (labelsInvert)
				labelColor = color.invert();
			else
				labelColor = color.multiply(labelsColorMultiply); 
		}

                //draw the rectangle	
		drawRect(item,sx,sy,w,h, color,
		         (this.increaseBorderWidthByLevel?item.depth:1)*borderWidth); 

                //draw label if required	
		if (doLabelsOnTop){
		        //if no children, draw on center, otherwise draw on top
			if (item.child != null)
				drawLabel(sx,sy,w,this.labelsOnTopSize,item.label, labelColor, 1);
			else
				drawLabel(sx,sy+h/2-this.labelsOnTopSize/2,w,this.labelsOnTopSize,item.label, labelColor, 1);
	                //subtract label size from update sy and h
			sy+=this.labelsOnTopSize;
			h -= this.labelsOnTopSize;
		}
                
                //add parent to child padding		
		if (this.childPadding > 0){
			sx+=this.childPadding;
			w-=this.childPadding*2;
			if (!doLabelsOnTop){ 
				sy+=this.childPadding;
				h-=this.childPadding*2;
			}else{
				h-=this.childPadding;
			}
		}

                //recurse according to layout mode			
		if (layoutMode == 0){
			renderChildrenAlternate(item.child, item.childCount, item.weight, 
						 sx,sy,w,h,
						 vertical); 
		}else{
			renderChildrenBestSplit(item.child, item.childCount, item.weight, 
						sx,sy,w,h,
						vertical);
	       }

                //draw the lables		 
		if (!doLabelsOnTop){
			drawLabel(sx,sy,w,h, item.label, labelColor,item.level*this.labelsAlphaStart/maxLevels);
		}
	}catch(e:StackOverflowError){
	        //unfortunately, this may happen :(
	        Log.error(e);
	}
    }

    /**
     * Renders children using the alternate layout. On every level, the remaining rectangle is split
     * horizontally or vertically in an alternating fashion.
     *
     * @param {TreeItem} child - the first child in the children list
     * @param {int} childCount - the expected children count in the list
     * @param {Number} weight - the total weight of all children
     * @param {Number} sx - coordinate of upper left corner of rectangle 
     * @param {Number} sy - coordinate of upper right corner of rectangle
     * @param {Number} w - width of rectangle
     * @param {Number} h - height of rectangle
     * @param {Boolean} vertical - split the rectangle vertically or horizontally
     */
    private function renderChildrenAlternate(child:TreeItem, childCount:int, weight:Number, 
    				    sx:Number,sy:Number,
    				    w:Number,h:Number,
    				    vertical:Boolean):void{
        //accumulated percentage    				    
	var accP:Number = 0;
	//horizontal padding
	var wPad:Number = (vertical?this.siblingPadding:0);
	//vertical padding
	var hPad:Number = (vertical?0:this.siblingPadding);
	//width after padding
	var ww:Number = w-(childCount-1)*wPad;
	//height after padding
	var hh:Number = h-(childCount-1)*hPad;
	
	//iterate over children and render them
	var i:Number = 0;
	while (child != null){
	       //determine sub-level sx,sy
	       var _sx:int = sx + (vertical?accP:0)*ww + i*wPad;
	       var _sy:int = sy + (vertical?0:accP)*hh + i*hPad;
	       //determine percentage
	       var p:Number = child.weight / weight;
	       var _w:int = (vertical?p:1)*ww-wPad;
	       var _h:int = (vertical?1:p)*hh-hPad;
	       //recurse
	       renderRecurse(child,_sx,_sy,_w,_h, !vertical);
	       child = child.sibling;
	       //accumulate percentages
	       accP += p;
	       i++;
	}
    }
    
    /**
     * Renders children using the best split layout. On every step, the list of children
     * is split into 2 such that the ratio between the two sides of the split are optimal. 
     *
     * @param {TreeItem} child - the first child in the children list
     * @param {int} childCount - the expected children count in the list
     * @param {Number} weight - the total weight of all children
     * @param {Number} x - coordinate of upper left corner of rectangle 
     * @param {Number} y - coordinate of upper right corner of rectangle
     * @param {Number} w - width of rectangle
     * @param {Number} h - height of rectangle
     * @param {Boolean} vertical - split the rectangle vertically or horizontally
     */
    private function renderChildrenBestSplit(child:TreeItem, childCount:int, weight:Number, 
    				    x:Number,y:Number,
    				    w:Number,h:Number,
    				    vertical:Boolean):void{

        //if there is only 1 child, just recurse 
	if (childCount == 1){
		renderRecurse(child,x,y,
			w*(vertical?(child.weight/weight):1),
			h*(vertical?1:(child.weight/weight)), 
			!vertical);
		return;
	}else if (childCount < 1){
                //no children - exit
                return;
	}

	//compute best split
	var bestSplitRatio:Number = Number.POSITIVE_INFINITY;
	var bestSplitChild:TreeItem = null;
	var bestSplitCount:int = 0;
	var bestSplitW:Number = 0;

        //iterate over children until best split is found
	var firstChild:TreeItem = child;

        //accumulated weight		
	var accW:Number = 0;
	var i:Number = 0;
	while (child != null && i<childCount && accW < weight)
	{
		i++;
		accW += child.weight;
		//compute ratio between left side and right side
		var ratio:Number = Math.max(accW/(weight-accW),(weight-accW)/accW);
		if (ratio < bestSplitRatio)
		{
		      //found best ratio so far - store it
		      bestSplitRatio = ratio;
		      bestSplitChild = child.sibling;
		      bestSplitCount = i;
		      bestSplitW = accW; 
		}
		child = child.sibling;
	}

        //split vertically if w>h, otherwise split horizontally	
	vertical = w>h;

        //compute width, height and padding	
	var ww:Number = w*(vertical?(bestSplitW/weight):1);
	var hh:Number = h*(vertical?1:(bestSplitW/weight));
	var wPad:Number = vertical?this.siblingPadding/2:0;
	var hPad:Number = vertical?0:this.siblingPadding/2;

        //recurse one side
	renderChildrenBestSplit(
		firstChild,bestSplitCount,bestSplitW,
		x,
		y,
		w*(vertical?(bestSplitW/weight):1)-wPad,
		h*(vertical?1:(bestSplitW/weight))-hPad,
		!vertical);
	//recurse 2nd side
	renderChildrenBestSplit(
		bestSplitChild,childCount-bestSplitCount,weight-bestSplitW,
		x+w*(vertical?(bestSplitW/weight):0)+wPad,
		y+h*(vertical?0:(bestSplitW/weight))+hPad,
		w-w*(vertical?(bestSplitW/weight):0)-wPad,
		h-h*(vertical?0:(bestSplitW/weight))-hPad,
		!vertical);
		
    } 

    /**
     * Draws a clickable rectangle for the given item in the given position.
     *
     * @param {TreeItem} item - item to draw
     * @param {Number} x - coordinate of upper left corner of rectangle 
     * @param {Number} y - coordinate of upper right corner of rectangle
     * @param {Number} w - width of rectangle
     * @param {Number} h - height of rectangle
     * @param {Color} c - fill color
     * @param {Number} border - border width
     */
    private function drawRect(item:TreeItem, x:Number, y:Number, w:Number, h:Number, c:Color, border:Number):void {

        //create a rectangle sprite
	var rec:TreeRect = new TreeRect(item,x,y,w,h,c,this.extrudeAmount,border,this.borderColor);

        //add sprite to top level sprite
        addChild(rec);
        //add sprite to all sprites list (so it can be disposed of easily when redrawing)
        allSprites.push(rec);
        
        //add an event listenr
	rec.addEventListener(MouseEvent.CLICK, clickHandler);
    }

    /**
     * Handles mouse clicks events on tree rectangles
     * @param {MouseEvent} event
     */
    private function clickHandler(event:MouseEvent):void{
    
    	Log.trace('click: '+event.stageX+','+event.stageY+':'+event.target);

        //create the tool tip text field    	
	var ttt:TextField = toolTipTextField;
    	if (ttt == null){
    		this.toolTipTextField = new TextField();
    		ttt = toolTipTextField;
	        var format:TextFormat = new TextFormat();
		format.font = 'Verdana';
      		format.color = 0;
      		format.size = 10;
		ttt.setTextFormat(format);
    		ttt.selectable = false;
		ttt.autoSize = 'left';
		ttt.mouseEnabled = false;
		ttt.background = true;
		ttt.backgroundColor = 0xffffff;
		ttt.alpha = 0.75;
		addChild(ttt);
		//ttt.addEventListener(MouseEvent.CLICK,toolTopClickHandler);
    	}
    	
    	//populate and position the tool tip text field
	ttt.text = event.target.toText(); 
	ttt.x = event.stageX;
	ttt.y = event.stageY;
    	
    }

    /**
     * Handles mouse double clicks events on tree rectangles
     * @param {MouseEvent} event
     */
    private function dblClickHandler(event:MouseEvent):void{
    	Log.trace('dblclick: '+event.stageX+','+event.stageY+':'+event.target);
    	Log.trace(event.target.toText());

	focusNode = event.target.getItem();
	render();    	
    	
    }

    /**
     * Draws text into a constrained area. Since Flash doesn't have an API to determine
     * a rendered string dimension without drawing it first, this method encapsulates a
     * binary search algorithm that tries to find the largest string that can be contained
     * in the given target area 
     *
     * @param {Number} x - coordinate of upper left corner of target area 
     * @param {Number} y - coordinate of upper right corner of target area
     * @param {Number} w - width of target area
     * @param {Number} h - height of target area
     * @param {Color} c - fill color
     * @param {Number} alpha - transperancy control
     */
    private function drawLabel(x:Number, y:Number, w:Number, h:Number, label:String, c:Color, alpha:Number):void {
      if (label == null || w <= 0 || h <= 0)
      	return;
      	
      //create a text field with a certain text format
      var format:TextFormat = new TextFormat();
      format.font = 'Verdana';
      format.color = c.toInt();
      //format.alpha = 0.5;
      var topSize:int = 1000;
      var lowSize:int = 0;
      var curSize:int = 1;

      //place holder for the text field
      var txt:TextField = null;
      
      //binary search loop
      while (true){
        //update size
	format.size = curSize;
	//recreate textfield
	if (txt != null)
		removeChild(txt);
	txt = new TextField();
        txt.selectable = false;
        txt.autoSize = 'left';
        txt.width = 1;
        txt.height = 1;
	txt.background = false;
        txt.alpha = alpha;
        txt.text = (label==null)?'{null}':label;
      	txt.setTextFormat(format);
        txt.mouseEnabled = false;
        addChild(txt);

        //verify size
      	if (txt.width <= w && txt.height <= h) //font too small
   		lowSize = curSize;
      	else
       	if (txt.width > w || txt.height > h) //font too big
      		topSize = curSize;
      	else
      		break; //font just right
      	
      	//update size
      	var prevSize:int = curSize;
      	curSize = (lowSize + topSize)/2;
      	if (curSize == prevSize)
      		break;
      }

      //if text is just too big, remove it      
      if (txt != null && (txt.width > w || txt.height > h)){
      	removeChild(txt);
      }else{
        //centralize text
	txt.x = x + w/2 - txt.width/2;
      	txt.y = y + h/2 - txt.height/2;
      	
      	//put in sprites list so can be removed later
      	allSprites.push(txt);
      }
   }

   /**
    * Handle resize events by re-rendering.
    * @param {Event} event
    */
   private function resizeHandler(event:Event):void {
    	    Log.trace('resizing');
            render();
   }

    /**
     * Creates External Interfaces allowing JavaScript to communicate with the Flash object, 
     * and singals JavaScript that Flash is ready to be called. 
     */   
    private function createJSInterface():void{
            if (ExternalInterface.available) {
                try {
                    //security configuration
                    Security.allowInsecureDomain("*");
                    Security.allowDomain("*");

                    //record and rendering
                    ExternalInterface.addCallback("addRecord", extAddRecord);
                    ExternalInterface.addCallback("render", extRender);
                    
                    //rendering options
                    ExternalInterface.addCallback("setMaxRecords", extSetMaxRecords);
//                    ExternalInterface.addCallback("setBorderStyle", extSetBorderStyle);
//                    ExternalInterface.addCallback("setFillStyle", extSetFillStyle);
//                    ExternalInterface.addCallback("setLayoutStyle", extSetLayoutStyle);
 //                   ExternalInterface.addCallback("setLabelStyle", extSetLabelStyle);
                    ExternalInterface.addCallback("setOptions", extSetOptions);

                    Log.trace("External interface created!");

                    //signal JavaScript that all is ready
	            var id:String = stage.loaderInfo.parameters['id'];
		    ExternalInterface.call("TreeMapGViz.signalSWFReady",id);
		    Log.trace("Signaled readiness (id="+id+")");
                    
                } catch (e:Error) {
                    Log.error(e);
                }
                
            } else {
            	Log.trace("External interface is not available for this container.");
            }
    } 

    /**
     * External Interface method used to populate the tree with records.
     * 
     * @param {Number} w - weight
     * @param {Number} c - color value (can be NaN or null)
     * @param {Array} a - array of string labels
     */   
    private function extAddRecord(w:Number,c:Number,a:Array):void{
    	addRecord(w,c,a);
    }   

    /**
     * External Interface method used to trigger rendering 
     */    
    private function extRender():void{
    	render();
    }
    
    /**
     * External Interface method used to set max number of records
     * @param {int} n - max number of records  
     */    
    private function extSetMaxRecords(n:int):void{
    	this.maxRecords = n;
    }

    /**
     * Utility function for handling undefined values.
     * @param {Object} o - some value
     * @param {Object} then - value to fall back if o is undefined 
     */
    private function ifUndefInt(o:int, then:int):int{
        return o == undefined?then:o;
    }

    private function ifUndefNum(o:Number, then:Number):Number{
        return o == undefined?then:o;
    }

    private function ifUndefStr(o:String, then:String):String{
        return o == undefined?then:o;
    }

    private function ifUndefBool(o:Boolean, then:Boolean):Boolean{
        return o == undefined?then:o;
    }

    private function extSetOptions(o:Object):void{
        Log.trace("setOptions()");

        //layout
        this.sort = ifUndefBool(o.sort,true);
        this.layoutMode = ifUndefInt(o.layoutMode,1);

        //labels        
        this.labelColor = Color.parse(ifUndefStr(o.labelColor,null));
        this.labelsOnTopSize = ifUndefInt(o.labelsOnTopSize,0);
        this.labelsInvert = ifUndefBool(o.labelsInvert,true);
        this.labelsAlphaStart = ifUndefBool(o.labelsAlpha,false)?0.2:1;
        this.labelsColorMultiply = ifUndefBool(o.labelsColorMultiply,false)?20:0;

        //fill
        this.rootColor = Color.parse(ifUndefStr(o.rootColor,null));
        this.colorPertrube = ifUndefNum(o.pertrube,0.3);
        this.randomColorsStartLevel = ifUndefInt(o.randomLevel,1);
        this.minColor = Color.parse(ifUndefStr(o.minColor,'0000ff'));
        this.maxColor = Color.parse(ifUndefStr(o.maxColor,'ff0000'));

        //border
        this.borderWidth = ifUndefInt(o.borderWidth,1);
        this.borderColor = Color.parse(ifUndefStr(o.borderColor,null));
        this.increaseBorderWidthByLevel = ifUndefBool(o.increaseBorderByLevel,false);
        this.extrudeAmount = ifUndefInt(o.extrudeAmount,0);
        this.childPadding = ifUndefInt(o.childPadding,6);
        this.siblingPadding = ifUndefInt(o.siblingPadding,3);

    }

    /**
     * External Interface method used to set border style options
     * @param {Number} width - border with  
     * @param {String} color - border color (can be null)  
     * @param {Boolean} increaseByLevel - whether border width increases every level
     * @param {Number} extrudeAmount - controls the 3d effect by coloring the border with a (1+x) or (1-x) multiplication of the fill color.
     * @param {Number} childPadding - controls parent-child padding
     * @param {Number} siblingPadding - control child-child padding
     */    
    private function extSetBorderStyle(
    	width:Number,
    	color:String,
    	increaseByLevel:Boolean,
    	extrudeAmount:Number,
    	childPadding:Number,
    	siblingPadding:Number):void
    {
    	try{
    		this.borderWidth = width;
    		this.borderColor = Color.parse(color);
    		this.increaseBorderWidthByLevel = increaseByLevel;
    		this.extrudeAmount = extrudeAmount;
    		this.childPadding = childPadding;
    		this.siblingPadding = siblingPadding;
    	}catch(e:Error){
    		Log.error(e);
    	}
    }
    	
    	
    private function extSetFillStyle(
    	rootColor:String,
    	pertrube:Number,
    	randomLevel:int,
    	minColor:String,
    	maxColor:String):void
    {
	this.rootColor = Color.parse(rootColor);
	this.colorPertrube = pertrube;
	this.randomColorsStartLevel = randomLevel;
	this.minColor = Color.parse(minColor);
	this.maxColor = Color.parse(maxColor);
    }

    private function extSetLayoutStyle(
    	sort:Boolean,
    	bestSplit:Boolean):void
    {
	this.sort = sort;
	this.layoutMode = bestSplit?1:0;
    }
    	
        
    private function extSetLabelStyle(
    	labelColor:String,
    	labelsOnTopSize:int,
    	labelsAlpha:Boolean,
    	labelsInvert:Boolean,
    	labelsColorMultiply:Boolean
    ):void
    {
    	this.labelColor = labelColor == null? null:Color.parse(labelColor);
    	this.labelsOnTopSize = labelsOnTopSize;
    	this.labelsInvert = labelsInvert;
    	this.labelsAlphaStart = labelsAlpha?0.2:1;
    	this.labelsColorMultiply = labelsColorMultiply?20:0;
    }
}
}
