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

  // Another extension: AJAX data sources. Add data-remote-source to a .selectpicker to activate this.
  // Will send a request to that route with ?q=user-text-here
  const sendSearchRequest = async (source, target) => {
    target = $(target);
    const input = target.val();
    const response = await fetch(`${source}?q=${encodeURIComponent(input)}`);
    const data = await response.json();

    const options = data.map(i => `<option value="${i.value}">${i.text}</option>`);
    const select = target.parents('div.bootstrap-select').find('select');
    select.empty();
    $('<option value></option>').appendTo(select);
    options.forEach(o => $(o).appendTo(select));
    select.selectpicker('refresh');
  };

  let timeout;

  $('.selectpicker[data-remote-source]').each((i, e) => {
    const source = $(e).data('remote-source');

    $(e).selectpicker({
      dropupAuto: true,
      liveSearch: true,
      liveSearchNormalize: true,
      showSubtext: true,
      noneResultsText: 'No results matched your search or you need to enter more characters to search with.'
    });

    $(e).parent().find('.bs-searchbox input[type="text"]').on('keydown', ev => {
      if ($(ev.target).val().length < 2) {
        return;
      }

      if (timeout) {
        clearTimeout(timeout);
      }

      timeout = setTimeout(() => {
        sendSearchRequest(source, ev.target);
      }, 200);
    });
  });
}
