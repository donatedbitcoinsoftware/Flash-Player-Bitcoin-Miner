// Flash Player Bitcoin Miner
//
// This code handles the network communication between the bitcoin miner written in C
// and the bitcoin mining pool.
// Processing is done in display frame handling function. This function has to return
// within a limited amount of time (approx. 15 seconds).
// For this reason mining has to be split in chunks which fit in a time allocated
// for one display frame (Note: for this project the frame rate is set to 24 FPS).
// In addition to that one display frame cannot be completely saturated with calculations
// otherwise it will negatively impact other Flash animations running on the same
// web page or even on different browser tabs (in some cases all Flash animations share
// the same thread).
//
// This code is free software: you can redistribute it and/or modify it under
// the terms of the GNU Lesser General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option)
// any later version.
//
// This code is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for
// more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with code. If not, see <http://www.gnu.org/licenses/>.

package{
  import cmodule.miner.CLibInit;
  import flash.display.LoaderInfo;
  import flash.display.Shape;
  import flash.display.Sprite;
  import flash.display.StageAlign;
  import flash.display.StageScaleMode;
  import flash.events.Event;
  import flash.events.IOErrorEvent;
  import flash.events.TimerEvent;
  import flash.net.URLLoader;
  import flash.net.URLLoaderDataFormat;
  import flash.net.URLRequest;
  import flash.net.URLRequestHeader;
  import flash.net.URLRequestMethod;
  import flash.utils.Timer;
  import mx.utils.Base64Encoder;

  public class miner extends Sprite{
    // C library
    private var lib:Object;
    // Initiate nonce values
    private var chunk:int = 1000;
    private var minimum:int = 0
    private var maximum:int = chunk;
    private var limit:int = chunk;
    // Initiate scan-time value
    private var scantime:int = 10;
    // Information about the mining pool (host, port number, worker name & password)
    private var host:String = "";
    private var port:String = "";
    private var user:String = "";
    private var pass:String = "";
    // Mining pool info is combined into:
    // - The URL for pool bitcoin mining pool proxy
    // - The Base64 authorization string
    private var pool:String;
    // Request headers with MIME type and authorization
    private var mime:URLRequestHeader = new URLRequestHeader("Content-type", "application/json");
    private var auth:URLRequestHeader;
    // For measuring performance
    private var timestamp:Date;
    // Processing variables
    private var run:Boolean = false;
    private var hash1:String;
    private var data:String;
    private var midstate:String;
    private var target:String;
 
    public function miner(){
      var loader:CLibInit = new CLibInit;
      lib = loader.init();
      // Prepare bitcoin mining pool related values
      var variable:Object;
      variable = LoaderInfo(this.root.loaderInfo).parameters.host;
      if(variable != null){
        host = variable.toString();
      }
      variable = LoaderInfo(this.root.loaderInfo).parameters.port;
      if(variable != null){
        port = variable.toString();
      }
      variable = LoaderInfo(this.root.loaderInfo).parameters.user;
      if(variable != null){
        user = variable.toString();
      }
      variable = LoaderInfo(this.root.loaderInfo).parameters.pass;
      if(variable != null){
        pass = variable.toString();
      }
      // Combine the bitcoin mining pool information
      if(host == "" || port == ""){
        // Use originating host as a bitcoin mining pool server
        var regexp:RegExp = new RegExp("^(?:f|ht)tp(?:s)?\://([^/]+)", "im");
        host = root.loaderInfo.loaderURL.match(regexp)[1].toString();
        port = "8332";
        pool = "http://" + host + ":" + port + "/";
      }else{
        // Use the originating host as bitcoin mining pool proxy
        pool = "/proxy?host=" + host + "&port=" + port;
      }
      var encoder:Base64Encoder = new Base64Encoder();
      encoder.encode(user + ":" + pass)
      var token:String = "Basic " + encoder.toString();
      auth = new URLRequestHeader("Authorization", token);
      // Start mining function
      addEventListener(Event.ENTER_FRAME, mine);
      // Request mining work
      request();
      // Fill the view with white rectangle
      stage.scaleMode = StageScaleMode.NO_SCALE;
      stage.align = StageAlign.TOP_LEFT;
      var rectangle:Shape = new Shape();
      rectangle.graphics.beginFill(0xFFFFFF);
      rectangle.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
      rectangle.graphics.endFill();
      addChild(rectangle);
    }

    private function request(proof:String = ""):void{
      var content:Object;
      // Include proof-of-work if provided
      if(proof != ""){
        content = {"method":"getwork", "id":0, "params":[proof]};
      }else{
        content = {"method":"getwork", "id":0, "params":[]};
      }
      // Send the JSON request with an HTTP POST
      var request:URLRequest = new URLRequest(pool);
      request.method = URLRequestMethod.POST;
      request.requestHeaders.push(auth);
      request.requestHeaders.push(mime);
      request.data = JSON.stringify(content);
      var fetcher:URLLoader = new URLLoader();
      fetcher.dataFormat = URLLoaderDataFormat.TEXT;
      fetcher.addEventListener(IOErrorEvent.IO_ERROR, error);
      fetcher.addEventListener(Event.COMPLETE, process);
      fetcher.load(request);
    }

    // This funtion is called when a response is received from bitcoin mining pool
    private function process(event:Event):void{
      var fetcher:URLLoader = URLLoader(event.target);
      var response:Object;
      try{
        // Parse the response into a JSON object
        response = JSON.parse(fetcher.data);
        if(response["error"] == null){
          if(response["result"] == true || response["result"] == false){
            // This is a response to a submitted proof-of-work
            // Check if it is a true or false one and request a new job
            if(response["result"]){
              trace("True proof-of-work");
            }else{
              trace("False proof-of-work");
            }
            request();
          }else{
            // This is a response to a request for a new job, get to it
            hash1    = response["result"]["hash1"];
            data     = response["result"]["data"];
            midstate = response["result"]["midstate"];
            target   = response["result"]["target"];
            timestamp = new Date();
            run = true;
          }
        }else{
          recover();
        }
      }catch(error:Error){
        recover();
        return;
      }
    }

    private function mine(event:Event):void{
      var then:Date = new Date();
      var iterations:Number = 0;
      while(run){
        // Work on a chunk of mining job
        try{
          var result:Object = lib.start(hash1, data, midstate, target, minimum, maximum);
        }catch(error:RangeError){
          trace(error.message);
          trace(minimum);
          trace(maximum);
          return;
        }
        var now:Date = new Date();
        if(result.data.length > 0 || (maximum >= limit)){
          // Either found something or reached the end of the job
          if(result.data.length > 0){
            // Found something
            trace("Found: " + result.data);
          }
          // Adjust the nonce limit depending on planned scantime and hashing rate
          var delta:int = now.time - timestamp.time;
          limit = result.last * 30000 / delta;
          if(limit > 0xFFFFFFFA){
            limit = 0xFFFFFFFA;
          }
          // We will begin with the first chunk of work in the next frame
          minimum = 0;
          maximum = chunk;
          run = false;
          // Calculate the performance
          var rate:int = result.last / delta;
          trace("" + rate + " khash/s");
          // Submit proof-of-work or ask for a new job
          request(result.data);
          return;
        }else{
          // Shift to a next chunk of the job
          minimum = maximum;
          maximum = minimum + chunk;
          maximum = maximum > limit ? limit : maximum;
        }
        // Now make sure we do not exceed time allocated for a display frame
        // and that we do not fully saturate display frame with calculations
        // (full saturation would be at 41.7 - it is derived from the FPS rate)
        iterations += 1.0;
        var duration:Number = (now.time - then.time) / iterations;
        if(duration * (iterations + 1.0) > 40.5){
          return;
        }
      }
    }

    private function retry(event:TimerEvent):void{
      request();
    }

    private function recover():void{
      // Ask for a new job after a timeout of 30 seconds
      var timer:Timer = new Timer(30000, 1);
      timer.addEventListener(TimerEvent.TIMER, retry);
      timer.start();
    }

    private function error(event:IOErrorEvent):void{
      recover();
    }
  }
}
