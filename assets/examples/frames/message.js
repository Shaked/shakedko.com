//PostMessage Handler
var authorizedDomain,callback; 

//Handle postMessage messages 
var messageHandler = function(e){ 
	if (e.origin == authorizedDomain.replace(/([^:]+:\/\/[^\/]+).*/,'$1')){
		var data = JSON.parse(e.data); 
		callback(data); 
		
	}; 
};

//Make sure we can receive message and attach events
var receiveMessageHandler = function(object){
	authorizedDomain = object.authorizedDomain; 
	callback	= object.callback; 
	// we have to listen for 'message'
	if (window.addEventListener){
		window.addEventListener('message', messageHandler, false);
	} else {
		window.attachEvent('message',messageHandler);
	};
}; 

//Handle postMessage, validate browser support. 
var postMessageHandler = function(object){ 
	if (object.win.postMessage){
		try {
			object.win.postMessage(JSON.stringify(object.data),object.origin.replace(/([^:]+:\/\/[^\/]+).*/,'$1'));
		} catch(e){
			console.log(e);
		};	
	} else {
		throw "postMessage is not supported by your browser"; 
	}; 	
}; 
