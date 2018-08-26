import createDebug from 'debug';

const debug = createDebug('ms:util');
// Common utilities

// call `enter`(pathname) when visiting `path` (string orregex)
// call `exit`(pathname) when leaving `path`
const routes = [];
$(document).on('turbolinks:load', () => {
  const { pathname } = location;
  for (const route of routes) {
    if (route.pathisRe ? pathname.match(route.path) : route.path === pathname) {
      route.enter.call(null, pathname);
      route.current = true;
    }
    else if (route.current) {
      route.current = false;
      route.exit.call(null, pathname);
    }
  }
});

$(window).on('beforeunload', () => {
  debug('onbeforeunload');
  const route = routes.find(route => route.current) || { exit: () => {} };
  route.current = false;
  route.exit.call(null);
});

export function route(path, enter, exit = () => {}) {
  if (!path || !enter) {
    throw new Error('Expecting at least two arguments to utils.route(), got: ' + JSON.stringify(arguments));
  }
  routes.push({
    path,
    pathisRe: path instanceof RegExp,
    enter,
    exit,
    current: false
  });
}

export function onLoad(cb) {
  $(document).on('turbolinks:load', cb);
}

export function installSelectpickers() {
  $('.selectpicker').selectpicker({
    dropupAuto: true,
    liveSearch: true,
    liveSearchNormalize: true,
    showSubtext: true,
    noneResultsText: 'No results matched {0}. Hit Enter to create it.'
  });

  // Selectpicker "extension": custom input. If there are no options matching the live search,
  // create a new one, add it to the list, and select it.
  $('.bs-searchbox input[type="text"]').on('keydown', ev => {
    const tgt = $(ev.target);
    const list = tgt.parents('.dropdown-menu');

    // User hit Enter and there were no results found for the given input
    if (ev.keyCode === 13 && list.find('li.no-results').length > 0) {
      ev.preventDefault();

      const select = tgt.parents('div.bootstrap-select').find('select');
      const input = tgt.val();
      const option = $(`<option value="${input}">${input}</option>`);
      option.appendTo(select);
      select.selectpicker('refresh')
      .selectpicker('val', input)
      .selectpicker('toggle');
    }
  });
}
