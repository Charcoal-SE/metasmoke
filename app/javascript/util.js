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
  const currentRoutes = routes.filter(route => route.current);
  currentRoutes.forEach(route => {
    route.current = false;
    if (typeof route.exit === 'function') {
      route.exit.call(null);
    }
  });
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

    $(e).parent().find('.bs-searchbox input[type="search"]').on('keydown', ev => {
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
