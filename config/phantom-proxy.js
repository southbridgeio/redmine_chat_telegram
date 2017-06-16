var args = require('system').args;
var page = require('webpage').create();

function exit () {
  phantom.exit();
}

if (args.length === 1) {
  console.log('Usage: <url>');
  exit()
}

page.onConsoleMessage = function(msg) {
  console.log(msg);
};

page.onError = function(msg, trace) {
  console.log(msg);
  trace.forEach(function(item) {
    console.log('  ', item.file, ':', item.line);
  });
};

function waitFor(testFx, onReady, timeOutMillis) {
  var maxtimeOutMillis = timeOutMillis ? timeOutMillis : 5000, //< Default Max Timout is 5s
      start = new Date().getTime(),
      condition = false,
      interval = setInterval(function () {
        if ((new Date().getTime() - start < maxtimeOutMillis) && !condition) {
          // If not time-out yet and condition not yet fulfilled
          condition = (typeof (testFx) === "string" ? eval(testFx) : testFx()); //< defensive code
        } else {
          if (!condition) {
            // If condition still not fulfilled (timeout but condition is 'false')
            //console.log("'waitFor()' timeout");
            typeof (onReady) === "string" ? eval(onReady) : onReady();
            clearInterval(interval);
            //phantom.exit(1);
          } else {
            // Condition fulfilled (timeout and/or condition is 'true')
            console.log("'waitFor()' finished in " + (new Date().getTime() - start) + "ms.");
            typeof (onReady) === "string" ? eval(onReady) : onReady(); //< Do what it's supposed to do once the condition is fulfilled
            clearInterval(interval); //< Stop this interval
          }
        }
      }, 500); //< repeat check every 500ms
}

var url = args[1];

console.log(url);

page.open(url, function() {
  waitFor(
    function () {
      return page.evaluate(function () {
        return $('#api-status').hasClass('ready');
      });
    },
    function () {
      exit()
    }, 10000);
});
