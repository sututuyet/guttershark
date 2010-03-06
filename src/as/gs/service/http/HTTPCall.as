package gs.service.http 
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLVariables;
	import flash.utils.Dictionary;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	/**
	 * Dispatched when the service call is complete.
	 * 
	 * @eventType gs.service.http.HTTPServiceEvent
	 */
	[Event("complete", type="gs.services.http.HTTPServiceEvent")]
	
	/**
	 * Dispatched the first time the service call is sent.
	 * 
	 * @eventType gs.service.http.HTTPServiceEvent
	 */
	[Event("firstCall", type="gs.services.http.HTTPServiceEvent")]
	
	/**
	 * Dispatched when all retries have attempted and failed.
	 * 
	 * @eventType gs.service.http.HTTPServiceEvent
	 */
	[Event("timeout", type="gs.services.http.HTTPServiceEvent")]
	
	/**
	 * Dispatched each time a retry is sent.
	 * 
	 * @eventType gs.service.http.HTTPServiceEvent
	 */
	[Event("retry", type="gs.services.http.HTTPServiceEvent")]
	
	/**
	 * Dispatched when the service call fails.
	 * 
	 * @eventType gs.service.http.HTTPServiceEvent
	 */
	[Event("fault", type="gs.services.http.HTTPServiceEvent")]
	
	/**
	 * Dispatched on IOError.
	 * 
	 * @eventType flash.events.IOErrorEvent
	 */
	[Event("ioError", type="flash.events.IOErrorEvent")]
	
	/**
	 * Dispatched for progress updates.
	 * 
	 * @eventType flash.events.ProgressEvent
	 */
	[Event("progress", type="flash.events.ProgressEvent")]
	
	/**
	 * Dispatched for security errors.
	 * 
	 * @eventType flash.events.SecurityErrorEvent
	 */
	[Event("securityError", type="flash.events.SecurityErrorEvent")]
	
	/**
	 * Dispatched for http status events whose status code is not 0 and not 200.
	 * 
	 * @eventType flash.events.HTTPStatusEvent
	 */
	[Event("httpStatus", type="flash.events.HTTPStatusEvent")]
	
	/**
	 * Dispatched when the request is opened.
	 * 
	 * @eventType flash.events.Event
	 */
	[Event("open", type="flash.events.Event")]
	
	/**
	 * The HTTPCall class simplifies http requests.
	 * 
	 * <p>The HTTPCall class also adds timeouts, retries, and gives you the
	 * option of setting callback functions for events instead of
	 * using addEventListener.</p>
	 * 
	 * <script src="http://mint.codeendeavor.com/?js" type="text/javascript"></script>
	 */
	public class HTTPCall extends EventDispatcher
	{
		
		/**
		 * Internal lookup.
		 */
		private static var _htc:Dictionary = new Dictionary(true);
		
		/**
		 * @private
		 * 
		 * The http call id.
		 */
		public var id:String;
		
		/**
		 * A callback for when the first attempt is made.
		 */
		public var onFirstCall:Function;
		
		/**
		 * A callback to handle the result - you get passed an HTTPCallResult.
		 */
		public var onResult:Function;
		
		/**
		 * A callback to handle a fault - you get passed an HTTPCallFault.
		 */
		public var onFault:Function;
		
		/**
		 * A callback when a retry happens.
		 */
		public var onRetry:Function;
		
		/**
		 * A callback to call when all retries have tried but no
		 * result is available.
		 */
		public var onTimeout:Function;
		
		/**
		 * A callback to handle security errors.
		 */
		public var onSecurityError:Function;
		
		/**
		 * A callback for progress events.
		 */
		public var onProgress:Function;
		
		/**
		 * A callback for io error events.
		 */
		public var onIOError:Function;
		
		/**
		 * A callback for when the request is opened.
		 */
		public var onOpen:Function;
		
		/**
		 * A callback for http status events.
		 */
		public var onHTTPStatus:Function;
		
		/**
		 * The time each attempt is given before timeing out,
		 * and trying again.
		 */
		public var timeout:int;
		
		/**
		 * The number of retries allowed.
		 */
		public var retries:int;
		
		/**
		 * The response format.
		 */
		public var responseFormat:String;
		
		/**
		 * A result handler class - the default is HTTPCallResultHandler.
		 * 
		 * <p>You can create your own handler classes to intercept
		 * a result and process it accordingly. Read through the
		 * source of HTTPCallResultHandler to customize</p>
		 */
		public var resultHandler:Class;
		
		/**
		 * Internal loader for the request.
		 */
		public var loader:URLLoader;
		
		/**
		 * Internal request for the call.
		 */
		public var request:URLRequest;
		
		/**
		 * Request method.
		 */
		protected var _method:String;
		
		/**
		 * Request data.
		 */
		protected var _data:Object;
		
		/**
		 * Whether or not this service has been sent yet.
		 */
		private var sent:Boolean;
		
		/**
		 * Try counter.
		 */
		private var tries:int;
		
		/**
		 * setTimeout id.
		 */
		private var timeoutid:Number;
		
		/**
		 * Whether or not this call is complete.
		 */
		private var complete:Boolean;
		
		/**
		 * Get an HTTPCall instance.
		 * 
		 * @param id The id of the http call.
		 */
		public static function get(id:String):HTTPCall
		{
			if(!id)return null;
			return _htc[id];
		}
		
		/**
		 * Save an HTTPCall instance.
		 * 
		 * @param id The id for the http call.
		 * @param call The http call.
		 */
		public static function set(id:String,call:HTTPCall):void
		{
			if(!id||!call)return;
			if(!call.id)call.id=id;
			_htc[id]=call;
		}
		
		/**
		 * Unset (delete) and HTTPCall instance.
		 * 
		 * @param id The http call id.
		 */
		public static function unset(id:String):void
		{
			if(!id)return;
			delete _htc[id];
		}
		
		/**
		 * Constructor for HTTPCall instances.
		 * 
		 * @param _url The URL endpoint.
		 * @param _method The request method (URLRequestMethod.POST or URLRequestMethod.GET).
		 * @param _timeout The time given to each attempt before retrying.
		 * @param _retries The numer of retries allowed.
		 * @param _responseFormat The response format for the call. (HTTPCallResponseFormat).
		 * @param _resultHandler A class to use as the result handler. The default is HTTPCallResultHandler.
		 */
		public function HTTPCall(_url:String,_method:String="GET",_data:Object=null,_timeout:int=5000,_retries:int=1,_responseFormat:String="variables",_resultHandler:Class=null)
		{
			if(!_url)throw new Error("ERROR: Parameter {url} cannot be null.");
			sent=false;
			tries=0;
			timeout=_timeout;
			retries=_retries;
			resultHandler=_resultHandler || HTTPCallResultHandler;
			request=new URLRequest(_url);
			request.requestHeaders=[];
			loader=new URLLoader();
			responseFormat=_responseFormat;
			data=_data;
			method=_method;
		}
		
		/**
		 * Set callbacks for events.
		 * 
		 * @param _onResult The on result handler.
		 * @param _onFault The on fault handler.
		 * @param _onTimeout The timeout handler.
		 * @param _onRetry The on retry handler.
		 * @param _onFirstCall The on first call handler.
		 * @param _onProgress The on progress handler.
		 * @param _onHTTPStatus The on http status handler.
		 * @param _onOpen The on open handler.
		 * @param _onIOError The on io error handler.
		 * @param _onSecurityError The on security error handler.
		 */
		public function setCallbacks(_onResult:Function=null,_onFault:Function=null,_onTimeout:Function=null,_onRetry:Function=null,_onFirstCall:Function=null,_onProgress:Function=null,_onHTTPStatus:Function=null,_onOpen:Function=null,_onIOError:Function=null,_onSecurityError:Function=null):void
		{
			onOpen=_onOpen;
			onHTTPStatus=_onHTTPStatus;
			onIOError=_onIOError;
			onResult=_onResult;
			onFault=_onFault;
			onTimeout=_onTimeout;
			onRetry=_onRetry;
			onFirstCall=_onFirstCall;
			onSecurityError=_onSecurityError;
			onProgress=_onProgress;
		}
		
		/**
		 * Add a header to the request.
		 * 
		 * @param name The header name.
		 * @param value The header value.
		 */
		public function addHeader(name:String,value:String):void
		{
			var header:URLRequestHeader=new URLRequestHeader(name,value);
			request.requestHeaders.push(header);
		}
		
		/**
		 * Removes all headers.
		 */
		public function clearHeaders():void
		{
			request.requestHeaders=[];
		}
		
		/**
		 * The request method.
		 */
		public function set method(val:String):void
		{
			_method=val;
			request.method=val;
		}
		
		/**
		 * The request method.
		 */
		public function get method():String
		{
			return _method;
		}
		
		/**
		 * The request data to submit for either POST or GET.
		 */
		public function set data(val:Object):void
		{
			_data=val;
			var key:String;
			var urlv:URLVariables=new URLVariables();
			for(key in val) urlv[key]=val;
			request.data=urlv;
		}
		
		/**
		 * The request data to submit for either POST or GET.
		 */
		public function get data():Object
		{
			return _data;
		}
		
		/**
		 * Executes this call.
		 */
		public function send():void
		{
			if(sent && !complete)return;
			execute();
		}
		
		/**
		 * Real execution logic.
		 */
		private function execute():void
		{
			if(tries==0 && onFirstCall!=null)onFirstCall();
			else if(tries==0)dispatchEvent(new HTTPCallEvent(HTTPCallEvent.FIRST_CALL));
			if(tries>retries && onTimeout!=null)
			{
				onTimeout();
				return;
			}
			else if(tries > retries)
			{
				dispatchEvent(new HTTPCallEvent(HTTPCallEvent.TIMEOUT));
				return;
			}
			removeEventListeners();
			loader=null;
			loader=new URLLoader();
			if(responseFormat == HTTPCallResponseFormat.TEXT) loader.dataFormat=URLLoaderDataFormat.TEXT;
			if(responseFormat == HTTPCallResponseFormat.JSON) loader.dataFormat=URLLoaderDataFormat.TEXT;
			if(responseFormat == HTTPCallResponseFormat.XML) loader.dataFormat=URLLoaderDataFormat.TEXT;
			if(responseFormat == HTTPCallResponseFormat.VARIABLES) loader.dataFormat=URLLoaderDataFormat.VARIABLES;
			if(responseFormat == HTTPCallResponseFormat.BINARY) loader.dataFormat=URLLoaderDataFormat.BINARY;
			addEventListeners();
			sent=true;
			if(tries>0&&onRetry!=null)onRetry();
			else if(tries>0 && onRetry==null)dispatchEvent(new HTTPCallEvent(HTTPCallEvent.RETRY));
			tries++;
			try{loader.load(request);}catch(e:*){}
			clearTimeout(timeoutid);
			if(timeout<50)timeout=1500;
			timeoutid=setTimeout(_timeout,timeout);
		}
		
		/**
		 * Call timeout handler.
		 */
		protected function _timeout():void
		{
			if(complete)return;
			execute();
		}
		
		/**
		 * Call complete handler.
		 */
		protected function _complete(e:Event):void
		{
			clearTimeout(timeoutid);
			complete=true;
			var reshandler:* =new resultHandler();
			var res:* =reshandler.process(this);
			if(res is HTTPCallResult && onResult!=null)onResult(res);
			else if(res is HTTPCallResult && onResult==null)dispatchEvent(new HTTPCallEvent(HTTPCallEvent.COMPLETE,false,false,res));
			if(res is HTTPCallFault && onFault!=null)onFault(res);
			else if(res is HTTPCallFault && onFault==null) dispatchEvent(new HTTPCallEvent(HTTPCallEvent.FAULT,false,false,null,res));
		}
		
		/**
		 * Internal progress handler.
		 */
		protected function _onProgress(e:ProgressEvent):void
		{
			if(onProgress!=null)onProgress(e);
			else dispatchEvent(e);
		}
		
		/**
		 * Internal open handler.
		 */
		protected function _onOpen(e:Event):void
		{
			if(onOpen!=null)onOpen();
			else dispatchEvent(e);
		}
		
		/**
		 * Internal http status handler.
		 */
		protected function _onHTTPStatus(e:HTTPStatusEvent):void
		{
			if(e.status!=0&&e.status!=200)return;
			if(onHTTPStatus!=null)onHTTPStatus(e);
			else dispatchEvent(e);
		}
		
		/**
		 * Internal io error handler.
		 */
		protected function _onIOError(e:IOErrorEvent):void
		{
			if(onIOError!=null)onIOError();
			else dispatchEvent(e);
		}
		
		/**
		 * Internal security error event handler.
		 */
		protected function _onSecurityError(e:SecurityErrorEvent):void
		{
			if(onSecurityError!=null)onSecurityError();
			else dispatchEvent(e);
		}

		/**
		 * Removes listeners.
		 */
		protected function removeEventListeners():void
		{
			if(!loader)return;
			loader.removeEventListener(Event.COMPLETE,_complete);
			loader.removeEventListener(Event.OPEN,_onOpen);
			loader.removeEventListener(ProgressEvent.PROGRESS,_onProgress);
			loader.removeEventListener(HTTPStatusEvent.HTTP_STATUS,_onHTTPStatus);
			loader.removeEventListener(IOErrorEvent.DISK_ERROR,_onIOError);
			loader.removeEventListener(IOErrorEvent.IO_ERROR,_onIOError);
			loader.removeEventListener(IOErrorEvent.NETWORK_ERROR,_onIOError);
			loader.removeEventListener(IOErrorEvent.VERIFY_ERROR,_onIOError);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR,_onSecurityError);
		}
		
		/**
		 * Adds listeners.
		 */
		protected function addEventListeners():void
		{
			if(!loader)return;
			loader.addEventListener(Event.COMPLETE,_complete);
			loader.addEventListener(Event.OPEN,_onOpen);
			loader.addEventListener(ProgressEvent.PROGRESS,_onProgress);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS,_onHTTPStatus);
			loader.addEventListener(IOErrorEvent.DISK_ERROR,_onIOError);
			loader.addEventListener(IOErrorEvent.IO_ERROR,_onIOError);
			loader.addEventListener(IOErrorEvent.NETWORK_ERROR,_onIOError);
			loader.addEventListener(IOErrorEvent.VERIFY_ERROR,_onIOError);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,_onSecurityError);
		}
		
		/**
		 * Dispose of this http call.
		 */
		public function dispose():void
		{
			removeEventListeners();
			HTTPCall.unset(id);
			id=null;
			request=null;
			loader=null;
			tries=0;
			retries=0;
			onResult=null;
			onFault=null;
			onFirstCall=null;
			onTimeout=null;
			onRetry=null;
			onIOError=null;
			onHTTPStatus=null;
			onOpen=null;
			onSecurityError=null;
			responseFormat=null;
			resultHandler=null;
			sent=false;
			timeoutid=NaN;
			complete=false;
			_method=null;
			_data=null;
		}
	}
}