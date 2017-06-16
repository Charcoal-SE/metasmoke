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

import Turbolinks from 'turbolinks';
import '../turbolinks_prefetch.coffee'; // The original is in coffee.
Turbolinks.start();

import '../cable';

import '../admin';
import '../api';
import '../code_status';
import '../flag_conditions';
import '../reasons';
import '../review';
import '../stack_exchange_users';
import '../status';
import '../user_site_settings';

import createDebug from 'debug';
const debug = createDebug('ms:app');

$(document).on('turbolinks:load', () => {
  $('.sortable-table').tablesort();

  $('.selectpicker').selectpicker();

  $('.admin-report').click(function (ev) {
    ev.preventDefault();
    const reason = window.prompt('Why does this post need admin attention?');
    if (reason === null) {
      return;
    }
    $.ajax({
      type: 'POST',
      url: '/posts/needs_admin',
      data: {
        id: $(this).data('post-id'),
        reason
      }
    }).done(data => {
      if (data === 'OK') {
        window.alert('Post successfully reported for admin attention.');
      }
    }).fail(jqXHR => {
      window.alert('Post was not reported: status ' + jqXHR.status);
      debug('report failed:', jqXHR.responseText, 'status:', jqXHR.status, '\n', jqXHR);
    });
  });

  $('.admin-report-done').click(function (ev) {
    ev.preventDefault();
    $.ajax({
      type: 'POST',
      url: '/admin/clear_flag',
      data: {
        id: $(this).data('flag-id')
      },
      target: $(this)
    }).done(function (data) {
      if (data === 'OK') {
        window.alert('Marked done.');
        $(this.target).parent().parent().siblings().addBack().siblings('.flag-' + $(this.target).data('flag-id')).first().prev().remove();
        $(this.target).parents('tr').remove();
      }
    }).fail(jqXHR => {
      window.alert('Failed to mark done: status ' + jqXHR.status);
      debug('flag completion failed:', jqXHR.responseText, 'status:', jqXHR.status, '\n', jqXHR);
    });
  });

  $('.announcement-collapse').click(ev => {
    ev.preventDefault();

    const collapser = $('.announcement-collapse');
    const announcements = $('.announcements').children('.alert-info');
    const showing = collapser.text().indexOf('Hide') > -1;
    if (showing) {
      const text = announcements.map((i, x) => $('p', x).text()).toArray().join(' ');
      localStorage.setItem('metasmoke-announcements-read', text);
      $('.announcements').slideUp(500);
      collapser.text('Show announcements');
    } else {
      localStorage.removeItem('metasmoke-announcements-read');
      $('.announcements').slideDown(500);
      collapser.text('Hide announcements');
    }
  });

  (function () {
    const announcements = $('.announcements').children('.alert-info');
    const text = announcements.map((i, x) => $('p', x).text()).toArray().join(' ');

    const read = localStorage.getItem('metasmoke-announcements-read');
    if (read && read === text) {
      $('.announcements').hide();
      $('.announcement-collapse').text('Show announcements');
    }
  })();
});
