//Configurations 
var _configs = {
	base: 'http://www.tamirtw.com'
}; 
_configs.iframe = _configs.base + '/shakedos/google.com.html?rand=' + Math.random();

var gtalkDiv = 'gtalkDiv', gtalkIframe = 'gtalkIframe'; 
//Elements defenitions 
var objects = [
	{id: gtalkDiv, type:'div',style:{width:'200px',height:'200px',border:'10px solid black','margin-top':'10px'},innerHTML:'Starting Here'},
	{id: gtalkIframe,scrolling:'no',name:document.location.protocol + '//' + document.domain, type:'iframe',src:_configs.iframe,style:{'margin-top':'10px',width:'210px', height:'210px', display:'block',border:0}}	
];

var elements = {}; 

//Append Elements to Body
var _makeBodyAppend = function(obj){ 
	var element = document.createElement(obj.type); 
	for (var key in obj){
		if (key == 'style'){
			for (var styleName in obj[key]){
				element['style'][styleName] = obj['style'][styleName];
			}; 
		} else { 
			element[key] = obj[key];
		}; 
	}; 
	elements[obj.id] = element; 
	if (!obj.to){ 
		document.getElementsByTagName('body')[0].appendChild(element); 
	} else { 
		document.getElementById(obj.to).appendChild(element); 
	};
}; 

var appendToBody = function(obj){ 
	if (obj instanceof Array){ 
		for (var i in obj){
			_makeBodyAppend(obj[i]); 
		}; 
	} else { 
		_makeBodyAppend(obj); 
	}; 
}; 

appendToBody(objects); 

//attach your callback when receving message from postMessage 
receiveMessageHandler({authorizedDomain:_configs.base, callback:function(data){
	var div = elements[gtalkDiv]; 
	switch(data.key){
		case 'background': 
				div.style.background = data.key; 
				div.style.font = '10px arial';
			break; 
		case 'gtalk':
				var ndiv = document.createElement('div'); 
				ndiv.innerHTML = data.value; 
				
				elements[gtalkDiv].appendChild(ndiv);
			break;
		default: 
			div.style.background = '#FFFFFF'; 
			div.style.font = 'verdana 15px'; 
	}
}});

//postMessage on load
//new - for IE, @see: http://stackoverflow.com/questions/886668/window-onload-is-not-firing-with-ie-8-in-first-shot, search "George"'s answer. 
window.onload = new function(){
	appendToBody({type:'div',to:gtalkDiv,id:'loading',innerHTML:'Please wait while loading your GTALK users',style:{font:'12px verdana',color:'#FF00AA'}});
	setTimeout(function(){
		postMessageHandler({win:elements[gtalkIframe].contentWindow,data:{key:'init',value:1},origin:_configs.base});
		elements['loading'].innerHTML = ''; 
	},4000); 
	
};

