import createDebug from 'debug';
import { onLoad } from './util'

const debug = createDebug('ms:data');

window.store = {};

let addDataListRow = function() {
    $(".data-list").prepend($("#data-list-row").clone());
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
    debug('fetchData:', type, limit);
    let limits = {};
    limits[type] = limit;
    fetchDataMultiple([type], limits);
};

let fetchDataMultiple = function(types, limits) {
    debug('fetchDataMultiple:', types, limits);
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
    const types = ['announcements', 'api_keys', 'audits', 'commit_statuses', 'deletion_logs', 'feedbacks',
                   'flag_conditions', 'flag_logs', 'flag_settings', 'moderator_sites', 'posts', 'reasons', 'roles',
                   'sites', 'smoke_detectors', 'stack_exchange_users', 'statistics', 'user_site_settings', 'users'];
    const select = $("#data-list-row").find(".data-type-select");
    for (let i = 0; i < types.length; i++) {
        let dataType = types[i];
        let $option = $("<option>").val(dataType).text(humanize(dataType));
        select.append($option);
    }
};

onLoad(() => {
    preloadDataTypes();
    $(".schema-display").hide();

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
});
