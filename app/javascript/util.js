import createDebug from 'debug';

const debug = createDebug('ms:util');
// Common utilities

// call `enter`(pathname) when visiting `path` (string or regex)
// call `exit`(pathname) when leaving `path`
const routes = [];
$(document).on('turbolinks:load', () => {
  const { pathname } = location;
  // Call the exit function for all routes which were current.
  for (const route of routes) {
    if (route.current) {
      // We've loaded a new page.  We need to call the the exit function for any routes that
      // matched the prior page (i.e.  are marked as current), even if we're transitioning
      // to a page which will also match this route.  If we don't always do this, then code
      // which is setting up a new page can end up either not being called too many times
      // without tearing down what's been set up.
      // Note that the exit function is being called when the new <body> DOM already exists,
      // so the exit function doesn't need to undo changes which were made to the prior body.
      if (typeof route.exit === 'function') {
        route.exit.call(null, pathname);
      }
    }
  }
  // Call the enter function for all matching routes.
  for (const route of routes) {
    route.current = false;
    if (route.pathisRe ? route.path.test(pathname) : route.path === pathname) {
      // Note: for forward/back translations the state of the DOM may be notably different
      // than for loading a new page.
      route.enter.call(null, pathname);
      route.current = true;
    }
  }
});

$(window).on('beforeunload', () => {
  debug('onbeforeunload');
  // Call all existing exit functions for current routes.
  //
  // Note that the exit functions are being called when the DOM for the page which
  // matched the route still exists at this time, which is different than for Turbolinks
  // transitions where the exit function is called after the new <body> DOM exists.
  const currentRoutes = routes.filter(route => route.current);
  currentRoutes.forEach(route => {
    route.current = false;
    if (typeof route.exit === 'function') {
      route.exit.call(null);
    }
  });
});

// Run a function upon loading a "new page" that matches `path` and/or having exited a
// page where the `path` matched upon loading.  These are called upon either initial loading
// of an MS page or for Turbolinks transitions to "new" pages.  Turbolinks replaces the
// <body> element. Both the enter and exit functions are called after the new DOM exists.
// In addition, the exit function is called on the window beforeunload event just prior to
// an actual transition to a completely new page. At that point a new DOM does not exist.
//
// path can be either a String, which must be an exact match to the
//   window.location.pathname, or a RegExp, which must return true for
//   path.test(window.location.pathname).
// The enter function is called with the window.location.pathname of the *new* page when
//   transitioning to a new page, either a fresh page load or a Turbolinks load, when the
//   window.location.pathname matches the supplied path.
// The exit function is called with the window.location.pathname of the *new* page when
//   a new page DOM *has already been loaded* using a Turbolinks transition when the
//   window.location.pathname of the *prior* page matched the supplied path.
// All applicable exit functions are called prior to any enter functions for the new page.
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
  $('.bs-searchbox input[type="search"]').on('keydown', ev => {
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

    $(e).parent().find('.bs-searchbox input[type="search"]').on('keydown input', ev => {
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

  // For domain tag selection, copy the class and style from the selected option to the .filter-option-inner-inner.
  function useOptionClassAndStyleForSelectedDropdownOption(event, clickedIndex, isSelected) {
    const $target = $(event.target);
    const dropdown = $target.closest('.dropdown');
    const innerInner = dropdown.find('.filter-option-inner-inner').first();
    innerInner[0].className = 'filter-option-inner-inner';
    innerInner.removeAttr('style');
    if (isSelected) {
      const option = event.target.options[clickedIndex];
      innerInner
        .addClass(option.className)
        .attr('style', $(option).attr('style'));
    }
  }
  $('.domain-tag-list #tag_name').off('changed.bs.select');
  $('.domain-tag-list #tag_name').on('changed.bs.select', useOptionClassAndStyleForSelectedDropdownOption);
  // For all AS-XXXX tags indicate that they are "special". The class really should be based on the database, not a text match.
  $('.domain-tag-list option[value^="AS-"]').addClass('special-tag');
  $('.domain-tag-list div.bootstrap-select select').selectpicker('refresh');
  $('.domain-tag-list .dropdown-toggle:not(.bs-placeholder) .filter-option-inner-inner').each(function () {
    const valueText = this.firstChild.textContent;
    const $this = $(this);
    const selectedOption = $this.closest('.bootstrap-select').find(`select option[value="${valueText}"]`);
    if (selectedOption.length > 0) {
      $this
        .addClass(selectedOption[0].className)
        .attr('style', selectedOption.attr('style'));
    }
  });
}

// Cred. broofa et. al. https://stackoverflow.com/a/2117523
export function uuid4() {
  return ([1e7] + -1e3 + -4e3 + -8e3 + -1e11).replace(/[018]/g, c =>
    (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16)
  );
}

export function hashCode(str) {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const character = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + character;
    hash &= hash;
  }
  return hash;
}

// Local Settings panel
export function addLocalSettingsHeaderToAccount() {
  if ($('.local-settings-panels-container').length === 0) {
    $('div.row').append(`<br style="clear: both;">
    <h2 class="text-center">Local Browser Settings</h2>
    <p class="text-center">These settings apply only to the current browser.</p>
    <div class="row local-settings-row">
      <div class="col-md-8 col-md-offset-2 local-settings-panels-container">
      </div>
    </div>`);
  }
}

export function addLocalSettingsPanel(content) {
  addLocalSettingsHeaderToAccount();
  const panelsContainer = $('.local-settings-panels-container');
  const panel = $(`<div class="panel panel-default">
    <div class="panel-body">
    </div>
  </div>`);
  panel.find('.panel-body').append(content);
  panelsContainer.append(panel);
}
