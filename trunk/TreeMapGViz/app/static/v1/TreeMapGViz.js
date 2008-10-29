//Auther: Yaar
//
//TreeMapGViz is a Google Visualization for Spreadsheets and the GViz API. 

/**
 * Constructs a new TreeMapGViz object.
 *
 * Expected format:
 *   At least one column of string labels representing the hierarchy.
 *   One column of numeric weight values.
 *   An optional column of numeric heat values.
 *
 * @param {Element} container - The html container to draw under.
 *
 * @constructor
 */
function TreeMapGViz(container){

	//reference to the container
	this.container = container;
	this.id = 'TreeMapGViz_x';//'TreeMapGViz_'+Math.random();
	this.swfReady = false;
	this.swf = null;

	//dispatch table used to dispatch messages from SWF object to JS object...
	if (TreeMapGViz['dispatchTable'] == null)
		TreeMapGViz['dispatchTable'] = new Object();
	TreeMapGViz.dispatchTable[this.id] = this;

	//...but we also want to store a reference to a singleton, just in case	
	TreeMapGViz.singleton = this;
	
	TreeMapGViz.debug('created '+this);	
}

/**
 * URL to the SWF file.
 * @type{String}
 */
//TreeMapGViz.SWF_SRC = 'http://treemap-gviz.googlecode.com/svn/trunk/TreeMapGViz/deploy/TreeMapGViz.swf?r='+Math.random();
//TreeMapGViz.SWF_SRC = 'TreeMapGViz.swf?r='+Math.random(); 
TreeMapGViz.SWF_SRC = 'http://treemapgviz.appspot.com/static/v1/TreeMapGViz.swf?r='+Math.random();


/**
 * overrides the default toString behavior
 */
TreeMapGViz.prototype.toString = function(){
	return 'TreeMapGViz_'+this.id;
}

/**
 * Draws the TreeMapGViz based on the data and option
 *
 * @param {google.visualization.DataTable} data The data table.
 * @param {Object?} options options.
 */
TreeMapGViz.prototype.draw = function(data, options) {
	try{
		TreeMapGViz.debug(this+'.draw()');
		
		//store references to swf, data and options 
		this.swfReady = false;
		this.data = data;
		this.options = options;
		
		//embed SWF object
		this.embedSWF();
		
		//wait for messages from SWF object
		this.waitForSWF();
	}catch(e){
		TreeMapGViz.debug('Error:'+e);
		throw e;
	}
}

/**
 * A callback function that is used by the SWF object to signal JS it is ready for data.
 *
 * @param {String} id the id of the TreeMapGViz object
 * @param {Object?} options options.
 */
TreeMapGViz.signalSWFReady = function(id){
	var tmg = null;
	
	//use dispatch table to traffic the message to the relevant TreeMapGViz object
	if (TreeMapGViz['dispatchTable']==null || id == null)
		tmg = TreeMapGViz.singleton;
	else
		tmg = TreeMapGViz.dispatchTable[id];
	
	if (tmg == null)
		TreeMapGViz.debug('TreeMapGViz with id '+id+' was not found');
	else{
		//mark as ready
		tmg.swfReady = true;
	}	
}


/**
 * Writes HTML to embed the SWF object inside the container 
 */
TreeMapGViz.prototype.embedSWF = function(){
	var html = [];
	var w = this.options.width;
	var h = this.options.height;
	var flashVars = 'id='+this.id+'&debug='+TreeMapGViz.DEBUG;
	if (navigator.appName.indexOf("Microsoft") != -1)
	{
		var params = [['movie',TreeMapGViz.SWF_SRC],
					  ['allowScriptAccess','always'],
					  ['FlashVars',flashVars]];
		html.push('<object id="'+this.id+'" classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" width="'+w+'" height="'+h+'">');
		for (var i=0; i<params.length; i++){
			var p = params[i];
			html.push('<param name="'+p[0]+'" value="'+p[1]+'"/>');
		}
		html.push('</object>');
	}
    else
    {
        html.push('<embed name="'+this.id+'" src="'+TreeMapGViz.SWF_SRC+'" style="width:'+(w)+'; height:'+(h)+';" allowscriptaccess="always" flashVars="'+flashVars+'"/>');
    }
    this.container.innerHTML = html.join('\r\n');
}


/**
 * Waits for a ready signal from the SWF object using 100 ms timeouts, then calls the render function.
 */
