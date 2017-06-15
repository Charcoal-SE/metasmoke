import createDebug from 'debug';
import { onLoad } from './util'

const debug = createDebug('ms:data');

window.store = {};
window.results = [];

let addDataListRow = function() {
    $(".data-list").prepend($("#data-list-row").clone().removeClass('template'));
};

let displaySchema = function(table) {
    $.ajax({
        'type': 'GET',
        'url': `/data/schema?table=${table}`
    }).done(data => {
        $(".schema-display").show();
        $(".schema-table-name").text(table);
        $(".table-schema").html(data.join('<br/>'));
    }).fail(xhr => {
        debug('Failed to get schema:', xhr);
    });
};

let fetchData = function(type, limit) {
    let limits = {};
    limits[type] = limit;
    fetchDataMultiple([type], limits);
};

let fetchDataMultiple = function(types, limits) {
    let required = [];
    for (let i = 0; i < types.length; i++) {
        if (!store.hasOwnProperty(types[i]) || store[types[i]].length !== limits[types[i]]) {
            required.push(types[i]);
        }
    }

    $.ajax({
        'type': 'GET',
        'url': '/data/retrieve',
        'data': {
            'types': required,
            'limits': limits
        }
    }).done(data => {
        let keys = Object.keys(data);
        for (let i = 0; i < keys.length; i++) {
            let key = keys[i];
            store[key] = data[key];
        }
    }).fail(xhr => {
        debug('Couldn\'t load data:', xhr);
    });
};

let humanize = function(s) {
    s = s.replace(/[-_]/g, ' ');
    return s.charAt(0).toUpperCase() + s.slice(1);
};

let preloadDataTypes = function() {
    const types = ['announcements', 'api_keys', 'commit_statuses', 'deletion_logs', 'feedbacks',
                   'flag_conditions', 'flag_logs', 'flag_settings', 'moderator_sites', 'posts', 'reasons', 'roles',
                   'sites', 'smoke_detectors', 'stack_exchange_users', 'statistics', 'user_site_settings', 'users'];
    const select = $("#data-list-row").find(".data-type-select");
    for (let i = 0; i < types.length; i++) {
        let dataType = types[i];
        let $option = $("<option>").val(dataType).text(humanize(dataType));
        select.append($option);
    }
};

let renderResults = function() {
    $(".results-table").show();

    let $headerRow = $(".results-header");
    let $resultBody = $(".results-body");

    $headerRow.find('th').remove();
    $resultBody.find('tr').remove();

    if (!(results instanceof Array)) {
        throw new Error('window.results is not an array; can\'t render it');
    }

    let typeCheck = results.map(x => x instanceof Array);
    if (typeCheck.indexOf(false) >= 0) {
        throw new Error('Not all elements of window.results are arrays; can\'t render results');
    }

    let columns = Math.max(...results.map(x => x.length));
    if (results.length < 1) {
        return;
    }

    let headers = results[0];
    for (let i = 0; i < headers.length; i++) {
        $headerRow.append($("<th>").text(headers[i]));
    }

    if (results.length < 2) {
        return;
    }

    for (let i = 1; i < results.length; i++) {
        let $row = $("<tr>");
        for (let m = 0; m < results[i].length; m++) {
            $row.append($("<td>").text(results[i][m]));
        }
        $resultBody.append($row);
    }
};

let validateDataset = function() {
    let types = [];
    let limits = {};
    $(".data-list-item").each((i, item) => {
        if ($(item).hasClass('template')) {
            return;
        }

        let $this = $(item);
        let type = $this.find('.data-type-select').first().val();
        let limit = $this.find('.data-type-limit').first().val();
        if (type && limit && type.length > 0 && limit.length > 0) {
            types.push(type);
            limits[type] = limit;
        }
    });

    let storedTypes = Object.keys(store);
    let surplusTypes = storedTypes.filter(x => types.indexOf(x) < 0);
    for (let m = 0; m < surplusTypes.length; m++) {
        delete store[surplusTypes[m]];
    }

    fetchDataMultiple(types, limits);
};

onLoad(() => {
    preloadDataTypes();
    $(".schema-display").hide();
    $(".script-help").hide();

    let editor = ace.edit('editor');
    editor.setTheme('ace/theme/monokai');
    editor.getSession().setMode('ace/mode/javascript');
    editor.setOptions({
        minLines: 15,
        maxLines: 30,
        useSoftTabs: true,
        tabSize: 4,
        printMarginColumn: 120
    });
    editor.resize();

    $(".add-data").on('click', ev => {
        ev.preventDefault();
        addDataListRow();
    });

    $(document).on('change', ".data-type-limit, .data-type-select", ev => {
        let $this = $(ev.target);
        let isLimit = $this.hasClass('data-type-limit');
        let $limit = isLimit ? $this : $this.siblings(isLimit ? '.data-type-select' : '.data-type-limit').first();
        let $select = isLimit ? $this.siblings(isLimit ? '.data-type-select' : '.data-type-limit').first() : $this;

        if ($limit.val() && $select.val() && $limit.val().length > 0 && $select.val().length > 0) {
            let type = $select.val();
            let limit = $limit.val();
            fetchData(type, limit);
        }
    });

    $(document).on('change', '.data-type-select', ev => {
        let $this = $(ev.target);
        if ($this.val().length > 0) {
            displaySchema($this.val());
        }
    });

    $(".toggle-script-help").on('click', ev => {
        ev.preventDefault();
        $(".script-help").slideToggle(500);
    });

    $(".run-script").on('click', ev => {
        let $this = $(ev.target);
        $this.attr('disabled', 'disabled');

        validateDataset();

        results = [];
        let scriptContent = editor.getValue();
        eval.call(null, scriptContent);
        renderResults();

        $this.removeAttr('disabled');
    });
});
