import createDebug from 'debug';

import { route } from './util';

const debug = createDebug('ms:data');

window.store = {};
/* globals store, ace */

const loadPromise = ($el, gbl) => new Promise(resolve => window[gbl] ? resolve() : $el.on('load', resolve));

const addDataListRow = () => {
  $('.data-list').prepend($('#data-list-row').clone().removeClass('template'));
};

const displaySchema = async table => {
  $.ajax({
    type: 'GET',
    url: `/data/schema?table=${table}`
  }).done(data => {
    $('.schema-display').show();
    $('.schema-table-name').text(table);
    $('.table-schema').html(data.join('<br/>'));
  }).fail(xhr => {
    debug('Failed to get schema:', xhr);
  });
};

const fetchDataMultiple = async (types, limits) => {
  const required = [];
  for (let i = 0; i < types.length; i++) {
    if (!store.hasOwnProperty(types[i]) || store[types[i]].length !== limits[types[i]]) {
      required.push(types[i]);
    }
  }

  $.ajax({
    type: 'GET',
    url: '/data/retrieve',
    data: {
      types: required,
      limits
    }
  }).done(data => {
    const keys = Object.keys(data);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      store[key] = data[key];
    }
  }).fail(xhr => {
    debug('Couldn\'t load data:', xhr);
  });
};

const fetchData = (type, limit) => {
  const limits = {};
  limits[type] = limit;
  fetchDataMultiple([type], limits);
};

const humanize = function (s) {
  s = s.replace(/[-_]/g, ' ');
  return s.charAt(0).toUpperCase() + s.slice(1);
};

const preloadDataTypes = function () {
  const types = ['announcements', 'api_keys', 'commit_statuses', 'deletion_logs', 'feedbacks',
    'flag_conditions', 'flag_logs', 'flag_settings', 'moderator_sites', 'posts', 'reasons', 'roles',
    'sites', 'smoke_detectors', 'stack_exchange_users', 'statistics', 'user_site_settings', 'users'];
  const select = $('#data-list-row').find('.data-type-select');
  for (let i = 0; i < types.length; i++) {
    const dataType = types[i];
    const $option = $('<option>').val(dataType).text(humanize(dataType));
    select.append($option);
  }
};

const renderResults = (err, results) => {
  if (err) {
    debug('failed:', err);
    $('.js-script-error').attr('data-content', err.stack).fadeIn();
    return;
  }
  try {
    $('.results-table').show();

    const $headerRow = $('.results-header');
    const $resultBody = $('.results-body');

    $headerRow.find('th').remove();
    $resultBody.find('tr').remove();

    if (!(Array.isArray(results))) {
      throw new TypeError('results is not an array; can\'t render it');
    }

    const typeCheck = results.map(x => Array.isArray(x));
    if (typeCheck.indexOf(false) >= 0) {
      throw new Error('Not all elements of results are arrays; can\'t render results');
    }

    if (results.length >= 1) {
      const headers = results[0];
      for (let i = 0; i < headers.length; i++) {
        $headerRow.append($('<th>').text(headers[i]));
      }

      if (results.length >= 2) {
        for (let i = 1; i < results.length; i++) {
          const $row = $('<tr>');
          for (let m = 0; m < results[i].length; m++) {
            $row.append($('<td>').text(results[i][m]));
          }
          $resultBody.append($row);
        }
      }
    }

    $('.js-script-error').popover('hide').fadeOut();
  } catch (err) {
    $('.js-script-error').attr('data-content', err.stack).fadeIn();
  }
};

const validateDataset = () => {
  const types = [];
  const limits = {};
  $('.data-list-item').each((i, item) => {
    if ($(item).hasClass('template')) {
      return;
    }

    const $this = $(item);
    const type = $this.find('.data-type-select').first().val();
    const limit = $this.find('.data-type-limit').first().val();
    if (type && limit && type.length > 0 && limit.length > 0) {
      types.push(type);
      limits[type] = limit;
    }
  });

  const storedTypes = Object.keys(store);
  const surplusTypes = storedTypes.filter(x => types.indexOf(x) < 0);
  for (let m = 0; m < surplusTypes.length; m++) {
    delete store[surplusTypes[m]];
  }

  fetchDataMultiple(types, limits);
};

const themes = {
  dark: 'ace/theme/monokai',
  light: 'ace/theme/xcode'
};
let theme = localStorage.editorTheme || themes.dark;

let editor;
route('/data', async () => {
  preloadDataTypes();
  $('.schema-display').hide();
  $('.script-help').hide();

  await loadPromise($('.js-ace'), 'ace');

  const url = new URL(location.href);
  url.pathname = '/data_sandbox.js';

  editor = ace.edit('editor');
  if (localStorage.dataExplorerScriptContent) {
    editor.getSession().getDocument().setValue(localStorage.dataExplorerScriptContent);
  }
  // Why? Because.
  editor.$blockScrolling = Infinity;
  editor.getSession().setMode('ace/mode/javascript');
  editor.setOptions({
    minLines: 15,
    maxLines: 30,
    useSoftTabs: true,
    tabSize: 2,
    printMarginColumn: 120
  });
  editor.resize();

  $('.js-theme-toggle').click(e => {
    e.preventDefault();
    if (theme === themes.dark) {
      theme = themes.light;
      $('.js-theme-toggle').text('🌙');
    } else {
      theme = themes.dark;
      $('.js-theme-toggle').text('☀️');
    }
    editor.setTheme(theme);
    localStorage.editorTheme = theme;
  });
  $('.js-theme-toggle').click().click();

  $('.add-data').on('click', ev => {
    ev.preventDefault();
    addDataListRow();
  });

  $(document).on('change', '.data-type-limit, .data-type-select', ({ target }) => {
    const $this = $(target);
    const isLimit = $this.hasClass('data-type-limit');
    const $limit = isLimit ? $this : $this.siblings(isLimit ? '.data-type-select' : '.data-type-limit').first();
    const $select = isLimit ? $this.siblings(isLimit ? '.data-type-select' : '.data-type-limit').first() : $this;

    if ($limit.val() && $select.val() && $limit.val().length > 0 && $select.val().length > 0) {
      const type = $select.val();
      const limit = $limit.val();
      fetchData(type, limit);
    }
  });

  $(document).on('change', '.data-type-select', ({ target }) => {
    const $this = $(target);
    if ($this.val().length > 0) {
      displaySchema($this.val());
    }
  });

  $('.toggle-script-help').on('click', ev => {
    ev.preventDefault();
    $('.script-help').slideToggle(500);
  });

  $('.run-script').on('click', ({ target }) => {
    const $this = $(target);
    $this.attr('disabled', 'disabled');

    validateDataset();

    let results = null;
    let error = null;
    try {
      // eslint-disable-next-line no-eval
      results = eval(editor.getValue())(store);
    } catch (err) {
      error = err;
    }

    renderResults(error, results);

    const csv = btoa(results.map(x => x.join(',')).join('\n'));
    const uri = `data:text/csv;base64,${csv}`;
    $('.csv-download').attr('href', uri);

    $this.removeAttr('disabled');
  });
}, () => {
  localStorage.dataExplorerScriptContent = editor.getValue();
});
