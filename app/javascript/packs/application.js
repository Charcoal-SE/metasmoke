// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

/* eslint-disable
  import/no-unassigned-import,
  import/newline-after-import,
  import/first
*/

import createDebug from 'debug';

import Turbolinks from 'turbolinks';
import '../turbolinks_prefetch.coffee'; // The original is in coffee.
Turbolinks.start();

import '../cable';

import '../admin';
import '../api';
import '../code_status';
import '../data';
import '../developer';
import '../domain_links';
import '../email_preferences';
import '../flag_conditions';
import '../flag_settings';
import '../reasons';
import '../review';
import '../stack_exchange_users';
import '../status';
import '../user_site_settings';
import '../graphs';
import '../site_settings';
import '../comments';
import '../spam_waves';
import '../general_fixes';

import { onLoad, installSelectpickers, uuid4, hashCode } from '../util';

const metasmoke = window.metasmoke = {
  debug: createDebug('ms:application'),

  storage: new Proxy(localStorage, {
    get: (target, name) => {
      return target.metasmoke ? JSON.parse(target.metasmoke)[name] : null;
    },

    set: (target, name, value) => {
      if (!target.metasmoke) {
        target.metasmoke = JSON.stringify({});
      }
      const data = JSON.parse(target.metasmoke);
      data[name] = value;
      target.metasmoke = JSON.stringify(data);
      return true;
    }
  }),

  init: Object.assign(() => {
    $('[data-toggle="tooltip"]').tooltip();
    $('[data-toggle="popover"]').popover();

    $('.sortable-table').tablesort();

    $('.form-submit').click(ev => {
      $(ev.target).parent().submit();
    });

    $('.wave-preview').click(() => {
      $.ajax({
        url: '/spam-waves/preview',
        data: $('form').serialize()
      });
    });

    installSelectpickers();

    metasmoke.init.setupAnnouncementCollapse();
    metasmoke.init.initFormParamCleanups();
    metasmoke.init.setupAjaxDeduplicator();
    metasmoke.init.checkReviewCountKicker();
    metasmoke.init.setPostRenderModes();
  }, {
    setupAnnouncementCollapse: () => {
      $('.announcement-collapse').click(ev => {
        ev.preventDefault();

        const collapser = $('.announcement-collapse');
        const announcements = $('.announcements').children('.alert-info');
        const showing = collapser.text().indexOf('Hide') > -1;
        if (showing) {
          const text = announcements.map((i, x) => $('p', x).text()).toArray().join(' ');
          metasmoke.storage['read-announcements'] = text;
          $('.announcements:not(body)').slideUp(500);
          collapser.text('Show announcements');
        }
        else {
          metasmoke.storage['read-announcements'] = null;
          $('.announcements:not(body)').slideDown(500);
          collapser.text('Hide announcements');
        }
      });

      const announcements = $('.announcements').children('.alert-info');
      const text = announcements.map((i, x) => $('p', x).text()).toArray().join(' ');

      const read = metasmoke.storage['read-announcements'];
      if (read && read === text) {
        $('.announcements:not(body)').hide();
        $('.announcement-collapse').text('Show announcements');
      }
    },

    initFormParamCleanups: () => {
      const formParameterCleanups = [];

      $(document.body).on('submit', 'form', ev => {
        const tgt = $(ev.target);
        if (formParameterCleanups.indexOf(tgt[0]) === -1) {
          ev.preventDefault();
          $(tgt.find(':input').toArray().filter(e => $(e).val() === '')).attr('disabled', true);
          formParameterCleanups.push(tgt[0]);
          tgt.submit();
        }
      });
    },

    setupAjaxDeduplicator: () => {
      $(document.body).on('ajax:beforeSend', 'form[data-deduplicate]', (ev, xhr) => {
        const $tgt = $(ev.target);
        if (!$tgt.data('dedup-uuid')) {
          $tgt.attr('data-dedup-uuid', uuid4());
        }

        const dedupUuid = $tgt.data('dedup-uuid');
        const data = $(ev.target).serialize();
        const requestId = `${dedupUuid}/${hashCode(data)}`;
        xhr.setRequestHeader('X-AJAX-Deduplicate', requestId);
      });
    },

    checkReviewCountKicker: () => {
      const reviewCounter = $('.reviews-count');
      if (reviewCounter.length > 0 && parseInt(reviewCounter.text().trim(), 10) > 50) {
        const reviewAlertedAt = parseInt(metasmoke.storage['review-alerted-at'] || 0, 10);
        const diff = (Date.now() - reviewAlertedAt) / 1000;
        if (diff >= 14400) {
          reviewCounter.attr('data-toggle', 'tooltip').attr('data-placement', 'bottom')
          .attr('title', 'Got 5 minutes to do 10 reviews?');
          reviewCounter.tooltip('show');
          metasmoke.storage['review-alerted-at'] = Date.now().toString();
        }
      }
    },

    setPostRenderModes: () => {
      $(document.body).on('click', '.post-render-mode', ev => {
        const mode = $(ev.target).data('render-mode');
        metasmoke.storage['post-render-mode'] = mode;
        metasmoke.debug(`default render mode updated to ${mode}`);
      });

      if (metasmoke.storage['post-render-mode']) {
        $(`.post-render-mode[data-render-mode="${metasmoke.storage['post-render-mode']}"]`).tab('show');
      }

      $(document.body).on('DOMNodeInserted', '.post-body, .review-item-container', () => {
        $(`.post-render-mode[data-render-mode="${metasmoke.storage['post-render-mode']}"]`).tab('show');
      });
    }
  })
};

onLoad(() => {
  metasmoke.init();
});
