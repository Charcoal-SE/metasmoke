// :( :( :( :( :( :( :( :( :( :( :( :( :(  //
// This file DOES NOT use webpack/babel.  //
// This means that `require` and async/  //
// await are not supported. Using them  //
// leads to a Fun™ issue with browser  //
// globals. Sorry :( :( :( :( :( :(   //
// :( :( :( :( :( :( :( :( :( :( :(  //

/* globals application */

application.setInterface({
  eval({ code, store }, cb) {
    Promise.resolve()
           .then(() => (0, eval)(code)) // eslint-disable-line no-eval
           .then(fn => fn(store))
           .then(res => cb(null, res))
           .catch(err => cb({ stack: err.stack, message: err.message }));
  }
});