TreeMapGViz.prototype.waitForSWF = function(){
	var ready = false;
	
	if (this.swfReady){
		//ready
		ready = true;
		if (this.swf == null){
   			if (navigator.appName.indexOf("Microsoft") != -1)
				this.swf = window[this.id];
    		else
	        	this.swf = document[this.id];
	    }
    	
		if (this.swf.render == null){
			//in FF, swf might be signaling but the external API is not available yet, so not ready yet
			TreeMapGViz.debug('swf not really ready');
			ready = false;
		}	
	}
	
	if (ready){
		TreeMapGViz.debug('swf ready! '+this.swf);
		this.render();
	}
	else
		setTimeout('TreeMapGViz.dispatchTable["'+this.id+'"].waitForSWF()',100);
}

/**
 * Renders the tree map by sending options and data to the SWF object. 
 */
TreeMapGViz.prototype.render = function(){
    TreeMapGViz.debug('render()');
    
    try{
    	this.loadOptions();
    	if (this.data == 'test')
    		this.loadTestData();
    	else
    		this.loadData();
    
	    this.swf.render();
	}catch(e){
		TreeMapGViz.debug('error in render(): '+e);
	}   
}
/**
 * Reads user options from the options object and communicates them to the SWF object.
 */
TreeMapGViz.prototype.loadOptions = function(){
    try{    
        var o = new Object();
        
        //layout options
        o.layoutMode = 1; 
        o.sort = false;
        
        //label options
        o.labelColor = null;
        o.labelsOnTopSize = 16;
        o.labelsAlpha = false;
        o.labelsInvert = true;
        o.labelsColorMultiply = false;
        
        //fill options
        o.rootColor = 'ffffff';
        o.pertrube = 0.3;
        o.randomLevel = 1;
        o.minColor = '00ff00';
        o.maxColor = 'ff0000';
        
        //border options
        o.borderWidth = 1; 
        o.borderColor = null;
        o.increaseBorderByLevel = false;
        o.borderExtrudeAmount = 0.0;
        o.childPadding = 6;
        o.siblingPadding = 4;
        
        this.pathToken = null;
        
		if (this.options != null && this.options.getInt != null){

			o.width = this.options.width;
			o.height = this.options.height;
			
			this.pathToken = this.options.getString('pathToken');
			if (this.pathToken.length == 0){ this.pathToken = null; };
			
            if (this.options.getInt('labels')==2)
                o.labelsOnTopSize = 0;
            o.minColor = this.options.getString('minColor');
            o.maxColor = this.options.getString('maxColor');
	
			if (this.options.getInt('layout')==1){
				//3d
				o.borderWidth = 2;
				o.borderExtrudeAmount = 0.25;
			}else{
				//flat
                o.borderWidth = 1;
                o.borderExtrudeAmount = 0;
			}
			
		}
		
		this.swf.setOptions(o);
		
    }catch(e){
		TreeMapGViz.debug('error: '+e);
	}
}

/**
 * Loads data from the data object into the SWF object.
 */
TreeMapGViz.prototype.loadData = function(){

    TreeMapGViz.debug('loadData()');
	var s = this.swf;
	var d = this.data;

	//validate data
	if (d == null)
		throw 'DataTable must be provided';
	var rowsNum = d.getNumberOfRows();
	if (rowsNum < 1)
		throw 'At least one row is required';
	var colsNum = d.getNumberOfColumns();
	if (colsNum < 2)
		throw 'At least one column is required';
	TreeMapGViz.debug('cols='+colsNum+',rows='+rowsNum);

	//determine weights, color and label columns indexes
	var wCol = null; 
	var cCol = null;
	var lCols = [];
	for (var i=0; i<colsNum; i++){
		var t = d.getColumnType(i);
		if (t == 'number'){
			if (wCol == null)
				wCol = i;
			else if (cCol == null)
				cCol = i;
			else
				lCols.push(i);
		}else{
			lCols.push(i);
		}
	}

	if (wCol == null)
		throw 'At least one numeric column is required';

	//populate SWF with data rows
	s.setMaxRecords(rowsNum);
	var prevL = null;
	for (var i=0; i<rowsNum; i++){
		try{
			//weight
			var w = d.getValue(i,wCol);
			if (w <= 0) continue;
			//color
			var c = (cCol == null)?null:d.getValue(i,cCol);
			//labels
			var l = null;
			if (lCols.length > 1 || this.pathToken == null){
				l = new Array(lCols.length);
				for (var j=0; j<lCols.length; j++){
					l[j] = d.getValue(i,lCols[j]);
					if (l[j] == null) l[j] = '';
					if (l[j] == '' && prevL != '')
					    l[j] = prevL[j];
				}
				prevL = l;
			}
			else
			{
				//split value by path token
				var path = d.getValue(i,lCols[0]);
				if (path != null)
					l = path.split(this.pathToken);
				else
					l = ['ERROR'];
			}
			s.addRecord(w,c,l);
		}catch(e){
			throw e;
		}
	}
}

/**
 * Loads random data into the SWF object. This is used only in development.
 */
TreeMapGViz.prototype.loadTestData = function(){
	TreeMapGViz.debug('loadTestData()');

    var rows = 100;
	var s = this.swf;
    s.setMaxRecords(rows);
    for (var i = 0; i<3*rows/4; i++){
    	s.addRecord(Math.random(), 0, 
    		['A'+Math.floor(Math.random()*10),
    		 'B'+Math.floor(Math.random()*10),
    		 'C'+Math.floor(Math.random()*10)]);
    }
    for (var i = 0; i<rows/4; i++){
    	s.addRecord(Math.random(), 0, 
    		['A'+Math.floor(Math.random()*10),
    		 'B'+Math.floor(Math.random()*10)]);
    }
}


/**
 * Initialization and creation of a TreeMapGViz in the context of a spreadsheet gadget.
 */
TreeMapGViz.gadgetInit = function(contentDiv,enableDebug){
	TreeMapGViz.debugInit(enableDebug,contentDiv);
	google.load("visualization", "1.0");
	
	var apiLoadedHandler = function(){
		try{
			//create data api query an send it based on prefs 
			var prefs = new _IG_Prefs();
			var gadgetHelper = new google.visualization.GadgetHelper(); 
			var query = gadgetHelper.createQueryFromPrefs(prefs);
			query.send(queryResponseHandler);
		}catch(e){
			TreeMapGViz.debug('error on apiLoadedHandler(): '+e);
		}
	};
	
	var queryResponseHandler = function(res){
		try{
	        var dt = res.getDataTable();
			var tmg = new TreeMapGViz(contentDiv);

			var prefs = new _IG_Prefs();

			//prefs.width = contentDiv.clientWidth-12; 
			//prefs.height = contentDiv.clientHeight-12; 
			prefs.width = document.body.clientWidth - 12;
			prefs.height = document.body.clientHeight - 12;

			tmg.draw(dt,prefs);

		}catch(e){
			TreeMapGViz.debug('error on queryResponseHandler(): '+e);
		}
	};
	
	google.setOnLoadCallback(apiLoadedHandler);
}


/**
 * Static variable controls debugging output
 * @type bool
 * @private
 */
TreeMapGViz.DEBUG = false;

/**
 * Static method enables debugging and creates a textarea where debug messages are printed
 * @param {enable} enables/disables debugging output.
 * @param {contentDiv} a reference div area next to which the textarea is put. The div will be resized in the process.
 * @private
 */
TreeMapGViz.debugInit = function(enableDebug,contentDiv){
	try{
		TreeMapGViz.DEBUG = enable;
		if (!enable)
			return;
			
		TreeMapGViz.debugHTML = '';
		
		//create the textarea
		var e = document.createElement('textarea');
		e.setAttribute('style','position:absolute; top:0; left:0; width:100%; height:25%; font-size:8pt; padding:0px; color:black; overflow:scroll; background-color:grey');
		TreeMapGViz.debugElement = e;
		contentDiv.parentNode.appendChild(e);
		
		//resize the div
		contentDiv.style.top = '25%';
		contentDiv.style.height = '75%';
	}catch(e){
		//do nothing		
	}
}

/**
 * Static method for printing debug messages when debugging is enabled.
 * @param {msg} message to print
 * @private
 */
TreeMapGViz.debug = function(msg) {
	try{
		if (TreeMapGViz.DEBUG) {
			TreeMapGViz.debugHTML += msg +'\r\n';
			TreeMapGViz.debugElement.value = TreeMapGViz.debugHTML;
		}
	}catch(e){
		//do nothing
	}
}

